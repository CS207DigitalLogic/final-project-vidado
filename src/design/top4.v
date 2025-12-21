module top4 #(
    parameter DATA_WIDTH          = 9,        // 数据位宽
    parameter MAX_SIZE            = 5,        // 单个矩阵??大规模（1~5??
    parameter MATRIX_NUM          = 8,        // 全局??大矩阵数??
    parameter MAX_MATRIX_PER_SIZE = 5,        // 每个规模??多存储矩阵数
    parameter DEBOUNCE_CNT_MAX    = 20'd100000, // 按键消抖计数阈???
    parameter CLK_FREQ            = 100_000_000,
    parameter BAUD_RATE           = 115200
)(
    input  wire clk,            // 系统时钟
    input  wire rst_n,          // 低有效复??
    input  wire uart_rx,        // UART接收数据
    output wire uart_tx,        // UART发???数??
    input  wire [2:0] sw_mode,  // 模式选择????
    input  wire btn_confirm,    // 确认按钮
    input  wire btn_return,     // 返回按钮
    input  wire btn_random,     // 随机按钮
    output reg led_error_status,// 错误状???指示灯
    output [7:0] seg_cs_pin,    // 8个数码管位???
    output [7:0] seg_data_0_pin,// 数码管段??0
    output [7:0] seg_data_1_pin,// 数码管段??1
    output reg [13:0] led
);

// ========================== 1. 内部信号定义 ==========================


// 数码管显示模块相关信??
reg [11:0] menuState;
reg [8:0] seconds;
reg [31:0] sec_cnt;

// 消抖后的按键信号
wire btn_confirm_pulse;
wire btn_return_pulse;
wire btn_random_pulse;

// Matrix Storage 相关信号
wire        wr_en;
reg [2:0]  wr_row;
reg [2:0]  wr_col;
reg [DATA_WIDTH-1:0] storage_input_data[0:24]; // ??终连接到Storage的数??

// 来自 RX Handler 的信??
wire rx_handler_wr_en;
wire [2:0] rx_handler_row;
wire [2:0] rx_handler_col;
wire [2:0] rx_handler_target_idx;
wire rx_handler_done;
wire [7:0] rx_handler_data [0:24];

wire [DATA_WIDTH-1:0] storage_output_data[0:24]; 
reg wr_en_reg;       // 手动控制的写使能 (用于随机生成)
reg write_flag;      // 写入完成标志
assign wr_en = wr_en_reg;


// 显示与查询相??
reg [2:0] req_scale_row;
reg [2:0] req_scale_col;
reg [2:0] req_index;
wire [2:0] output_matrix_row;
wire [2:0] output_matrix_col;
wire [4:0] num;           // 改为 5 位，匹配 Info 模块
wire [2:0] storage_cnt_raw; // 新增??个变量，专门用来?? Storage 修正后的 3 位输??

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
reg [DATA_WIDTH-1:0] scalar_value;    
reg  start_info_display_pulse;
reg start_search_display_pulse;

// 1. Matrix Displayer 的信??
    wire        disp_tx_start;
    wire [7:0]  disp_tx_data;
    wire        disp_busy;      // 对应 matrix_displayer ?? busy

    // 2. Info Display 的信??
    wire        info_tx_start;
    wire [7:0]  info_tx_data;
    wire        info_busy;      // 对应 matrix_info_display ?? busy

    // 3. Search Displayer 的信??
    wire        search_tx_start;
    wire [7:0]  search_tx_data;
    wire        search_busy;    // 对应 matrix_search_displayer ?? busy

    // 4. ??终汇?? UART TX 的信??
    reg         final_tx_start;
    reg  [7:0]  final_tx_data;
    wire        uart_real_busy; // 真正?? UART 忙信??
    
    // 5. 新增：Displayer 80 的信号
    wire        disp80_tx_start;
    wire [7:0]  disp80_tx_data;
    wire        disp80_busy; 
    reg         display_start80; // 状态机控制这个信号


// 定义各模块对 Storage 的查询信??
    // 1. Info 模块想查的地??
    wire [2:0] info_qry_row;
    wire [2:0] info_qry_col;

    // 2. Search 模块想查的地??
    wire [2:0] search_req_row;
    wire [2:0] search_req_col;
    wire [2:0] search_req_idx;


    // 3. ??终连?? Storage 的信?? (仲裁结果)
    reg [2:0] final_storage_row;
    reg [2:0] final_storage_col;
    reg [2:0] final_storage_idx;




wire [2:0] scale_matrix_cnt; // 对应存储模块?? scale_matrix_cnt 输出


// 扁平化的读取数据，用于传?? displayer
wire [25*DATA_WIDTH-1:0] storage_data_flat;
// ?? storage_output_data (array) 打包?? flat vector
// 假设 storage_output_data[0] 对应低位
genvar k;
generate
    for (k=0; k<25; k=k+1) begin : pack_data
        assign storage_data_flat[k*DATA_WIDTH +: DATA_WIDTH] = storage_output_data[k];
    end
endgenerate

wire [2:0] rand_r;
wire [2:0] rand_c;
wire [4:0] rand_cnt;

// ========================== 2. 解决多驱动问题的核心修改 ==========================

// ??终聚合的运算结果 (Reg类型，由Mux驱动)
reg [DATA_WIDTH-1:0] matrix_ans [0:24]; 
reg [2:0] matrix_ans_r_out;
reg [2:0] matrix_ans_c_out;
wire calc_busy; // 聚合的忙信号

// --- 各个子模块的独立输出 Wire ---

// A. 加法器输??
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

// E. 卷积输出 (80个数??)
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

// ========== 状???机相关 ==========
reg [9:0] state;

