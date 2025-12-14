module top #(
    parameter DATA_WIDTH          = 9,        // 数据位宽
    parameter MAX_SIZE            = 5,        // 单个矩阵最大规模（1~5）
    parameter MATRIX_NUM          = 8,        // 全局最大矩阵数量
    parameter MAX_MATRIX_PER_SIZE = 4,        // 每个规模最多存储矩阵数
    parameter DEBOUNCE_CNT_MAX    = 20'd100000, // 按键消抖计数阈值（100ms@1MHz时钟）
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire clk,            // 系统时钟
    input  wire rst_n,          // 低有效复位
    input  wire uart_rx,        // UART接收数据
    output wire uart_tx,        // UART发送数据
    input  wire [2:0] sw_mode,  // 模式选择开关
    input  wire btn_confirm,    // 确认按钮
    input  wire btn_return,     // 返回按钮
    output reg led_error_status,// 错误状态指示灯
    output [7:0] seg_cs_pin,    // 8个数码管位选 (G2/C2/C1/H1/G1/F1/E1/G6)
    output [7:0] seg_data_0_pin, // 数码管段选0 (B4/A4/A3/B1/A1/B3/B2/D5)
    output [7:0] seg_data_1_pin  // 数码管段选1 (D4/E3/D3/F4/F3/E2/D2/H2)
);

// -------------------------- 内部信号定义 --------------------------

// 数码管显示模块相关信号
reg [11:0] menuState;      // 菜单状态（100/200/300/400/410~450）
reg [8:0] seconds;         // 秒数（seconds[8]为显示使能，[7:0]为0~99秒）
reg [31:0] sec_cnt;        // 秒计数器（50MHz计数到50_000_000为1秒）

// 消抖后的按键信号
wire btn_confirm_pulse;
wire btn_return_pulse;

// Matrix Storage 相关信号
wire        wr_en;
reg [2:0]  wr_row;
reg [2:0]  wr_col;
reg [DATA_WIDTH-1:0] storage_input_data[0:24]; 
wire [DATA_WIDTH-1:0] storage_output_data[0:24]; 
reg wr_en_reg;       // 存储模块写使能
reg write_flag;      // 写入完成标志（防重复触发）
reg [2:0] req_scale_row;
reg [2:0] req_scale_col;
reg [2:0] req_index;
wire [2:0] output_matrix_row;
wire [2:0] output_matrix_col;
wire [3:0] num; 

// Matrix Operator 相关信号
wire en;

reg [DATA_WIDTH-1:0] matrix_opr_1 [0:24]; 
reg [DATA_WIDTH-1:0] matrix_opr_2 [0:24];
wire [DATA_WIDTH-1:0] matrix_ans [0:24];
reg [3:0] matrix_opr_1_r1;
reg [3:0] matrix_opr_1_c1;
reg [3:0] matrix_opr_2_r2;
reg [3:0] matrix_opr_2_c2;
wire [3:0] matrix_ans_r_out;
wire [3:0] matrix_ans_c_out;

wire [DATA_WIDTH-1:0] scalar_value;

// UART 
wire [7:0] rx_data;
wire       rx_done;
// UART TX
reg [7:0] tx_data;
reg       tx_start;
wire       tx_busy;

// 随机矩阵生成模块相关信号
wire [DATA_WIDTH-1:0] rand_data [0:24];
wire rand_update_done;
reg [2:0] rand_row;  // 随机矩阵行数
reg [2:0] rand_col;  // 随机矩阵列数
reg rand_gen_en;     // 随机矩阵生成使能
reg [7:0] min_val;   // 随机数最小值
reg [7:0] max_val;   // 随机数最大值

// ========== 状态定义 ==========
localparam [3:0]
    S_IDLE        = 4'd0,   // 开机后初始状态
    S_MAIN_MENU   = 4'd1,   // 主菜单状态
    S_INPUT_MAT   = 4'd2,   // 矩阵输入模式
    S_GEN_MAT     = 4'd3,   // 矩阵生成模式
    S_DISP_MAT    = 4'd4,   // 矩阵展示模式
    S_OPER_MENU   = 4'd5,   // 矩阵运算菜单
    S_OPER_TRANS  = 4'd6,   // 矩阵转置
    S_OPER_ADD    = 4'd7,   // 矩阵加法
    S_OPER_SCALE  = 4'd8,   // 标量乘法
    S_OPER_MULT   = 4'd9,   // 矩阵乘法
    S_OPER_CONV   = 4'd10,  // 卷积运算（bonus）
    S_SELECT_OP1  = 4'd11,  // 选择第一个运算数
    S_SELECT_OP2  = 4'd12,  // 选择第二个运算数
    S_COMPUTE     = 4'd13,  // 执行计算
    S_DISPLAY_RES = 4'd14,  // 显示结果
    S_ERROR_TIMER = 4'd15;  // 错误倒计时处理
reg [3:0] state, next_state;

// ========== 状态机相关寄存器和计数器 ==========
reg [2:0] input_dim_m, input_dim_n;  // 输入矩阵维度
reg [3:0] input_element_cnt;         // 已输入元素计数
reg [3:0] gen_matrix_cnt;            // 要生成的矩阵个数
reg [3:0] selected_op_type;          // 选择的运算类型
reg [1:0] selected_mat_index;        // 选择的矩阵索引
reg [7:0] scalar_value_reg;          // 标量值
reg [7:0] timer_config;              // 倒计时时间配置(5-15秒)
reg [7:0] error_timer;               // 错误倒计时
reg [3:0] sub_state;                 // 子状态机
reg [3:0] mat_select_state;          // 矩阵选择状态机
reg [3:0] compute_cnt;               // 计算进度计数

// UART发送缓冲区
reg [7:0] uart_buffer [0:63];
reg [5:0] uart_buf_ptr;
reg uart_send_flag;
reg [7:0] uart_byte_cnt;

// 矩阵输入缓冲区
reg [DATA_WIDTH-1:0] input_buffer [0:24];
reg [7:0] input_values [0:49];  // 用于存储串口接收的ASCII值

// 卷积核缓冲区
reg [DATA_WIDTH-1:0] kernel_buffer [0:8];

// ========== 矩阵运算模块使能控制 ==========
reg add_en, scalar_en, trans_en, mult_en, conv_en;

// ========== 模块实例化 ==========
uart_rx #(
    .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)
) u_rx (
    .clk(clk), .rst_n(rst_n),
    .rx(uart_rx),
    .rx_data(rx_data),
    .rx_done(rx_done)
);

uart_tx #(
    .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)
) u_tx (
    .clk(clk), .rst_n(rst_n),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(uart_tx),
    .tx_busy(tx_busy)
);

key_debounce u_keydebounce1 (
    .clk(clk),
    .rst_n(rst_n),
    .btn_trigger(btn_confirm),
    .btn_pulse(btn_confirm_pulse)
);

key_debounce u_keydebounce2 (
    .clk(clk),
    .rst_n(rst_n),
    .btn_trigger(btn_return),
    .btn_pulse(btn_return_pulse)
);

