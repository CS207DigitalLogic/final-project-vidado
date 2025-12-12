module test_2 #(
    // 核心参数（与子模块对齐）
    parameter DATA_WIDTH          = 8,        // 数据位宽
    parameter MAX_SIZE            = 5,        // 单个矩阵最大规模（1~5）
    parameter MATRIX_NUM          = 8,        // 全局最大矩阵数量
    parameter MAX_MATRIX_PER_SIZE = 4,        // 每个规模最多存储矩阵数
    parameter DEBOUNCE_CNT_MAX    = 20'd100000, // 按键消抖计数阈值（100ms@1MHz时钟）
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire                     clk,            // 系统时钟
    input  wire                     rst_n,          // 低有效复位
    input  wire       uart_rx,
    output wire       uart_tx,
    // 输入：3*2位拨码开关（编码矩阵行/列）
    input  wire [2:0]               sw_row,         // 行选择拨码（3位，对应1~5）
    input  wire [2:0]               sw_col,         // 列选择拨码（3位，对应1~5）
    // 输入：触发按钮（低有效/高有效均可，消抖处理）
    input  wire                     btn_trigger,    // 按下触发矩阵生成+存储
    input  wire                     btn_display_all,// 新增：按下输出所有存储矩阵
    // 可选输出：存储模块状态（用于调试/显示）
    output wire [2:0]               dbg_matrix_row,     // 调试用矩阵行数
    output wire [2:0]               dbg_matrix_col,    // 调试用矩阵列数
    output wire [3:0]               num              // 调试用当前规模矩阵数量
    
);
// UART 
    wire [7:0] rx_data;
    wire       rx_done;
    // UART TX
    wire [7:0] tx_data;
    wire       tx_start;
    wire       tx_busy;

    // Matrix Storage Interconnects
    wire        wr_en;
    wire [2:0]  wr_idx;
    wire [2:0]  wr_row;
    wire [2:0]  wr_col;
    wire [7:0]  w_data[24:0]; // 写数据连线

    // Control
    wire        save_done; // RX Handler 完成信号

    // 新增：显示所有矩阵相关信号
    wire                            btn_display_all_pulse; // 显示按钮消抖脉冲
    reg                             display_all_flag;      // 显示所有标志
    reg [2:0]                       display_index;         // 显示索引
    wire                             display_busy;          // 显示忙信号
    wire                            display_next;          // 显示下一个矩阵
    reg [3:0]                       display_total;         // 要显示的总矩阵数
    reg [3:0]                       display_count;         // 已显示计数

    // 新增：按键消抖模块（用于btn_display_all）
    key_debounce u_keydebounce_display (
        .clk(clk),
        .rst_n(rst_n),
        .btn_trigger(btn_display_all),
        .btn_pulse(btn_display_all_pulse)
    );

    // 新增：显示完成信号
    assign display_next = (display_all_flag && !display_busy && (display_count < display_total));

    uart_rx #(
        .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)
    ) u_rx (
        .clk(clk), .rst_n(rst_n),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
    
    // ============================================
    // 4. Matrix Displayer (显示模块)
    // ============================================
    matrix_displayer u_displayer (
        .clk(clk), .rst_n(rst_n),
        .start(rand_update_done || display_next), // 修改：存储完成或显示下一个时触发
        .busy(display_busy),           // 连接到显示忙信号
        
        // 维度信息：直接使用刚才写入的维度
        .matrix_row(sw_row),
        .matrix_col(sw_col),
        
        // 数据输入：来自 Storage 的读出数据
        .d0(r_data[0]), .d1(r_data[1]), .d2(r_data[2]), .d3(r_data[3]), .d4(r_data[4]),
        .d5(r_data[5]), .d6(r_data[6]), .d7(r_data[7]), .d8(r_data[8]), .d9(r_data[9]),
        .d10(r_data[10]),.d11(r_data[11]),.d12(r_data[12]),.d13(r_data[13]),.d14(r_data[14]),
        .d15(r_data[15]),.d16(r_data[16]),.d17(r_data[17]),.d18(r_data[18]),.d19(r_data[19]),
        .d20(r_data[20]),.d21(r_data[21]),.d22(r_data[22]),.d23(r_data[23]),.d24(r_data[24]),
        
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy)
    );

    // ============================================
    // 5. UART TX 模块
    // ============================================
    uart_tx #(
        .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)
    ) u_tx (
        .clk(clk), .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(uart_tx),
        .tx_busy(tx_busy)
    );
// UART RX END

// ---------------------------
// 内部信号声明
// ---------------------------
// 按键消抖输出
wire                            btn_pulse;       // 消抖后的按键单脉冲
// 随机矩阵生成器接口
wire [DATA_WIDTH-1:0]           rand_data[0:24]; // 随机矩阵数据总线
wire                            rand_update_done;// 随机矩阵生成完成
// 矩阵存储模块接口
reg                             wr_en_reg;       // 存储模块写使能
// 状态控制
reg                             write_flag;      // 写入完成标志（防重复触发）
wire [DATA_WIDTH-1:0]           r_data[0:24];

