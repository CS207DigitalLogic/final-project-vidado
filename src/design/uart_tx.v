`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire rst_n,
    input wire tx_start,         // 开始发送脉冲
    input wire [7:0] tx_data,    // 待发送数据
    output reg tx,               // UART TX 信号线
    output reg tx_busy           // 忙信号
);

    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;
    
    // 状态定义
    localparam S_IDLE  = 0;
    localparam S_START = 1;
    localparam S_DATA  = 2;
    localparam S_STOP  = 3;

    reg [2:0] state;
    reg [15:0] baud_cnt;
    reg [2:0] bit_idx;
    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            tx <= 1'b1; // 空闲高电平
            tx_busy <= 1'b0;
            baud_cnt <= 0;
            bit_idx <= 0;
            data_reg <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    tx <= 1'b1;
                    if (tx_start) begin
                        state <= S_START;
                        tx_busy <= 1'b1;
                        data_reg <= tx_data;
                        baud_cnt <= 0;
                    end else begin
                        tx_busy <= 1'b0;
                    end
                end

                S_START: begin
                    tx <= 1'b0; // 起始位
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        state <= S_DATA;
                        bit_idx <= 0;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end

                S_DATA: begin
                    tx <= data_reg[bit_idx]; // 发送数据位 (LSB first)
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
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
                    tx <= 1'b1; // 停止位
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        state <= S_IDLE;
                        tx_busy <= 1'b0;
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end
            endcase
        end
    end
endmodule
