`timescale 1ns / 1ps

module display_test_top(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] led
);

    parameter CLK_FREQ  = 100_000_000;
    parameter BAUD_RATE = 115200;

    // ============================================
    // 信号定义
    // ============================================
    
    // UART RX
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

    wire [7:0]  r_data[24:0]; // 读数据连线
    
    // Control
    wire        save_done; // RX Handler 完成信号

    assign led = rx_data; // LED 闪烁指示

    // ============================================
    // 1. UART RX 模块
    // ============================================
    uart_rx #(
        .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)
    ) u_rx (
        .clk(clk), .rst_n(rst_n),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // ============================================
    // 2. Matrix RX Handler (接收并解析)
    // ============================================
    matrix_rx_handler u_handler (
        .clk(clk), .rst_n(rst_n),
        .rx_data(rx_data), .rx_done(rx_done),
        
        // 输出到 Storage 的写接口
        .storage_wr_en(wr_en),
        .storage_target_idx(wr_idx),
        .storage_row(wr_row),
        .storage_col(wr_col),
        
        .data_flat_0(w_data[0]),   .data_flat_1(w_data[1]),   .data_flat_2(w_data[2]),
        .data_flat_3(w_data[3]),   .data_flat_4(w_data[4]),   .data_flat_5(w_data[5]),
        .data_flat_6(w_data[6]),   .data_flat_7(w_data[7]),   .data_flat_8(w_data[8]),
        .data_flat_9(w_data[9]),   .data_flat_10(w_data[10]), .data_flat_11(w_data[11]),
        .data_flat_12(w_data[12]), .data_flat_13(w_data[13]), .data_flat_14(w_data[14]),
        .data_flat_15(w_data[15]), .data_flat_16(w_data[16]), .data_flat_17(w_data[17]),
        .data_flat_18(w_data[18]), .data_flat_19(w_data[19]), .data_flat_20(w_data[20]),
        .data_flat_21(w_data[21]), .data_flat_22(w_data[22]), .data_flat_23(w_data[23]),
        .data_flat_24(w_data[24]),

        .save_done_pulse(save_done)
    );

    // ============================================
    // 3. Multi Matrix Storage (你的存储模块)
    // ============================================
    // 注意：根据你的文件，Multi Matrix Storage 会根据 target_idx 写入
    // 读出时，我们需要告诉它读哪一个。这里为了测试，我们默认读第0个 (idx=0)
    // 你的 storage 模块输出是 matrix_data_X 还是直接 data_out 组？
    // 假设你的 Storage 模块实例化如下 (需匹配你上传的文件端口):
    
    multi_matrix_storage #(
        .DATA_WIDTH(8)
    ) u_storage (
        .clk(clk),
        .rst_n(rst_n),
        
        // 写入端口
        .wr_en(wr_en),
        .target_idx(wr_idx), // 来自 RX Handler
        .write_row(wr_row),
        .write_col(wr_col),
        .data_in_0(w_data[0]), .data_in_1(w_data[1]), .data_in_2(w_data[2]), .data_in_3(w_data[3]), .data_in_4(w_data[4]),
        .data_in_5(w_data[5]), .data_in_6(w_data[6]), .data_in_7(w_data[7]), .data_in_8(w_data[8]), .data_in_9(w_data[9]),
        .data_in_10(w_data[10]),.data_in_11(w_data[11]),.data_in_12(w_data[12]),.data_in_13(w_data[13]),.data_in_14(w_data[14]),
        .data_in_15(w_data[15]),.data_in_16(w_data[16]),.data_in_17(w_data[17]),.data_in_18(w_data[18]),.data_in_19(w_data[19]),
        .data_in_20(w_data[20]),.data_in_21(w_data[21]),.data_in_22(w_data[22]),.data_in_23(w_data[23]),.data_in_24(w_data[24]),
        
        // 读取端口 (根据你的模块定义，这里可能需要 req_idx)
        // 假设我们总是读取刚写入的 index (这里 RX Handler 默认写的是 0)
        .req_idx(3'd0), 
        // 下面是输出数据，连接到 Displayer
        .matrix_data_0(r_data[0]), .matrix_data_1(r_data[1]), .matrix_data_2(r_data[2]), .matrix_data_3(r_data[3]), .matrix_data_4(r_data[4]),
        .matrix_data_5(r_data[5]), .matrix_data_6(r_data[6]), .matrix_data_7(r_data[7]), .matrix_data_8(r_data[8]), .matrix_data_9(r_data[9]),
        .matrix_data_10(r_data[10]),.matrix_data_11(r_data[11]),.matrix_data_12(r_data[12]),.matrix_data_13(r_data[13]),.matrix_data_14(r_data[14]),
        .matrix_data_15(r_data[15]),.matrix_data_16(r_data[16]),.matrix_data_17(r_data[17]),.matrix_data_18(r_data[18]),.matrix_data_19(r_data[19]),
        .matrix_data_20(r_data[20]),.matrix_data_21(r_data[21]),.matrix_data_22(r_data[22]),.matrix_data_23(r_data[23]),.matrix_data_24(r_data[24])
    );

    // ============================================
    // 4. Matrix Displayer (显示模块)
    // ============================================
    matrix_displayer u_displayer (
        .clk(clk), .rst_n(rst_n),
        .start(save_done), // 当存储写入完成后，立即触发显示
        .busy(),           // 暂时不用
        
        // 维度信息：直接使用刚才写入的维度
        .matrix_row(wr_row),
        .matrix_col(wr_col),
        
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

endmodule