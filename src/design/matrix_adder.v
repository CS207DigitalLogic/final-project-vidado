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
    // 内部信号
    wire order_a_en, order_b_en;
    wire internal_en;
    reg en_delay;  // en延迟一拍
    
    // ==================== 两个Order模块实例化 ====================
    // 矩阵A的重排结果
    wire [DATA_WIDTH-1:0] ordered_a_0;
    wire [DATA_WIDTH-1:0] ordered_a_1;
    wire [DATA_WIDTH-1:0] ordered_a_2;
    wire [DATA_WIDTH-1:0] ordered_a_3;
    wire [DATA_WIDTH-1:0] ordered_a_4;
    wire [DATA_WIDTH-1:0] ordered_a_5;
    wire [DATA_WIDTH-1:0] ordered_a_6;
    wire [DATA_WIDTH-1:0] ordered_a_7;
    wire [DATA_WIDTH-1:0] ordered_a_8;
    wire [DATA_WIDTH-1:0] ordered_a_9;
    wire [DATA_WIDTH-1:0] ordered_a_10;
    wire [DATA_WIDTH-1:0] ordered_a_11;
    wire [DATA_WIDTH-1:0] ordered_a_12;
    wire [DATA_WIDTH-1:0] ordered_a_13;
    wire [DATA_WIDTH-1:0] ordered_a_14;
    wire [DATA_WIDTH-1:0] ordered_a_15;
    wire [DATA_WIDTH-1:0] ordered_a_16;
    wire [DATA_WIDTH-1:0] ordered_a_17;
    wire [DATA_WIDTH-1:0] ordered_a_18;
    wire [DATA_WIDTH-1:0] ordered_a_19;
    wire [DATA_WIDTH-1:0] ordered_a_20;
    wire [DATA_WIDTH-1:0] ordered_a_21;
    wire [DATA_WIDTH-1:0] ordered_a_22;
    wire [DATA_WIDTH-1:0] ordered_a_23;
    wire [DATA_WIDTH-1:0] ordered_a_24;
    
    // 矩阵B的重排结果
    wire [DATA_WIDTH-1:0] ordered_b_0;
    wire [DATA_WIDTH-1:0] ordered_b_1;
    wire [DATA_WIDTH-1:0] ordered_b_2;
    wire [DATA_WIDTH-1:0] ordered_b_3;
    wire [DATA_WIDTH-1:0] ordered_b_4;
    wire [DATA_WIDTH-1:0] ordered_b_5;
    wire [DATA_WIDTH-1:0] ordered_b_6;
    wire [DATA_WIDTH-1:0] ordered_b_7;
    wire [DATA_WIDTH-1:0] ordered_b_8;
    wire [DATA_WIDTH-1:0] ordered_b_9;
    wire [DATA_WIDTH-1:0] ordered_b_10;
    wire [DATA_WIDTH-1:0] ordered_b_11;
    wire [DATA_WIDTH-1:0] ordered_b_12;
    wire [DATA_WIDTH-1:0] ordered_b_13;
    wire [DATA_WIDTH-1:0] ordered_b_14;
    wire [DATA_WIDTH-1:0] ordered_b_15;
    wire [DATA_WIDTH-1:0] ordered_b_16;
    wire [DATA_WIDTH-1:0] ordered_b_17;
    wire [DATA_WIDTH-1:0] ordered_b_18;
    wire [DATA_WIDTH-1:0] ordered_b_19;
    wire [DATA_WIDTH-1:0] ordered_b_20;
    wire [DATA_WIDTH-1:0] ordered_b_21;
    wire [DATA_WIDTH-1:0] ordered_b_22;
    wire [DATA_WIDTH-1:0] ordered_b_23;
    wire [DATA_WIDTH-1:0] ordered_b_24;
    
    // Order模块实例1：矩阵A
    matirx_order #(.DATA_WIDTH(DATA_WIDTH)) order_a_inst (
        // 输入端口
        .clk(clk),
        .reset_n(reset_n),
        .r(r1),
        .c(c1),
        .data_in_0(data1_in_0),
        .data_in_1(data1_in_1),
        .data_in_2(data1_in_2),
        .data_in_3(data1_in_3),
        .data_in_4(data1_in_4),
        .data_in_5(data1_in_5),
        .data_in_6(data1_in_6),
        .data_in_7(data1_in_7),
        .data_in_8(data1_in_8),
        .data_in_9(data1_in_9),
        .data_in_10(data1_in_10),
        .data_in_11(data1_in_11),
        .data_in_12(data1_in_12),
        .data_in_13(data1_in_13),
        .data_in_14(data1_in_14),
        .data_in_15(data1_in_15),
        .data_in_16(data1_in_16),
        .data_in_17(data1_in_17),
        .data_in_18(data1_in_18),
        .data_in_19(data1_in_19),
        .data_in_20(data1_in_20),
        .data_in_21(data1_in_21),
        .data_in_22(data1_in_22),
        .data_in_23(data1_in_23),
        .data_in_24(data1_in_24),
        .en(en),
        // 输出端口
        .data_out_0(ordered_a_0),
        .data_out_1(ordered_a_1),
        .data_out_2(ordered_a_2),
        .data_out_3(ordered_a_3),
        .data_out_4(ordered_a_4),
        .data_out_5(ordered_a_5),
        .data_out_6(ordered_a_6),
        .data_out_7(ordered_a_7),
        .data_out_8(ordered_a_8),
        .data_out_9(ordered_a_9),
        .data_out_10(ordered_a_10),
        .data_out_11(ordered_a_11),
        .data_out_12(ordered_a_12),
        .data_out_13(ordered_a_13),
        .data_out_14(ordered_a_14),
        .data_out_15(ordered_a_15),
        .data_out_16(ordered_a_16),
        .data_out_17(ordered_a_17),
        .data_out_18(ordered_a_18),
        .data_out_19(ordered_a_19),
        .data_out_20(ordered_a_20),
        .data_out_21(ordered_a_21),
        .data_out_22(ordered_a_22),
        .data_out_23(ordered_a_23),
        .data_out_24(ordered_a_24),
        .isOrdered(order_a_en)
    );
    
    // Order模块实例2：矩阵B
    matirx_order #(.DATA_WIDTH(DATA_WIDTH)) order_b_inst (
        // 输入端口
        .clk(clk),
        .reset_n(reset_n),
        .r(r2),
        .c(c2),
        .data_in_0(data2_in_0),
        .data_in_1(data2_in_1),
        .data_in_2(data2_in_2),
        .data_in_3(data2_in_3),
        .data_in_4(data2_in_4),
        .data_in_5(data2_in_5),
        .data_in_6(data2_in_6),
        .data_in_7(data2_in_7),
        .data_in_8(data2_in_8),
        .data_in_9(data2_in_9),
        .data_in_10(data2_in_10),
        .data_in_11(data2_in_11),
        .data_in_12(data2_in_12),
        .data_in_13(data2_in_13),
        .data_in_14(data2_in_14),
        .data_in_15(data2_in_15),
        .data_in_16(data2_in_16),
        .data_in_17(data2_in_17),
        .data_in_18(data2_in_18),
        .data_in_19(data2_in_19),
        .data_in_20(data2_in_20),
        .data_in_21(data2_in_21),
        .data_in_22(data2_in_22),
        .data_in_23(data2_in_23),
        .data_in_24(data2_in_24),
        .en(en),
        // 输出端口
        .data_out_0(ordered_b_0),
        .data_out_1(ordered_b_1),
        .data_out_2(ordered_b_2),
        .data_out_3(ordered_b_3),
        .data_out_4(ordered_b_4),
        .data_out_5(ordered_b_5),
        .data_out_6(ordered_b_6),
        .data_out_7(ordered_b_7),
        .data_out_8(ordered_b_8),
        .data_out_9(ordered_b_9),
        .data_out_10(ordered_b_10),
        .data_out_11(ordered_b_11),
        .data_out_12(ordered_b_12),
        .data_out_13(ordered_b_13),
        .data_out_14(ordered_b_14),
        .data_out_15(ordered_b_15),
        .data_out_16(ordered_b_16),
        .data_out_17(ordered_b_17),
        .data_out_18(ordered_b_18),
        .data_out_19(ordered_b_19),
        .data_out_20(ordered_b_20),
        .data_out_21(ordered_b_21),
        .data_out_22(ordered_b_22),
        .data_out_23(ordered_b_23),
        .data_out_24(ordered_b_24),
        .isOrdered(order_b_en)
    );
    
    // 第二级：Transpose模块的en（延迟一拍）
    always@(order_a_en or order_b_en) begin
        // 只有在同时算好或都被重置时才触发
        if (order_a_en == order_b_en)
        en_delay <= order_a_en;  // 这里其实也是个锁存器
    end
    assign internal_en = en_delay;
    
    // busy状态触发器
    always@(en) begin
        if (en) begin
            busy <= 1;
        end
    end

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
                a_row_0 = ordered_a_0;
                a_row_1 = ordered_a_1;
                a_row_2 = ordered_a_2;
                a_row_3 = ordered_a_3;
                a_row_4 = ordered_a_4;
            end
            3'd1: begin
                a_row_0 = ordered_a_5;
                a_row_1 = ordered_a_6;
                a_row_2 = ordered_a_7;
                a_row_3 = ordered_a_8;
                a_row_4 = ordered_a_9;
            end
            3'd2: begin
                a_row_0 = ordered_a_10;
                a_row_1 = ordered_a_11;
                a_row_2 = ordered_a_12;
                a_row_3 = ordered_a_13;
                a_row_4 = ordered_a_14;
            end
            3'd3: begin
                a_row_0 = ordered_a_15;
                a_row_1 = ordered_a_16;
                a_row_2 = ordered_a_17;
                a_row_3 = ordered_a_18;
                a_row_4 = ordered_a_19;
            end
            3'd4: begin
                a_row_0 = ordered_a_20;
                a_row_1 = ordered_a_21;
                a_row_2 = ordered_a_22;
                a_row_3 = ordered_a_23;
                a_row_4 = ordered_a_24;
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
                b_row_0 = ordered_b_0;
                b_row_1 = ordered_b_1;
                b_row_2 = ordered_b_2;
                b_row_3 = ordered_b_3;
                b_row_4 = ordered_b_4;
            end
            3'd1: begin
                b_row_0 = ordered_b_5;
                b_row_1 = ordered_b_6;
                b_row_2 = ordered_b_7;
                b_row_3 = ordered_b_8;
                b_row_4 = ordered_b_9;
            end
            3'd2: begin
                b_row_0 = ordered_b_10;
                b_row_1 = ordered_b_11;
                b_row_2 = ordered_b_12;
                b_row_3 = ordered_b_13;
                b_row_4 = ordered_b_14;
            end
            3'd3: begin
                b_row_0 = ordered_b_15;
                b_row_1 = ordered_b_16;
                b_row_2 = ordered_b_17;
                b_row_3 = ordered_b_18;
                b_row_4 = ordered_b_19;
            end
            3'd4: begin
                b_row_0 = ordered_b_20;
                b_row_1 = ordered_b_21;
                b_row_2 = ordered_b_22;
                b_row_3 = ordered_b_23;
                b_row_4 = ordered_b_24;
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
    reg internal_busy;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // 复位所有寄存器和输出
            row_counter <= 0;
            busy <= 0;
            internal_busy <= 0;
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
            if (internal_en && !internal_busy && !isCalculated) begin
                // 检查矩阵是否可以相加（维度必须相等）
                if (r1 == r2 && c1 == c2) begin
                    r_out <= r1;
                    c_out <= c1;
                    internal_busy <= 1;
                    row_counter <= 0;
                    isValid <= 1;
                end 
                else begin
                    // 维度不匹配，无效操作
                    isValid <= 0;
                end
            end else if (internal_busy) begin
                // 忙状态：进行计算和存储
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
                    internal_busy <= 0;
                    isCalculated <= 1;
                    row_counter <= 0;
                end
            end else if (!en) begin
                // 复位所有寄存器和输出
                row_counter <= 0;
                busy <= 0;
                internal_busy <= 0;
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