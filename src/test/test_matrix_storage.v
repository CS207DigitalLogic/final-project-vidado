module test_matrix_storage #(
    parameter DATA_WIDTH        = 8,
    parameter MAX_SIZE          = 5,
    parameter MATRIX_NUM        = 8,        // 全局最多8个矩阵
    parameter MAX_MATRIX_PER_SIZE = 4,      // 每个规模最多4个矩阵
    parameter CLK_FREQ          = 100000000,
    parameter BAUD_RATE         = 115200
)(
    input wire                     clk,
    input wire                     rst_n,
    // 矩阵写入接口
    input wire                     matrix_wr_en,
    input wire [MATRIX_IDX_W-1:0]  matrix_idx,
    input wire [2:0]               store_row,      // 写入时指定存储规模（行）
    input wire [2:0]               store_col,      // 写入时指定存储规模（列）
    input wire [ADDR_IN_W-1:0]     wr_addr_in,
    input wire [DATA_WIDTH-1:0]    matrix_wr_data,
    
    // 遍历控制接口
    input wire                     traverse_trig,  // 单次遍历触发（手动）
    input wire                     all_traverse_trig, // 【新增】遍历所有矩阵触发
    input wire [2:0]               traverse_row,   // 目标遍历规模（行，手动指定）
    input wire [2:0]               traverse_col,   // 目标遍历规模（列，手动指定）
    
    // 状态反馈接口
    output wire                    traverse_busy,  // 遍历中
    output wire                    traverse_done,  // 遍历完成（脉冲）
    // UART输出接口
    output wire                    uart_tx,
    //LEDs for debug
    output  [13:0]             led
);

// ---------------------------
// 局部参数
// ---------------------------
localparam MEM_DEPTH_PER_MATRIX = MAX_SIZE * MAX_SIZE;
localparam ADDR_IN_W = (MEM_DEPTH_PER_MATRIX <= 1)  ? 1 : 
                      (MEM_DEPTH_PER_MATRIX <= 2)  ? 2 : 
                      (MEM_DEPTH_PER_MATRIX <= 4)  ? 3 : 
                      (MEM_DEPTH_PER_MATRIX <= 8)  ? 4 : 
                      (MEM_DEPTH_PER_MATRIX <= 16) ? 5 : 
                      (MEM_DEPTH_PER_MATRIX <= 32) ? 5 : 
                      (MEM_DEPTH_PER_MATRIX <= 64) ? 6 : 
                      (MEM_DEPTH_PER_MATRIX <= 128) ? 7 : 8;

localparam MATRIX_IDX_W = (MATRIX_NUM <= 1)  ? 1 : 
                         (MATRIX_NUM <= 2)  ? 2 : 
                         (MATRIX_NUM <= 4)  ? 3 : 
                         (MATRIX_NUM <= 8)  ? 3 : 
                         (MATRIX_NUM <= 16) ? 4 : 
                         (MATRIX_NUM <= 32) ? 5 : 6;

localparam SEL_IDX_W = (MAX_MATRIX_PER_SIZE <= 1)  ? 1 : 
                      (MAX_MATRIX_PER_SIZE <= 2)  ? 2 : 
                      (MAX_MATRIX_PER_SIZE <= 4)  ? 2 : 
                      (MAX_MATRIX_PER_SIZE <= 8)  ? 3 : 
                      (MAX_MATRIX_PER_SIZE <= 16) ? 4 : 5;

// ---------------------------
// 内部连接信号
// ---------------------------
wire [DATA_WIDTH-1:0] matrix_rd_data;
wire matrix_burst_done;
wire [2:0] curr_store_row;
wire [2:0] curr_store_col;
wire [SEL_IDX_W-1:0] size_cnt_out;
wire sel_by_size;
wire [2:0] sel_row;
wire [2:0] sel_col;
wire [SEL_IDX_W-1:0] sel_idx;

wire uart_tx_start;
wire [DATA_WIDTH-1:0] uart_tx_data;
wire uart_tx_busy;
wire buf_full;
wire send_done;
wire matrix_burst_en;
wire send_trig;

