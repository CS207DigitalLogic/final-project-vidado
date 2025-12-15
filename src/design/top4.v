module top4 #(
    parameter DATA_WIDTH          = 9,        // 数据位宽
    parameter MAX_SIZE            = 5,        // 单个矩阵最大规模（1~5）
    parameter MATRIX_NUM          = 8,        // 全局最大矩阵数量
    parameter MAX_MATRIX_PER_SIZE = 4,        // 每个规模最多存储矩阵数
    parameter DEBOUNCE_CNT_MAX    = 20'd100000, // 按键消抖计数阈值
    parameter CLK_FREQ            = 100_000_000,
    parameter BAUD_RATE           = 115200
)(
    input  wire clk,            // 系统时钟
    input  wire rst_n,          // 低有效复位
    input  wire uart_rx,        // UART接收数据
    output wire uart_tx,        // UART发送数据
    input  wire [2:0] sw_mode,  // 模式选择开关
    input  wire btn_confirm,    // 确认按钮
    input  wire btn_return,     // 返回按钮
    output reg led_error_status,// 错误状态指示灯
    output [7:0] seg_cs_pin,    // 8个数码管位选
    output [7:0] seg_data_0_pin,// 数码管段选0
    output [7:0] seg_data_1_pin,// 数码管段选1
    output reg [13:0] led
);

// ========================== 1. 内部信号定义 ==========================

// 数码管显示模块相关信号
reg [11:0] menuState;
reg [8:0] seconds;
reg [31:0] sec_cnt;

// 消抖后的按键信号
wire btn_confirm_pulse;
wire btn_return_pulse;

// Matrix Storage 相关信号
wire        wr_en;
reg [2:0]  wr_row;
reg [2:0]  wr_col;
reg [DATA_WIDTH-1:0] storage_input_data[0:24]; // 最终连接到Storage的数据

// 来自 RX Handler 的信号
wire rx_handler_wr_en;
wire [2:0] rx_handler_row;
wire [2:0] rx_handler_col;
wire [2:0] rx_handler_target_idx;
wire rx_handler_done;
wire [7:0] rx_handler_data [0:24];

wire [DATA_WIDTH-1:0] storage_output_data[0:24]; 
reg wr_en_reg;       // 手动控制的写使能 (用于随机生成)
reg write_flag;      // 写入完成标志

// 显示与查询相关
reg [2:0] req_scale_row;
reg [2:0] req_scale_col;
reg [2:0] req_index;
wire [2:0] output_matrix_row;
wire [2:0] output_matrix_col;
wire [3:0] num; 

reg [DATA_WIDTH-1:0] matrix_display_data[0:24];
reg [2:0] display_row;
reg [2:0] display_col;
reg display_start;
wire display_busy;

// Matrix Operator 输入信号
wire en;
reg [DATA_WIDTH-1:0] matrix_opr_1 [0:24];
reg [DATA_WIDTH-1:0] matrix_opr_2 [0:24];
reg [3:0] matrix_opr_1_r1;
reg [3:0] matrix_opr_1_c1;
reg [3:0] matrix_opr_2_r2;
reg [3:0] matrix_opr_2_c2;
reg [7:0] scalar_value_reg;
wire [DATA_WIDTH-1:0] scalar_value;

// ========================== 2. 解决多驱动问题的核心修改 ==========================

// 最终聚合的运算结果 (Reg类型，由Mux驱动)
reg [DATA_WIDTH-1:0] matrix_ans [0:24]; 
reg [2:0] matrix_ans_r_out;
reg [2:0] matrix_ans_c_out;
wire calc_busy; // 聚合的忙信号

// --- 各个子模块的独立输出 Wire ---

// A. 加法器输出
wire [DATA_WIDTH-1:0] add_res [0:24];
wire [2:0] add_r_out, add_c_out;
wire add_busy_sig, add_valid;

// B. 标量乘法输出
wire [DATA_WIDTH-1:0] scalar_res [0:24];
wire [2:0] scalar_r_out, scalar_c_out; // 虽模块接口有定义，但标量乘法维度不变
wire scalar_busy_sig;

// C. 转置输出
wire [DATA_WIDTH-1:0] trans_res [0:24];
wire [2:0] trans_r_out, trans_c_out;
wire trans_busy_sig;

// D. 矩阵乘法输出
wire [DATA_WIDTH-1:0] mult_res [0:24];
wire [2:0] mult_r_out, mult_c_out;
wire mult_busy_sig, mult_valid;

// E. 卷积输出 (80个数据)
wire [DATA_WIDTH-1:0] conv_res [0:79];
wire conv_busy_sig;

// ===========================================================================

