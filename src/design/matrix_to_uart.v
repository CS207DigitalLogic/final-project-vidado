module matrix_to_uart #(
    parameter DATA_WIDTH    = 8,        // 与矩阵模块、UART模块一致
    parameter MAX_SIZE      = 5,        // 单个矩阵最大规模（5x5）
    parameter CLK_FREQ      = 100000000 // 系统时钟频率（与UART模块一致）
)(
    input wire                     clk,            // 系统时钟
    input wire                     rst_n,          // 低有效复位
    // 与多矩阵存储模块接口
    input wire [DATA_WIDTH-1:0]    matrix_data,    // 矩阵连续输出的数据（rd_data）
    input wire                     matrix_burst_done, // 矩阵输出完成（burst_done）
    input wire                     matrix_burst_en, // 矩阵连续输出使能（触发缓存）
    input wire [2:0]               curr_row_valid, // 当前矩阵有效行数（从矩阵模块获取）
    input wire [2:0]               curr_col_valid, // 当前矩阵有效列数（从矩阵模块获取）
    // 控制信号（触发发送缓冲区数据）
    input wire                     send_trig,      // 触发UART发送缓冲区数据（缓存完成后外部触发）
    // 与UART发送模块接口
    output reg                     uart_tx_start,  // UART发送触发（tx_start）
    output reg [DATA_WIDTH-1:0]    uart_tx_data,   // UART待发送数据（tx_data）
    input wire                     uart_tx_busy,   // UART忙状态（tx_busy）
    // 缓冲区状态反馈
    output reg                     buf_full,       // 缓冲区已满（缓存完成）
    output reg                     send_done       // UART发送完成
);

// 缓冲区参数：深度=MAX_SIZE*MAX_SIZE（25），存储完整矩阵
localparam BUF_DEPTH = MAX_SIZE * MAX_SIZE;
localparam BUF_ADDR_W = (BUF_DEPTH <= 1)  ? 1 :  // 1个元素→1位地址（0）
                       (BUF_DEPTH <= 2)  ? 2 :  // 2个元素→2位地址（0~1）
                       (BUF_DEPTH <= 4)  ? 3 :  // 3~4个元素→3位地址（0~3）
                       (BUF_DEPTH <= 8)  ? 4 :  // 5~8个元素→4位地址（0~7）
                       (BUF_DEPTH <= 16) ? 5 :  // 9~16个元素→5位地址（0~15）
                       (BUF_DEPTH <= 32) ? 6 :  // 17~32个元素→6位地址（0~31）
                       7;  // 最大支持64个元素（足够你的MAX_SIZE=5→25个元素）

// 内部信号
reg [DATA_WIDTH-1:0] matrix_buf [0:BUF_DEPTH-1]; // 矩阵缓冲区（存储完整矩阵）
reg [BUF_ADDR_W-1:0] buf_wr_idx;                // 缓冲区写地址（缓存阶段用）
reg [BUF_ADDR_W-1:0] buf_rd_idx;                // 缓冲区读地址（发送阶段用）
reg [BUF_ADDR_W-1:0] buf_total;                 // 缓冲区有效元素数（=row_valid*col_valid）
reg [2:0] send_state;                           // 发送状态机