// ---------------------------
// 【新增逻辑】全矩阵遍历控制状态机
// ---------------------------
// 状态定义
localparam S_IDLE       = 3'd0;
localparam S_UPDATE_SIZE= 3'd1; // 更新自动遍历的规模
localparam S_WAIT_CNT   = 3'd2; // 等待存储模块输出该规模的计数值
localparam S_CHECK_CNT  = 3'd3; // 检查该规模下是否有矩阵
localparam S_TRIGGER    = 3'd4; // 触发底层遍历模块
localparam S_WAIT_DONE  = 3'd5; // 等待底层遍历完成
localparam S_NEXT_SIZE  = 3'd6; // 准备下一个规模

reg [2:0] fsm_state;
reg [2:0] fsm_state1;
reg [2:0] auto_row;
reg [2:0] auto_col;
reg       auto_trig;
reg       is_all_mode; // 1=全遍历模式, 0=手动模式

// 上升沿检测 all_traverse_trig
reg trig_d1, trig_d2;
wire trig_pos = trig_d1 & ~trig_d2;

reg led5;
//assign led[2] = fsm_state1[0];
 //   assign led[3] = fsm_state1[1];
//    assign led[4] = fsm_state1[2];
//    assign led[5] = led5;
//    assign led[6] = all_traverse_trig;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        trig_d1 <= 1'b0;
        trig_d2 <= 1'b0;
    end else begin
        trig_d1 <= all_traverse_trig;
        trig_d2 <= trig_d1;
    end
end
always @(*) begin
    fsm_state1 = fsm_state+1;
end
assign led[7]=traverse_busy;
assign led[8]=1'b1;
reg led9,led10,led11,led12,led13;
assign led[9]=led9;
assign led[10]=led10;
assign led[11]=led11;
assign led[12]=led12;
assign led[13]=led13;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fsm_state <= S_IDLE;
        auto_row  <= 3'd1;
        auto_col  <= 3'd1;
        auto_trig <= 1'b0;
        is_all_mode <= 1'b0;
    end else begin
        if(trig_pos) begin
           led5=1'b1;
        end
        case (fsm_state)
            S_IDLE: begin
                auto_trig <= 1'b0;
                // 当检测到触发，且系统不忙时启动
                if (trig_pos && !traverse_busy) begin
                    led9=1'b1;
                    fsm_state <= S_UPDATE_SIZE;
                    is_all_mode <= 1'b1;
                    auto_row <= 3'd1;
                    auto_col <= 3'd1;
                end else if (!is_all_mode) begin
                    // 确保非全遍历模式下标志位清除
                    is_all_mode <= 1'b0;
                end
            end

            S_UPDATE_SIZE: begin
                // 状态仅用于更新Mux输出的地址，需要等待一拍给 size_cnt_out 反应
                fsm_state <= S_WAIT_CNT;
            end

            S_WAIT_CNT: begin
                // multi_matrix_storage 的 size_cnt_out 更新需要一个时钟周期
                fsm_state <= S_CHECK_CNT;
            end

            S_CHECK_CNT: begin
                if (size_cnt_out > 0) begin
                    // 该规模有矩阵，触发遍历
                    fsm_state <= S_TRIGGER;
                    led10=1'b1;
                end else begin
                    // 该规模无矩阵，跳过
                    fsm_state <= S_NEXT_SIZE;
                end
            end

            S_TRIGGER: begin
                auto_trig <= 1'b1; // 发送脉冲
                fsm_state <= S_WAIT_DONE;
            end

            S_WAIT_DONE: begin
                auto_trig <= 1'b0; // 撤销脉冲
                // 等待底层模块完成该规模的遍历
                if (traverse_done) begin
                    fsm_state <= S_NEXT_SIZE;
                end
            end

            S_NEXT_SIZE: begin
                // 遍历逻辑：先增加列，列满增加行
                if (auto_col < MAX_SIZE) begin
                    auto_col <= auto_col + 1'd1;
                    fsm_state <= S_UPDATE_SIZE;
                end else begin
                    auto_col <= 3'd1;
                    if (auto_row < MAX_SIZE) begin
                        auto_row <= auto_row + 1'd1;
                        fsm_state <= S_UPDATE_SIZE;
                        led11=1'b1; 
                    end else begin
                        // 所有行列遍历完成
                        fsm_state <= S_IDLE;
                        is_all_mode <= 1'b0;
                        led12=1'b1;
                    end
                end
            end

            default: fsm_state <= S_IDLE;
        endcase
    end