multi_matrix_storage #(
    .DATA_WIDTH(DATA_WIDTH),
    .MAX_SIZE(MAX_SIZE),
    .MATRIX_NUM(MATRIX_NUM),
    .MAX_MATRIX_PER_SIZE(MAX_MATRIX_PER_SIZE)
) u_matrix_storage (
    .clk(clk),
    .rst_n(rst_n),
    // 写入接口
    .wr_en(wr_en_reg),                     // 写使能（生成完成后触发）
    .write_row(wr_row),                    // 写入矩阵行数（拨码输入）
    .write_col(wr_col),                    // 写入矩阵列数（拨码输入）
    .data_in_0(storage_input_data[0]),
    .data_in_1(storage_input_data[1]),
    .data_in_2(storage_input_data[2]),
    .data_in_3(storage_input_data[3]),
    .data_in_4(storage_input_data[4]),
    .data_in_5(storage_input_data[5]),
    .data_in_6(storage_input_data[6]),
    .data_in_7(storage_input_data[7]),
    .data_in_8(storage_input_data[8]),
    .data_in_9(storage_input_data[9]),
    .data_in_10(storage_input_data[10]),
    .data_in_11(storage_input_data[11]),
    .data_in_12(storage_input_data[12]),
    .data_in_13(storage_input_data[13]),
    .data_in_14(storage_input_data[14]),
    .data_in_15(storage_input_data[15]),
    .data_in_16(storage_input_data[16]),
    .data_in_17(storage_input_data[17]),
    .data_in_18(storage_input_data[18]),
    .data_in_19(storage_input_data[19]),
    .data_in_20(storage_input_data[20]),
    .data_in_21(storage_input_data[21]),
    .data_in_22(storage_input_data[22]),
    .data_in_23(storage_input_data[23]),
    .data_in_24(storage_input_data[24]),
    // 查询接口（连接到显示控制逻辑）
    .req_scale_row(req_scale_row),
    .req_scale_col(req_scale_col),
    .req_idx(req_index),           // 修改：连接到显示索引
    // 输出接口（调试用）
    .scale_matrix_cnt(num),
    .matrix_data_0(storage_output_data[0]),
    .matrix_data_1(storage_output_data[1]),
    .matrix_data_2(storage_output_data[2]),
    .matrix_data_3(storage_output_data[3]),
    .matrix_data_4(storage_output_data[4]),
    .matrix_data_5(storage_output_data[5]),
    .matrix_data_6(storage_output_data[6]),
    .matrix_data_7(storage_output_data[7]),
    .matrix_data_8(storage_output_data[8]),
    .matrix_data_9(storage_output_data[9]),
    .matrix_data_10(storage_output_data[10]),
    .matrix_data_11(storage_output_data[11]),
    .matrix_data_12(storage_output_data[12]),
    .matrix_data_13(storage_output_data[13]),
    .matrix_data_14(storage_output_data[14]),
    .matrix_data_15(storage_output_data[15]),
    .matrix_data_16(storage_output_data[16]),
    .matrix_data_17(storage_output_data[17]),
    .matrix_data_18(storage_output_data[18]),
    .matrix_data_19(storage_output_data[19]),
    .matrix_data_20(storage_output_data[20]),
    .matrix_data_21(storage_output_data[21]),
    .matrix_data_22(storage_output_data[22]),
    .matrix_data_23(storage_output_data[23]),
    .matrix_data_24(storage_output_data[24]),
    .matrix_row(output_matrix_row),
    .matrix_col(output_matrix_col),
    .matrix_valid()
);

// 随机矩阵生成模块实例化
random_matrix_generator #(
    .WIDTH(DATA_WIDTH),
    .MAX_DIM(MAX_SIZE)
) u_rand_matrix (
    .clk(clk),
    .rst_n(rst_n),
    .row(rand_row),                  // 随机矩阵行数
    .col(rand_col),                  // 随机矩阵列数
    .min_val(min_val),               // 随机数最小值
    .max_val(max_val),               // 随机数最大值
    .update_en(rand_gen_en),         // 随机矩阵生成使能
    // 随机矩阵数据输出（连接到存储模块输入）
    .matrix_out0(rand_data[0]),
    .matrix_out1(rand_data[1]),
    .matrix_out2(rand_data[2]),
    .matrix_out3(rand_data[3]),
    .matrix_out4(rand_data[4]),
    .matrix_out5(rand_data[5]),
    .matrix_out6(rand_data[6]),
    .matrix_out7(rand_data[7]),
    .matrix_out8(rand_data[8]),
    .matrix_out9(rand_data[9]),
    .matrix_out10(rand_data[10]),
    .matrix_out11(rand_data[11]),
    .matrix_out12(rand_data[12]),
    .matrix_out13(rand_data[13]),
    .matrix_out14(rand_data[14]),
    .matrix_out15(rand_data[15]),
    .matrix_out16(rand_data[16]),
    .matrix_out17(rand_data[17]),
    .matrix_out18(rand_data[18]),
    .matrix_out19(rand_data[19]),
    .matrix_out20(rand_data[20]),
    .matrix_out21(rand_data[21]),
    .matrix_out22(rand_data[22]),
    .matrix_out23(rand_data[23]),
    .matrix_out24(rand_data[24]),
    .update_done(rand_update_done) // 矩阵生成完成标志
);

matrix_adder #(
    .DATA_WIDTH(DATA_WIDTH)
) u_matrix_adder (
    .clk(clk),
    .reset_n(rst_n),
    .r1(matrix_opr_1_r1),
    .c1(matrix_opr_1_c1),
    .data1_in_0(matrix_opr_1[0]),
    .data1_in_1(matrix_opr_1[1]),
    .data1_in_2(matrix_opr_1[2]),
    .data1_in_3(matrix_opr_1[3]),
    .data1_in_4(matrix_opr_1[4]),
    .data1_in_5(matrix_opr_1[5]),
    .data1_in_6(matrix_opr_1[6]),
    .data1_in_7(matrix_opr_1[7]),
    .data1_in_8(matrix_opr_1[8]),
    .data1_in_9(matrix_opr_1[9]),
    .data1_in_10(matrix_opr_1[10]),
    .data1_in_11(matrix_opr_1[11]),
    .data1_in_12(matrix_opr_1[12]),
    .data1_in_13(matrix_opr_1[13]),
    .data1_in_14(matrix_opr_1[14]),
    .data1_in_15(matrix_opr_1[15]),
    .data1_in_16(matrix_opr_1[16]),
    .data1_in_17(matrix_opr_1[17]),
    .data1_in_18(matrix_opr_1[18]),
    .data1_in_19(matrix_opr_1[19]),
    .data1_in_20(matrix_opr_1[20]),
    .data1_in_21(matrix_opr_1[21]),
    .data1_in_22(matrix_opr_1[22]),
    .data1_in_23(matrix_opr_1[23]),
    .data1_in_24(matrix_opr_1[24]),
    .r2(matrix_opr_2_r2),
    .c2(matrix_opr_2_c2),
    .data2_in_0(matrix_opr_2[0]),
    .data2_in_1(matrix_opr_2[1]),
    .data2_in_2(matrix_opr_2[2]),
    .data2_in_3(matrix_opr_2[3]),
    .data2_in_4(matrix_opr_2[4]),
    .data2_in_5(matrix_opr_2[5]),
    .data2_in_6(matrix_opr_2[6]),
    .data2_in_7(matrix_opr_2[7]),
    .data2_in_8(matrix_opr_2[8]),
    .data2_in_9(matrix_opr_2[9]),
    .data2_in_10(matrix_opr_2[10]),
    .data2_in_11(matrix_opr_2[11]),
    .data2_in_12(matrix_opr_2[12]),
    .data2_in_13(matrix_opr_2[13]),
    .data2_in_14(matrix_opr_2[14]),
    .data2_in_15(matrix_opr_2[15]),
    .data2_in_16(matrix_opr_2[16]),
    .data2_in_17(matrix_opr_2[17]),
    .data2_in_18(matrix_opr_2[18]),
    .data2_in_19(matrix_opr_2[19]),
    .data2_in_20(matrix_opr_2[20]),
    .data2_in_21(matrix_opr_2[21]),
    .data2_in_22(matrix_opr_2[22]),
    .data2_in_23(matrix_opr_2[23]),
    .data2_in_24(matrix_opr_2[24]),
    .en(add_en),
    .r_out(matrix_ans_r_out),
    .c_out(matrix_ans_c_out),
    .data_out_0(matrix_ans[0]),
    .data_out_1(matrix_ans[1]),
    .data_out_2(matrix_ans[2]),
    .data_out_3(matrix_ans[3]),
    .data_out_4(matrix_ans[4]),
    .data_out_5(matrix_ans[5]),
    .data_out_6(matrix_ans[6]),
    .data_out_7(matrix_ans[7]),
    .data_out_8(matrix_ans[8]),
    .data_out_9(matrix_ans[9]),
    .data_out_10(matrix_ans[10]),
    .data_out_11(matrix_ans[11]),
    .data_out_12(matrix_ans[12]),
    .data_out_13(matrix_ans[13]),
    .data_out_14(matrix_ans[14]),
    .data_out_15(matrix_ans[15]),
    .data_out_16(matrix_ans[16]),
    .data_out_17(matrix_ans[17]),
    .data_out_18(matrix_ans[18]),
    .data_out_19(matrix_ans[19]),
    .data_out_20(matrix_ans[20]),
    .data_out_21(matrix_ans[21]),
    .data_out_22(matrix_ans[22]),
    .data_out_23(matrix_ans[23]),
    .data_out_24(matrix_ans[24]),
    .isValid(),
    .busy()
);

