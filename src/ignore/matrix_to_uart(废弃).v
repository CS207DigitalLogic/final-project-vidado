module matrix_to_uart #(
    parameter DATA_WIDTH        = 8,                // 数据位宽（与矩阵/uart模块一致）
    parameter MAX_SIZE          = 5,                // 单个矩阵最大规模（5x5）
    parameter MATRIX_NUM        = 8,                // 全局最大矩阵数量（与矩阵模块一致）
    parameter MAX_MATRIX_PER_SIZE = 4,              // 每个规模最多矩阵数（与矩阵模块一致）
    parameter CLK_FREQ          = 100000000         // 系统时钟频率（与UART模块一致）
)(
    input wire                     clk,                // 系统时钟
    input wire                     rst_n,              // 低有效复位
    // ---------------------------
    // 功能选择与矩阵选择控制
    // ---------------------------
    input wire [1:0]               send_func,          // 发送功能选择：00=指定序号，01=指定规模所有，10=统计信息
    input wire                     sel_by_size,        // 1=按规模选择，0=按全局索引（仅功能00用）
    input wire [2:0]               sel_row,            // 选择的规模（行数）
    input wire [2:0]               sel_col,            // 选择的规模（列数）
    input wire [SEL_IDX_W-1:0]     sel_idx,            // 同规模下的矩阵索引（仅功能00/01用）
    input wire [MATRIX_IDX_W-1:0]  matrix_idx,         // 全局矩阵索引（仅功能00用）
    // ---------------------------
    // 矩阵存储模块暴露的核心数组（输入）
    // ---------------------------
    input wire [DATA_WIDTH-1:0]    mem_out [0:MATRIX_NUM-1] [0:MEM_DEPTH_PER_MATRIX-1],  // 矩阵数据
    input wire [2:0]               row_self_out [0:MATRIX_NUM-1],  // 每个矩阵实际行数
    input wire [2:0]               col_self_out [0:MATRIX_NUM-1],  // 每个矩阵实际列数
    input wire [MATRIX_IDX_W-1:0]  size2matrix_out [1:MAX_SIZE] [1:MAX_SIZE] [0:MAX_MATRIX_PER_SIZE-1],  // 规模→全局索引映射
    input wire [SEL_IDX_W-1:0]     size_cnt_out [1:MAX_SIZE] [1:MAX_SIZE],  // 每个规模矩阵数
    input wire [0:MATRIX_NUM-1]    matrix_init_flag_out,  // 矩阵初始化标记（统计总数用）
    // ---------------------------
    // 控制与UART接口
    // ---------------------------
    input wire                     send_trig,          // 触发UART发送
    input wire                     uart_tx_busy,       // UART忙状态（tx_busy）
    output reg                     uart_tx_start,      // UART发送触发（tx_start）
    output reg [DATA_WIDTH-1:0]    uart_tx_data,       // UART待发送数据（tx_data）
    // ---------------------------
    // 状态反馈
    // ---------------------------
    output reg                     buf_full,           // 缓冲区已满（数据读取完成）
    output reg                     send_done           // UART发送完成
);

// ---------------------------
// 局部参数（与矩阵存储模块一致）
// ---------------------------
localparam MEM_DEPTH_PER_MATRIX = MAX_SIZE * MAX_SIZE;  // 单个矩阵最大存储深度（25）
localparam BUF_DEPTH = MEM_DEPTH_PER_MATRIX;            // 缓冲区深度=单个矩阵最大深度

// 缓冲区地址位宽（覆盖BUF_DEPTH个地址）
localparam BUF_ADDR_W = (BUF_DEPTH <= 1)  ? 1 :
                       (BUF_DEPTH <= 2)  ? 2 :
                       (BUF_DEPTH <= 4)  ? 3 :
                       (BUF_DEPTH <= 8)  ? 4 :
                       (BUF_DEPTH <= 16) ? 5 :
                       (BUF_DEPTH <= 32) ? 6 :
                       7;

