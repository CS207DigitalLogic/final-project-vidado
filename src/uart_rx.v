`timescale 1ns / 1ps

module uart_rx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire rst_n,
    input wire rx,              // UART RX 信号线
    output reg [7:0] rx_data,   // 接收到的数据
    output reg rx_done          // 数据有效脉冲
);

    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;

    reg [1:0] rx_sync;
    wire rx_negedge;
    
    // 状态定义
    localparam S_IDLE  = 0;
    localparam S_START = 1;
    localparam S_DATA  = 2;
    localparam S_STOP  = 3;

    reg [2:0] state;
    reg [15:0] baud_cnt;
    reg [2:0] bit_idx;
    reg [7:0] shift_reg;

    // 同步打拍，消除亚稳态
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) rx_sync <= 2'b11;
        else rx_sync <= {rx_sync[0], rx};
    end
    
    // 检测下降沿（起始位）
    assign rx_negedge = (rx_sync[1] && !rx_sync[0]);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            rx_data <= 0;
            rx_done <= 0;
            baud_cnt <= 0;
            bit_idx <= 0;
            shift_reg <= 0;
        end else begin
            rx_done <= 1'b0; // 默认为0
            case (state)
                S_IDLE: begin
                    if (rx_negedge) begin
                        state <= S_START;
                        baud_cnt <= 0;
                    end
                end

                S_START: begin
                    // 等待起始位中间点 (BAUD_DIV / 2)
                    if (baud_cnt == BAUD_DIV / 2) begin
                        if (rx_sync[0] == 0) begin // 确认是低电平
                            state <= S_DATA;
                            baud_cnt <= 0;
                            bit_idx <= 0;
                        end else begin
                            state <= S_IDLE; // 误触发
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end

                S_DATA: begin
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        shift_reg[bit_idx] <= rx_sync[0];
                        if (bit_idx == 7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end

                S_STOP: begin
                    if (baud_cnt == BAUD_DIV - 1) begin
                        state <= S_IDLE;
                        rx_data <= shift_reg;
                        rx_done <= 1'b1; // 接收完成
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
            endcase
        end
    end
endmodule