// UART发???缓冲区
reg [7:0] uart_buffer [0:63];
reg [5:0] uart_buf_ptr;
reg uart_send_flag;
reg [7:0] uart_byte_cnt;

// 运算模块使能控制
reg add_en, scalar_en, trans_en, mult_en, conv_en;

// ========================== 3. 模块实例?? ==========================
always @(*) begin
        // 优先级???辑：谁想发数据，就把谁连到 UART ??
        // 这里假设同一时间只有??个模块会工作（由你的状???机保证??
        
        if (disp_tx_start) begin
            // 既然 Displayer 想发送，就???它
            final_tx_start = disp_tx_start;
            final_tx_data  = disp_tx_data;
        end 
        else if (info_tx_start) begin
            // Info 模块想发??
            final_tx_start = info_tx_start;
            final_tx_data  = info_tx_data;
        end 
        else if (search_tx_start) begin
            // Search 模块想发??
            final_tx_start = search_tx_start;
            final_tx_data  = search_tx_data;
        end 
        else if (disp80_tx_start) begin
            final_tx_start = disp80_tx_start;
            final_tx_data  = disp80_tx_data;
        end
        else begin
            // 没人发???，保持安静
            final_tx_start = 1'b0;
            final_tx_data  = 8'd0;
        end
    end



uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx (
    .clk(clk), .rst_n(rst_n),
    .rx(uart_rx), .rx_data(rx_data), .rx_done(rx_done)
);

uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_tx (
    .clk(clk), .rst_n(rst_n),
    .tx_start (final_tx_start),  // 连到仲裁后的信号
        .tx_data  (final_tx_data),   // 连到仲裁后的信号
        .tx       (uart_tx),         // 输出到物理引??
        .tx_busy  (uart_real_busy)   // 输出忙信号给??有子模块
);

key_debounce u_keydebounce1 (
    .clk(clk), .rst_n(rst_n), .btn_trigger(btn_confirm), .btn_pulse(btn_confirm_pulse)
);
key_debounce u_keydebounce2 (
    .clk(clk), .rst_n(rst_n), .btn_trigger(btn_return), .btn_pulse(btn_return_pulse)
);
key_debounce u_keydebounce3 (
    .clk(clk), .rst_n(rst_n), .btn_trigger(btn_random), .btn_pulse(btn_random_pulse)
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

// Storage 地址仲裁逻辑
always @(*) begin
    //if (start_info_display_pulse) begin 
    
    if (start_info_display_pulse || info_busy) begin 
        // Info 模块只需要查数量 (cnt)，不??要读具体数据 (idx 设为0即可)
        final_storage_row = info_qry_row;
        final_storage_col = info_qry_col;
        final_storage_idx = 3'd0; 
    end
    else if (start_search_display_pulse || search_busy) begin 
        
        // Search 模块??要查全部
        final_storage_row = search_req_row;
        final_storage_col = search_req_col;
        final_storage_idx = search_req_idx;
    end
    else begin
        
        // 使用主状态机控制的寄存器 
        final_storage_row = req_scale_row;
        final_storage_col = req_scale_col;
        final_storage_idx = req_index;
    end
end

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
    .req_scale_row(final_storage_row),
    .req_scale_col(final_storage_col),
    .req_idx      (final_storage_idx),       
    .scale_matrix_cnt(scale_matrix_cnt),
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

assign num = {2'b00, scale_matrix_cnt};

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

// 随机数生成器
reg rand_en;
wire [2:0] rand_num;
random_num_generator #(
    .WIDTH(8) 
) rng_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .en         (rand_en),         
    .min_val    (3'd1),         
    .max_val    (rand_cnt),         
    .random_num (rand_num)
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
    // 输出连接到独立Wire (??80个输??)
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
    .busy(disp_busy), 
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
    .tx_start   (disp_tx_start), // 连到专用??
    .tx_data    (disp_tx_data),  // 连到专用??
    .tx_busy    (uart_real_busy) // 监听 UART 真正的忙信号
);

// Segment Display
segment_display u_segment_display(
    .clk(clk), .reset(rst_n),
    .menuState(menuState), .seconds(seconds),
    .tub_sel1(seg_cs_pin[0]), .tub_sel2(seg_cs_pin[1]), .tub_sel3(seg_cs_pin[2]), .tub_sel4(seg_cs_pin[3]),
    .tub_sel5(seg_cs_pin[4]), .tub_sel6(seg_cs_pin[5]), .tub_sel7(seg_cs_pin[6]), .tub_sel8(seg_cs_pin[7]),
    .tub_control1(seg_data_0_pin), .tub_control2(seg_data_1_pin)
);

//matrix_info_display
matrix_info_display #(
        .MAX_SIZE(MAX_SIZE)
    ) u_matrix_info (
        .clk(clk),
        .rst_n(rst_n),
        .start_req(start_info_display_pulse), // 生成??个开始脉冲（例如按下确认键且模式匹配时）
        .busy(info_busy),
        .uart_tx_busy   (uart_real_busy), // 监听 UART 真正的忙信号
        .uart_tx_start  (info_tx_start),  // 连到专用??
        .uart_tx_data   (info_tx_data),   // 连到专用??
        .qry_row(info_qry_row),
        .qry_col(info_qry_col),
        .qry_cnt(scale_matrix_cnt),       // 连接存储模块的计数输??
        .random_r       (rand_r),       // wire [2:0] rand_r
        .random_c       (rand_c),       // wire [2:0] rand_c
        .random_cnt     (rand_cnt)      // wire [4:0] rand_cnt
    );