// 全局矩阵索引位宽（与矩阵模块一致）
localparam MATRIX_IDX_W = (MATRIX_NUM <= 1)  ? 1 :
                         (MATRIX_NUM <= 2)  ? 2 :
                         (MATRIX_NUM <= 4)  ? 3 :
                         (MATRIX_NUM <= 8)  ? 3 :
                         (MATRIX_NUM <= 16) ? 4 :
                         (MATRIX_NUM <= 32) ? 5 :
                         6;

// 同规模索引位宽（与矩阵模块一致）
localparam SEL_IDX_W = (MAX_MATRIX_PER_SIZE <= 1)  ? 1 :
                      (MAX_MATRIX_PER_SIZE <= 2)  ? 2 :
                      (MAX_MATRIX_PER_SIZE <= 4)  ? 2 :
                      (MAX_MATRIX_PER_SIZE <= 8)  ? 3 :
                      (MAX_MATRIX_PER_SIZE <= 16) ? 4 :
                      5;

// ---------------------------
// 功能选择定义
// ---------------------------
localparam FUNC_SPEC_IDX   = 2'b00;  // 发送指定规模下指定序号的矩阵
localparam FUNC_SPEC_SCALE = 2'b01;  // 发送指定规模的所有矩阵
localparam FUNC_ALL_INFO   = 2'b10;  // 发送所有矩阵的统计信息

// ---------------------------
// 状态机状态定义（修正为4位，支持0~11）
// ---------------------------
localparam IDLE                = 4'd0;  // 空闲
localparam READ_MATRIX         = 4'd1;  // 读取单个矩阵到缓冲区
localparam SEND_SIGN           = 4'd2;  // 发送符号（'-'或跳过）
localparam SEND_HIGH           = 4'd3;  // 发送数据高4位ASCII
localparam SEND_LOW            = 4'd4;  // 发送数据低4位ASCII
localparam SEND_SPACE          = 4'd5;  // 发送元素分隔空格
localparam SEND_NEWLINE        = 4'd6;  // 发送矩阵结束换行
localparam SEND_BATCH_NEXT     = 4'd7;  // 批量发送：切换到下一个矩阵
localparam SEND_INFO_TOTAL     = 4'd8;  // 发送统计信息：全局矩阵总数
localparam SEND_INFO_SCALE     = 4'd9;  // 发送统计信息：单个规模详情（r*c*cnt）
localparam SEND_INFO_SEP       = 4'd10; // 发送统计信息：分隔符（空格/*）
localparam SEND_INFO_DONE      = 4'd11; // 发送统计信息：完成

// ---------------------------
// 内部信号（新增负数处理相关）
// ---------------------------
// 矩阵选择相关
reg [MATRIX_IDX_W-1:0] valid_global_idx;          // 有效目标矩阵全局索引
reg [2:0] curr_row, curr_col;                     // 目标矩阵有效行数/列数
reg [2:0] r_valid, c_valid;                       // 有效选择规模（行/列）
reg [SEL_IDX_W-1:0] spec_scale_total;             // 指定规模的矩阵总数

// 缓冲区相关
reg [DATA_WIDTH-1:0] matrix_buf [0:BUF_DEPTH-1];  // 矩阵数据缓冲区
reg [BUF_ADDR_W-1:0] buf_wr_idx;                  // 缓冲区写地址
reg [BUF_ADDR_W-1:0] buf_rd_idx;                  // 缓冲区读地址
reg [BUF_ADDR_W-1:0] buf_total;                   // 缓冲区有效元素数

// 批量发送相关
reg [SEL_IDX_W-1:0] batch_idx;                    // 批量发送时的同规模索引计数器

