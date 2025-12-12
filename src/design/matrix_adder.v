module matrix_adder #(
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
    reg [2:0] row_counter;  // 0-4计数器，只需计数5行
    
    // === 5个并行加法器 ===
    wire [DATA_WIDTH-1:0] adder_result_0, adder_result_1, adder_result_2, adder_result_3, adder_result_4;
    
    // 被选中的矩阵A元素（一行5个）
    reg [DATA_WIDTH-1:0] a_row_0, a_row_1, a_row_2, a_row_3, a_row_4;
    
    // 被选中的矩阵B元素（同一行5个）
    reg [DATA_WIDTH-1:0] b_row_0, b_row_1, b_row_2, b_row_3, b_row_4;
    
    // 5个并行加法器
    assign adder_result_0 = a_row_0 + b_row_0;
    assign adder_result_1 = a_row_1 + b_row_1;
    assign adder_result_2 = a_row_2 + b_row_2;
    assign adder_result_3 = a_row_3 + b_row_3;
    assign adder_result_4 = a_row_4 + b_row_4;
    
    // === 组合逻辑选择元素 ===
    always @(*) begin
        // 根据行计数器选择矩阵A的一整行
        case(row_counter)
            3'd0: begin
                a_row_0 = data1_in_0;
                a_row_1 = data1_in_1;
                a_row_2 = data1_in_2;
                a_row_3 = data1_in_3;
                a_row_4 = data1_in_4;
            end
            3'd1: begin
                a_row_0 = data1_in_5;
                a_row_1 = data1_in_6;
                a_row_2 = data1_in_7;
                a_row_3 = data1_in_8;
                a_row_4 = data1_in_9;
            end
            3'd2: begin
                a_row_0 = data1_in_10;
                a_row_1 = data1_in_11;
                a_row_2 = data1_in_12;
                a_row_3 = data1_in_13;
                a_row_4 = data1_in_14;
            end
            3'd3: begin
                a_row_0 = data1_in_15;
                a_row_1 = data1_in_16;
                a_row_2 = data1_in_17;
                a_row_3 = data1_in_18;
                a_row_4 = data1_in_19;
            end
            3'd4: begin
                a_row_0 = data1_in_20;
                a_row_1 = data1_in_21;
                a_row_2 = data1_in_22;
                a_row_3 = data1_in_23;
                a_row_4 = data1_in_24;
            end
            default: begin
                a_row_0 = 0;
                a_row_1 = 0;
                a_row_2 = 0;
                a_row_3 = 0;
                a_row_4 = 0;
            end
        endcase
        
        // 选择矩阵B的同一行
        case(row_counter)
            3'd0: begin
                b_row_0 = data2_in_0;
                b_row_1 = data2_in_1;
                b_row_2 = data2_in_2;
                b_row_3 = data2_in_3;
                b_row_4 = data2_in_4;
            end
            3'd1: begin
                b_row_0 = data2_in_5;
                b_row_1 = data2_in_6;
                b_row_2 = data2_in_7;
                b_row_3 = data2_in_8;
                b_row_4 = data2_in_9;
            end
            3'd2: begin
                b_row_0 = data2_in_10;
                b_row_1 = data2_in_11;
                b_row_2 = data2_in_12;
                b_row_3 = data2_in_13;
                b_row_4 = data2_in_14;
            end
            3'd3: begin
                b_row_0 = data2_in_15;
                b_row_1 = data2_in_16;
                b_row_2 = data2_in_17;
                b_row_3 = data2_in_18;
                b_row_4 = data2_in_19;
            end
            3'd4: begin
                b_row_0 = data2_in_20;
                b_row_1 = data2_in_21;
                b_row_2 = data2_in_22;
                b_row_3 = data2_in_23;
                b_row_4 = data2_in_24;
            end
            default: begin
                b_row_0 = 0;
                b_row_1 = 0;
                b_row_2 = 0;
                b_row_3 = 0;
                b_row_4 = 0;
            end
        endcase
    end
    
    // === 时序控制逻辑 ===
    reg isCalculated;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // 复位所有寄存器和输出
            row_counter <= 0;
            busy <= 0;
            isValid <= 1;
            r_out <= 0;
            c_out <= 0;
            isCalculated <= 0;
            
            // 清空所有输出
            data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
            data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
            data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
            data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
            data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
        end else begin
            if (en && !busy && !isCalculated) begin
                // 检查矩阵是否可以相加（维度必须相等）
                if (r1 == r2 && c1 == c2) begin
                    r_out <= r1;
                    c_out <= c1;  // 注意：加法输出维度等于输入维度
                    busy <= 1;
                    row_counter <= 0;
                    isValid <= 1;
                end 
                else begin
                    // 维度不匹配，无效操作
                    isValid <= 0;
                end
            end else if (busy) begin
                // 忙状态：进行计算和存储
                // 在当前时钟沿，adder_result已经包含了一整行的计算结果
                // 将这5个结果复制到对应的5个输出位置
                case(row_counter)
                    3'd0: begin
                        // 第0行：复制到data_out_0到data_out_4
                        data_out_0 <= adder_result_0;
                        data_out_1 <= adder_result_1;
                        data_out_2 <= adder_result_2;
                        data_out_3 <= adder_result_3;
                        data_out_4 <= adder_result_4;
                    end
                    3'd1: begin
                        // 第1行：复制到data_out_5到data_out_9
                        data_out_5 <= adder_result_0;
                        data_out_6 <= adder_result_1;
                        data_out_7 <= adder_result_2;
                        data_out_8 <= adder_result_3;
                        data_out_9 <= adder_result_4;
                    end
                    3'd2: begin
                        // 第2行：复制到data_out_10到data_out_14
                        data_out_10 <= adder_result_0;
                        data_out_11 <= adder_result_1;
                        data_out_12 <= adder_result_2;
                        data_out_13 <= adder_result_3;
                        data_out_14 <= adder_result_4;
                    end
                    3'd3: begin
                        // 第3行：复制到data_out_15到data_out_19
                        data_out_15 <= adder_result_0;
                        data_out_16 <= adder_result_1;
                        data_out_17 <= adder_result_2;
                        data_out_18 <= adder_result_3;
                        data_out_19 <= adder_result_4;
                    end
                    3'd4: begin
                        // 第4行：复制到data_out_20到data_out_24
                        data_out_20 <= adder_result_0;
                        data_out_21 <= adder_result_1;
                        data_out_22 <= adder_result_2;
                        data_out_23 <= adder_result_3;
                        data_out_24 <= adder_result_4;
                    end
                endcase
                
                 // 递增行计数器（除了最后一行）
                if (row_counter < 4) begin
                    row_counter <= row_counter + 1;
                end else begin
                    // 完成所有5行元素的计算
                    busy <= 0;
                    isCalculated <= 1;
                    row_counter <= 0;
                end
            end else if (!en) begin
                // 复位所有寄存器和输出
                row_counter <= 0;
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