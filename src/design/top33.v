module top33 #(
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
    output [7:0] seg_data_1_pin // 数码管段选1
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
localparam [3:0]
    S_IDLE        = 4'd0,
    S_MAIN_MENU   = 4'd1,
    S_INPUT_MAT   = 4'd2,   
    S_GEN_MAT     = 4'd3,   
    S_DISP_MAT    = 4'd4,   
    S_OPER_MENU   = 4'd5,   
    S_OPER_TRANS  = 4'd6,   
    S_OPER_ADD    = 4'd7,   
    S_OPER_SCALE  = 4'd8,   
    S_OPER_MULT   = 4'd9,   
    S_OPER_CONV   = 4'd10,  
    S_SELECT_OP1  = 4'd11,  
    S_SELECT_OP2  = 4'd12,  
    S_COMPUTE     = 4'd13,  
    S_DISPLAY_RES = 4'd14,  
    S_ERROR_TIMER = 4'd15;

reg [3:0] state, next_state;
reg [3:0] gen_matrix_cnt;
reg [3:0] selected_op_type; // 1:Trans, 2:Add, 3:Scale, 4:Mult, 5:Conv
reg [1:0] selected_mat_index;
reg [7:0] timer_config;
reg [7:0] error_timer;
reg [3:0] sub_state;
reg [3:0] mat_select_state;
reg [3:0] compute_cnt;

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

// ========================== 4. 逻辑连接 ==========================

assign en = add_en | scalar_en | trans_en | mult_en | conv_en;
assign scalar_value = scalar_value_reg;

// 忙信号汇总
assign calc_busy = (selected_op_type == 1) ? trans_busy_sig :
                   (selected_op_type == 2) ? add_busy_sig :
                   (selected_op_type == 3) ? scalar_busy_sig :
                   (selected_op_type == 4) ? mult_busy_sig :
                   (selected_op_type == 5) ? conv_busy_sig : 1'b0;

// Storage 写入逻辑复用: 手动输入 vs 随机生成
assign wr_en = (state == S_INPUT_MAT) ? rx_handler_wr_en : wr_en_reg;

// ========================== 5. 输出多路选择逻辑 (MUX) ==========================
// 解决 Multiple Driver 的关键部分

integer k;
always @(*) begin
    // 默认值
    matrix_ans_r_out = 0;
    matrix_ans_c_out = 0;
    for (k = 0; k < 25; k = k + 1) begin
        matrix_ans[k] = 0;
    end

    case (selected_op_type)
        1: begin // Transpose
            matrix_ans_r_out = trans_r_out;
            matrix_ans_c_out = trans_c_out;
            for (k = 0; k < 25; k = k + 1) matrix_ans[k] = trans_res[k];
        end
        2: begin // Add
            matrix_ans_r_out = add_r_out;
            matrix_ans_c_out = add_c_out;
            for (k = 0; k < 25; k = k + 1) matrix_ans[k] = add_res[k];
        end
        3: begin // Scalar
            matrix_ans_r_out = scalar_r_out;
            matrix_ans_c_out = scalar_c_out;
            for (k = 0; k < 25; k = k + 1) matrix_ans[k] = scalar_res[k];
        end
        4: begin // Multiply
            matrix_ans_r_out = mult_r_out;
            matrix_ans_c_out = mult_c_out;
            for (k = 0; k < 25; k = k + 1) matrix_ans[k] = mult_res[k];
        end
        5: begin // Convolution
            // 卷积模块输出是 8行10列 (80个数据)
            // 但显示模块和 matrix_ans 只有 25 个容量 (5x5)
            // 这里我们只截取前 25 个用于显示
            matrix_ans_r_out = 3'd5; 
            matrix_ans_c_out = 3'd5;
            for (k = 0; k < 25; k = k + 1) matrix_ans[k] = conv_res[k];
        end
        default: begin
            // 保持默认0
        end
    endcase
end

// ========================== 6. 状态机逻辑实现 ==========================