matrix_scalar #(
    .DATA_WIDTH(DATA_WIDTH)
) u_matrix_scalar (
    .clk(clk),
    .reset_n(rst_n),
    .r(matrix_opr_1_r1),
    .c(matrix_opr_1_c1),
    .data_in_0(matrix_opr_1[0]),
    .data_in_1(matrix_opr_1[1]),
    .data_in_2(matrix_opr_1[2]),
    .data_in_3(matrix_opr_1[3]),
    .data_in_4(matrix_opr_1[4]),
    .data_in_5(matrix_opr_1[5]),
    .data_in_6(matrix_opr_1[6]),
    .data_in_7(matrix_opr_1[7]),
    .data_in_8(matrix_opr_1[8]),
    .data_in_9(matrix_opr_1[9]),
    .data_in_10(matrix_opr_1[10]),
    .data_in_11(matrix_opr_1[11]),
    .data_in_12(matrix_opr_1[12]),
    .data_in_13(matrix_opr_1[13]),
    .data_in_14(matrix_opr_1[14]),
    .data_in_15(matrix_opr_1[15]),
    .data_in_16(matrix_opr_1[16]),
    .data_in_17(matrix_opr_1[17]),
    .data_in_18(matrix_opr_1[18]),
    .data_in_19(matrix_opr_1[19]),
    .data_in_20(matrix_opr_1[20]),
    .data_in_21(matrix_opr_1[21]),
    .data_in_22(matrix_opr_1[22]),
    .data_in_23(matrix_opr_1[23]),
    .data_in_24(matrix_opr_1[24]),
    .en(scalar_en),
    .scalar(scalar_value),
    .r_out(matrix_ans_r_out),
    .c_out(matrix_ans_c_out),
    .data_out_0(matrix_ans[0]),
    .data_out_1(matrix_ans[1]),
    .data_out_2(matrix_ans[2]),
    .data_out_3(matrix_ans[3]),
    .data_out_4(matrix_ans[4]),
    .data_out_5(matrix_ans[5]),
    .data_out_6(matrix_ans[6]),
    .data_out_7(matrix_ans[7]),
    .data_out_8(matrix_ans[8]),
    .data_out_9(matrix_ans[9]),
    .data_out_10(matrix_ans[10]),
    .data_out_11(matrix_ans[11]),
    .data_out_12(matrix_ans[12]),
    .data_out_13(matrix_ans[13]),
    .data_out_14(matrix_ans[14]),
    .data_out_15(matrix_ans[15]),
    .data_out_16(matrix_ans[16]),
    .data_out_17(matrix_ans[17]),
    .data_out_18(matrix_ans[18]),
    .data_out_19(matrix_ans[19]),
    .data_out_20(matrix_ans[20]),
    .data_out_21(matrix_ans[21]),
    .data_out_22(matrix_ans[22]),
    .data_out_23(matrix_ans[23]),
    .data_out_24(matrix_ans[24]),
    .busy()
);

matrix_transpose #(
    .DATA_WIDTH(DATA_WIDTH)
) u_matrix_transpose (
    .clk(clk),
    .reset_n(rst_n),
    .r(matrix_opr_1_r1),
    .c(matrix_opr_1_c1),
    .data_in_0(matrix_opr_1[0]),
    .data_in_1(matrix_opr_1[1]),
    .data_in_2(matrix_opr_1[2]),
    .data_in_3(matrix_opr_1[3]),
    .data_in_4(matrix_opr_1[4]),
    .data_in_5(matrix_opr_1[5]),
    .data_in_6(matrix_opr_1[6]),
    .data_in_7(matrix_opr_1[7]),
    .data_in_8(matrix_opr_1[8]),
    .data_in_9(matrix_opr_1[9]),
    .data_in_10(matrix_opr_1[10]),
    .data_in_11(matrix_opr_1[11]),
    .data_in_12(matrix_opr_1[12]),
    .data_in_13(matrix_opr_1[13]),
    .data_in_14(matrix_opr_1[14]),
    .data_in_15(matrix_opr_1[15]),
    .data_in_16(matrix_opr_1[16]),
    .data_in_17(matrix_opr_1[17]),
    .data_in_18(matrix_opr_1[18]),
    .data_in_19(matrix_opr_1[19]),
    .data_in_20(matrix_opr_1[20]),
    .data_in_21(matrix_opr_1[21]),
    .data_in_22(matrix_opr_1[22]),
    .data_in_23(matrix_opr_1[23]),
    .data_in_24(matrix_opr_1[24]),
    .en(trans_en),
    .r_out(matrix_ans_r_out),
    .c_out(matrix_ans_c_out),
    .data_out_0(matrix_ans[0]),
    .data_out_1(matrix_ans[1]),
    .data_out_2(matrix_ans[2]),
    .data_out_3(matrix_ans[3]),
    .data_out_4(matrix_ans[4]),
    .data_out_5(matrix_ans[5]),
    .data_out_6(matrix_ans[6]),
    .data_out_7(matrix_ans[7]),
    .data_out_8(matrix_ans[8]),
    .data_out_9(matrix_ans[9]),
    .data_out_10(matrix_ans[10]),
    .data_out_11(matrix_ans[11]),
    .data_out_12(matrix_ans[12]),
    .data_out_13(matrix_ans[13]),
    .data_out_14(matrix_ans[14]),
    .data_out_15(matrix_ans[15]),
    .data_out_16(matrix_ans[16]),
    .data_out_17(matrix_ans[17]),
    .data_out_18(matrix_ans[18]),
    .data_out_19(matrix_ans[19]),
    .data_out_20(matrix_ans[20]),
    .data_out_21(matrix_ans[21]),
    .data_out_22(matrix_ans[22]),
    .data_out_23(matrix_ans[23]),
    .data_out_24(matrix_ans[24]),
    .busy()
);