// UART 信号
wire [7:0] rx_data;
wire       rx_done;
wire [7:0] tx_data;
wire       tx_start;
wire       tx_busy;

// 随机矩阵生成模块信号
wire [DATA_WIDTH-1:0] rand_data [0:24];
wire rand_update_done;
reg [2:0] rand_row;  
reg [2:0] rand_col;  
reg rand_gen_en;
reg [7:0] min_val;   
reg [7:0] max_val;   

// ========== 状态机相关 ==========
reg [8:0] state, next_state;

// UART发送缓冲区
reg [7:0] uart_buffer [0:63];
reg [5:0] uart_buf_ptr;
reg uart_send_flag;
reg [7:0] uart_byte_cnt;

// 运算模块使能控制
reg add_en, scalar_en, trans_en, mult_en, conv_en;

// ========================== 3. 模块实例化 ==========================

uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx (
    .clk(clk), .rst_n(rst_n),
    .rx(uart_rx), .rx_data(rx_data), .rx_done(rx_done)
);

uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_tx (
    .clk(clk), .rst_n(rst_n),
    .tx_start(tx_start), .tx_data(tx_data), .tx(uart_tx), .tx_busy(tx_busy)
);

key_debounce u_keydebounce1 (
    .clk(clk), .rst_n(rst_n), .btn_trigger(btn_confirm), .btn_pulse(btn_confirm_pulse)
);
key_debounce u_keydebounce2 (
    .clk(clk), .rst_n(rst_n), .btn_trigger(btn_return), .btn_pulse(btn_return_pulse)
);

// RX Handler
matrix_rx_handler u_rx_handler (
    .clk(clk), .rst_n(rst_n),
    .rx_data(rx_data), .rx_done(rx_done),
    .storage_wr_en(rx_handler_wr_en),
    .storage_target_idx(rx_handler_target_idx),
    .storage_row(rx_handler_row), .storage_col(rx_handler_col),
    .data_flat_0(rx_handler_data[0]), .data_flat_1(rx_handler_data[1]), .data_flat_2(rx_handler_data[2]),
    .data_flat_3(rx_handler_data[3]), .data_flat_4(rx_handler_data[4]), .data_flat_5(rx_handler_data[5]),
    .data_flat_6(rx_handler_data[6]), .data_flat_7(rx_handler_data[7]), .data_flat_8(rx_handler_data[8]),
    .data_flat_9(rx_handler_data[9]), .data_flat_10(rx_handler_data[10]),.data_flat_11(rx_handler_data[11]),
    .data_flat_12(rx_handler_data[12]),.data_flat_13(rx_handler_data[13]),.data_flat_14(rx_handler_data[14]),
    .data_flat_15(rx_handler_data[15]),.data_flat_16(rx_handler_data[16]),.data_flat_17(rx_handler_data[17]),
    .data_flat_18(rx_handler_data[18]),.data_flat_19(rx_handler_data[19]),.data_flat_20(rx_handler_data[20]),
    .data_flat_21(rx_handler_data[21]),.data_flat_22(rx_handler_data[22]),.data_flat_23(rx_handler_data[23]),
    .data_flat_24(rx_handler_data[24]),
    .save_done_pulse(rx_handler_done)
);

