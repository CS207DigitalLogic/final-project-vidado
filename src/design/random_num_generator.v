// 带使能+动态范围的随机数生成器
module random_num_generator #(
    parameter WIDTH    = 8  // 仅保留数据位宽参数
)(
    input  clk,
    input  rst_n,
    input  en,                  // LFSR使能
    input  [WIDTH-1:0] min_val, // 随机数最小值（输入端口）
    input  [WIDTH-1:0] max_val, // 随机数最大值（输入端口）
    output reg [WIDTH-1:0] random_num
);

reg [WIDTH-1:0] lfsr;
wire feedback;
wire [WIDTH-1:0] range;       // 随机数范围（max-min+1）
wire [WIDTH-1:0] valid_min;   // 有效最小值（边界保护）
wire [WIDTH-1:0] valid_max;   // 有效最大值（边界保护）

// 边界保护：确保max_val >= min_val，否则强制min=0、max=WIDTH最大值
assign valid_min = (max_val >= min_val) ? min_val : {WIDTH{1'b0}};
assign valid_max = (max_val >= min_val) ? max_val : {WIDTH{1'b1}};
assign range = valid_max - valid_min + 1'b1; // 范围长度
assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]; // 8位LFSR反馈（适配WIDTH=8）

// LFSR仅在en=1时移位
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lfsr <= {WIDTH{1'b1}}; // 复位初始值
    end else if (en) begin
        lfsr <= {lfsr[WIDTH-2:0], feedback};
    end
end

// 随机数生成（仅en=1时更新，且限制在有效范围内）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        random_num <= valid_min;
    end else if (en) begin
        random_num <= valid_min + (lfsr % range); // 取模限制范围
    end
end

endmodule