// matrix_search_displayer
matrix_search_displayer #(
    .MAX_MATRICES(MAX_MATRIX_PER_SIZE), // 使用 top4 定义的参??
    .DATA_WIDTH(DATA_WIDTH)             // 传入 9
) u_search_displayer (
    .clk(clk),
    .rst_n(rst_n),
    .start(start_search_display_pulse),        // 连接你的触发信号
    .busy(search_busy),
    
    // 设置想要搜索的目标维度，这里示例为手动输入的 wr_row/col 
    // 或???你可以连接特定的寄存器，比?? req_scale_row
    .target_row(req_scale_row), // 使用用户当前设置的查询行
    .target_col(req_scale_col), // 使用用户当前设置的查询列
    
    // Storage 接口 (输出?? MUX)
    .req_scale_row  (search_req_row),    
    .req_scale_col  (search_req_col),    
    .req_idx        (search_req_idx),     
    
    // Storage 接口 (输入)
    .scale_matrix_cnt(num[2:0]), // num ?? 4bit，截取低3位或确保匹配
    .read_data(storage_data_flat),
    
    // UART 接口
    .tx_start   (search_tx_start), // 连到专用??
    .tx_data    (search_tx_data),  // 连到专用??
    .tx_busy    (uart_real_busy)  // 监听 UART 真正的忙信号
);

// Matrix Displayer 80 
matrix_displayer80 #(.DATA_WIDTH(DATA_WIDTH)) u_matrix_displayer80 (
    .clk(clk), .rst_n(rst_n),
    .start(display_start80), // 连到状态机控制的寄存器
    .busy(disp80_busy),      // 连到 wire
    
    // 连接 80 个卷积结果
    .d0(conv_res[0]),   .d1(conv_res[1]),   .d2(conv_res[2]),   .d3(conv_res[3]),   .d4(conv_res[4]),
    .d5(conv_res[5]),   .d6(conv_res[6]),   .d7(conv_res[7]),   .d8(conv_res[8]),   .d9(conv_res[9]),
    .d10(conv_res[10]), .d11(conv_res[11]), .d12(conv_res[12]), .d13(conv_res[13]), .d14(conv_res[14]),
    .d15(conv_res[15]), .d16(conv_res[16]), .d17(conv_res[17]), .d18(conv_res[18]), .d19(conv_res[19]),
    .d20(conv_res[20]), .d21(conv_res[21]), .d22(conv_res[22]), .d23(conv_res[23]), .d24(conv_res[24]),
    .d25(conv_res[25]), .d26(conv_res[26]), .d27(conv_res[27]), .d28(conv_res[28]), .d29(conv_res[29]),
    .d30(conv_res[30]), .d31(conv_res[31]), .d32(conv_res[32]), .d33(conv_res[33]), .d34(conv_res[34]),
    .d35(conv_res[35]), .d36(conv_res[36]), .d37(conv_res[37]), .d38(conv_res[38]), .d39(conv_res[39]),
    .d40(conv_res[40]), .d41(conv_res[41]), .d42(conv_res[42]), .d43(conv_res[43]), .d44(conv_res[44]),
    .d45(conv_res[45]), .d46(conv_res[46]), .d47(conv_res[47]), .d48(conv_res[48]), .d49(conv_res[49]),
    .d50(conv_res[50]), .d51(conv_res[51]), .d52(conv_res[52]), .d53(conv_res[53]), .d54(conv_res[54]),
    .d55(conv_res[55]), .d56(conv_res[56]), .d57(conv_res[57]), .d58(conv_res[58]), .d59(conv_res[59]),
    .d60(conv_res[60]), .d61(conv_res[61]), .d62(conv_res[62]), .d63(conv_res[63]), .d64(conv_res[64]),
    .d65(conv_res[65]), .d66(conv_res[66]), .d67(conv_res[67]), .d68(conv_res[68]), .d69(conv_res[69]),
    .d70(conv_res[70]), .d71(conv_res[71]), .d72(conv_res[72]), .d73(conv_res[73]), .d74(conv_res[74]),
    .d75(conv_res[75]), .d76(conv_res[76]), .d77(conv_res[77]), .d78(conv_res[78]), .d79(conv_res[79]),
    
    .tx_start (disp80_tx_start),
    .tx_data  (disp80_tx_data),
    .tx_busy  (uart_real_busy)
);

