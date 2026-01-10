`timescale 1ns / 1ps

module uart_test_top(
    input  wire       clk,          // 系统时钟 (100MHz)
    input  wire       rst_n,        // 复位信号 (低电平有效，可绑定到一个按键或开关)
    input  wire       uart_rx,      // UART 接收引脚
    output wire       uart_tx,      // UART 发送引脚
    output wire [7:0] led           // LED 显示接收到的数据
);

    // ==========================================
    // 参数定义
    // ==========================================
    parameter CLK_FREQ  = 100_000_000; // 根据您的板子实际时钟频率修改
    parameter BAUD_RATE = 115200;      // 波特率

    // ==========================================
    // 内部信号
    // ==========================================
    wire [7:0] rx_data;
    wire       rx_done;
    wire       tx_busy;
    
    reg  [7:0] tx_data_reg;
    reg        tx_start_reg;

    // 将接收到的数据直接连接到 LED
    // 注意：如果是负逻辑LED（低电平亮），可能需要取反，如 assign led = ~rx_data;
    assign led = rx_data; 

    // ==========================================
    // 模块例化
    // ==========================================

    // 1. 串口接收模块
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_rx (
        .clk(clk),
        .rst_n(~rst_n),
        .rx(uart_rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // 2. 串口发送模块
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_tx (
        .clk(clk),
        .rst_n(~rst_n),
        .tx_start(tx_start_reg),
        .tx_data(tx_data_reg),
        .tx(uart_tx),
        .tx_busy(tx_busy)
    );

    // ==========================================
    // 回环逻辑 (Loopback Logic)
    // ==========================================
    // 当接收到数据 (rx_done 脉冲) 时，如果发送端不忙，则触发发送
    always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            tx_start_reg <= 1'b0;
            tx_data_reg  <= 8'd0;
        end else begin
            // 默认拉低启动信号（脉冲形式）
            tx_start_reg <= 1'b0;

            // 当接收完成，且发送模块空闲时
            if (rx_done && !tx_busy) begin
                tx_data_reg  <= rx_data; // 将接收到的数据给发送端
                tx_start_reg <= 1'b1;    // 产生一个时钟周期的开始脉冲
            end
        end
    end

endmodule