module matrix_scalar #(
    parameter DATA_WIDTH = 9
) (
    input clk,
    input reset_n,
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
    input [DATA_WIDTH-1:0] scalar,
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
    output reg busy
);
    // === 计数器控制 ===
    reg [2:0] row_counter;  // 0-4计数器，只需计数5行
    
    // === 5个并行乘法器 ===
    wire [DATA_WIDTH-1:0] result_0, result_1, result_2, result_3, result_4;
    
    // 被选中的矩阵元素（一行5个）
    reg [DATA_WIDTH-1:0] mat_row_0, mat_row_1, mat_row_2, mat_row_3, mat_row_4;
    
    // 标量寄存器，在整个计算期间保持恒定
    reg [DATA_WIDTH-1:0] scalar_reg;
    
    // 5个并行乘法器
    assign result_0 = mat_row_0 * scalar_reg;
    assign result_1 = mat_row_1 * scalar_reg;
    assign result_2 = mat_row_2 * scalar_reg;
    assign result_3 = mat_row_3 * scalar_reg;
    assign result_4 = mat_row_4 * scalar_reg;
    
    // === 组合逻辑选择元素 ===
    always @(*) begin
        // 根据行计数器选择矩阵的一整行
        case(row_counter)
            3'd0: begin
                mat_row_0 = data_in_0;
                mat_row_1 = data_in_1;
                mat_row_2 = data_in_2;
                mat_row_3 = data_in_3;
                mat_row_4 = data_in_4;
            end
            3'd1: begin
                mat_row_0 = data_in_5;
                mat_row_1 = data_in_6;
                mat_row_2 = data_in_7;
                mat_row_3 = data_in_8;
                mat_row_4 = data_in_9;
            end
            3'd2: begin
                mat_row_0 = data_in_10;
                mat_row_1 = data_in_11;
                mat_row_2 = data_in_12;
                mat_row_3 = data_in_13;
                mat_row_4 = data_in_14;
            end
            3'd3: begin
                mat_row_0 = data_in_15;
                mat_row_1 = data_in_16;
                mat_row_2 = data_in_17;
                mat_row_3 = data_in_18;
                mat_row_4 = data_in_19;
            end
            3'd4: begin
                mat_row_0 = data_in_20;
                mat_row_1 = data_in_21;
                mat_row_2 = data_in_22;
                mat_row_3 = data_in_23;
                mat_row_4 = data_in_24;
            end
            default: begin
                mat_row_0 = 0;
                mat_row_1 = 0;
                mat_row_2 = 0;
                mat_row_3 = 0;
                mat_row_4 = 0;
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
            r_out <= 0;
            c_out <= 0;
            isCalculated <= 0;
            scalar_reg <= 0;
            
            // 清空所有输出
            data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
            data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
            data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
            data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
            data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
        end else begin
            if (en && !busy && !isCalculated) begin
                // 开始新计算：锁存标量值和矩阵维度
                scalar_reg <= scalar;
                r_out <= r;
                c_out <= c;
                busy <= 1;
                row_counter <= 0;
            end else if (busy) begin
                // 忙状态：进行计算和存储
                // 在当前时钟沿，result已经包含了一整行的计算结果
                // 将这5个结果复制到对应的5个输出位置
                case(row_counter)
                    3'd0: begin
                        // 第0行：复制到data_out_0到data_out_4
                        data_out_0 <= result_0;
                        data_out_1 <= result_1;
                        data_out_2 <= result_2;
                        data_out_3 <= result_3;
                        data_out_4 <= result_4;
                    end
                    3'd1: begin
                        // 第1行：复制到data_out_5到data_out_9
                        data_out_5 <= result_0;
                        data_out_6 <= result_1;
                        data_out_7 <= result_2;
                        data_out_8 <= result_3;
                        data_out_9 <= result_4;
                    end
                    3'd2: begin
                        // 第2行：复制到data_out_10到data_out_14
                        data_out_10 <= result_0;
                        data_out_11 <= result_1;
                        data_out_12 <= result_2;
                        data_out_13 <= result_3;
                        data_out_14 <= result_4;
                    end
                    3'd3: begin
                        // 第3行：复制到data_out_15到data_out_19
                        data_out_15 <= result_0;
                        data_out_16 <= result_1;
                        data_out_17 <= result_2;
                        data_out_18 <= result_3;
                        data_out_19 <= result_4;
                    end
                    3'd4: begin
                        // 第4行：复制到data_out_20到data_out_24
                        data_out_20 <= result_0;
                        data_out_21 <= result_1;
                        data_out_22 <= result_2;
                        data_out_23 <= result_3;
                        data_out_24 <= result_4;
                        
                        // 完成所有5行计算
                        busy <= 0;
                        isCalculated <= 1;
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