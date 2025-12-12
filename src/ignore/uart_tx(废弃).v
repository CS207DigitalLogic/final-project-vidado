module uart_tx #(
    parameter CLK_FREQ  = 100000000, // 系统时钟频率（100MHz）
    parameter BAUD_RATE = 115200     // UART波特率（115200bps）
)(
    input wire         clk,          // 系统时钟
    input wire         rst_n,        // 低有效复位
    input wire         tx_start,     // 发送触发信号（高电平有效）
    input wire [7:0]   tx_data,      // 待发送的8位并行数据
    output reg         tx,           // UART串行发送引脚
    output reg         tx_busy       // 发送忙状态（高电平=忙）
);

    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;

    reg [15:0] baud_cnt;
    reg [3:0] bit_idx;
    reg [9:0] tx_shift;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            baud_cnt <= 0;
            bit_idx <= 0;
            tx_shift <= 10'b1111111111;
            tx <= 1'b1;
            tx_busy <= 1'b0;
        end else begin
            if(tx_start && !tx_busy) begin
                tx_shift <= {1'b1, tx_data, 1'b0};
                tx_busy <= 1'b1;
                baud_cnt <= 0;
                bit_idx <= 0;
            end else if(tx_busy) begin
                if(baud_cnt < BAUD_DIV - 1) begin
                    baud_cnt <= baud_cnt + 1;
                end else begin
                    baud_cnt <= 0;
                    tx <= tx_shift[0];
                    tx_shift <= {1'b1, tx_shift[9:1]};  
                    bit_idx <= bit_idx + 1;
                    if(bit_idx == 9) begin
                        tx_busy <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
