/// 分频器，将输入时钟信号按tiaoPin参数进行分频，输出分频后的时钟信号clk_out

`timescale 1ns / 1ps

module divider (
  input clk,
  input rst_n,
  input [13:0] tiaoPin,
  output  clk_out
);

  reg [13:0] counter;
  reg clk_out_1;
  always @(posedge clk or negedge rst_n) begin
    if (rst_n) begin
      counter <= 14'd0;
      clk_out_1 <= 1'b0;
    end
     else begin
      if (counter == tiaoPin) begin
        counter <= 14'd0;
        clk_out_1 <= ~clk_out_1;
      end    
      if (counter == 14'd0) begin
            counter <= 14'd1;
            clk_out_1 <= 1'b1;
          end    
      else begin
        counter <= counter + 1;
      end
    end
  end
 
assign clk_out=clk_out_1;
endmodule