// 统计信息发送相关
reg [MATRIX_IDX_W-1:0] global_matrix_cnt;          // 全局已初始化矩阵总数
reg [2:0] traverse_r, traverse_c;                  // 规模遍历计数器（行/列）
reg [3:0] info_digit;                              // 数字拆分缓存（0~99）
reg [1:0] info_digit_cnt;                          // 数字位数计数器（1~2位）
reg [2:0] info_state;                              // 统计信息发送子状态：0=行，1=*，2=列，3=*，4=个数，5=空格

// 负数处理相关（新增）
reg is_negative;                                   // 当前元素是否为负数（bit7=1）
reg [DATA_WIDTH-1:0] abs_data;                     // 当前元素的绝对值（补码转原码）

// 状态机主状态（已为4位，无需修改）
reg [3:0] send_state;                              // 主状态机（4位支持0~15，满足扩展需求）

// ---------------------------
// 1. 组合逻辑：计算核心参数（矩阵选择+统计信息+负数处理）
// ---------------------------
reg [SEL_IDX_W-1:0] s_valid;
always @(*) begin
    // 1.1 有效选择规模计算（边界保护：1~MAX_SIZE）
    r_valid = (sel_row >= 1 && sel_row <= MAX_SIZE) ? sel_row : 1'd1;
    c_valid = (sel_col >= 1 && sel_col <= MAX_SIZE) ? sel_col : 1'd1;
    spec_scale_total = size_cnt_out[r_valid][c_valid];  // 指定规模的矩阵总数

    // 1.2 目标矩阵索引计算（按功能区分）
    case (send_func)
        FUNC_SPEC_IDX: begin
            if (sel_by_size) begin
                // 功能00：按规模+指定序号选择
                s_valid = (sel_idx < spec_scale_total) ? sel_idx : {SEL_IDX_W{1'b0}};
                valid_global_idx = (spec_scale_total > 0) ? size2matrix_out[r_valid][c_valid][s_valid] : {MATRIX_IDX_W{1'b0}};
            end else begin
                // 功能00：按全局索引选择
                valid_global_idx = (matrix_idx < MATRIX_NUM && matrix_init_flag_out[matrix_idx]) ? matrix_idx : {MATRIX_IDX_W{1'b0}};
            end
            // 目标矩阵规模
            curr_row = row_self_out[valid_global_idx];
            curr_col = col_self_out[valid_global_idx];
            curr_row = (curr_row >= 1 && curr_row <= MAX_SIZE) ? curr_row : 1'd1;
            curr_col = (curr_col >= 1 && curr_col <= MAX_SIZE) ? curr_col : 1'd1;
        end
        FUNC_SPEC_SCALE: begin
            // 功能01：批量发送时，先默认选择第0个矩阵，后续由batch_idx控制
            valid_global_idx = (spec_scale_total > 0) ? size2matrix_out[r_valid][c_valid][0] : {MATRIX_IDX_W{1'b0}};
            curr_row = r_valid;
            curr_col = c_valid;
        end
        default: begin
            // 功能10：统计信息发送，无需目标矩阵
            valid_global_idx = {MATRIX_IDX_W{1'b0}};
            curr_row = 1'd0;
            curr_col = 1'd0;
        end
    endcase

    // 1.3 计算全局已初始化矩阵总数（遍历所有矩阵的初始化标记）
    global_matrix_cnt = {MATRIX_IDX_W{1'b0}};
    for (integer m = 0; m < MATRIX_NUM; m = m + 1) begin
        if (matrix_init_flag_out[m]) begin
            global_matrix_cnt = global_matrix_cnt + 1'b1;
        end
    end

    // 1.4 负数处理：判断符号+计算绝对值（仅矩阵数据发送时有效）
    if (send_state == SEND_SIGN && (send_func == FUNC_SPEC_IDX || send_func == FUNC_SPEC_SCALE)) begin
        is_negative = matrix_buf[buf_rd_idx][7];  // 最高位为1→负数
        // 补码转绝对值：负数=~data+1，正数=原码
        abs_data = is_negative ? (~matrix_buf[buf_rd_idx] + 1'b1) : matrix_buf[buf_rd_idx];
    end else begin
        is_negative = 1'b0;
        abs_data = {DATA_WIDTH{1'b0}};
    end
end

// ---------------------------
// 2. 辅助函数：数字转ASCII（支持0~99，返回两位ASCII，高位为0则不发送）
// ---------------------------
reg [DATA_WIDTH-1:0] digit2ascii [0:1];  // [0]高位，[1]低位
reg [7:0] num;
always @(*) begin
    case (info_state)
        3'd0: num = traverse_r;          // 规模行号
        3'd2: num = traverse_c;          // 规模列号
        3'd4: num = size_cnt_out[traverse_r][traverse_c];  // 规模矩阵数
        default: num = global_matrix_cnt;// 全局总数
    endcase

    // 拆分十位和个位
    digit2ascii[0] = (num / 10) ? (8'h30 + num / 10) : 8'h00;  // 高位（0则无效）
    digit2ascii[1] = 8'h30 + num % 10;                          // 低位（必有效）
end

// ---------------------------
// 3. 状态机与核心逻辑（时序）
// ---------------------------
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位初始化
        for (i = 0; i < BUF_DEPTH; i = i + 1) begin
            matrix_buf[i] <= {DATA_WIDTH{1'b0}};
        end
        buf_wr_idx <= {BUF_ADDR_W{1'b0}};
        buf_rd_idx <= {BUF_ADDR_W{1'b0}};
        buf_total <= {BUF_ADDR_W{1'b0}};
        buf_full <= 1'b0;
        send_state <= IDLE;
        uart_tx_start <= 1'b0;
        uart_tx_data <= {DATA_WIDTH{1'b0}};
        send_done <= 1'b0;

        // 批量发送相关复位
        batch_idx <= {SEL_IDX_W{1'b0}};

        // 统计信息发送相关复位
        traverse_r <= 1'd1;
        traverse_c <= 1'd1;
        info_digit <= 4'd0;
        info_digit_cnt <= 2'd0;
        info_state <= 3'd0;

        // 负数处理相关复位
        is_negative <= 1'b0;
        abs_data <= {DATA_WIDTH{1'b0}};
    end else begin
        // 默认值：避免 latch
        uart_tx_start <= 1'b0;
        send_done <= 1'b0;
        buf_full <= 1'b0;

        case (send_state)
            // ---------------------------
            // 空闲状态：等待发送触发，根据功能初始化参数
            // ---------------------------
            IDLE: begin
                if (send_trig && !uart_tx_busy) begin
                    case (send_func)
                        FUNC_SPEC_IDX: begin
                            // 功能00：指定序号→读取目标矩阵
                            send_state <= READ_MATRIX;
                            buf_wr_idx <= {BUF_ADDR_W{1'b0}};
                            buf_total <= curr_row * curr_col;
                        end
                        FUNC_SPEC_SCALE: begin
                            // 功能01：指定规模所有→初始化批量计数器，读取第一个矩阵
                            if (spec_scale_total > 0) begin
                                batch_idx <= {SEL_IDX_W{1'b0}};
                                valid_global_idx <= size2matrix_out[r_valid][c_valid][0];
                                send_state <= READ_MATRIX;
                                buf_wr_idx <= {BUF_ADDR_W{1'b0}};
                                buf_total <= r_valid * c_valid;
                            end else begin
                                // 该规模无矩阵→直接发送完成
                                send_done <= 1'b1;
                                send_state <= IDLE;
                            end
                        end
                        FUNC_ALL_INFO: begin
                            // 功能10：统计信息→发送全局总数
                            send_state <= SEND_INFO_TOTAL;
                            info_digit_cnt <= 2'd0;
                            traverse_r <= 1'd1;
                            traverse_c <= 1'd1;
                            info_state <= 3'd0;
                        end
                        default: send_state <= IDLE;
                    endcase
                end
            end

            // ---------------------------
            // 读取矩阵：从mem_out数组填充缓冲区（所有矩阵发送共用）
            // ---------------------------
            READ_MATRIX: begin
                matrix_buf[buf_wr_idx] <= mem_out[valid_global_idx][buf_wr_idx];
                buf_wr_idx <= buf_wr_idx + 1'b1;

                if (buf_wr_idx == buf_total - 1'b1) begin
                    buf_full <= 1'b1;
                    buf_rd_idx <= {BUF_ADDR_W{1'b0}};
                    send_state <= SEND_SIGN;  // 读取完成→先处理符号
                end
            end

            // ---------------------------
            // 发送符号：负数发送'-'，正数直接跳转到发送高4位
            // ---------------------------
            SEND_SIGN: begin
                if (!uart_tx_busy) begin
                    if (is_negative) begin
                        // 负数→发送'-'符号（ASCII 0x2D）
                        uart_tx_start <= 1'b1;
                        uart_tx_data <= 8'h2D;
                        send_state <= SEND_HIGH;
                    end else begin
                        // 正数/零→跳过符号，直接发送高4位
                        send_state <= SEND_HIGH;
                    end
                end
            end

            // ---------------------------
            // 发送单个矩阵：高4位ASCII（使用绝对值计算）
            // ---------------------------
            SEND_HIGH: begin
                if (!uart_tx_busy) begin
                    uart_tx_start <= 1'b1;
                    // 用绝对值的高4位计算ASCII
                    uart_tx_data <= (abs_data[7:4] < 4'd10) ? 
                                   (8'h30 + abs_data[7:4]) : 
                                   (8'h41 + abs_data[7:4] - 4'd10);
                    send_state <= SEND_LOW;
                end
            end

            // ---------------------------
            // 发送单个矩阵：低4位ASCII（使用绝对值计算）
            // ---------------------------
            SEND_LOW: begin
                if (!uart_tx_busy) begin
                    uart_tx_start <= 1'b1;
                    // 用绝对值的低4位计算ASCII
                    uart_tx_data <= (abs_data[3:0] < 4'd10) ? 
                                   (8'h30 + abs_data[3:0]) : 
                                   (8'h41 + abs_data[3:0] - 4'd10);
                    send_state <= SEND_SPACE;
                end
            end

            // ---------------------------
            // 发送单个矩阵：元素分隔空格
            // ---------------------------
            SEND_SPACE: begin
                if (!uart_tx_busy) begin
                    uart_tx_start <= 1'b1;
                    uart_tx_data <= 8'h20;  // 空格ASCII（0x20）

                    if (buf_rd_idx == buf_total - 1'b1) begin
                        send_state <= SEND_NEWLINE;  // 矩阵发送完成→换行
                    end else begin
                        buf_rd_idx <= buf_rd_idx + 1'b1;
                        send_state <= SEND_SIGN;  // 下一个元素→先处理符号
                    end
                end
            end

            // ---------------------------
            // 发送单个矩阵：换行（区分功能处理后续流程）
            // ---------------------------
            SEND_NEWLINE: begin
                if (!uart_tx_busy) begin
                    uart_tx_start <= 1'b1;
                    uart_tx_data <= 8'h0A;  // 换行ASCII（0x0A）

                    case (send_func)
                        FUNC_SPEC_IDX: begin
                            // 功能00：单个矩阵发送完成→复位
                            send_done <= 1'b1;
                            send_state <= IDLE;
                            buf_wr_idx <= {BUF_ADDR_W{1'b0}};
                            buf_rd_idx <= {BUF_ADDR_W{1'b0}};
                            buf_total <= {BUF_ADDR_W{1'b0}};
                        end
                        FUNC_SPEC_SCALE: begin
                            // 功能01：批量发送→检查是否还有下一个矩阵
                            if (batch_idx == spec_scale_total - 1'b1) begin
                                // 所有矩阵发送完成
                                send_done <= 1'b1;
                                send_state <= IDLE;
                                batch_idx <= {SEL_IDX_W{1'b0}};
                            end else begin
                                // 切换到下一个矩阵
                                send_state <= SEND_BATCH_NEXT;
                                batch_idx <= batch_idx + 1'b1;
                            end
                        end
                        default: send_state <= IDLE;
                    endcase
                end
            end

            // ---------------------------
            // 批量发送：切换到下一个矩阵
            // ---------------------------
            SEND_BATCH_NEXT: begin
                // 更新目标矩阵索引为下一个序号
                valid_global_idx <= size2matrix_out[r_valid][c_valid][batch_idx];
                send_state <= READ_MATRIX;
                buf_wr_idx <= {BUF_ADDR_W{1'b0}};
                buf_total <= r_valid * c_valid;  // 同一规模矩阵规模相同
            end

            // ---------------------------
            // 统计信息：发送全局矩阵总数（0~99）
            // ---------------------------
            SEND_INFO_TOTAL: begin
                if (!uart_tx_busy) begin
                    case (info_digit_cnt)
                        2'd0: begin
                            // 发送十位（若不为0）
                            if (digit2ascii[0] != 8'h00) begin
                                uart_tx_start <= 1'b1;
                                uart_tx_data <= digit2ascii[0];
                                info_digit_cnt <= 2'd1;
                            end else begin
                                // 十位为0→直接发送个位
                                uart_tx_start <= 1'b1;
                                uart_tx_data <= digit2ascii[1];
                                info_digit_cnt <= 2'd2;
                            end
                        end
                        2'd1: begin
                            // 发送个位
                            uart_tx_start <= 1'b1;
                            uart_tx_data <= digit2ascii[1];
                            info_digit_cnt <= 2'd2;
                        end
                        2'd2: begin
                            // 总数发送完成→发送空格，开始发送规模详情
                            uart_tx_start <= 1'b1;
                            uart_tx_data <= 8'h20;  // 空格
                            info_digit_cnt <= 2'd0;
                            send_state <= SEND_INFO_SCALE;
                        end
                    endcase
                end
            end

            // ---------------------------
            // 统计信息：发送单个规模详情（r*c*cnt）
            // ---------------------------
            SEND_INFO_SCALE: begin
                if (!uart_tx_busy) begin
                    case (info_state)
                        3'd0: begin
                            // 发送行号（r）
                            if (info_digit_cnt == 2'd0) begin
                                if (digit2ascii[0] != 8'h00) begin
                                    uart_tx_start <= 1'b1;
                                    uart_tx_data <= digit2ascii[0];
                                    info_digit_cnt <= 2'd1;
                                end else begin
                                    uart_tx_start <= 1'b1;
                                    uart_tx_data <= digit2ascii[1];
                                    info_digit_cnt <= 2'd2;
                                end
                            end else if (info_digit_cnt == 2'd1) begin
                                uart_tx_start <= 1'b1;
                                uart_tx_data <= digit2ascii[1];
                                info_digit_cnt <= 2'd2;
                            end else begin
                                // 行号发送完成→发送*
                                info_digit_cnt <= 2'd0;
                                info_state <= 3'd1;
                                send_state <= SEND_INFO_SEP;
                            end
                        end
                        3'd2: begin
                            // 发送列号（c）
                            if (info_digit_cnt == 2'd0) begin
                                if (digit2ascii[0] != 8'h00) begin
                                    uart_tx_start <= 1'b1;
                                    uart_tx_data <= digit2ascii[0];
                                    info_digit_cnt <= 2'd1;
                                end else begin
                                    uart_tx_start <= 1'b1;
                                    uart_tx_data <= digit2ascii[1];
                                    info_digit_cnt <= 2'd2;
                                end
                            end else if (info_digit_cnt == 2'd1) begin
                                uart_tx_start <= 1'b1;
                                uart_tx_data <= digit2ascii[1];
                                info_digit_cnt <= 2'd2;
                            end else begin
                                // 列号发送完成→发送*
                                info_digit_cnt <= 2'd0;
                                info_state <= 3'd3;
                                send_state <= SEND_INFO_SEP;
                            end
                        end
                        3'd4: begin
                            // 发送矩阵数（cnt）
                            if (info_digit_cnt == 2'd0) begin
                                if (digit2ascii[0] != 8'h00) begin
                                    uart_tx_start <= 1'b1;
                                    uart_tx_data <= digit2ascii[0];
                                    info_digit_cnt <= 2'd1;
                                end else begin
                                    uart_tx_start <= 1'b1;
                                    uart_tx_data <= digit2ascii[1];
                                    info_digit_cnt <= 2'd2;
                                end
                            end else if (info_digit_cnt == 2'd1) begin
                                uart_tx_start <= 1'b1;
                                uart_tx_data <= digit2ascii[1];
                                info_digit_cnt <= 2'd2;
                            end else begin
                                // 矩阵数发送完成→发送空格
                                info_digit_cnt <= 2'd0;
                                info_state <= 3'd5;
                                send_state <= SEND_INFO_SEP;
                            end
                        end
                    endcase
                end
            end

            // ---------------------------
            // 统计信息：发送分隔符（*或空格）
            // ---------------------------
            SEND_INFO_SEP: begin
                if (!uart_tx_busy) begin
                    case (info_state)
                        3'd1: begin
                            // 行号后→*
                            uart_tx_start <= 1'b1;
                            uart_tx_data <= 8'h2A;  // *的ASCII（0x2A）
                            info_state <= 3'd2;  // 下一步发送列号
                            send_state <= SEND_INFO_SCALE;
                        end
                        3'd3: begin
                            // 列号后→*
                            uart_tx_start <= 1'b1;
                            uart_tx_data <= 8'h2A;
                            info_state <= 3'd4;  // 下一步发送矩阵数
                            send_state <= SEND_INFO_SCALE;
                        end
                        3'd5: begin
                            // 矩阵数后→空格
                            uart_tx_start <= 1'b1;
                            uart_tx_data <= 8'h20;
                            // 遍历下一个规模
                            if (traverse_c == MAX_SIZE) begin
                                traverse_c <= 1'd1;
                                traverse_r <= traverse_r + 1'd1;
                            end else begin
                                traverse_c <= traverse_c + 1'd1;
                            end

                            // 检查是否遍历完所有规模
                            if (traverse_r > MAX_SIZE) begin
                                send_state <= SEND_INFO_DONE;
                            end else begin
                                // 检查当前规模是否有矩阵，无则跳过
                                if (size_cnt_out[traverse_r][traverse_c] == 0) begin
                                    send_state <= SEND_INFO_SCALE;
                                end else begin
                                    info_state <= 3'd0;  // 有矩阵→发送行号
                                    send_state <= SEND_INFO_SCALE;
                                end
                            end
                        end
                    endcase
                end
            end

            // ---------------------------
            // 统计信息：发送完成（换行）
            // ---------------------------
            SEND_INFO_DONE: begin
                if (!uart_tx_busy) begin
                    uart_tx_start <= 1'b1;
                    uart_tx_data <= 8'h0A;  // 换行
                    send_done <= 1'b1;
                    send_state <= IDLE;
                    // 复位统计相关参数
                    traverse_r <= 1'd1;
                    traverse_c <= 1'd1;
                    info_state <= 3'd0;
                end
            end

            // ---------------------------
            // 异常状态：复位到空闲
            // ---------------------------
            default: begin
                send_state <= IDLE;
            end
        endcase
    end
end

endmodule