matrix_multiplier #(
    .DATA_WIDTH(DATA_WIDTH)
) u_matrix_multiplier (
    .clk(clk),
    .reset_n(rst_n),
    .r1(matrix_opr_1_r1),
    .c1(matrix_opr_1_c1),
    .data1_in_0(matrix_opr_1[0]),
    .data1_in_1(matrix_opr_1[1]),
    .data1_in_2(matrix_opr_1[2]),
    .data1_in_3(matrix_opr_1[3]),
    .data1_in_4(matrix_opr_1[4]),
    .data1_in_5(matrix_opr_1[5]),
    .data1_in_6(matrix_opr_1[6]),
    .data1_in_7(matrix_opr_1[7]),
    .data1_in_8(matrix_opr_1[8]),
    .data1_in_9(matrix_opr_1[9]),
    .data1_in_10(matrix_opr_1[10]),
    .data1_in_11(matrix_opr_1[11]),
    .data1_in_12(matrix_opr_1[12]),
    .data1_in_13(matrix_opr_1[13]),
    .data1_in_14(matrix_opr_1[14]),
    .data1_in_15(matrix_opr_1[15]),
    .data1_in_16(matrix_opr_1[16]),
    .data1_in_17(matrix_opr_1[17]),
    .data1_in_18(matrix_opr_1[18]),
    .data1_in_19(matrix_opr_1[19]),
    .data1_in_20(matrix_opr_1[20]),
    .data1_in_21(matrix_opr_1[21]),
    .data1_in_22(matrix_opr_1[22]),
    .data1_in_23(matrix_opr_1[23]),
    .data1_in_24(matrix_opr_1[24]),
    .r2(matrix_opr_2_r2),
    .c2(matrix_opr_2_c2),
    .data2_in_0(matrix_opr_2[0]),
    .data2_in_1(matrix_opr_2[1]),
    .data2_in_2(matrix_opr_2[2]),
    .data2_in_3(matrix_opr_2[3]),
    .data2_in_4(matrix_opr_2[4]),
    .data2_in_5(matrix_opr_2[5]),
    .data2_in_6(matrix_opr_2[6]),
    .data2_in_7(matrix_opr_2[7]),
    .data2_in_8(matrix_opr_2[8]),
    .data2_in_9(matrix_opr_2[9]),
    .data2_in_10(matrix_opr_2[10]),
    .data2_in_11(matrix_opr_2[11]),
    .data2_in_12(matrix_opr_2[12]),
    .data2_in_13(matrix_opr_2[13]),
    .data2_in_14(matrix_opr_2[14]),
    .data2_in_15(matrix_opr_2[15]),
    .data2_in_16(matrix_opr_2[16]),
    .data2_in_17(matrix_opr_2[17]),
    .data2_in_18(matrix_opr_2[18]),
    .data2_in_19(matrix_opr_2[19]),
    .data2_in_20(matrix_opr_2[20]),
    .data2_in_21(matrix_opr_2[21]),
    .data2_in_22(matrix_opr_2[22]),
    .data2_in_23(matrix_opr_2[23]),
    .data2_in_24(matrix_opr_2[24]),
    .en(mult_en),
    .r_out(matrix_ans_r_out),
    .c_out(matrix_ans_c_out),
    .data_out_0(matrix_ans[0]),
    .data_out_1(matrix_ans[1]),
    .data_out_2(matrix_ans[2]),
    .data_out_3(matrix_ans[3]),
    .data_out_4(matrix_ans[4]),
    .data_out_5(matrix_ans[5]),
    .data_out_6(matrix_ans[6]),
    .data_out_7(matrix_ans[7]),
    .data_out_8(matrix_ans[8]),
    .data_out_9(matrix_ans[9]),
    .data_out_10(matrix_ans[10]),
    .data_out_11(matrix_ans[11]),
    .data_out_12(matrix_ans[12]),
    .data_out_13(matrix_ans[13]),
    .data_out_14(matrix_ans[14]),
    .data_out_15(matrix_ans[15]),
    .data_out_16(matrix_ans[16]),
    .data_out_17(matrix_ans[17]),
    .data_out_18(matrix_ans[18]),
    .data_out_19(matrix_ans[19]),
    .data_out_20(matrix_ans[20]),
    .data_out_21(matrix_ans[21]),
    .data_out_22(matrix_ans[22]),
    .data_out_23(matrix_ans[23]),
    .data_out_24(matrix_ans[24]),
    .isValid(),
    .busy()
);

segment_display u_segment_display(
    .clk(clk),
    .reset(rst_n),
    .menuState(menuState),
    .seconds(seconds),
    // 数码管位选：tub_sel1~8对应seg_cs_pin[0]~[7]
    .tub_sel1(seg_cs_pin[0]),
    .tub_sel2(seg_cs_pin[1]),
    .tub_sel3(seg_cs_pin[2]),
    .tub_sel4(seg_cs_pin[3]),
    .tub_sel5(seg_cs_pin[4]),
    .tub_sel6(seg_cs_pin[5]),
    .tub_sel7(seg_cs_pin[6]),
    .tub_sel8(seg_cs_pin[7]),
    // 数码管段选：tub_control1→seg_data_0_pin，tub_control2→seg_data_1_pin
    .tub_control1(seg_data_0_pin),
    .tub_control2(seg_data_1_pin)
);

matrix_conv #(
    .DATA_WIDTH(DATA_WIDTH)
) u_matrix_conv (
    .clk(clk),
    .reset_n(rst_n),
    .data_in_0(matrix_opr_1[0]),
    .data_in_1(matrix_opr_1[1]),
    .data_in_2(matrix_opr_1[2]),
    .data_in_3(matrix_opr_1[3]),
    .data_in_4(matrix_opr_1[4]),
    .data_in_5(matrix_opr_1[5]),
    .data_in_6(matrix_opr_1[6]),
    .data_in_7(matrix_opr_1[7]),
    .data_in_8(matrix_opr_1[8]),
    .data_in_9(matrix_opr_1[9]),
    .data_in_10(matrix_opr_1[10]),
    .data_in_11(matrix_opr_1[11]),
    .data_in_12(matrix_opr_1[12]),
    .data_in_13(matrix_opr_1[13]),
    .data_in_14(matrix_opr_1[14]),
    .data_in_15(matrix_opr_1[15]),
    .data_in_16(matrix_opr_1[16]),
    .data_in_17(matrix_opr_1[17]),
    .data_in_18(matrix_opr_1[18]),
    .data_in_19(matrix_opr_1[19]),
    .data_in_20(matrix_opr_1[20]),
    .data_in_21(matrix_opr_1[21]),
    .data_in_22(matrix_opr_1[22]),
    .data_in_23(matrix_opr_1[23]),
    .data_in_24(matrix_opr_1[24]),
    .en(conv_en),
    .data_out_0(matrix_ans[0]),
    .data_out_1(matrix_ans[1]),
    .data_out_2(matrix_ans[2]),
    .data_out_3(matrix_ans[3]),
    .data_out_4(matrix_ans[4]),
    .data_out_5(matrix_ans[5]),
    .data_out_6(matrix_ans[6]),
    .data_out_7(matrix_ans[7]),
    .data_out_8(matrix_ans[8]),
    .data_out_9(matrix_ans[9]),
    .data_out_10(matrix_ans[10]),
    .data_out_11(matrix_ans[11]),
    .data_out_12(matrix_ans[12]),
    .data_out_13(matrix_ans[13]),
    .data_out_14(matrix_ans[14]),
    .data_out_15(matrix_ans[15]),
    .data_out_16(matrix_ans[16]),
    .data_out_17(matrix_ans[17]),
    .data_out_18(matrix_ans[18]),
    .data_out_19(matrix_ans[19]),
    .data_out_20(matrix_ans[20]),
    .data_out_21(matrix_ans[21]),
    .data_out_22(matrix_ans[22]),
    .data_out_23(matrix_ans[23]),
    .data_out_24(matrix_ans[24]),
    .busy()
);