// 先声明状态机状态（确保在模块顶部定义，避免未定义错误）
localparam IDLE           = 3'd0;
localparam BUFFER_MATRIX  = 3'd1;
localparam WAIT_SEND_TRIG = 3'd2;
localparam SEND_HIGH      = 3'd3;
localparam SEND_LOW       = 3'd4;
localparam SEND_SPACE     = 3'd5;
localparam SEND_NEWLINE   = 3'd6;
integer i;
// 合并后的唯一时序逻辑块（所有 send_state 操作集中在此，无多驱动）
always @(posedge clk or negedge rst_n) begin
    // 循环变量声明（老版本 Verilog 要求：always 块开头声明）
    
    if (!rst_n) begin
        // 合并原两个块的复位逻辑，统一初始化所有变量
        for (i = 0; i < BUF_DEPTH; i=i+1) begin
            matrix_buf[i] <= {DATA_WIDTH{1'b0}}; // 缓冲区初始化清零
        end
        buf_wr_idx <= {BUF_ADDR_W{1'b0}};       // 写地址清零
        buf_total <= {BUF_ADDR_W{1'b0}};        // 有效元素数清零
        buf_full <= 1'b0;                       // 缓冲区未满
        send_state <= IDLE;                     // 状态机复位到空闲
        buf_rd_idx <= {BUF_ADDR_W{1'b0}};       // 读地址清零
        uart_tx_start <= 1'b0;                  // UART 发送启动信号清零
        uart_tx_data <= {DATA_WIDTH{1'b0}};     // UART 发送数据清零
        send_done <= 1'b0;                      // 发送完成标志清零
    end else begin
        // 默认值：避免 latch（组合逻辑锁存）
        uart_tx_start <= 1'b0;
        send_done <= 1'b0;
        
        // 统一的状态机逻辑（整合原两个块的所有状态）
        case (send_state)
            // ---------------------------
            // 1. 原第一个块的逻辑：缓冲区写
            // ---------------------------
            IDLE: begin
                // 矩阵启动连续输出，开始缓存
                if (matrix_burst_en && !buf_full) begin
                    send_state <= BUFFER_MATRIX;
                    buf_wr_idx <= 1'b0; // 写地址从0开始
                    // 计算缓冲区有效元素数（=当前矩阵行数×列数）
                    buf_total <= curr_row_valid * curr_col_valid;
                end
            end
            BUFFER_MATRIX: begin
                // 写入当前矩阵元素到缓冲区
                matrix_buf[buf_wr_idx] <= matrix_data;
                buf_wr_idx <= buf_wr_idx + 1'b1; // 写地址自增
                
                // 矩阵输出完成（burst_done），缓存满
                if (matrix_burst_done) begin
                    buf_full <= 1'b1;
                    send_state <= WAIT_SEND_TRIG; // 跳转至等待发送触发
                end
            end
            
            // ---------------------------
            // 2. 原第二个块的逻辑：UART发送
            // ---------------------------
            WAIT_SEND_TRIG: begin
                // 外部触发发送，且UART空闲，开始发送
                if (send_trig && !uart_tx_busy) begin
                    send_state <= SEND_HIGH;
                    buf_rd_idx <= {BUF_ADDR_W{1'b0}}; // 读地址从0开始
                end
            end
            SEND_HIGH: begin
                // 发送缓冲区当前元素的高4位ASCII
                if (!uart_tx_busy) begin
                    uart_tx_start <= 1'b1;
                    uart_tx_data <= (matrix_buf[buf_rd_idx][7:4] < 4'd10) ? 
                                   (8'h30 + matrix_buf[buf_rd_idx][7:4]) : 
                                   (8'h41 + matrix_buf[buf_rd_idx][7:4] - 4'd10);
                    send_state <= SEND_LOW;
                end
            end
            SEND_LOW: begin
                // 发送低4位ASCII
                if (!uart_tx_busy) begin
                    uart_tx_start <= 1'b1;
                    uart_tx_data <= (matrix_buf[buf_rd_idx][3:0] < 4'd10) ? 
                                   (8'h30 + matrix_buf[buf_rd_idx][3:0]) : 
                                   (8'h41 + matrix_buf[buf_rd_idx][3:0] - 4'd10);
                    send_state <= SEND_SPACE;
                end
            end
            SEND_SPACE: begin
                // 发送空格
                if (!uart_tx_busy) begin
                    uart_tx_start <= 1'b1;
                    uart_tx_data <= 8'h20; // 空格ASCII（0x20）
                    
                    // 所有元素发送完？→ 发送换行；否则→下一个元素
                    if (buf_rd_idx == buf_total - 1'b1) begin
                        send_state <= SEND_NEWLINE;
                    end else begin
                        buf_rd_idx <= buf_rd_idx + 1'b1;
                        send_state <= SEND_HIGH;
                    end
                end
            end
            SEND_NEWLINE: begin
                // 发送换行，标记发送完成，复位缓冲区状态
                if (!uart_tx_busy) begin
                    uart_tx_start <= 1'b1;
                    uart_tx_data <= 8'h0A; // 换行ASCII（0x0A）
                    send_done <= 1'b1;     // 发送完成反馈
                    
                    // 发送完成后，复位缓冲区状态，回到IDLE
                    buf_full <= 1'b0;
                    buf_wr_idx <= {BUF_ADDR_W{1'b0}};
                    buf_total <= {BUF_ADDR_W{1'b0}};
                    send_state <= IDLE;
                end
            end
            
            default: begin
                // 异常状态复位到IDLE，增强鲁棒性
                send_state <= IDLE;
            end
        endcase
    end
end

endmodule