// Storage
multi_matrix_storage #(
    .DATA_WIDTH(DATA_WIDTH), .MAX_SIZE(MAX_SIZE), .MATRIX_NUM(MATRIX_NUM), .MAX_MATRIX_PER_SIZE(MAX_MATRIX_PER_SIZE)
) u_matrix_storage (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en),             
    .write_row(wr_row), .write_col(wr_col),             
    .data_in_0(storage_input_data[0]), .data_in_1(storage_input_data[1]), .data_in_2(storage_input_data[2]),
    .data_in_3(storage_input_data[3]), .data_in_4(storage_input_data[4]), .data_in_5(storage_input_data[5]),
    .data_in_6(storage_input_data[6]), .data_in_7(storage_input_data[7]), .data_in_8(storage_input_data[8]),
    .data_in_9(storage_input_data[9]), .data_in_10(storage_input_data[10]),.data_in_11(storage_input_data[11]),
    .data_in_12(storage_input_data[12]),.data_in_13(storage_input_data[13]),.data_in_14(storage_input_data[14]),
    .data_in_15(storage_input_data[15]),.data_in_16(storage_input_data[16]),.data_in_17(storage_input_data[17]),
    .data_in_18(storage_input_data[18]),.data_in_19(storage_input_data[19]),.data_in_20(storage_input_data[20]),
    .data_in_21(storage_input_data[21]),.data_in_22(storage_input_data[22]),.data_in_23(storage_input_data[23]),
    .data_in_24(storage_input_data[24]),
    .req_scale_row(req_scale_row), .req_scale_col(req_scale_col), .req_idx(req_index),           
    .scale_matrix_cnt(num),
    .matrix_data_0(storage_output_data[0]), .matrix_data_1(storage_output_data[1]), .matrix_data_2(storage_output_data[2]),
    .matrix_data_3(storage_output_data[3]), .matrix_data_4(storage_output_data[4]), .matrix_data_5(storage_output_data[5]),
    .matrix_data_6(storage_output_data[6]), .matrix_data_7(storage_output_data[7]), .matrix_data_8(storage_output_data[8]),
    .matrix_data_9(storage_output_data[9]), .matrix_data_10(storage_output_data[10]),.matrix_data_11(storage_output_data[11]),
    .matrix_data_12(storage_output_data[12]),.matrix_data_13(storage_output_data[13]),.matrix_data_14(storage_output_data[14]),
    .matrix_data_15(storage_output_data[15]),.matrix_data_16(storage_output_data[16]),.matrix_data_17(storage_output_data[17]),
    .matrix_data_18(storage_output_data[18]),.matrix_data_19(storage_output_data[19]),.matrix_data_20(storage_output_data[20]),
    .matrix_data_21(storage_output_data[21]),.matrix_data_22(storage_output_data[22]),.matrix_data_23(storage_output_data[23]),
    .matrix_data_24(storage_output_data[24]),
    .matrix_row(output_matrix_row), .matrix_col(output_matrix_col), .matrix_valid()
);

// Random Generator
random_matrix_generator #(.WIDTH(DATA_WIDTH), .MAX_DIM(MAX_SIZE)) u_rand_matrix (
    .clk(clk), .rst_n(rst_n),
    .row(rand_row), .col(rand_col), .min_val(min_val), .max_val(max_val), .update_en(rand_gen_en),
    .matrix_out0(rand_data[0]), .matrix_out1(rand_data[1]), .matrix_out2(rand_data[2]),
    .matrix_out3(rand_data[3]), .matrix_out4(rand_data[4]), .matrix_out5(rand_data[5]),
    .matrix_out6(rand_data[6]), .matrix_out7(rand_data[7]), .matrix_out8(rand_data[8]),
    .matrix_out9(rand_data[9]), .matrix_out10(rand_data[10]),.matrix_out11(rand_data[11]),
    .matrix_out12(rand_data[12]),.matrix_out13(rand_data[13]),.matrix_out14(rand_data[14]),
    .matrix_out15(rand_data[15]),.matrix_out16(rand_data[16]),.matrix_out17(rand_data[17]),
    .matrix_out18(rand_data[18]),.matrix_out19(rand_data[19]),.matrix_out20(rand_data[20]),
    .matrix_out21(rand_data[21]),.matrix_out22(rand_data[22]),.matrix_out23(rand_data[23]),
    .matrix_out24(rand_data[24]), .update_done(rand_update_done)
);