// ========== 状态机主逻辑 ==========
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;
        sub_state <= 0;
        mat_select_state <= 0;
        wr_en_reg <= 0;
        write_flag <= 0;
        led_error_status <= 0;
        uart_send_flag <= 0;
        add_en <= 0;
        scalar_en <= 0;
        trans_en <= 0;
        mult_en <= 0;
        conv_en <= 0;
        menuState <= 0;
        seconds <= 0;
        sec_cnt <= 0;
        input_dim_m <= 0;
        input_dim_n <= 0;
        input_element_cnt <= 0;
        gen_matrix_cnt <= 0;
        selected_op_type <= 0;
        selected_mat_index <= 0;
        scalar_value_reg <= 0;
        timer_config <= 10; // 默认10秒
        error_timer <= 0;
        compute_cnt <= 0;
        uart_buf_ptr <= 0;
        uart_byte_cnt <= 0;
        tx_start <= 0;
        rand_gen_en <= 0;
        rand_row <= 0;
        rand_col <= 0;
        min_val <= 0;  // 默认最小值0
        max_val <= 9;  // 默认最大值9
    end else begin
        case (state)
            S_IDLE: begin
                // 系统初始化
                state <= S_MAIN_MENU;
                menuState <= 0;
            end
            
            S_MAIN_MENU: begin
                if (btn_confirm_pulse) begin
                    case (sw_mode)
                        3'b000: begin
                            state <= S_INPUT_MAT;
                            menuState <= 100;
                        end
                        3'b001: begin
                            state <= S_GEN_MAT;
                            menuState <= 200;
                        end
                        3'b010: begin
                            state <= S_DISP_MAT;
                            menuState <= 300;
                        end
                        3'b011: begin
                            state <= S_OPER_MENU;
                            menuState <= 400;
                        end
                        default: state <= S_MAIN_MENU;
                    endcase
                end
            end
            
            S_INPUT_MAT: begin
                if (btn_return_pulse) begin
                    state <= S_MAIN_MENU;
                end else begin
                    case (sub_state)
                        0: begin
                            // 等待输入矩阵维度m
                            if (rx_done) begin
                                if (rx_data >= "0" && rx_data <= "5") begin
                                    input_dim_m <= rx_data - "0";
                                    sub_state <= 1;
                                end else begin
                                    led_error_status <= 1; // 维度错误
                                end
                            end
                        end
                        1: begin
                            // 等待输入矩阵维度n
                            if (rx_done) begin
                                if (rx_data >= "0" && rx_data <= "5") begin
                                    input_dim_n <= rx_data - "0";
                                    sub_state <= 2;
                                    input_element_cnt <= 0;
                                end else begin
                                    led_error_status <= 1;
                                end
                            end
                        end
                        2: begin
                            // 接收矩阵元素
                            if (rx_done) begin
                                if (rx_data >= "0" && rx_data <= "9") begin
                                    input_values[input_element_cnt] <= rx_data - "0";
                                    input_element_cnt <= input_element_cnt + 1;
                                    
                                    // 检查是否接收完所有元素
                                    if (input_element_cnt == (input_dim_m * input_dim_n - 1)) begin
                                        sub_state <= 3;
                                    end
                                end else begin
                                    led_error_status <= 1; // 元素值错误
                                end
                            end
                        end
                        3: begin
                            // 存储矩阵到存储器
                            
                            write_flag <= 1;
                            wr_row <= input_dim_m;
                            wr_col <= input_dim_n;
                            
                            // 直接赋值每个元素（不使用循环）
                            storage_input_data[0] <= (0 < input_dim_m * input_dim_n) ? input_values[0] : 0;
                            storage_input_data[1] <= (1 < input_dim_m * input_dim_n) ? input_values[1] : 0;
                            storage_input_data[2] <= (2 < input_dim_m * input_dim_n) ? input_values[2] : 0;
                            storage_input_data[3] <= (3 < input_dim_m * input_dim_n) ? input_values[3] : 0;
                            storage_input_data[4] <= (4 < input_dim_m * input_dim_n) ? input_values[4] : 0;
                            storage_input_data[5] <= (5 < input_dim_m * input_dim_n) ? input_values[5] : 0;
                            storage_input_data[6] <= (6 < input_dim_m * input_dim_n) ? input_values[6] : 0;
                            storage_input_data[7] <= (7 < input_dim_m * input_dim_n) ? input_values[7] : 0;
                            storage_input_data[8] <= (8 < input_dim_m * input_dim_n) ? input_values[8] : 0;
                            storage_input_data[9] <= (9 < input_dim_m * input_dim_n) ? input_values[9] : 0;
                            storage_input_data[10] <= (10 < input_dim_m * input_dim_n) ? input_values[10] : 0;
                            storage_input_data[11] <= (11 < input_dim_m * input_dim_n) ? input_values[11] : 0;
                            storage_input_data[12] <= (12 < input_dim_m * input_dim_n) ? input_values[12] : 0;
                            storage_input_data[13] <= (13 < input_dim_m * input_dim_n) ? input_values[13] : 0;
                            storage_input_data[14] <= (14 < input_dim_m * input_dim_n) ? input_values[14] : 0;
                            storage_input_data[15] <= (15 < input_dim_m * input_dim_n) ? input_values[15] : 0;
                            storage_input_data[16] <= (16 < input_dim_m * input_dim_n) ? input_values[16] : 0;
                            storage_input_data[17] <= (17 < input_dim_m * input_dim_n) ? input_values[17] : 0;
                            storage_input_data[18] <= (18 < input_dim_m * input_dim_n) ? input_values[18] : 0;
                            storage_input_data[19] <= (19 < input_dim_m * input_dim_n) ? input_values[19] : 0;
                            storage_input_data[20] <= (20 < input_dim_m * input_dim_n) ? input_values[20] : 0;
                            storage_input_data[21] <= (21 < input_dim_m * input_dim_n) ? input_values[21] : 0;
                            storage_input_data[22] <= (22 < input_dim_m * input_dim_n) ? input_values[22] : 0;
                            storage_input_data[23] <= (23 < input_dim_m * input_dim_n) ? input_values[23] : 0;
                            storage_input_data[24] <= (24 < input_dim_m * input_dim_n) ? input_values[24] : 0;
                            wr_en_reg <= 1;
                            sub_state <= 4;
                        end
                        4: begin
                            // 等待存储完成
                            wr_en_reg <= 0;
                            if (write_flag) begin
                                write_flag <= 0;
                                sub_state <= 0;
                                state <= S_MAIN_MENU;
                            end
                        end
                    endcase
                end
            end
            
           S_GEN_MAT: begin
    if (btn_return_pulse) begin
        state <= S_MAIN_MENU;
        sub_state <= 0; // 退回主菜单时重置子状态
        led_error_status <= 0; // 可选：重置错误灯
    end else begin
        case (sub_state)
            0: begin
                // 等待输入矩阵行数m
                led_error_status <= 0; // 初始化为0，避免错误状态残留
                if (rx_done) begin
                    if (rx_data >= "0" && rx_data <= "5") begin
                        rand_row <= rx_data - "0";
                        sub_state <= 1;
                    end else begin
                        led_error_status <= 1;
                    end
                end
            end
            1: begin
                // 等待输入矩阵列数n
                if (rx_done) begin
                    if (rx_data >= "0" && rx_data <= "5") begin
                        rand_col <= rx_data - "0";
                        sub_state <= 2;
                    end else begin
                        led_error_status <= 1;
                    end
                end
            end
            2: begin
                // 等待输入要生成的矩阵个数
                if (rx_done) begin
                    if (rx_data >= "1" && rx_data <= "2") begin
                        gen_matrix_cnt <= rx_data - "0";
                        sub_state <= 3;
                        // 设置随机数范围
                        min_val <= 0;  // 默认0
                        max_val <= 9;  // 默认9
                         uart_buffer[0] <= "Q";
                    uart_buf_ptr <= 1;
                    uart_send_flag <= 1;
                    end else begin
                        led_error_status <= 1;
                    end
                end
            end
            3: begin
                // 启动随机矩阵生成
                rand_gen_en <= 1;
                sub_state <= 4;
                uart_buffer[0] <= "W";
                    uart_buf_ptr <= 1;
                    uart_send_flag <= 1;
            end
            4: begin
                // 步骤1：停止随机生成，等待生成完成
                rand_gen_en <= 0;
                if (rand_update_done) begin
                    // 先给存储输入数据赋值（非阻塞赋值，本周期结束后更新）
                    storage_input_data[0] <= rand_data[0];
                    storage_input_data[1] <= rand_data[1];
                    storage_input_data[2] <= rand_data[2];
                    storage_input_data[3] <= rand_data[3];
                    storage_input_data[4] <= rand_data[4];
                    storage_input_data[5] <= rand_data[5];
                    storage_input_data[6] <= rand_data[6];
                    storage_input_data[7] <= rand_data[7];
                    storage_input_data[8] <= rand_data[8];
                    storage_input_data[9] <= rand_data[9];
                    storage_input_data[10] <= rand_data[10];
                    storage_input_data[11] <= rand_data[11];
                    storage_input_data[12] <= rand_data[12];
                    storage_input_data[13] <= rand_data[13];
                    storage_input_data[14] <= rand_data[14];
                    storage_input_data[15] <= rand_data[15];
                    storage_input_data[16] <= rand_data[16];
                    storage_input_data[17] <= rand_data[17];
                    storage_input_data[18] <= rand_data[18];
                    storage_input_data[19] <= rand_data[19];
                    storage_input_data[20] <= rand_data[20];
                    storage_input_data[21] <= rand_data[21];
                    storage_input_data[22] <= rand_data[22];
                    storage_input_data[23] <= rand_data[23];
                    storage_input_data[24] <= rand_data[24];
                    
                    // 配置写入参数（行/列）
                    write_flag <= 1;
                    wr_row <= rand_row;
                    wr_col <= rand_col;
                    uart_buffer[0] <= "E";
                    uart_buf_ptr <= 1;
                    uart_send_flag <= 1;
                    // 跳转到中间状态，准备拉高写使能
                    sub_state <= 4_1;
                    // 写使能保持低电平
                    wr_en_reg <= 0;
                end
            end
            4_1: begin
                // 步骤2：拉高写使能一个周期（此时storage_input_data已更新）
                wr_en_reg <= 1;
                sub_state <= 5;
                uart_buffer[0] <= "R";
                    uart_buf_ptr <= 1;
                    uart_send_flag <= 1;
            end
            5: begin
                // 步骤3：拉低写使能，完成写入
                wr_en_reg <= 0;
                if (write_flag) begin
                    write_flag <= 0;
                    gen_matrix_cnt <= gen_matrix_cnt - 1;
                    uart_buffer[0] <= "T";
                    uart_buf_ptr <= 1;
                    uart_send_flag <= 1;
                    if (gen_matrix_cnt == 1) begin
                        // 所有矩阵生成完成，重置子状态并返回主菜单
                        sub_state <= 0;
                        state <= S_MAIN_MENU;
                        uart_buffer[0] <= "Y";
                    uart_buf_ptr <= 1;
                    uart_send_flag <= 1;
                    end else begin
                        // 生成下一个矩阵
                        uart_buffer[0] <= "U";
                    uart_buf_ptr <= 1;
                    uart_send_flag <= 1;
                        sub_state <= 3;
                    end
                end
            end
            default: sub_state <= 0; // 异常状态重置
        endcase
    end