// 缓存
reg [7:0] rx_buf;
reg [4:0] input_cnt;    // 当前录入到第几个数据
reg [4:0] input_total;  // 总共需要录入多少个数据 (Row * Col)
// 状???机
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 10'd000;
        menuState <= 10'd010;
        wr_en_reg <= 0;
        write_flag <= 0;
        led_error_status <= 0;
        uart_send_flag <= 0;
        add_en <= 0; scalar_en <= 0; trans_en <= 0; mult_en <= 0; conv_en <= 0;
        seconds <= 0; sec_cnt <= 0;
        uart_buf_ptr <= 0; 
        uart_byte_cnt <= 0;
        rand_gen_en <= 0; rand_row <= 0; rand_col <= 0;
        min_val <= 0; max_val <= 9;
        display_start <= 0;
        display_start80 <= 0;
        // 测试用灯
        led <= 14'b00_0000_0000_0011;
        // 初始?? storage inputs
        for (i=0; i<25; i=i+1) storage_input_data[i] <= 0;
    end 
    else begin
        menuState <= state;
        case(state)
            10'd000: begin
                // 初始状???操作（留白??
                led <= 14'b00_0000_0000_1100;
                
                if (btn_confirm_pulse) begin
                    case(sw_mode)
                        3'b001: state <= 10'd100;  // 模式1输入并存??
                        3'b010: state <= 10'd200;  // 模式2随机生成
                        3'b011: state <= 10'd300;  // 模式3矩阵展示
                        3'b100: state <= 10'd400;  // 模式4运算
                        3'b110: state <= 10'd600;  // 模式6随机数调试
                        default: state <= 10'd000;
                    endcase
                end
            end
            
            10'd600: begin
                led <= rand_cnt;
                rand_en <= 1'b1;
                
                if (btn_confirm_pulse) begin
                    led <= rand_num;
                    state <= 10'd610;
                end
                if (btn_return_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd000;
                end
            end
            
            10'd610: begin
                
                if (btn_confirm_pulse) begin
                    state <= 10'd600;
                end
                if (btn_return_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd000;
                end
            end
            
            10'd100: begin
                // 只要串口收到数据
                if (rx_done) begin
                    // 过滤：只接受 1~5 的数字
                    if (rx_data >= "1" && rx_data <= "5") begin
                        wr_row <= rx_data - "0"; // 存入行
                        state <= 10'd110;        // 【自动跳转】去输列
                    end
                end
                
                // 保留返回键
                if (btn_return_pulse) state <= 10'd000; 
            end

            // --- 自动接收列数 (Col) ---
            10'd110: begin
                if (rx_done) begin
                    // 过滤：只接受 1~5 的数字
                    if (rx_data >= "1" && rx_data <= "5") begin
                        wr_col <= rx_data - "0"; // 存入列
                        state <= 10'd120;        // 【自动跳转】去计算
                    end
                end
                
                if (btn_return_pulse) state <= 10'd100;
            end

            // --- 计算矩阵总元素个数 & 初始化 ---
            10'd120: begin
                input_total <= wr_row * wr_col; // 计算 R * C
                input_cnt <= 0;                 // 计数器清零
                state <= 10'd130;               // 马上进入数据接收
            end

            // --- 步骤 3: 自动接收矩阵元素 (Data) ---
            10'd130: begin
                if (rx_done) begin
                    // 过滤：只接受 0~9 的数字 (忽略空格、换行、逗号)
                    if (rx_data >= "0" && rx_data <= "9") begin
                        
                        // 1. 存入当前数据
                        storage_input_data[input_cnt] <= rx_data - "0";
                        
                        // 2. 检查是否输完了
                        if (input_cnt + 1 >= input_total) begin
                            state <= 10'd140; // 【自动跳转】去写入
                        end else begin
                            input_cnt <= input_cnt + 1; // 指针移向下一个
                        end
                    end
                end
                
                if (btn_return_pulse) state <= 10'd100;
            end

            // --- 步骤 4: 触发写入 (Pulse wr_en) ---
            10'd140: begin
                wr_en_reg <= 1'b1; // 拉高写使能，存入 Storage
                state <= 10'd141;
            end

            // --- 步骤 5: 释放与完成 ---
            10'd141: begin
                wr_en_reg <= 1'b0; // 写入完成，拉低
                
                // 这里回到 100，准备接收下一个矩阵，或者等待切模式
                state <= 10'd150; 
            end

            10'd150: begin

                // 已完成，可以返回
                if (btn_return_pulse || btn_confirm_pulse) state <= 10'd000; 
            end
            
            10'd200: begin
                // uart传入r
                led <= 14'b01_0000_0000_0000;
                rx_buf <= rx_data;
                rand_row <= rx_data-"0";

                if (btn_confirm_pulse) begin
                    state <= 10'd210;
                end
                if (btn_return_pulse) begin
                    state <= 10'd000;
                end
            end
            
            10'd210: begin
                // uart传入c，随机生成矩阵并存储
                led <= 14'b01_0000_0000_0000;
                rx_buf <= rx_data;
                rand_col <= rx_data-"0";

                if (btn_confirm_pulse) begin
                    state <= 10'd220;
                end
            end

            10'd220: begin
                // uart传入c，随机生成矩??
                led <= 14'b01_0000_0000_0000;
                rand_gen_en <= 1'b1;
                if(rand_update_done) begin
                    rand_gen_en <= 1'b0;
                    state <= 10'd230;
                end
                
            end
           10'd230: begin
                // 1. 准备数据 (Data Setup)
                led <= 14'b01_0000_0000_0000;
             
                wr_row <= rand_row;
                wr_col <= rand_col; 
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
                
                // 【重要???确保在这里 wr_en 是低的，为产生上升沿做准??
                wr_en_reg <= 1'b0; 
                
                // 跳到专门??"触发状???"
                state <= 10'd233; 
            end
            10'd233: begin
                // 空状态，等待写入脉冲产生
                state <= 10'd234;
            end
            10'd234: begin
                // 空状态，等待写入脉冲产生
                state <= 10'd235;
            end
            // --- 新增状???：产生写脉?? (Write Pulse) ---
            10'd235: begin
                wr_en_reg <= 1'b1; // 拉高写使??
                state <= 10'd240;   // 立即跳转，只保持??个周期的高电??
            end
            // ---------------------------------------

            10'd240: begin
                // 【重要???立即拉低写使能！形?? 0->1->0 的脉??
                wr_en_reg <= 1'b0; 
                
                // 在这里可以放心地等待多久都行，因?? wr_en 已经?? 0 ??
                if (btn_confirm_pulse) begin
                    state <= 10'd000;
                end
            end
            10'd300: begin
                // 使用matrix_info_display模块展示矩阵
                rx_buf <= rx_data;
                req_scale_row <= 3'd0;
                req_scale_col <= 3'd0;
                
                start_info_display_pulse<=1'd1;

                state <= 10'd301;
              
            end

            10'd301: begin
                // 立刻拉低启动信号
                start_info_display_pulse <= 1'b0;
    
                state <= 10'd310;
            end

            10'd310: begin
                // uart传入r
                rx_buf <= rx_data;
            
                start_search_display_pulse <= 1'b0;
                display_row <= rx_data-"0";
                if (btn_confirm_pulse) begin
                    state <= 10'd320;
                end
                if (btn_return_pulse) begin
                    state <= 10'd000;
                end
            end
            
            10'd320: begin
                // uart传入c，展示矩??
                rx_buf <= rx_data;
                display_col <= rx_data-"0";
                if (btn_confirm_pulse) begin
                    // 1. 将用户输入的??/列传递给存储查询接口 (matrix_search_displayer 使用)
                    req_scale_row <= display_row;
                    // 注意：此?? display_col 已经是最新???（假设用户输入后才按确认）
                    req_scale_col <= display_col; 
                    
                    // 2. 拉高启动信号，触?? matrix_search_displayer
                    start_search_display_pulse <= 1'b1;
                    
                    // 3. 跳转到显示保持状??
                    // 如果停留?? 320，display_start 持续为高可能会导致模块不断复位或重发
                    state <= 10'd330; 
                end
                
                // 补充返回逻辑
                if (btn_return_pulse) begin
                    state <= 10'd000;
                end
            end
            10'd330: begin
                 start_search_display_pulse <= 1'b0;
                // 等待用户按下返回或确认键??出显??
                if (btn_return_pulse || btn_confirm_pulse) begin
                    state <= 10'd000;
                
                end
            end
            
             10'd400: begin
                // 模式4操作（留白）
                led <= 14'b00_0000_0000_0000;
                
                if (btn_confirm_pulse) begin
                    case(sw_mode)
                        3'b001: state <= 10'd410;  // 模式1矩阵转置
                        3'b010: state <= 10'd420;  // 模式2矩阵加法
                        3'b011: state <= 10'd430;  // 模式3矩阵标量
                        3'b100: state <= 10'd440;  // 模式4矩阵乘法
                        3'b101: state <= 10'd450;  // 模式5卷积运算
                    endcase
                end
            
                if (btn_return_pulse) begin
                    state <= 10'd000;
                end
            end
            
            10'd410: begin
                // 展示矩阵
                start_info_display_pulse<=1'd1;
                rand_en <= 1'b1;
                led <= rand_cnt;
                // uart传入r
                rx_buf <= rx_data;
                matrix_opr_1_r1 <= rx_buf-"0";
                
                if (btn_random_pulse) begin
                    req_index <= rand_num - 3'b1;
                    state <= 10'd510;
                end
                if (btn_confirm_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    state <= 10'd411;
                end
                if (btn_return_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    state <= 10'd400;
                end
            end
            
            10'd411: begin
                // uart传入c，展示矩阵
                rx_buf <= rx_data;
                matrix_opr_1_c1 <= rx_buf-"0";
                req_scale_col <= matrix_opr_1_c1;
                req_scale_row <= matrix_opr_1_r1;
                
                if (btn_confirm_pulse) begin
                    start_search_display_pulse <= 1'b1;
                    state <= 10'd412;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd412: begin
                // uart传入req_index，将指定矩阵传入转置模块
                rx_buf <= rx_data;
                req_index <= rx_buf-"0";

                if (btn_confirm_pulse) begin
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd413;
                end
                if (btn_return_pulse) begin
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd400;
                end
            end
            10'd413: begin
                // 准备展示选定的矩阵
                matrix_opr_1_r1 <= req_scale_row;
                matrix_opr_1_c1 <= req_scale_col;
                display_row <= req_scale_row;
                display_col <= req_scale_col;
                matrix_display_data[0]  <= storage_output_data[0];
                matrix_display_data[1]  <= storage_output_data[1];
                matrix_display_data[2]  <= storage_output_data[2];
                matrix_display_data[3]  <= storage_output_data[3];
                matrix_display_data[4]  <= storage_output_data[4];
                matrix_display_data[5]  <= storage_output_data[5];
                matrix_display_data[6]  <= storage_output_data[6];
                matrix_display_data[7]  <= storage_output_data[7];
                matrix_display_data[8]  <= storage_output_data[8];
                matrix_display_data[9]  <= storage_output_data[9];
                matrix_display_data[10] <= storage_output_data[10];
                matrix_display_data[11] <= storage_output_data[11];
                matrix_display_data[12] <= storage_output_data[12];
                matrix_display_data[13] <= storage_output_data[13];
                matrix_display_data[14] <= storage_output_data[14];
                matrix_display_data[15] <= storage_output_data[15];
                matrix_display_data[16] <= storage_output_data[16];
                matrix_display_data[17] <= storage_output_data[17];
                matrix_display_data[18] <= storage_output_data[18];
                matrix_display_data[19] <= storage_output_data[19];
                matrix_display_data[20] <= storage_output_data[20];
                matrix_display_data[21] <= storage_output_data[21];
                matrix_display_data[22] <= storage_output_data[22];
                matrix_display_data[23] <= storage_output_data[23];
                matrix_display_data[24] <= storage_output_data[24];
                if (btn_confirm_pulse) begin
                    display_start <= 1'b1;
                    state <= 10'd414; 
                end
            end
            10'd414: begin
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
                if (btn_confirm_pulse) begin
                    state <= 10'd415;
                end
            end
            10'd415: begin
                // 先拉高使能，不要在这个周期立刻读结果
                trans_en <= 1;
                // 跳转到等待计算结果的状???
                state <= 10'd416; 
            end

            10'd416: begin
                // 将trans_en变为1，开始转置，将转置结果接到display???
                display_start <= 0;
                display_row <= trans_r_out;
                display_col <= trans_c_out;
                matrix_display_data[0] <=trans_res[0];
                matrix_display_data[1] <=trans_res[1];
                matrix_display_data[2] <=trans_res[2];
                matrix_display_data[3] <=trans_res[3];
                matrix_display_data[4] <=trans_res[4];
                matrix_display_data[5] <=trans_res[5];
                matrix_display_data[6] <=trans_res[6];
                matrix_display_data[7] <=trans_res[7];
                matrix_display_data[8] <=trans_res[8];
                matrix_display_data[9] <=trans_res[9];
                matrix_display_data[10] <=trans_res[10];
                matrix_display_data[11] <=trans_res[11];
                matrix_display_data[12] <=trans_res[12];
                matrix_display_data[13] <=trans_res[13];
                matrix_display_data[14] <=trans_res[14];
                matrix_display_data[15] <=trans_res[15];
                matrix_display_data[16] <=trans_res[16];
                matrix_display_data[17] <=trans_res[17];
                matrix_display_data[18] <=trans_res[18];
                matrix_display_data[19] <=trans_res[19];
                matrix_display_data[20] <=trans_res[20];
                matrix_display_data[21] <=trans_res[21];
                matrix_display_data[22] <=trans_res[22];
                matrix_display_data[23] <=trans_res[23];
                matrix_display_data[24] <=trans_res[24];
                if (btn_confirm_pulse) begin
                    state <= 10'd417;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd417: begin
                // 将display_start变为1，开始传???
                display_start <= 1;
                
                if (btn_confirm_pulse) begin
                    // 将display_start和trans_en变为0
                    display_start <= 0;
                    trans_en <= 0;
                    state <= 10'd400;
                end
            end
            
            10'd420: begin
                // 展示矩阵
                start_info_display_pulse<=1'd1;
                // uart传入r
                rx_buf <= rx_data;
                matrix_opr_1_r1 <= rx_buf-"0";
                
                if (btn_random_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    rand_en <= 1'b1;
                    state <= 10'd520;
                end
                if (btn_confirm_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    state <= 10'd421;
                end
                if (btn_return_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    state <= 10'd400;
                end
            end
            
            10'd421: begin
                // uart传入c，展示矩阵
                rx_buf <= rx_data;
                matrix_opr_1_c1 <= rx_buf-"0";
                req_scale_col <= matrix_opr_1_c1;
                req_scale_row <= matrix_opr_1_r1;
                
                if (btn_confirm_pulse) begin
                    start_search_display_pulse <= 1'b1;
                    state <= 10'd422;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd422: begin
                // uart传入req_index
                rx_buf <= rx_data;
                req_index <= rx_buf-"0";
                
                if (btn_confirm_pulse) begin
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd423;
                end
                if (btn_return_pulse) begin
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd400;
                end
            end
            10'd423:begin
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
                state <=10'd424;
            end
            10'd424: begin
                // uart传入r
                rx_buf <= rx_data;
                matrix_opr_2_r2 <= rx_buf-"0";
                
                if (btn_confirm_pulse) begin
                    state <= 10'd425;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd425: begin
                // uart传入c
                rx_buf <= rx_data;
                matrix_opr_2_c2 <= rx_buf-"0";
                if (btn_confirm_pulse) begin
                    if ((matrix_opr_1_r1 == matrix_opr_2_r2) && (matrix_opr_1_c1 == matrix_opr_2_c2)) begin
                        state <= 10'd426;
                    end else begin
                        // 回到输入第二个矩阵的r，并触发倒计???
                        state <= 10'd424;
                    end
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd426: begin
                // uart传入req_index，将指定矩阵传入加法模块2端口
                rx_buf <= rx_data;
                req_index <= rx_buf-"0";
                req_scale_col<= matrix_opr_2_c2;
                req_scale_row<= matrix_opr_2_r2;
               
                if (btn_confirm_pulse) begin
                    state <= 10'd427;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            10'd427: begin
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
                state <=10'd428;
            end
            10'd428: begin
                // 将add_en变为1，开始加法，将加法结果接到display
                add_en <= 1;
                display_row <= add_r_out;
                display_col <= add_c_out;
                matrix_display_data[0] <=add_res[0];
                matrix_display_data[1] <=add_res[1];
                matrix_display_data[2] <=add_res[2];
                matrix_display_data[3] <=add_res[3];
                matrix_display_data[4] <=add_res[4];
                matrix_display_data[5] <=add_res[5];
                matrix_display_data[6] <=add_res[6];
                matrix_display_data[7] <=add_res[7];
                matrix_display_data[8] <=add_res[8];
                matrix_display_data[9] <=add_res[9];
                matrix_display_data[10] <=add_res[10];
                matrix_display_data[11] <=add_res[11];
                matrix_display_data[12] <=add_res[12];
                matrix_display_data[13] <=add_res[13];
                matrix_display_data[14] <=add_res[14];
                matrix_display_data[15] <=add_res[15];
                matrix_display_data[16] <=add_res[16];
                matrix_display_data[17] <=add_res[17];
                matrix_display_data[18] <=add_res[18];
                matrix_display_data[19] <=add_res[19];
                matrix_display_data[20] <=add_res[20];
                matrix_display_data[21] <=add_res[21];
                matrix_display_data[22] <=add_res[22];
                matrix_display_data[23] <=add_res[23];
                matrix_display_data[24] <=add_res[24];
                if (btn_confirm_pulse) begin
                    state <= 10'd429;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd429: begin
                // 将display_start变为1，开始传输
                display_start <= 1;
                
                if (btn_confirm_pulse) begin
                    // 将display_start和add_en变为0
                    display_start <= 0;
                    add_en <= 0;
                    state <= 10'd400;
                end
            end
            
            10'd430: begin
                // 展示矩阵
                start_info_display_pulse<=1'd1;
                // uart传入r
                rx_buf <= rx_data;
                matrix_opr_1_r1 <= rx_buf-"0";
                
                if (btn_random_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    rand_en <= 1'b1;
                    state <= 10'd530;
                end
                if (btn_confirm_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    state <= 10'd431;
                end
                if (btn_return_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    state <= 10'd400;
                end
            end
            
            10'd431: begin
                // uart传入c，展示矩???
                rx_buf <= rx_data;
                matrix_opr_1_c1 <= rx_buf-"0";
                req_scale_col <= matrix_opr_1_c1;
                req_scale_row <= matrix_opr_1_r1;

                if (btn_confirm_pulse) begin
                    start_search_display_pulse <= 1'b1;
                    state <= 10'd432;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd432: begin
                // uart传入req_index，将指定矩阵传入乘法模块
                rx_buf <= rx_data;
                req_index <= rx_buf-"0";

                if (btn_confirm_pulse) begin
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd433;
                end
                if (btn_return_pulse) begin
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd400;
                end
            end
            10'd433: begin
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
                state <=10'd434;
            end
            10'd434: begin
                // uart传入scalar，将标量传入乘法模块
                rx_buf <= rx_data;
                scalar_value <= rx_buf-"0";
                
                if (btn_confirm_pulse) begin
                    state <= 10'd435;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd435: begin
                // 将scalar_en变为1，开始转置，将乘法结果接到display???
                scalar_en <= 1;
                display_row <= scalar_r_out;
                display_col <= scalar_c_out;
                matrix_display_data[0] <= scalar_res[0];
                matrix_display_data[1] <= scalar_res[1];
                matrix_display_data[2] <= scalar_res[2];
                matrix_display_data[3] <= scalar_res[3];
                matrix_display_data[4] <= scalar_res[4];
                matrix_display_data[5] <= scalar_res[5];
                matrix_display_data[6] <= scalar_res[6];
                matrix_display_data[7] <= scalar_res[7];
                matrix_display_data[8] <= scalar_res[8];
                matrix_display_data[9] <= scalar_res[9];
                matrix_display_data[10] <= scalar_res[10];
                matrix_display_data[11] <= scalar_res[11];
                matrix_display_data[12] <= scalar_res[12];
                matrix_display_data[13] <= scalar_res[13];
                matrix_display_data[14] <= scalar_res[14];
                matrix_display_data[15] <= scalar_res[15];
                matrix_display_data[16] <= scalar_res[16];
                matrix_display_data[17] <= scalar_res[17];
                matrix_display_data[18] <= scalar_res[18];
                matrix_display_data[19] <= scalar_res[19];
                matrix_display_data[20] <= scalar_res[20];
                matrix_display_data[21] <= scalar_res[21];
                matrix_display_data[22] <= scalar_res[22];
                matrix_display_data[23] <= scalar_res[23];
                matrix_display_data[24] <= scalar_res[24];
                
                if (btn_confirm_pulse) begin
                    state <= 10'd436;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd436: begin
                // 将display_start变为1，开始传???
                display_start <= 1;
                
                if (btn_confirm_pulse) begin
                    // 将display_start和scalar_en变为0
                    display_start <= 0;
                    scalar_en <= 0;
                    state <= 10'd400;
                end
            end
            
            10'd440: begin
                // 展示矩阵
                start_info_display_pulse<=1'd1;
                // uart传入r
                rx_buf <= rx_data;
                matrix_opr_1_r1 <= rx_buf-"0";
                
                if (btn_random_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    rand_en <= 1'b1;
                    state <= 10'd540;
                end
                if (btn_confirm_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    state <= 10'd441;
                end
                if (btn_return_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    state <= 10'd400;
                end
            end
            
            10'd441: begin
                // uart传入c，展示矩阵
                rx_buf <= rx_data;
                matrix_opr_1_c1 <= rx_buf-"0";
                req_scale_col <= matrix_opr_1_c1;
                req_scale_row <= matrix_opr_1_r1;
                
                if (btn_confirm_pulse) begin
                    start_search_display_pulse <= 1'b1;
                    state <= 10'd442;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd442: begin
                // uart传入req_index，将指定矩阵传入矩阵乘法模块1端口
                rx_buf <= rx_data;
                req_index <= rx_buf-"0";
                
                if (btn_confirm_pulse) begin
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd443;
                end
                if (btn_return_pulse) begin
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd400;
                end
            end
            10'd443: begin
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
                state <=10'd444;
            end
            10'd444: begin
                // uart传入r
                rx_buf <= rx_data;
                matrix_opr_2_r2 <= rx_buf-"0";

                if (btn_confirm_pulse) begin
                    state <= 10'd445;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd445: begin
                // uart传入c
                rx_buf <= rx_data;
                matrix_opr_2_c2 <= rx_buf-"0";
                req_scale_row <= matrix_opr_2_r2;
                req_scale_col <= matrix_opr_2_c2;
                
                if (btn_confirm_pulse) begin
                    if ((matrix_opr_1_r1 == matrix_opr_2_r2) && (matrix_opr_1_c1 == matrix_opr_2_c2)) begin
                        state <= 10'd446;
                    end else begin
                        // 回到输入第二个矩阵的r，并触发倒计???
                        state <= 10'd443;
                    end
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd446: begin
                // uart传入req_index，将指定矩阵传入矩阵乘法模块2端口
                rx_buf <= rx_data;
                req_index <= rx_buf-"0";

                if (btn_confirm_pulse) begin
                    state <= 10'd447;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            10'd447: begin
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
                state <=10'd448;
            end
            10'd448: begin
                // 将mult_en变为1，开始加法，将乘法结果接到display???
                mult_en <= 1;
                display_row <= mult_r_out;
                display_col <= mult_c_out;
                matrix_display_data[0] <= mult_res[0];
                matrix_display_data[1] <= mult_res[1];
                matrix_display_data[2] <= mult_res[2];
                matrix_display_data[3] <= mult_res[3];
                matrix_display_data[4] <= mult_res[4];
                matrix_display_data[5] <= mult_res[5];
                matrix_display_data[6] <= mult_res[6];
                matrix_display_data[7] <= mult_res[7];
                matrix_display_data[8] <= mult_res[8];
                matrix_display_data[9] <= mult_res[9];
                matrix_display_data[10] <= mult_res[10];
                matrix_display_data[11] <= mult_res[11];
                matrix_display_data[12] <= mult_res[12];
                matrix_display_data[13] <= mult_res[13];
                matrix_display_data[14] <= mult_res[14];
                matrix_display_data[15] <= mult_res[15];
                matrix_display_data[16] <= mult_res[16];
                matrix_display_data[17] <= mult_res[17];
                matrix_display_data[18] <= mult_res[18];
                matrix_display_data[19] <= mult_res[19];
                matrix_display_data[20] <= mult_res[20];
                matrix_display_data[21] <= mult_res[21];
                matrix_display_data[22] <= mult_res[22];
                matrix_display_data[23] <= mult_res[23];
                matrix_display_data[24] <= mult_res[24];
                
                if (btn_confirm_pulse) begin
                    state <= 10'd449;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd449: begin
                // 将display_start变为1，开始传???
                display_start <= 1;
                
                if (btn_confirm_pulse) begin
                    // 将display_start和mult_en变为0
                    display_start <= 0;
                    mult_en <= 0;
                    state <= 10'd400;
                end
            end
            
            10'd450: begin
                // 展示矩阵
                start_info_display_pulse <= 1'd1;
                // uart传入req_index，将指定矩阵传入矩阵乘法模块2端口
                rx_buf <= rx_data;
                req_index <= rx_buf-"0";
                req_scale_col <= 2'd3;
                req_scale_row <= 2'd3;
                start_search_display_pulse <= 1'b1;
                
                if (btn_random_pulse) begin
                    start_info_display_pulse <= 1'd0;
                    start_search_display_pulse <= 1'b0;
                    rand_en <= 1'b1;
                    state <= 10'd550;
                end
                if (btn_confirm_pulse) begin
                    start_info_display_pulse <= 1'd0;
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd451;
                end
                if (btn_return_pulse) begin
                    start_info_display_pulse <= 1'd0;
                    start_search_display_pulse <= 1'b0;
                    state <= 10'd400;
                end
            end
            
            10'd451: begin
                // 准备展示选定的矩阵
                matrix_opr_1_r1 <= req_scale_row;
                matrix_opr_1_c1 <= req_scale_col;
                display_row <= req_scale_row;
                display_col <= req_scale_col;
                matrix_display_data[0]  <= storage_output_data[0];
                matrix_display_data[1]  <= storage_output_data[1];
                matrix_display_data[2]  <= storage_output_data[2];
                matrix_display_data[3]  <= storage_output_data[3];
                matrix_display_data[4]  <= storage_output_data[4];
                matrix_display_data[5]  <= storage_output_data[5];
                matrix_display_data[6]  <= storage_output_data[6];
                matrix_display_data[7]  <= storage_output_data[7];
                matrix_display_data[8]  <= storage_output_data[8];
                matrix_display_data[9]  <= storage_output_data[9];
                matrix_display_data[10] <= storage_output_data[10];
                matrix_display_data[11] <= storage_output_data[11];
                matrix_display_data[12] <= storage_output_data[12];
                matrix_display_data[13] <= storage_output_data[13];
                matrix_display_data[14] <= storage_output_data[14];
                matrix_display_data[15] <= storage_output_data[15];
                matrix_display_data[16] <= storage_output_data[16];
                matrix_display_data[17] <= storage_output_data[17];
                matrix_display_data[18] <= storage_output_data[18];
                matrix_display_data[19] <= storage_output_data[19];
                matrix_display_data[20] <= storage_output_data[20];
                matrix_display_data[21] <= storage_output_data[21];
                matrix_display_data[22] <= storage_output_data[22];
                matrix_display_data[23] <= storage_output_data[23];
                matrix_display_data[24] <= storage_output_data[24];
                if (btn_confirm_pulse) begin
                    display_start <= 1'b1;
                    state <= 10'd452; 
                end
            end
            
            10'd452: begin
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
                if (btn_confirm_pulse) begin
                    display_start <= 1'b0;
                    state <= 10'd453;
                end
            end
            
            10'd453: begin
                // 将conv_en变为1，开始卷积，将卷积结果接到displayer80???
                conv_en <= 1;
                
                if (btn_confirm_pulse) begin
                    state <= 10'd454;
                end
                if (btn_return_pulse) begin
                    state <= 10'd400;
                end
            end
            
            10'd454: begin
                // 将display80_start变为1，开始传???
                display_start80 <= 1;
                
                if (btn_confirm_pulse) begin
                    // 将display_start和conv_en变为0
                    display_start80 <= 0;
                    conv_en <= 0;
                    state <= 10'd400;
                end
            end
            
            10'd510: begin
                // 根据info传出的随机矩阵规模和数量(生成随机序号)选定矩阵，直接跳到413展示矩阵
                req_scale_row <= rand_row;
                req_scale_col <= rand_col;

                led <= req_index;
                
                if (btn_confirm_pulse) begin
                    start_info_display_pulse <= 1'b0;
                    rand_en <= 1'b0;
                    state <= 10'd413;
                end
                if (btn_return_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd410;
                end
            end
            
            10'd520: begin
                
                if (btn_confirm_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd521;
                end
                if (btn_return_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd420;
                end
            end
            
            10'd530: begin
                
                if (btn_confirm_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd531;
                end
                if (btn_return_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd430;
                end
            end
            
            10'd540: begin
                
                if (btn_confirm_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd541;
                end
                if (btn_return_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd440;
                end
            end
            
            10'd550: begin
                
                if (btn_confirm_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd551;
                end
                if (btn_return_pulse) begin
                    rand_en <= 1'b0;
                    state <= 10'd450;
                end
            end
        endcase
    end
end

endmodule