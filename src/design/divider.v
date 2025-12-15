module divider (
    input clk,
    input rst_n,
    input [13:0] tiaoPin,
    output reg clk_out
);
    reg [13:0] counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 0;
        end else if (counter >= tiaoPin) begin
            counter <= 0;
            clk_out <= ~clk_out;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule