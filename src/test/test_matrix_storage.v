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
    // 遍历控制接口（新增）
    input wire                     traverse_trig,  // 遍历触发（1=开始遍历）
    input wire [2:0]               traverse_row,   // 目标遍历规模（行）
    input wire [2:0]               traverse_col,   // 目标遍历规模（列）
    // 状态反馈接口
    output wire                    traverse_busy,  // 遍历中
    output wire                    traverse_done,  // 遍历完成（脉冲）
    // UART输出接口
    output wire                    uart_tx
);

// ---------------------------
// 局部参数（自动计算）
// ---------------------------
// 1. 矩阵内地址位宽 ADDR_IN_W（替代 $clog2(MEM_DEPTH_PER_MATRIX)）
// MEM_DEPTH_PER_MATRIX = MAX_SIZE * MAX_SIZE（单个矩阵最大存储深度，如5x5=25）
localparam MEM_DEPTH_PER_MATRIX = MAX_SIZE * MAX_SIZE;
localparam ADDR_IN_W = (MEM_DEPTH_PER_MATRIX <= 1)  ? 1 :  // 1个元素→1位（0）
                      (MEM_DEPTH_PER_MATRIX <= 2)  ? 2 :  // 2个元素→2位（0~1）
                      (MEM_DEPTH_PER_MATRIX <= 4)  ? 3 :  // 3~4个元素→3位（0~3）
                      (MEM_DEPTH_PER_MATRIX <= 8)  ? 4 :  // 5~8个元素→4位（0~7）
                      (MEM_DEPTH_PER_MATRIX <= 16) ? 5 :  // 9~16个元素→5位（0~15）
                      (MEM_DEPTH_PER_MATRIX <= 32) ? 5 :  // 17~32个元素→5位（0~31，覆盖25）
                      (MEM_DEPTH_PER_MATRIX <= 64) ? 6 :  // 33~64个元素→6位（0~63）
                      (MEM_DEPTH_PER_MATRIX <= 128) ? 7 : // 65~128个元素→7位
                      8;  // 最大支持256个元素（满足MAX_SIZE=16→16x16=256）

// 2. 全局矩阵索引位宽 MATRIX_IDX_W（替代 $clog2(MATRIX_NUM)）
// MATRIX_NUM：全局最大矩阵数量（如8个）
localparam MATRIX_IDX_W = (MATRIX_NUM <= 1)  ? 1 :  // 1个矩阵→1位（0）
                         (MATRIX_NUM <= 2)  ? 2 :  // 2个矩阵→2位（0~1）
                         (MATRIX_NUM <= 4)  ? 3 :  // 3~4个矩阵→3位（0~3）
                         (MATRIX_NUM <= 8)  ? 3 :  // 5~8个矩阵→3位（0~7，覆盖8个）
                         (MATRIX_NUM <= 16) ? 4 :  // 9~16个矩阵→4位（0~15）
                         (MATRIX_NUM <= 32) ? 5 :  // 17~32个矩阵→5位（0~31）
                         6;  // 最大支持64个矩阵

// 3. 同规模索引位宽 SEL_IDX_W（替代 $clog2(MAX_MATRIX_PER_SIZE)）
// MAX_MATRIX_PER_SIZE：每个规模最多存储的矩阵数（如4个）
localparam SEL_IDX_W = (MAX_MATRIX_PER_SIZE <= 1)  ? 1 :  // 1个矩阵→1位（0）
                      (MAX_MATRIX_PER_SIZE <= 2)  ? 2 :  // 2个矩阵→2位（0~1）
                      (MAX_MATRIX_PER_SIZE <= 4)  ? 2 :  // 3~4个矩阵→2位（0~3，覆盖4个）
                      (MAX_MATRIX_PER_SIZE <= 8)  ? 3 :  // 5~8个矩阵→3位（0~7）
                      (MAX_MATRIX_PER_SIZE <= 16) ? 4 :  // 9~16个矩阵→4位（0~15）
                      5;  // 最大支持32个矩阵/规模
// ---------------------------
// 内部连接信号
// ---------------------------
// 矩阵模块相关
wire [DATA_WIDTH-1:0] matrix_rd_data;
wire matrix_burst_done;
wire [2:0] curr_store_row;
wire [2:0] curr_store_col;
wire [SEL_IDX_W-1:0] size_cnt_out;  // 目标规模矩阵总数
wire                     sel_by_size;
wire [2:0]               sel_row;
wire [2:0]               sel_col;
wire [SEL_IDX_W-1:0]     sel_idx;

// 缓冲区+UART相关
wire uart_tx_start;
wire [DATA_WIDTH-1:0] uart_tx_data;
wire uart_tx_busy;
wire buf_full;
wire send_done;
wire matrix_burst_en;
wire send_trig;

// ---------------------------
// 1. 实例化矩阵存储模块（升级后）
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
    // 遍历相关新增接口
    .traverse_row(traverse_row),
    .traverse_col(traverse_col),
    .size_cnt_out(size_cnt_out)
);

// ---------------------------
// 2. 实例化规模遍历控制模块（新增）
// ---------------------------
matrix_size_traverse #(
    .SEL_IDX_W(SEL_IDX_W),
    .CLK_FREQ(CLK_FREQ)
) u_traverse_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .traverse_trig(traverse_trig),
    .traverse_row(traverse_row),
    .traverse_col(traverse_col),
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
// 3. 实例化缓冲区桥接模块（复用）
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
// 4. 实例化UART发送模块（复用）
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