end
            
            S_DISP_MAT: begin
                // 显示所有存储的矩阵
                if (btn_return_pulse) begin
                    state <= S_MAIN_MENU;
                end else begin
                    // 通过UART发送矩阵信息
                    uart_buffer[0] <= "D";
                    uart_buffer[1] <= "i";
                    uart_buffer[2] <= "s";
                    uart_buffer[3] <= "p";
                    uart_buffer[4] <= "l";
                    uart_buffer[5] <= "a";
                    uart_buffer[6] <= "y";
                    uart_buffer[7] <= " ";
                    uart_buffer[8] <= "M";
                    uart_buffer[9] <= "a";
                    uart_buffer[10] <= "t";
                    uart_buffer[11] <= "r";
                    uart_buffer[12] <= "i";
                    uart_buffer[13] <= "x";
                    uart_buf_ptr <= 14;
                    uart_send_flag <= 1;
                    state <= S_MAIN_MENU;
                end
            end
            
            S_OPER_MENU: begin
                if (btn_confirm_pulse) begin
                    case (sw_mode)
                        3'b000: begin
                            state <= S_OPER_TRANS;
                            selected_op_type <= 1;
                            menuState <= 410;
                        end
                        3'b001: begin
                            state <= S_OPER_ADD;
                            selected_op_type <= 2;
                            menuState <= 420;
                        end
                        3'b010: begin
                            state <= S_OPER_SCALE;
                            selected_op_type <= 3;
                            menuState <= 440;
                        end
                        3'b011: begin
                            state <= S_OPER_MULT;
                            selected_op_type <= 4;
                            menuState <= 450;
                        end
                        3'b100: begin
                            state <= S_OPER_CONV;
                            selected_op_type <= 5;
                            menuState <= 460;
                        end
                        default: state <= S_OPER_MENU;
                    endcase
                end
                if (btn_return_pulse) begin
                    state <= S_MAIN_MENU;
                end
            end
            
            S_OPER_TRANS: begin
                // 矩阵转置只需要一个操作数
                state <= S_SELECT_OP1;
                mat_select_state <= 0;
            end
            
            S_OPER_ADD: begin
                // 矩阵加法需要两个操作数
                state <= S_SELECT_OP1;
                mat_select_state <= 0;
            end
            
            S_OPER_SCALE: begin
                // 标量乘法：先选矩阵，再输入标量
                state <= S_SELECT_OP1;
                mat_select_state <= 0;
            end
            
            S_OPER_MULT: begin
                // 矩阵乘法需要两个操作数
                state <= S_SELECT_OP1;
                mat_select_state <= 0;
            end
            
            S_OPER_CONV: begin
                // 卷积运算：需要输入卷积核
                state <= S_SELECT_OP1;
                mat_select_state <= 0;
            end
            
            S_SELECT_OP1: begin
                case (mat_select_state)
                    0: begin
                        // 提示用户输入第一个矩阵维度
                        uart_buffer[0] <= "E";
                        uart_buffer[1] <= "n";
                        uart_buffer[2] <= "t";
                        uart_buffer[3] <= "e";
                        uart_buffer[4] <= "r";
                        uart_buffer[5] <= " ";
                        uart_buffer[6] <= "m";
                        uart_buffer[7] <= ":";
                        uart_buf_ptr <= 8;
                        uart_send_flag <= 1;
                        mat_select_state <= 1;
                    end
                    1: begin
                        // 等待输入行数
                        if (rx_done && rx_data >= "0" && rx_data <= "5") begin
                            req_scale_row <= rx_data - "0";
                            mat_select_state <= 2;
                        end
                    end
                    2: begin
                        // 等待输入列数
                        uart_buffer[0] <= "E";
                        uart_buffer[1] <= "n";
                        uart_buffer[2] <= "t";
                        uart_buffer[3] <= "e";
                        uart_buffer[4] <= "r";
                        uart_buffer[5] <= " ";
                        uart_buffer[6] <= "n";
                        uart_buffer[7] <= ":";
                        uart_buf_ptr <= 8;
                        uart_send_flag <= 1;
                        mat_select_state <= 3;
                    end
                    3: begin
                        if (rx_done && rx_data >= "0" && rx_data <= "5") begin
                            req_scale_col <= rx_data - "0";
                            mat_select_state <= 4;
                        end
                    end
                    4: begin
                        // 显示该维度的所有矩阵
                        // 查询存储模块
                        req_index <= 0;
                        // 等待存储模块返回数据
                        mat_select_state <= 5;
                    end
                    5: begin
                        // 显示矩阵列表
                        // 通过UART发送矩阵数据
                        mat_select_state <= 6;
                    end
                    6: begin
                        // 等待用户选择矩阵
                        if (rx_done && rx_data >= "0" && rx_data <= "9") begin
                            selected_mat_index <= rx_data - "0";
                            
                            // 从存储模块读取选中的矩阵到运算缓冲区
                            req_index <= selected_mat_index;
                            mat_select_state <= 7;
                        end
                    end
                    7: begin
                        // 将读取的矩阵存入运算缓冲区1
                        // 直接赋值每个元素（不使用循环）
                        matrix_opr_1[0] <= storage_output_data[0];
                        matrix_opr_1[1] <= storage_output_data[1];
                        matrix_opr_1[2] <= storage_output_data[2];
                        matrix_opr_1[3] <= storage_output_data[3];
                        matrix_opr_1[4] <= storage_output_data[4];
                        matrix_opr_1[5] <= storage_output_data[5];
                        matrix_opr_1[6] <= storage_output_data[6];
                        matrix_opr_1[7] <= storage_output_data[7];
                        matrix_opr_1[8] <= storage_output_data[8];
                        matrix_opr_1[9] <= storage_output_data[9];
                        matrix_opr_1[10] <= storage_output_data[10];
                        matrix_opr_1[11] <= storage_output_data[11];
                        matrix_opr_1[12] <= storage_output_data[12];
                        matrix_opr_1[13] <= storage_output_data[13];
                        matrix_opr_1[14] <= storage_output_data[14];
                        matrix_opr_1[15] <= storage_output_data[15];
                        matrix_opr_1[16] <= storage_output_data[16];
                        matrix_opr_1[17] <= storage_output_data[17];
                        matrix_opr_1[18] <= storage_output_data[18];
                        matrix_opr_1[19] <= storage_output_data[19];
                        matrix_opr_1[20] <= storage_output_data[20];
                        matrix_opr_1[21] <= storage_output_data[21];
                        matrix_opr_1[22] <= storage_output_data[22];
                        matrix_opr_1[23] <= storage_output_data[23];
                        matrix_opr_1[24] <= storage_output_data[24];
                        
                        matrix_opr_1_r1 <= output_matrix_row;
                        matrix_opr_1_c1 <= output_matrix_col;
                        
                        // 根据运算类型决定下一步
                        if (selected_op_type == 1 || selected_op_type == 5) begin
                            // 转置或卷积只需要一个操作数
                            state <= S_COMPUTE;
                        end else if (selected_op_type == 3) begin
                            // 标量乘法需要输入标量
                            state <= S_SELECT_OP2;
                            mat_select_state <= 0;
                        end else begin
                            // 加法或乘法需要第二个操作数
                            state <= S_SELECT_OP2;
                            mat_select_state <= 0;
                        end
                    end
                endcase
            end
            
            S_SELECT_OP2: begin
                if (selected_op_type == 3) begin
                    // 标量乘法：输入标量值
                    case (mat_select_state)
                        0: begin
                            uart_buffer[0] <= "E";
                            uart_buffer[1] <= "n";
                            uart_buffer[2] <= "t";
                            uart_buffer[3] <= "e";
                            uart_buffer[4] <= "r";
                            uart_buffer[5] <= " ";
                            uart_buffer[6] <= "s";
                            uart_buffer[7] <= "c";
                            uart_buffer[8] <= "a";
                            uart_buffer[9] <= "l";
                            uart_buffer[10] <= "a";
                            uart_buffer[11] <= "r";
                            uart_buffer[12] <= ":";
                            uart_buf_ptr <= 13;
                            uart_send_flag <= 1;
                            mat_select_state <= 1;
                        end
                        1: begin
                            if (rx_done) begin
                                if (rx_data >= "0" && rx_data <= "9") begin
                                    scalar_value_reg <= rx_data - "0";
                                    state <= S_COMPUTE;
                                end
                            end
                        end
                    endcase
                end else begin
                    // 选择第二个矩阵
                    case (mat_select_state)
                        0: begin
                            uart_buffer[0] <= "S";
                            uart_buffer[1] <= "e";
                            uart_buffer[2] <= "l";
                            uart_buffer[3] <= "e";
                            uart_buffer[4] <= "c";
                            uart_buffer[5] <= "t";
                            uart_buffer[6] <= " ";
                            uart_buffer[7] <= "M";
                            uart_buffer[8] <= "a";
                            uart_buffer[9] <= "t";
                            uart_buffer[10] <= "2";
                            uart_buffer[11] <= ":";
                            uart_buf_ptr <= 12;
                            uart_send_flag <= 1;
                            mat_select_state <= 1;
                        end
                        1: begin
                            // 输入第二个矩阵维度
                            if (rx_done && rx_data >= "0" && rx_data <= "5") begin
                                req_scale_row <= rx_data - "0";
                                mat_select_state <= 2;
                            end
                        end
                        2: begin
                            uart_buffer[0] <= "E";
                            uart_buffer[1] <= "n";
                            uart_buffer[2] <= "t";
                            uart_buffer[3] <= "e";
                            uart_buffer[4] <= "r";
                            uart_buffer[5] <= " ";
                            uart_buffer[6] <= "n";
                            uart_buffer[7] <= ":";
                            uart_buf_ptr <= 8;
                            uart_send_flag <= 1;
                            mat_select_state <= 3;
                        end
                        3: begin
                            if (rx_done && rx_data >= "0" && rx_data <= "5") begin
                                req_scale_col <= rx_data - "0";
                                mat_select_state <= 4;
                            end
                        end
                        4: begin
                            // 显示该维度的矩阵
                            req_index <= 0;
                            mat_select_state <= 5;
                        end
                        5: begin
                            // 显示矩阵列表
                            mat_select_state <= 6;
                        end
                        6: begin
                            // 选择矩阵
                            if (rx_done && rx_data >= "0" && rx_data <= "9") begin
                                selected_mat_index <= rx_data - "0";
                                req_index <= selected_mat_index;
                                mat_select_state <= 7;
                            end
                        end
                        7: begin
                            // 读取第二个矩阵到运算缓冲区2
                            // 直接赋值每个元素（不使用循环）
                            matrix_opr_2[0] <= storage_output_data[0];
                            matrix_opr_2[1] <= storage_output_data[1];
                            matrix_opr_2[2] <= storage_output_data[2];
                            matrix_opr_2[3] <= storage_output_data[3];
                            matrix_opr_2[4] <= storage_output_data[4];
                            matrix_opr_2[5] <= storage_output_data[5];
                            matrix_opr_2[6] <= storage_output_data[6];
                            matrix_opr_2[7] <= storage_output_data[7];
                            matrix_opr_2[8] <= storage_output_data[8];
                            matrix_opr_2[9] <= storage_output_data[9];
                            matrix_opr_2[10] <= storage_output_data[10];
                            matrix_opr_2[11] <= storage_output_data[11];
                            matrix_opr_2[12] <= storage_output_data[12];
                            matrix_opr_2[13] <= storage_output_data[13];
                            matrix_opr_2[14] <= storage_output_data[14];
                            matrix_opr_2[15] <= storage_output_data[15];
                            matrix_opr_2[16] <= storage_output_data[16];
                            matrix_opr_2[17] <= storage_output_data[17];
                            matrix_opr_2[18] <= storage_output_data[18];
                            matrix_opr_2[19] <= storage_output_data[19];
                            matrix_opr_2[20] <= storage_output_data[20];
                            matrix_opr_2[21] <= storage_output_data[21];
                            matrix_opr_2[22] <= storage_output_data[22];
                            matrix_opr_2[23] <= storage_output_data[23];
                            matrix_opr_2[24] <= storage_output_data[24];
                            
                            matrix_opr_2_r2 <= output_matrix_row;
                            matrix_opr_2_c2 <= output_matrix_col;
                            
                            // 检查运算数合法性
                            if (selected_op_type == 2) begin
                                // 矩阵加法：检查维度是否相同
                                if (matrix_opr_1_r1 == matrix_opr_2_r2 && 
                                    matrix_opr_1_c1 == matrix_opr_2_c2) begin
                                    state <= S_COMPUTE;
                                end else begin
                                    state <= S_ERROR_TIMER;
                                    error_timer <= timer_config;
                                end
                            end else if (selected_op_type == 4) begin
                                // 矩阵乘法：检查列数是否等于行数
                                if (matrix_opr_1_c1 == matrix_opr_2_r2) begin
                                    state <= S_COMPUTE;
                                end else begin
                                    state <= S_ERROR_TIMER;
                                    error_timer <= timer_config;
                                end
                            end
                        end
                    endcase
                end
            end
            
            S_COMPUTE: begin
                case (selected_op_type)
                    1: begin
                        // 矩阵转置
                        trans_en <= 1;
                        compute_cnt <= 0;
                        sub_state <= 0;
                    end
                    2: begin
                        // 矩阵加法
                        add_en <= 1;
                        compute_cnt <= 0;
                        sub_state <= 0;
                    end
                    3: begin
                        // 标量乘法
                        scalar_en <= 1;
                        compute_cnt <= 0;
                        sub_state <= 0;
                    end
                    4: begin
                        // 矩阵乘法
                        mult_en <= 1;
                        compute_cnt <= 0;
                        sub_state <= 0;
                    end
                    5: begin
                        // 卷积运算
                        conv_en <= 1;
                        compute_cnt <= 0;
                        sub_state <= 0;
                    end
                endcase
                
                // 等待计算完成
                // 这里假设运算模块在完成计算后会拉低busy信号
                state <= S_DISPLAY_RES;
            end
            
            S_DISPLAY_RES: begin
                // 显示计算结果
                // 通过UART发送结果矩阵
                uart_buffer[0] <= "R";
                uart_buffer[1] <= "e";
                uart_buffer[2] <= "s";
                uart_buffer[3] <= "u";
                uart_buffer[4] <= "l";
                uart_buffer[5] <= "t";
                uart_buffer[6] <= ":";
                uart_buf_ptr <= 7;
                uart_send_flag <= 1;
                
                // 等待用户操作
                if (btn_confirm_pulse) begin
                    // 继续当前运算类型
                    case (selected_op_type)
                        1: state <= S_OPER_TRANS;
                        2: state <= S_OPER_ADD;
                        3: state <= S_OPER_SCALE;
                        4: state <= S_OPER_MULT;
                        5: state <= S_OPER_CONV;
                    endcase
                end
                if (btn_return_pulse) begin
                    state <= S_MAIN_MENU;
                end
            end
            
            S_ERROR_TIMER: begin
                // 错误倒计时处理
                led_error_status <= 1;
                
                if (sec_cnt == CLK_FREQ - 1) begin
                    sec_cnt <= 0;
                    if (error_timer > 0) begin
                        error_timer <= error_timer - 1;
                        seconds[7:0] <= error_timer - 1;
                        seconds[8] <= 1; // 显示使能
                    end else begin
                        // 倒计时结束，返回运算数选择
                        led_error_status <= 0;
                        seconds[8] <= 0;
                        if (selected_op_type == 3) begin
                            state <= S_SELECT_OP1;
                        end else begin
                            state <= S_SELECT_OP2;
                        end
                        mat_select_state <= 0;
                    end
                end else begin
                    sec_cnt <= sec_cnt + 1;
                end
                
                // 检查用户是否在倒计时内重新输入
                if (rx_done) begin
                    // 用户重新输入，重置倒计时
                    error_timer <= timer_config;
                end
            end
            
            default: state <= S_MAIN_MENU;
        endcase
    end
end

// ========== UART发送控制 ==========
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_start <= 0;
        tx_data <= 0;
        uart_byte_cnt <= 0;
    end else if (uart_send_flag && !tx_busy) begin
        if (uart_byte_cnt < uart_buf_ptr) begin
            tx_data <= uart_buffer[uart_byte_cnt];
            tx_start <= 1;
            uart_byte_cnt <= uart_byte_cnt + 1;
        end else begin
            uart_send_flag <= 0;
            uart_byte_cnt <= 0;
            tx_start <= 0;
        end
    end else begin
        tx_start <= 0;
    end
end

// ========== 运算模块使能信号分配 ==========
assign en = add_en | scalar_en | trans_en | mult_en | conv_en;

// ========== 矩阵存储模块写使能 ==========
assign wr_en = wr_en_reg;

// ========== 标量值分配 ==========
assign scalar_value = scalar_value_reg;

endmodule