// Matrix Adder
matrix_adder #(.DATA_WIDTH(DATA_WIDTH)) u_matrix_adder (
    .clk(clk), .reset_n(rst_n),
    .r1(matrix_opr_1_r1), .c1(matrix_opr_1_c1),
    .data1_in_0(matrix_opr_1[0]), .data1_in_1(matrix_opr_1[1]), .data1_in_2(matrix_opr_1[2]),
    .data1_in_3(matrix_opr_1[3]), .data1_in_4(matrix_opr_1[4]), .data1_in_5(matrix_opr_1[5]),
    .data1_in_6(matrix_opr_1[6]), .data1_in_7(matrix_opr_1[7]), .data1_in_8(matrix_opr_1[8]),
    .data1_in_9(matrix_opr_1[9]), .data1_in_10(matrix_opr_1[10]),.data1_in_11(matrix_opr_1[11]),
    .data1_in_12(matrix_opr_1[12]),.data1_in_13(matrix_opr_1[13]),.data1_in_14(matrix_opr_1[14]),
    .data1_in_15(matrix_opr_1[15]),.data1_in_16(matrix_opr_1[16]),.data1_in_17(matrix_opr_1[17]),
    .data1_in_18(matrix_opr_1[18]),.data1_in_19(matrix_opr_1[19]),.data1_in_20(matrix_opr_1[20]),
    .data1_in_21(matrix_opr_1[21]),.data1_in_22(matrix_opr_1[22]),.data1_in_23(matrix_opr_1[23]),
    .data1_in_24(matrix_opr_1[24]),
    .r2(matrix_opr_2_r2), .c2(matrix_opr_2_c2),
    .data2_in_0(matrix_opr_2[0]), .data2_in_1(matrix_opr_2[1]), .data2_in_2(matrix_opr_2[2]),
    .data2_in_3(matrix_opr_2[3]), .data2_in_4(matrix_opr_2[4]), .data2_in_5(matrix_opr_2[5]),
    .data2_in_6(matrix_opr_2[6]), .data2_in_7(matrix_opr_2[7]), .data2_in_8(matrix_opr_2[8]),
    .data2_in_9(matrix_opr_2[9]), .data2_in_10(matrix_opr_2[10]),.data2_in_11(matrix_opr_2[11]),
    .data2_in_12(matrix_opr_2[12]),.data2_in_13(matrix_opr_2[13]),.data2_in_14(matrix_opr_2[14]),
    .data2_in_15(matrix_opr_2[15]),.data2_in_16(matrix_opr_2[16]),.data2_in_17(matrix_opr_2[17]),
    .data2_in_18(matrix_opr_2[18]),.data2_in_19(matrix_opr_2[19]),.data2_in_20(matrix_opr_2[20]),
    .data2_in_21(matrix_opr_2[21]),.data2_in_22(matrix_opr_2[22]),.data2_in_23(matrix_opr_2[23]),
    .data2_in_24(matrix_opr_2[24]),
    .en(add_en),
    // 输出连接到独立Wire
    .r_out(add_r_out), .c_out(add_c_out),
    .data_out_0(add_res[0]), .data_out_1(add_res[1]), .data_out_2(add_res[2]),
    .data_out_3(add_res[3]), .data_out_4(add_res[4]), .data_out_5(add_res[5]),
    .data_out_6(add_res[6]), .data_out_7(add_res[7]), .data_out_8(add_res[8]),
    .data_out_9(add_res[9]), .data_out_10(add_res[10]),.data_out_11(add_res[11]),
    .data_out_12(add_res[12]),.data_out_13(add_res[13]),.data_out_14(add_res[14]),
    .data_out_15(add_res[15]),.data_out_16(add_res[16]),.data_out_17(add_res[17]),
    .data_out_18(add_res[18]),.data_out_19(add_res[19]),.data_out_20(add_res[20]),
    .data_out_21(add_res[21]),.data_out_22(add_res[22]),.data_out_23(add_res[23]),
    .data_out_24(add_res[24]),
    .isValid(add_valid), .busy(add_busy_sig)
);

// Matrix Scalar
matrix_scalar #(.DATA_WIDTH(DATA_WIDTH)) u_matrix_scalar (
    .clk(clk), .reset_n(rst_n),
    .r(matrix_opr_1_r1), .c(matrix_opr_1_c1),
    .data_in_0(matrix_opr_1[0]), .data_in_1(matrix_opr_1[1]), .data_in_2(matrix_opr_1[2]),
    .data_in_3(matrix_opr_1[3]), .data_in_4(matrix_opr_1[4]), .data_in_5(matrix_opr_1[5]),
    .data_in_6(matrix_opr_1[6]), .data_in_7(matrix_opr_1[7]), .data_in_8(matrix_opr_1[8]),
    .data_in_9(matrix_opr_1[9]), .data_in_10(matrix_opr_1[10]),.data_in_11(matrix_opr_1[11]),
    .data_in_12(matrix_opr_1[12]),.data_in_13(matrix_opr_1[13]),.data_in_14(matrix_opr_1[14]),
    .data_in_15(matrix_opr_1[15]),.data_in_16(matrix_opr_1[16]),.data_in_17(matrix_opr_1[17]),
    .data_in_18(matrix_opr_1[18]),.data_in_19(matrix_opr_1[19]),.data_in_20(matrix_opr_1[20]),
    .data_in_21(matrix_opr_1[21]),.data_in_22(matrix_opr_1[22]),.data_in_23(matrix_opr_1[23]),
    .data_in_24(matrix_opr_1[24]),
    .en(scalar_en), .scalar(scalar_value),
    // 输出连接到独立Wire
    .r_out(scalar_r_out), .c_out(scalar_c_out),
    .data_out_0(scalar_res[0]), .data_out_1(scalar_res[1]), .data_out_2(scalar_res[2]),
    .data_out_3(scalar_res[3]), .data_out_4(scalar_res[4]), .data_out_5(scalar_res[5]),
    .data_out_6(scalar_res[6]), .data_out_7(scalar_res[7]), .data_out_8(scalar_res[8]),
    .data_out_9(scalar_res[9]), .data_out_10(scalar_res[10]),.data_out_11(scalar_res[11]),
    .data_out_12(scalar_res[12]),.data_out_13(scalar_res[13]),.data_out_14(scalar_res[14]),
    .data_out_15(scalar_res[15]),.data_out_16(scalar_res[16]),.data_out_17(scalar_res[17]),
    .data_out_18(scalar_res[18]),.data_out_19(scalar_res[19]),.data_out_20(scalar_res[20]),
    .data_out_21(scalar_res[21]),.data_out_22(scalar_res[22]),.data_out_23(scalar_res[23]),
    .data_out_24(scalar_res[24]),
    .busy(scalar_busy_sig)
);

