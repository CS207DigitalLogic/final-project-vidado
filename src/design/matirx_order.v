module matirx_order#(
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
    
    reg [DATA_WIDTH-1:0] data_in [0:24];
    reg [DATA_WIDTH-1:0] data_out [0:24];
    
    integer i, j, input_idx, output_idx;
    
    always@(en) begin
        if (en) begin
            input_idx = 0;
            output_idx = 0;
            // 初始化输出数组向量为0
            data_out[0] = 0;
            data_out[1] = 0;
            data_out[2] = 0;
            data_out[3] = 0;
            data_out[4] = 0;
            data_out[5] = 0;
            data_out[6] = 0;
            data_out[7] = 0;
            data_out[8] = 0;
            data_out[9] = 0;
            data_out[10] = 0;
            data_out[11] = 0;
            data_out[12] = 0;
            data_out[13] = 0;
            data_out[14] = 0;
            data_out[15] = 0;
            data_out[16] = 0;
            data_out[17] = 0;
            data_out[18] = 0;
            data_out[19] = 0;
            data_out[20] = 0;
            data_out[21] = 0;
            data_out[22] = 0;
            data_out[23] = 0;
            data_out[24] = 0;
            // 将分散的输入信号存入数组
            data_in[0] = data_in_0;
            data_in[1] = data_in_1;
            data_in[2] = data_in_2;
            data_in[3] = data_in_3;
            data_in[4] = data_in_4;
            data_in[5] = data_in_5;
            data_in[6] = data_in_6;
            data_in[7] = data_in_7;
            data_in[8] = data_in_8;
            data_in[9] = data_in_9;
            data_in[10] = data_in_10;
            data_in[11] = data_in_11;
            data_in[12] = data_in_12;
            data_in[13] = data_in_13;
            data_in[14] = data_in_14;
            data_in[15] = data_in_15;
            data_in[16] = data_in_16;
            data_in[17] = data_in_17;
            data_in[18] = data_in_18;
            data_in[19] = data_in_19;
            data_in[20] = data_in_20;
            data_in[21] = data_in_21;
            data_in[22] = data_in_22;
            data_in[23] = data_in_23;
            data_in[24] = data_in_24;
            // 重排逻辑：将连续输入映射到5×5矩阵的行优先排列
            for (i = 0; i < 5; i = i + 1) begin
                for (j = 0; j < 5; j = j + 1) begin
                    output_idx = i * 5 + j;
                    
                    // 如果当前行小于输入矩阵的行数 且 当前列小于输入矩阵的列数
                    if (i < r && j < c) begin
                        // 从连续输入中取出数据
                        if (input_idx < 25) begin
                            data_out[output_idx] = data_in[input_idx];
                            input_idx = input_idx + 1;
                        end
                    end
                    // 否则保持为0（已在初始化中设置）
                end
            end
            // 将数组中的值赋给输出信号
            data_out_0 = data_out[0];
            data_out_1 = data_out[1];
            data_out_2 = data_out[2];
            data_out_3 = data_out[3];
            data_out_4 = data_out[4];
            data_out_5 = data_out[5];
            data_out_6 = data_out[6];
            data_out_7 = data_out[7];
            data_out_8 = data_out[8];
            data_out_9 = data_out[9];
            data_out_10 = data_out[10];
            data_out_11 = data_out[11];
            data_out_12 = data_out[12];
            data_out_13 = data_out[13];
            data_out_14 = data_out[14];
            data_out_15 = data_out[15];
            data_out_16 = data_out[16];
            data_out_17 = data_out[17];
            data_out_18 = data_out[18];
            data_out_19 = data_out[19];
            data_out_20 = data_out[20];
            data_out_21 = data_out[21];
            data_out_22 = data_out[22];
            data_out_23 = data_out[23];
            data_out_24 = data_out[24];
        end
    end
endmodule