end

// ---------------------------
// 信号多路复用 (MUX)
// ---------------------------
// 如果处于全遍历模式，使用自动生成的信号；否则使用外部输入信号
wire [2:0] active_traverse_row = is_all_mode ? auto_row : traverse_row;
wire [2:0] active_traverse_col = is_all_mode ? auto_col : traverse_col;
wire       active_traverse_trig= is_all_mode ? auto_trig : traverse_trig;

// ---------------------------
// 1. 实例化矩阵存储模块
// ---------------------------
multi_matrix_storage #(
    .DATA_WIDTH(DATA_WIDTH),
    .MAX_SIZE(MAX_SIZE),
    .MATRIX_NUM(MATRIX_NUM),
    .MAX_MATRIX_PER_SIZE(MAX_MATRIX_PER_SIZE)
) u_multi_matrix (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(matrix_wr_en),
    .matrix_idx(matrix_idx),
    .store_row(store_row),
    .store_col(store_col),
    .wr_addr_in(wr_addr_in),
    .wr_data(matrix_wr_data),
    .sel_by_size(sel_by_size),
    .sel_row(sel_row),
    .sel_col(sel_col),
    .sel_idx(sel_idx),
    .rd_en(1'b0),
    .rd_addr_in(0),
    .burst_en(matrix_burst_en),
    .rd_data(matrix_rd_data),
    .burst_done(matrix_burst_done),
    .curr_store_row(curr_store_row),
    .curr_store_col(curr_store_col),
    .curr_matrix_idx(),
    // 【修改】使用复用后的信号
    .traverse_row(active_traverse_row),
    .traverse_col(active_traverse_col),
    .size_cnt_out(size_cnt_out),
    .debug_leds(led[6:2])
);

// ---------------------------
// 2. 实例化规模遍历控制模块
// ---------------------------
matrix_size_traverse #(
    .SEL_IDX_W(SEL_IDX_W),
    .CLK_FREQ(CLK_FREQ)
) u_traverse_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    // 【修改】使用复用后的信号
    .traverse_trig(active_traverse_trig),
    .traverse_row(active_traverse_row),
    .traverse_col(active_traverse_col),
    
    .size_cnt_out(size_cnt_out),
    .sel_by_size(sel_by_size),
    .sel_row(sel_row),
    .sel_col(sel_col),
    .sel_idx(sel_idx),
    .matrix_burst_en(matrix_burst_en),
    .send_trig(send_trig),
    .buf_full(buf_full),
    .send_done(send_done),
    .traverse_busy(traverse_busy),
    .traverse_done(traverse_done)
);

// ---------------------------
// 3. 实例化缓冲区桥接模块 (无变化)
// ---------------------------
matrix_to_uart #(
    .DATA_WIDTH(DATA_WIDTH),
    .MAX_SIZE(MAX_SIZE),
    .CLK_FREQ(CLK_FREQ)
) u_bridge_buf (
    .clk(clk),
    .rst_n(rst_n),
    .matrix_data(matrix_rd_data),
    .matrix_burst_done(matrix_burst_done),
    .matrix_burst_en(matrix_burst_en),
    .curr_row_valid(curr_store_row),
    .curr_col_valid(curr_store_col),
    .send_trig(send_trig),
    .uart_tx_start(uart_tx_start),
    .uart_tx_data(uart_tx_data),
    .uart_tx_busy(uart_tx_busy),
    .buf_full(buf_full),
    .send_done(send_done)
);

// ---------------------------
// 4. 实例化UART发送模块 (无变化)
// ---------------------------
uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) u_uart_tx (
    .clk(clk),
    .rst_n(rst_n),
    .tx_start(uart_tx_start),
    .tx_data(uart_tx_data),
    .tx(uart_tx),
    .tx_busy(uart_tx_busy)
);

endmodule