// Matrix Transpose
matrix_transpose #(.DATA_WIDTH(DATA_WIDTH)) u_matrix_transpose (
    .clk(clk), .reset_n(rst_n),
    .r(matrix_opr_1_r1), .c(matrix_opr_1_c1),
    .data_in_0(matrix_opr_1[0]), .data_in_1(matrix_opr_1[1]), .data_in_2(matrix_opr_1[2]),
    .data_in_3(matrix_opr_1[3]), .data_in_4(matrix_opr_1[4]), .data_in_5(matrix_opr_1[5]),
    .data_in_6(matrix_opr_1[6]), .data_in_7(matrix_opr_1[7]), .data_in_8(matrix_opr_1[8]),
    .data_in_9(matrix_opr_1[9]), .data_in_10(matrix_opr_1[10]),.data_in_11(matrix_opr_1[11]),
    .data_in_12(matrix_opr_1[12]),.data_in_13(matrix_opr_1[13]),.data_in_14(matrix_opr_1[14]),
    .data_in_15(matrix_opr_1[15]),.data_in_16(matrix_opr_1[16]),.data_in_17(matrix_opr_1[17]),
    .data_in_18(matrix_opr_1[18]),.data_in_19(matrix_opr_1[19]),.data_in_20(matrix_opr_1[20]),
    .data_in_21(matrix_opr_1[21]),.data_in_22(matrix_opr_1[22]),.data_in_23(matrix_opr_1[23]),
    .data_in_24(matrix_opr_1[24]),
    .en(trans_en),
    // 输出连接到独立Wire
    .r_out(trans_r_out), .c_out(trans_c_out),
    .data_out_0(trans_res[0]), .data_out_1(trans_res[1]), .data_out_2(trans_res[2]),
    .data_out_3(trans_res[3]), .data_out_4(trans_res[4]), .data_out_5(trans_res[5]),
    .data_out_6(trans_res[6]), .data_out_7(trans_res[7]), .data_out_8(trans_res[8]),
    .data_out_9(trans_res[9]), .data_out_10(trans_res[10]),.data_out_11(trans_res[11]),
    .data_out_12(trans_res[12]),.data_out_13(trans_res[13]),.data_out_14(trans_res[14]),
    .data_out_15(trans_res[15]),.data_out_16(trans_res[16]),.data_out_17(trans_res[17]),
    .data_out_18(trans_res[18]),.data_out_19(trans_res[19]),.data_out_20(trans_res[20]),
    .data_out_21(trans_res[21]),.data_out_22(trans_res[22]),.data_out_23(trans_res[23]),
    .data_out_24(trans_res[24]),
    .busy(trans_busy_sig)
);