// 1Hz 脉冲产生逻辑 (用于倒计时)
reg [31:0] clk_div_cnt;
reg clk_1hz;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_div_cnt <= 0;
        clk_1hz <= 0;
    end else if (clk_div_cnt >= CLK_FREQ - 1) begin
        clk_div_cnt <= 0;
        clk_1hz <= 1;
    end else begin
        clk_div_cnt <= clk_div_cnt + 1;
        clk_1hz <= 0;
    end
end

// 状态机主逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;
        sub_state <= 0;
        led_error_status <= 0;
        error_timer <= 8'd10;  // 默认10秒
        timer_config <= 8'd10;
        add_en <= 0; scalar_en <= 0; trans_en <= 0; mult_en <= 0; conv_en <= 0;
        display_start <= 0;
        wr_en_reg <= 0;
        menuState <= 12'h000;
        selected_op_type <= 0;
        compute_cnt <= 0;
    end else begin
        // 默认拉低使能信号
        display_start <= 0;
        wr_en_reg <= 0;

        case (state)
            // 2.2.1 初始闲置状态
            S_IDLE: begin
                state <= S_MAIN_MENU;
            end

            // 主菜单：根据 sw_mode 选择模式
            S_MAIN_MENU: begin
                led_error_status <= 0;
                menuState <= {9'b0, sw_mode}; // 数码管显示当前模式编号
                if (btn_confirm_pulse) begin
                    case (sw_mode)
                        3'b000: state <= S_INPUT_MAT; // 输入模式
                        3'b001: state <= S_GEN_MAT;   // 随机生成
                        3'b010: state <= S_OPER_MENU;  // 运算模式
                        3'b011: state <= S_DISP_MAT;  // 存储查看
                        default: state <= S_MAIN_MENU;
                    endcase
                    sub_state <= 0;
                end
            end

            // 2.2.1 & 2.2.3 矩阵输入与存储
            S_INPUT_MAT: begin
                // rx_handler 内部已处理维度检测与 0 填充逻辑 
                if (rx_handler_done) begin
                    // 若 rx_handler 检测到维度超出 1~5 或数值 > 9，会触发报错
                    // 存储模块 multi_matrix_storage 自动处理覆盖逻辑 
                    state <= S_MAIN_MENU;
                end
                if (btn_return_pulse) state <= S_MAIN_MENU;
            end

            // 2.2.2 随机生成逻辑
            S_GEN_MAT: begin
                case (sub_state)
                    0: begin // 用户输入维度 m, n 和个数 (通过 sw_mode 模拟)
                        rand_row <= sw_mode + 1;
                        rand_col <= sw_mode + 1; 
                        min_val <= 8'd0;
                        max_val <= 8'd9;
                        if (btn_confirm_pulse) sub_state <= 1;
                    end
                    1: begin // 触发随机数生成器 [cite: 10]
                        rand_gen_en <= 1;
                        if (rand_update_done) begin
                            rand_gen_en <= 0;
                            sub_state <= 2;
                        end
                    end
                    2: begin // 写入存储器
                        for (k=0; k<25; k=k+1) storage_input_data[k] <= rand_data[k];
                        wr_row <= rand_row;
                        wr_col <= rand_col;
                        wr_en_reg <= 1; // 触发 Storage 写入
                        state <= S_MAIN_MENU;
                    end
                endcase
            end

            // 2.4.1 运算类型选择
            S_OPER_MENU: begin
                case (sw_mode)
                    3'b000: begin menuState <= 12'h514; selected_op_type <= 1; end // 'T' Transpose
                    3'b001: begin menuState <= 12'h411; selected_op_type <= 2; end // 'A' Add
                    3'b010: begin menuState <= 12'h422; selected_op_type <= 3; end // 'B' Scale
                    3'b011: begin menuState <= 12'h433; selected_op_type <= 4; end // 'C' Mult
                    3'b100: begin menuState <= 12'h410; selected_op_type <= 5; end // 'J' Conv
                endcase
                if (btn_confirm_pulse) state <= S_SELECT_OP1;
                if (btn_return_pulse) state <= S_MAIN_MENU;
            end

            // 2.4.3 选择第一个运算数
            S_SELECT_OP1: begin
                case (sub_state)
                    0: begin // 输入维度 m, n
                        req_scale_row <= sw_mode + 1;
                        req_scale_col <= sw_mode + 1;
                        if (btn_confirm_pulse) sub_state <= 1;
                    end
                    1: begin // 选择索引 idx
                        req_index <= sw_mode[1:0]; // 对应 MAX_MATRIX_PER_SIZE 
                        if (btn_confirm_pulse) begin
                            for (k=0; k<25; k=k+1) matrix_opr_1[k] <= storage_output_data[k];
                            matrix_opr_1_r1 <= output_matrix_row;
                            matrix_opr_1_c1 <= output_matrix_col;
                            
                            if (selected_op_type == 2 || selected_op_type == 4) begin
                                state <= S_SELECT_OP2; sub_state <= 0;
                            end else if (selected_op_type == 3) begin
                                state <= S_OPER_SCALE;
                            end else begin
                                state <= S_COMPUTE;
                            end
                        end
                    end
                endcase
            end

            // 选择第二个运算数并进行判定
            S_SELECT_OP2: begin
                case (sub_state)
                    0: begin
                        req_scale_row <= sw_mode + 1;
                        req_scale_col <= sw_mode + 1;
                        if (btn_confirm_pulse) sub_state <= 1;
                    end
                    1: begin
                        req_index <= sw_mode[1:0];
                        if (btn_confirm_pulse) begin
                            // 判定运算数合法性
                            if (selected_op_type == 2 && (matrix_opr_1_r1 != output_matrix_row || matrix_opr_1_c1 != output_matrix_col)) begin
                                state <= S_ERROR_TIMER; error_timer <= timer_config;
                            end else if (selected_op_type == 4 && (matrix_opr_1_c1 != output_matrix_row)) begin
                                state <= S_ERROR_TIMER; error_timer <= timer_config;
                            end else begin
                                for (k=0; k<25; k=k+1) matrix_opr_2[k] <= storage_output_data[k];
                                matrix_opr_2_r2 <= output_matrix_row;
                                matrix_opr_2_c2 <= output_matrix_col;
                                state <= S_COMPUTE;
                            end
                        end
                    end
                endcase
            end

            // 2.4.3.1.2) b) 报错倒计时逻辑
            S_ERROR_TIMER: begin
                led_error_status <= 1;
                menuState <= {4'hE, 4'h0, error_timer[3:0]}; // 数码管显示 E 和倒计时
                if (clk_1hz && error_timer > 0) error_timer <= error_timer - 1;
                
                if (error_timer == 0) begin
                    led_error_status <= 0;
                    state <= S_SELECT_OP1; sub_state <= 0;
                end
                // 倒计时内按下确认可立即重试
                if (btn_confirm_pulse) begin
                    led_error_status <= 0;
                    state <= S_SELECT_OP1; sub_state <= 0;
                end
            end

            // 执行运算运算
            S_COMPUTE: begin
                case (selected_op_type)
                    1: trans_en <= 1;
                    2: add_en <= 1;
                    3: scalar_en <= 1;
                    4: mult_en <= 1;
                    5: conv_en <= 1;
                endcase

                if (calc_busy) compute_cnt <= 1;
                else if (compute_cnt == 1) begin
                    add_en <= 0; scalar_en <= 0; trans_en <= 0; mult_en <= 0; conv_en <= 0;
                    compute_cnt <= 0;
                    state <= S_DISPLAY_RES;
                end
            end

            // 2.3 & 2.4.4 展示结果
            S_DISPLAY_RES: begin
                if (!display_busy && !display_start) begin
                    // 从 matrix_ans MUX 中加载计算结果 
                    for (k=0; k<25; k=k+1) matrix_display_data[k] <= matrix_ans[k];
                    display_row <= matrix_ans_r_out;
                    display_col <= matrix_ans_c_out;
                    display_start <= 1; // 触发 matrix_displayer 
                end
                if (btn_return_pulse) state <= S_MAIN_MENU;
            end

            default: state <= S_IDLE;
        endcase
    end
end

endmodule