// ---------------------------
// 1. 按键消抖模块（核心：消除物理按键抖动）
// ---------------------------
key_debounce u_keydebounce (
    .clk(clk),
    .rst_n(rst_n),
    .btn_trigger(btn_trigger),
    .btn_pulse(btn_pulse)
);

// ---------------------------
// 2. 随机矩阵生成器实例化
// ---------------------------
random_matrix_generator #(
    .WIDTH(DATA_WIDTH),
    .MAX_DIM(MAX_SIZE)
) u_rand_matrix (
    .clk(clk),
    .rst_n(rst_n),
    .row(sw_row),                  // 拨码开关行输入
    .col(sw_col),                  // 拨码开关列输入
    .min_val(8'd0),  // 随机数最小值：0
    .max_val(8'd9),  // 随机数最大值：255（8位）
    .update_en(btn_pulse),         // 消抖按键触发矩阵更新
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

// ---------------------------
// 3. 矩阵存储模块实例化
// ---------------------------
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
    .write_row(sw_row),                    // 写入矩阵行数（拨码输入）
    .write_col(sw_col),                    // 写入矩阵列数（拨码输入）
    .data_in_0(rand_data[0]),
    .data_in_1(rand_data[1]),
    .data_in_2(rand_data[2]),
    .data_in_3(rand_data[3]),
    .data_in_4(rand_data[4]),
    .data_in_5(rand_data[5]),
    .data_in_6(rand_data[6]),
    .data_in_7(rand_data[7]),
    .data_in_8(rand_data[8]),
    .data_in_9(rand_data[9]),
    .data_in_10(rand_data[10]),
    .data_in_11(rand_data[11]),
    .data_in_12(rand_data[12]),
    .data_in_13(rand_data[13]),
    .data_in_14(rand_data[14]),
    .data_in_15(rand_data[15]),
    .data_in_16(rand_data[16]),
    .data_in_17(rand_data[17]),
    .data_in_18(rand_data[18]),
    .data_in_19(rand_data[19]),
    .data_in_20(rand_data[20]),
    .data_in_21(rand_data[21]),
    .data_in_22(rand_data[22]),
    .data_in_23(rand_data[23]),
    .data_in_24(rand_data[24]),
    // 查询接口（连接到显示控制逻辑）
    .req_scale_row(sw_row),
    .req_scale_col(sw_col),
    .req_idx(display_index),           // 修改：连接到显示索引
    // 输出接口（调试用）
    .scale_matrix_cnt(num),
    .matrix_data_0(r_data[0]),
    .matrix_data_1(r_data[1]),
    .matrix_data_2(r_data[2]),
    .matrix_data_3(r_data[3]),
    .matrix_data_4(r_data[4]),
    .matrix_data_5(r_data[5]),
    .matrix_data_6(r_data[6]),
    .matrix_data_7(r_data[7]),
    .matrix_data_8(r_data[8]),
    .matrix_data_9(r_data[9]),
    .matrix_data_10(r_data[10]),
    .matrix_data_11(r_data[11]),
    .matrix_data_12(r_data[12]),
    .matrix_data_13(r_data[13]),
    .matrix_data_14(r_data[14]),
    .matrix_data_15(r_data[15]),
    .matrix_data_16(r_data[16]),
    .matrix_data_17(r_data[17]),
    .matrix_data_18(r_data[18]),
    .matrix_data_19(r_data[19]),
    .matrix_data_20(r_data[20]),
    .matrix_data_21(r_data[21]),
    .matrix_data_22(r_data[22]),
    .matrix_data_23(r_data[23]),
    .matrix_data_24(r_data[24]),
    .matrix_row(dbg_matrix_row),
    .matrix_col(dbg_matrix_col),
    .matrix_valid()
);

// ---------------------------
// 4. 核心控制逻辑：生成完成后触发存储写入
// ---------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_en_reg     <= 1'b0;
        write_flag    <= 1'b0;
    end else begin
        // 初始状态：写使能清零
        wr_en_reg <= 1'b0;

        // 检测到随机矩阵生成完成，且未触发过写入
        if (rand_update_done && !write_flag) begin
            wr_en_reg  <= 1'b1;                // 触发存储模块写使能
            write_flag <= 1'b1;                // 标记已写入，防重复触发
        end

        // 按键触发新请求时，清零写入标记
        if (btn_pulse) begin
            write_flag <= 1'b0;
        end
    end
end

// ---------------------------
// 5. 新增：显示所有存储矩阵的控制逻辑
// ---------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        display_all_flag <= 1'b0;
        display_index <= 3'b0;
        display_total <= 4'b0;
        display_count <= 4'b0;
    end else begin
        // 检测到显示所有按钮按下
        if (btn_display_all_pulse && !display_all_flag) begin
            display_all_flag <= 1'b1;
            display_index <= 3'b0;          // 从第一个矩阵开始
            display_total <= num;           // 获取当前规模的总矩阵数
            display_count <= 4'b0;          // 已显示计数清零
        end
        
        // 显示下一个矩阵
        if (display_next) begin
            // 更新索引和计数
            display_index <= display_index + 1'b1;
            display_count <= display_count + 1'b1;
        // 如果在显示过程中有新的矩阵写入，更新总数
        if (display_all_flag && (display_total != num)) begin
            display_total <= num;
        end
    end
end
end

endmodule