// Matrix Multiplier
matrix_multiplier #(.DATA_WIDTH(DATA_WIDTH)) u_matrix_multiplier (
    .clk(clk), .reset_n(rst_n),
    .r1(matrix_opr_1_r1), .c1(matrix_opr_1_c1),
    .data1_in_0(matrix_opr_1[0]), .data1_in_1(matrix_opr_1[1]), .data1_in_2(matrix_opr_1[2]),
    .data1_in_3(matrix_opr_1[3]), .data1_in_4(matrix_opr_1[4]), .data1_in_5(matrix_opr_1[5]),
    .data1_in_6(matrix_opr_1[6]), .data1_in_7(matrix_opr_1[7]), .data1_in_8(matrix_opr_1[8]),
    .data1_in_9(matrix_opr_1[9]), .data1_in_10(matrix_opr_1[10]),.data1_in_11(matrix_opr_1[11]),
    .data1_in_12(matrix_opr_1[12]),.data1_in_13(matrix_opr_1[13]),.data1_in_14(matrix_opr_1[14]),
    .data1_in_15(matrix_opr_1[15]),.data1_in_16(matrix_opr_1[16]),.data1_in_17(matrix_opr_1[17]),
    .data1_in_18(matrix_opr_1[18]),.data1_in_19(matrix_opr_1[19]),.data1_in_20(matrix_opr_1[20]),
    .data1_in_21(matrix_opr_1[21]),.data1_in_22(matrix_opr_1[22]),.data1_in_23(matrix_opr_1[23]),
    .data1_in_24(matrix_opr_1[24]),
    .r2(matrix_opr_2_r2), .c2(matrix_opr_2_c2),
    .data2_in_0(matrix_opr_2[0]), .data2_in_1(matrix_opr_2[1]), .data2_in_2(matrix_opr_2[2]),
    .data2_in_3(matrix_opr_2[3]), .data2_in_4(matrix_opr_2[4]), .data2_in_5(matrix_opr_2[5]),
    .data2_in_6(matrix_opr_2[6]), .data2_in_7(matrix_opr_2[7]), .data2_in_8(matrix_opr_2[8]),
    .data2_in_9(matrix_opr_2[9]), .data2_in_10(matrix_opr_2[10]),.data2_in_11(matrix_opr_2[11]),
    .data2_in_12(matrix_opr_2[12]),.data2_in_13(matrix_opr_2[13]),.data2_in_14(matrix_opr_2[14]),
    .data2_in_15(matrix_opr_2[15]),.data2_in_16(matrix_opr_2[16]),.data2_in_17(matrix_opr_2[17]),
    .data2_in_18(matrix_opr_2[18]),.data2_in_19(matrix_opr_2[19]),.data2_in_20(matrix_opr_2[20]),
    .data2_in_21(matrix_opr_2[21]),.data2_in_22(matrix_opr_2[22]),.data2_in_23(matrix_opr_2[23]),
    .data2_in_24(matrix_opr_2[24]),
    .en(mult_en),
    // 输出连接到独立Wire
    .r_out(mult_r_out), .c_out(mult_c_out),
    .data_out_0(mult_res[0]), .data_out_1(mult_res[1]), .data_out_2(mult_res[2]),
    .data_out_3(mult_res[3]), .data_out_4(mult_res[4]), .data_out_5(mult_res[5]),
    .data_out_6(mult_res[6]), .data_out_7(mult_res[7]), .data_out_8(mult_res[8]),
    .data_out_9(mult_res[9]), .data_out_10(mult_res[10]),.data_out_11(mult_res[11]),
    .data_out_12(mult_res[12]),.data_out_13(mult_res[13]),.data_out_14(mult_res[14]),
    .data_out_15(mult_res[15]),.data_out_16(mult_res[16]),.data_out_17(mult_res[17]),
    .data_out_18(mult_res[18]),.data_out_19(mult_res[19]),.data_out_20(mult_res[20]),
    .data_out_21(mult_res[21]),.data_out_22(mult_res[22]),.data_out_23(mult_res[23]),
    .data_out_24(mult_res[24]),
    .isValid(mult_valid), .busy(mult_busy_sig)
);

