module matrix_multiplier #(
    parameter DATA_WIDTH = 9
) (
    input clk,
    input reset_n,
    input [2:0] r1,
    input [2:0] c1,
    input [DATA_WIDTH-1:0] data1_in_0,
    input [DATA_WIDTH-1:0] data1_in_1,
    input [DATA_WIDTH-1:0] data1_in_2,
    input [DATA_WIDTH-1:0] data1_in_3,
    input [DATA_WIDTH-1:0] data1_in_4,
    input [DATA_WIDTH-1:0] data1_in_5,
    input [DATA_WIDTH-1:0] data1_in_6,
    input [DATA_WIDTH-1:0] data1_in_7,
    input [DATA_WIDTH-1:0] data1_in_8,
    input [DATA_WIDTH-1:0] data1_in_9,
    input [DATA_WIDTH-1:0] data1_in_10,
    input [DATA_WIDTH-1:0] data1_in_11,
    input [DATA_WIDTH-1:0] data1_in_12,
    input [DATA_WIDTH-1:0] data1_in_13,
    input [DATA_WIDTH-1:0] data1_in_14,
    input [DATA_WIDTH-1:0] data1_in_15,
    input [DATA_WIDTH-1:0] data1_in_16,
    input [DATA_WIDTH-1:0] data1_in_17,
    input [DATA_WIDTH-1:0] data1_in_18,
    input [DATA_WIDTH-1:0] data1_in_19,
    input [DATA_WIDTH-1:0] data1_in_20,
    input [DATA_WIDTH-1:0] data1_in_21,
    input [DATA_WIDTH-1:0] data1_in_22,
    input [DATA_WIDTH-1:0] data1_in_23,
    input [DATA_WIDTH-1:0] data1_in_24,
    input [2:0] r2,
    input [2:0] c2,
    input [DATA_WIDTH-1:0] data2_in_0,
    input [DATA_WIDTH-1:0] data2_in_1,
    input [DATA_WIDTH-1:0] data2_in_2,
    input [DATA_WIDTH-1:0] data2_in_3,
    input [DATA_WIDTH-1:0] data2_in_4,
    input [DATA_WIDTH-1:0] data2_in_5,
    input [DATA_WIDTH-1:0] data2_in_6,
    input [DATA_WIDTH-1:0] data2_in_7,
    input [DATA_WIDTH-1:0] data2_in_8,
    input [DATA_WIDTH-1:0] data2_in_9,
    input [DATA_WIDTH-1:0] data2_in_10,
    input [DATA_WIDTH-1:0] data2_in_11,
    input [DATA_WIDTH-1:0] data2_in_12,
    input [DATA_WIDTH-1:0] data2_in_13,
    input [DATA_WIDTH-1:0] data2_in_14,
    input [DATA_WIDTH-1:0] data2_in_15,
    input [DATA_WIDTH-1:0] data2_in_16,
    input [DATA_WIDTH-1:0] data2_in_17,
    input [DATA_WIDTH-1:0] data2_in_18,
    input [DATA_WIDTH-1:0] data2_in_19,
    input [DATA_WIDTH-1:0] data2_in_20,
    input [DATA_WIDTH-1:0] data2_in_21,
    input [DATA_WIDTH-1:0] data2_in_22,
    input [DATA_WIDTH-1:0] data2_in_23,
    input [DATA_WIDTH-1:0] data2_in_24,
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
    output reg [DATA_WIDTH-1:0] data_out_24,
    output reg isValid,
    output reg busy
);
// === 计数器控制 ===
    reg [4:0] calc_counter;  // 0-24计数器
    
    // === 行列坐标 ===
    wire [2:0] row_idx;
    wire [2:0] col_idx;
    assign row_idx = calc_counter / 5;  // 行号 = counter ÷ 5
    assign col_idx = calc_counter % 5;  // 列号 = counter % 5
    
    // === 5个乘法器 ===
    wire [DATA_WIDTH-1:0] product_0, product_1, product_2, product_3, product_4;
    wire [DATA_WIDTH-1:0] sum_result;
    
    // 被选中的矩阵A元素（固定行）
    reg [DATA_WIDTH-1:0] a_elem_0, a_elem_1, a_elem_2, a_elem_3, a_elem_4;
    
    // 被选中的矩阵B元素（固定列）
    reg [DATA_WIDTH-1:0] b_elem_0, b_elem_1, b_elem_2, b_elem_3, b_elem_4;
    
    assign product_0 = a_elem_0 * b_elem_0;
    assign product_1 = a_elem_1 * b_elem_1;
    assign product_2 = a_elem_2 * b_elem_2;
    assign product_3 = a_elem_3 * b_elem_3;
    assign product_4 = a_elem_4 * b_elem_4;
    assign sum_result = product_0 + product_1 + product_2 + product_3 + product_4;
    
    // === 组合逻辑选择元素 ===
    always @(*) begin
        // 选择矩阵A的指定行
        case(row_idx)
            3'd0: begin
                a_elem_0 = data1_in_0;
                a_elem_1 = data1_in_1;
                a_elem_2 = data1_in_2;
                a_elem_3 = data1_in_3;
                a_elem_4 = data1_in_4;
            end
            3'd1: begin
                a_elem_0 = data1_in_5;
                a_elem_1 = data1_in_6;
                a_elem_2 = data1_in_7;
                a_elem_3 = data1_in_8;
                a_elem_4 = data1_in_9;
            end
            3'd2: begin
                a_elem_0 = data1_in_10;
                a_elem_1 = data1_in_11;
                a_elem_2 = data1_in_12;
                a_elem_3 = data1_in_13;
                a_elem_4 = data1_in_14;
            end
            3'd3: begin
                a_elem_0 = data1_in_15;
                a_elem_1 = data1_in_16;
                a_elem_2 = data1_in_17;
                a_elem_3 = data1_in_18;
                a_elem_4 = data1_in_19;
            end
            3'd4: begin
                a_elem_0 = data1_in_20;
                a_elem_1 = data1_in_21;
                a_elem_2 = data1_in_22;
                a_elem_3 = data1_in_23;
                a_elem_4 = data1_in_24;
            end
            default: begin
                a_elem_0 = 0;
                a_elem_1 = 0;
                a_elem_2 = 0;
                a_elem_3 = 0;
                a_elem_4 = 0;
            end
        endcase
        
        // 选择矩阵B的指定列
        case(col_idx)
            3'd0: begin
                b_elem_0 = data2_in_0;
                b_elem_1 = data2_in_5;
                b_elem_2 = data2_in_10;
                b_elem_3 = data2_in_15;
                b_elem_4 = data2_in_20;
            end
            3'd1: begin
                b_elem_0 = data2_in_1;
                b_elem_1 = data2_in_6;
                b_elem_2 = data2_in_11;
                b_elem_3 = data2_in_16;
                b_elem_4 = data2_in_21;
            end
            3'd2: begin
                b_elem_0 = data2_in_2;
                b_elem_1 = data2_in_7;
                b_elem_2 = data2_in_12;
                b_elem_3 = data2_in_17;
                b_elem_4 = data2_in_22;
            end
            3'd3: begin
                b_elem_0 = data2_in_3;
                b_elem_1 = data2_in_8;
                b_elem_2 = data2_in_13;
                b_elem_3 = data2_in_18;
                b_elem_4 = data2_in_23;
            end
            3'd4: begin
                b_elem_0 = data2_in_4;
                b_elem_1 = data2_in_9;
                b_elem_2 = data2_in_14;
                b_elem_3 = data2_in_19;
                b_elem_4 = data2_in_24;
            end
            default: begin
                b_elem_0 = 0;
                b_elem_1 = 0;
                b_elem_2 = 0;
                b_elem_3 = 0;
                b_elem_4 = 0;
            end
        endcase
    end
    
    // === 时序控制逻辑 ===
    reg isCalculated;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // 复位所有寄存器和输出
            calc_counter <= 0;
            busy <= 0;
            isValid <= 1;
            r_out <= 0;
            c_out <= 0;
            isCalculated <= 0;
            
            data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
            data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
            data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
            data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
            data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
        end else begin
            if (en && !busy && !isCalculated) begin
                if (c1 == r2) begin
                    r_out <= r1;
                    c_out <= c2;
                    busy <= 1;
                    calc_counter <= 0;
                    isValid <= 1;
                end
                else begin
                    // 维度不匹配，无效操作
                    isValid <= 0;
                end
            end else if (busy) begin
                // 正在计算：存储上一个时钟周期的结果
                case(calc_counter)
                    0: data_out_0 <= sum_result[DATA_WIDTH-1:0];
                    1: data_out_1 <= sum_result[DATA_WIDTH-1:0];
                    2: data_out_2 <= sum_result[DATA_WIDTH-1:0];
                    3: data_out_3 <= sum_result[DATA_WIDTH-1:0];
                    4: data_out_4 <= sum_result[DATA_WIDTH-1:0];
                    5: data_out_5 <= sum_result[DATA_WIDTH-1:0];
                    6: data_out_6 <= sum_result[DATA_WIDTH-1:0];
                    7: data_out_7 <= sum_result[DATA_WIDTH-1:0];
                    8: data_out_8 <= sum_result[DATA_WIDTH-1:0];
                    9: data_out_9 <= sum_result[DATA_WIDTH-1:0];
                    10: data_out_10 <= sum_result[DATA_WIDTH-1:0];
                    11: data_out_11 <= sum_result[DATA_WIDTH-1:0];
                    12: data_out_12 <= sum_result[DATA_WIDTH-1:0];
                    13: data_out_13 <= sum_result[DATA_WIDTH-1:0];
                    14: data_out_14 <= sum_result[DATA_WIDTH-1:0];
                    15: data_out_15 <= sum_result[DATA_WIDTH-1:0];
                    16: data_out_16 <= sum_result[DATA_WIDTH-1:0];
                    17: data_out_17 <= sum_result[DATA_WIDTH-1:0];
                    18: data_out_18 <= sum_result[DATA_WIDTH-1:0];
                    19: data_out_19 <= sum_result[DATA_WIDTH-1:0];
                    20: data_out_20 <= sum_result[DATA_WIDTH-1:0];
                    21: data_out_21 <= sum_result[DATA_WIDTH-1:0];
                    22: data_out_22 <= sum_result[DATA_WIDTH-1:0];
                    23: data_out_23 <= sum_result[DATA_WIDTH-1:0];
                    24: data_out_24 <= sum_result[DATA_WIDTH-1:0];
                endcase
                
                // 递增计数器
                if (calc_counter < 24) begin
                    calc_counter <= calc_counter + 1;
                end else begin
                    // 完成所有25个元素的计算
                    busy <= 0;
                    isCalculated <= 1;
                    calc_counter <= 0;
                end
            end else if (!en) begin
                // 复位所有寄存器和输出
                calc_counter <= 0;
                busy <= 0;
                isValid <= 1;
                r_out <= 0;
                c_out <= 0;
                isCalculated <= 0;
                
                data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
                data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
                data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
                data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
                data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
            end
        end
    end
endmodule