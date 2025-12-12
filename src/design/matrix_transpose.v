module matrix_transpose #(
    parameter DATA_WIDTH = 9
) (
    input [2:0] r,
    input [2:0] c,
    input [DATA_WIDTH-1:0] data_in_0,
    input [DATA_WIDTH-1:0] data_in_1,
    input [DATA_WIDTH-1:0] data_in_2,
    input [DATA_WIDTH-1:0] data_in_3,
    input [DATA_WIDTH-1:0] data_in_4,
    input [DATA_WIDTH-1:0] data_in_5,
    input [DATA_WIDTH-1:0] data_in_6,
    input [DATA_WIDTH-1:0] data_in_7,
    input [DATA_WIDTH-1:0] data_in_8,
    input [DATA_WIDTH-1:0] data_in_9,
    input [DATA_WIDTH-1:0] data_in_10,
    input [DATA_WIDTH-1:0] data_in_11,
    input [DATA_WIDTH-1:0] data_in_12,
    input [DATA_WIDTH-1:0] data_in_13,
    input [DATA_WIDTH-1:0] data_in_14,
    input [DATA_WIDTH-1:0] data_in_15,
    input [DATA_WIDTH-1:0] data_in_16,
    input [DATA_WIDTH-1:0] data_in_17,
    input [DATA_WIDTH-1:0] data_in_18,
    input [DATA_WIDTH-1:0] data_in_19,
    input [DATA_WIDTH-1:0] data_in_20,
    input [DATA_WIDTH-1:0] data_in_21,
    input [DATA_WIDTH-1:0] data_in_22,
    input [DATA_WIDTH-1:0] data_in_23,
    input [DATA_WIDTH-1:0] data_in_24,
    input en,
    output reg [2:0] r_out,
    output reg [2:0] c_out,
    output reg [DATA_WIDTH-1:0] data_out_0,
    output reg [DATA_WIDTH-1:0] data_out_1,
    output reg [DATA_WIDTH-1:0] data_out_2,
    output reg [DATA_WIDTH-1:0] data_out_3,
    output reg [DATA_WIDTH-1:0] data_out_4,
    output reg [DATA_WIDTH-1:0] data_out_5,
    output reg [DATA_WIDTH-1:0] data_out_6,
    output reg [DATA_WIDTH-1:0] data_out_7,
    output reg [DATA_WIDTH-1:0] data_out_8,
    output reg [DATA_WIDTH-1:0] data_out_9,
    output reg [DATA_WIDTH-1:0] data_out_10,
    output reg [DATA_WIDTH-1:0] data_out_11,
    output reg [DATA_WIDTH-1:0] data_out_12,
    output reg [DATA_WIDTH-1:0] data_out_13,
    output reg [DATA_WIDTH-1:0] data_out_14,
    output reg [DATA_WIDTH-1:0] data_out_15,
    output reg [DATA_WIDTH-1:0] data_out_16,
    output reg [DATA_WIDTH-1:0] data_out_17,
    output reg [DATA_WIDTH-1:0] data_out_18,
    output reg [DATA_WIDTH-1:0] data_out_19,
    output reg [DATA_WIDTH-1:0] data_out_20,
    output reg [DATA_WIDTH-1:0] data_out_21,
    output reg [DATA_WIDTH-1:0] data_out_22,
    output reg [DATA_WIDTH-1:0] data_out_23,
    output reg [DATA_WIDTH-1:0] data_out_24
);
// 只在en从0变化到1的时候单次赋值，即使输入出现变化，只要en没有被清零就不会改变输出
// 所以en初始值为0，在使用该模块时先确保输入data正确，后将en赋1，离开转置运算时将en重置
always@(en) begin
    if(en) begin
        r_out = c;
        c_out = r;
        
        data_out_0 = data_in_0;   // [0][0]
        data_out_1 = data_in_5;   // [1][0]
        data_out_2 = data_in_10;  // [2][0]
        data_out_3 = data_in_15;  // [3][0]
        data_out_4 = data_in_20;  // [4][0]
        data_out_5 = data_in_1;   // [0][1]
        data_out_6 = data_in_6;   // [1][1]
        data_out_7 = data_in_11;  // [2][1]
        data_out_8 = data_in_16;  // [3][1]
        data_out_9 = data_in_21;  // [4][1]
        data_out_10 = data_in_2;  // [0][2]
        data_out_11 = data_in_7;  // [1][2]
        data_out_12 = data_in_12; // [2][2]
        data_out_13 = data_in_17; // [3][2]
        data_out_14 = data_in_22; // [4][2]
        data_out_15 = data_in_3;  // [0][3]
        data_out_16 = data_in_8;  // [1][3]
        data_out_17 = data_in_13; // [2][3]
        data_out_18 = data_in_18; // [3][3]
        data_out_19 = data_in_23; // [4][3]
        data_out_20 = data_in_4;  // [0][4]
        data_out_21 = data_in_9;  // [1][4]
        data_out_22 = data_in_14; // [2][4]
        data_out_23 = data_in_19; // [3][4]
        data_out_24 = data_in_24; // [4][4]
    end
    else begin
        r_out = 0;
        c_out = 0;
        data_out_0 = 0;
        data_out_1 = 0;
        data_out_2 = 0;
        data_out_3 = 0;
        data_out_4 = 0;
        data_out_5 = 0;
        data_out_6 = 0;
        data_out_7 = 0;
        data_out_8 = 0;
        data_out_9 = 0;
        data_out_10 = 0;
        data_out_11 = 0;
        data_out_12 = 0;
        data_out_13 = 0;
        data_out_14 = 0;
        data_out_15 = 0;
        data_out_16 = 0;
        data_out_17 = 0;
        data_out_18 = 0;
        data_out_19 = 0;
        data_out_20 = 0;
        data_out_21 = 0;
        data_out_22 = 0;
        data_out_23 = 0;
        data_out_24 = 0;
    end
end
endmodule