// Matrix Convolution (Bonus)
matrix_conv #(.DATA_WIDTH(DATA_WIDTH)) u_matrix_conv (
    .clk(clk), .reset_n(rst_n),
    .data_in_0(matrix_opr_1[0]), .data_in_1(matrix_opr_1[1]), .data_in_2(matrix_opr_1[2]),
    .data_in_3(matrix_opr_1[3]), .data_in_4(matrix_opr_1[4]), .data_in_5(matrix_opr_1[5]),
    .data_in_6(matrix_opr_1[6]), .data_in_7(matrix_opr_1[7]), .data_in_8(matrix_opr_1[8]),
    // 补全输入
    .data_in_9(matrix_opr_1[9]), .data_in_10(matrix_opr_1[10]),.data_in_11(matrix_opr_1[11]),
    .data_in_12(matrix_opr_1[12]),.data_in_13(matrix_opr_1[13]),.data_in_14(matrix_opr_1[14]),
    .data_in_15(matrix_opr_1[15]),.data_in_16(matrix_opr_1[16]),.data_in_17(matrix_opr_1[17]),
    .data_in_18(matrix_opr_1[18]),.data_in_19(matrix_opr_1[19]),.data_in_20(matrix_opr_1[20]),
    .data_in_21(matrix_opr_1[21]),.data_in_22(matrix_opr_1[22]),.data_in_23(matrix_opr_1[23]),
    .data_in_24(matrix_opr_1[24]),
    .en(conv_en),
    // 输出连接到独立Wire (共80个输出)
    .data_out_0(conv_res[0]), .data_out_1(conv_res[1]), .data_out_2(conv_res[2]),
    .data_out_3(conv_res[3]), .data_out_4(conv_res[4]), .data_out_5(conv_res[5]),
    .data_out_6(conv_res[6]), .data_out_7(conv_res[7]), .data_out_8(conv_res[8]),
    .data_out_9(conv_res[9]), .data_out_10(conv_res[10]),.data_out_11(conv_res[11]),
    .data_out_12(conv_res[12]),.data_out_13(conv_res[13]),.data_out_14(conv_res[14]),
    .data_out_15(conv_res[15]),.data_out_16(conv_res[16]),.data_out_17(conv_res[17]),
    .data_out_18(conv_res[18]),.data_out_19(conv_res[19]),.data_out_20(conv_res[20]),
    .data_out_21(conv_res[21]),.data_out_22(conv_res[22]),.data_out_23(conv_res[23]),
    .data_out_24(conv_res[24]),
    // 剩余端口连接
    .data_out_25(conv_res[25]), .data_out_26(conv_res[26]), .data_out_27(conv_res[27]),
    .data_out_28(conv_res[28]), .data_out_29(conv_res[29]), .data_out_30(conv_res[30]),
    .data_out_31(conv_res[31]), .data_out_32(conv_res[32]), .data_out_33(conv_res[33]),
    .data_out_34(conv_res[34]), .data_out_35(conv_res[35]), .data_out_36(conv_res[36]),
    .data_out_37(conv_res[37]), .data_out_38(conv_res[38]), .data_out_39(conv_res[39]),
    .data_out_40(conv_res[40]), .data_out_41(conv_res[41]), .data_out_42(conv_res[42]),
    .data_out_43(conv_res[43]), .data_out_44(conv_res[44]), .data_out_45(conv_res[45]),
    .data_out_46(conv_res[46]), .data_out_47(conv_res[47]), .data_out_48(conv_res[48]),
    .data_out_49(conv_res[49]), .data_out_50(conv_res[50]), .data_out_51(conv_res[51]),
    .data_out_52(conv_res[52]), .data_out_53(conv_res[53]), .data_out_54(conv_res[54]),
    .data_out_55(conv_res[55]), .data_out_56(conv_res[56]), .data_out_57(conv_res[57]),
    .data_out_58(conv_res[58]), .data_out_59(conv_res[59]), .data_out_60(conv_res[60]),
    .data_out_61(conv_res[61]), .data_out_62(conv_res[62]), .data_out_63(conv_res[63]),
    .data_out_64(conv_res[64]), .data_out_65(conv_res[65]), .data_out_66(conv_res[66]),
    .data_out_67(conv_res[67]), .data_out_68(conv_res[68]), .data_out_69(conv_res[69]),
    .data_out_70(conv_res[70]), .data_out_71(conv_res[71]), .data_out_72(conv_res[72]),
    .data_out_73(conv_res[73]), .data_out_74(conv_res[74]), .data_out_75(conv_res[75]),
    .data_out_76(conv_res[76]), .data_out_77(conv_res[77]), .data_out_78(conv_res[78]),
    .data_out_79(conv_res[79]),
    .busy(conv_busy_sig)
);

// Matrix Displayer
matrix_displayer u_matrix_displayer (
    .clk(clk), .rst_n(rst_n),
    .start(display_start),
    .busy(display_busy), 
    .matrix_row(display_row), .matrix_col(display_col),
    .d0(matrix_display_data[0]), .d1(matrix_display_data[1]), .d2(matrix_display_data[2]),
    .d3(matrix_display_data[3]), .d4(matrix_display_data[4]), .d5(matrix_display_data[5]),
    .d6(matrix_display_data[6]), .d7(matrix_display_data[7]), .d8(matrix_display_data[8]),
    .d9(matrix_display_data[9]), .d10(matrix_display_data[10]),.d11(matrix_display_data[11]),
    .d12(matrix_display_data[12]),.d13(matrix_display_data[13]),.d14(matrix_display_data[14]),
    .d15(matrix_display_data[15]),.d16(matrix_display_data[16]),.d17(matrix_display_data[17]),
    .d18(matrix_display_data[18]),.d19(matrix_display_data[19]),.d20(matrix_display_data[20]),
    .d21(matrix_display_data[21]),.d22(matrix_display_data[22]),.d23(matrix_display_data[23]),
    .d24(matrix_display_data[24]),
    .tx_start(tx_start), .tx_data(tx_data), .tx_busy(tx_busy)
);

// Segment Display
segment_display u_segment_display(
    .clk(clk), .reset(rst_n),
    .menuState(menuState), .seconds(seconds),
    .tub_sel1(seg_cs_pin[0]), .tub_sel2(seg_cs_pin[1]), .tub_sel3(seg_cs_pin[2]), .tub_sel4(seg_cs_pin[3]),
    .tub_sel5(seg_cs_pin[4]), .tub_sel6(seg_cs_pin[5]), .tub_sel7(seg_cs_pin[6]), .tub_sel8(seg_cs_pin[7]),
    .tub_control1(seg_data_0_pin), .tub_control2(seg_data_1_pin)
);

// 缓存
reg [7:0] rx_buf;

// 状态机
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 9'd000;
        next_state <= 9'd000;
        menuState <= 9'd010;
        wr_en_reg <= 0;
        write_flag <= 0;
        led_error_status <= 0;
        uart_send_flag <= 0;
        add_en <= 0; scalar_en <= 0; trans_en <= 0; mult_en <= 0; conv_en <= 0;
        seconds <= 0; sec_cnt <= 0;
        scalar_value_reg <= 0;
        uart_buf_ptr <= 0; 
        uart_byte_cnt <= 0;
        rand_gen_en <= 0; rand_row <= 0; rand_col <= 0;
        min_val <= 0; max_val <= 9;
        display_start <= 0;
        // 测试用灯
        led <= 14'b00_0000_0000_0011;
        // 初始化 storage inputs
        for (i=0; i<25; i=i+1) storage_input_data[i] <= 0;
    end 
    else begin
        menuState <= state;
//        state <= next_state;
        case(state)
            9'd000: begin
                // 初始状态操作（留白）
                
                led <= 14'b00_0000_0000_1100;
                
                if (btn_confirm_pulse) begin
                    case(sw_mode)
                        3'b001: state = 9'd100;  // 模式1输入并存储
                        3'b010: state = 9'd200;  // 模式2随机生成
                        3'b011: state = 9'd300;  // 模式3矩阵展示
                        3'b100: state = 9'd400;  // 模式4运算
                        default: state = 9'd000;
                    endcase
                end
            end
            
            9'd100: begin
                // uart传入r
                led <= 14'b10_0000_0000_0000;
                rx_buf <= rx_data;
                

                if (btn_confirm_pulse) begin
                    state = 9'd110;
                end
                if (btn_return_pulse) begin
                    state = 9'd000;
                end
            end
            
            9'd110: begin
                // uart传入c
                led <= 14'b10_0000_0000_0000;

                if (btn_confirm_pulse) begin
                    state = 9'd120;
                end
                if (btn_return_pulse) begin
                    state = 9'd000;
                end
            end
            
            9'd120: begin
                // uart传入矩阵，存储
                
                if (btn_confirm_pulse) begin
                    state = 9'd000;
                end
            end
            
            9'd200: begin
                // uart传入r
                led <= 14'b01_0000_0000_0000;
                rx_buf <= rx_data;
                

                if (btn_confirm_pulse) begin
                    state = 9'd210;
                end
                if (btn_return_pulse) begin
                    state = 9'd000;
                end
            end
            
            9'd210: begin
                // uart传入c，随机生成矩阵并存储
                led <= 14'b01_0000_0000_0000;

                if (btn_confirm_pulse) begin
                    state = 9'd000;
                end
            end
            
            9'd300: begin
                // uart传入r
                led <= 14'b00_1000_0000_0000;
                rx_buf <= rx_data;
                
    
                if (btn_confirm_pulse) begin
                    state = 9'd310;
                end
                if (btn_return_pulse) begin
                    state = 9'd000;
                end
            end
            
            9'd310: begin
                // uart传入c，展示矩阵
                led <= 14'b00_1000_0000_0000;

                if (btn_confirm_pulse) begin
                    state = 9'd000;
                end
            end
            
            9'd400: begin
                
                
                if (btn_return_pulse) begin
                    state = 9'd000;
                end
            end
            
            9'd400: begin
                // 模式4操作（留白）
                led <= 14'b00_0100_0000_0000;
                
                if (btn_confirm_pulse) begin
                    case(sw_mode)
                        3'b001: state = 9'd410;  // 模式1矩阵转置
                        3'b010: state = 9'd420;  // 模式2矩阵加法
                        3'b011: state = 9'd430;  // 模式3矩阵标量
                        3'b100: state = 9'd440;  // 模式4矩阵乘法
                        3'b101: state = 9'd450;  // 模式5卷积运算
                    endcase
                end
            
                if (btn_return_pulse) begin
                    next_state = 9'd000;
                end
            end
            
            9'd410: begin
            
                if (btn_return_pulse) begin
                    next_state = 9'd000;
                end
            end
            
            9'd420: begin
            
                if (btn_return_pulse) begin
                    next_state = 9'd000;
                end
            end
            
            9'd430: begin
            
                if (btn_return_pulse) begin
                    next_state = 9'd000;
                end
            end
            
            9'd440: begin
            
                if (btn_return_pulse) begin
                    next_state = 9'd000;
                end
            end
            
            9'd450: begin
            
                if (btn_return_pulse) begin
                    next_state = 9'd000;
                end
            end
        endcase
    end
end

endmodule
