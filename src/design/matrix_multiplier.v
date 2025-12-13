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
    // 内部信号
    wire order_a_en, order_b_en;
    wire internal_en;
    reg en_delay;  // en延迟一拍
    
    // ==================== 新增：两个Order模块实例化 ====================
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
                a_elem_0 = ordered_a_0;
                a_elem_1 = ordered_a_1;
                a_elem_2 = ordered_a_2;
                a_elem_3 = ordered_a_3;
                a_elem_4 = ordered_a_4;
            end
            3'd1: begin
                a_elem_0 = ordered_a_5;
                a_elem_1 = ordered_a_6;
                a_elem_2 = ordered_a_7;
                a_elem_3 = ordered_a_8;
                a_elem_4 = ordered_a_9;
            end
            3'd2: begin
                a_elem_0 = ordered_a_10;
                a_elem_1 = ordered_a_11;
                a_elem_2 = ordered_a_12;
                a_elem_3 = ordered_a_13;
                a_elem_4 = ordered_a_14;
            end
            3'd3: begin
                a_elem_0 = ordered_a_15;
                a_elem_1 = ordered_a_16;
                a_elem_2 = ordered_a_17;
                a_elem_3 = ordered_a_18;
                a_elem_4 = ordered_a_19;
            end
            3'd4: begin
                a_elem_0 = ordered_a_20;
                a_elem_1 = ordered_a_21;
                a_elem_2 = ordered_a_22;
                a_elem_3 = ordered_a_23;
                a_elem_4 = ordered_a_24;
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
                b_elem_0 = ordered_b_0;
                b_elem_1 = ordered_b_5;
                b_elem_2 = ordered_b_10;
                b_elem_3 = ordered_b_15;
                b_elem_4 = ordered_b_20;
            end
            3'd1: begin
                b_elem_0 = ordered_b_1;
                b_elem_1 = ordered_b_6;
                b_elem_2 = ordered_b_11;
                b_elem_3 = ordered_b_16;
                b_elem_4 = ordered_b_21;
            end
            3'd2: begin
                b_elem_0 = ordered_b_2;
                b_elem_1 = ordered_b_7;
                b_elem_2 = ordered_b_12;
                b_elem_3 = ordered_b_17;
                b_elem_4 = ordered_b_22;
            end
            3'd3: begin
                b_elem_0 = ordered_b_3;
                b_elem_1 = ordered_b_8;
                b_elem_2 = ordered_b_13;
                b_elem_3 = ordered_b_18;
                b_elem_4 = ordered_b_23;
            end
            3'd4: begin
                b_elem_0 = ordered_b_4;
                b_elem_1 = ordered_b_9;
                b_elem_2 = ordered_b_14;
                b_elem_3 = ordered_b_19;
                b_elem_4 = ordered_b_24;
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
    reg internal_busy;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // 复位所有寄存器和输出
            calc_counter <= 0;
            busy <= 0;
            isValid <= 1;
            internal_busy <= 0;
            r_out <= 0;
            c_out <= 0;
            isCalculated <= 0;
            
            data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
            data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
            data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
            data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
            data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
        end else begin
            if (internal_en && !internal_busy && !isCalculated) begin
                if (c1 == r2) begin
                    r_out <= r1;
                    c_out <= c2;
                    internal_busy <= 1;
                    calc_counter <= 0;
                    isValid <= 1;
                end
                else begin
                    // 维度不匹配，无效操作
                    isValid <= 0;
                end
            end else if (internal_busy) begin
                // 忙状态：进行计算和存储
                // 正在计算：存储上一个时钟周期的结果
                case(calc_counter)
                    0: data_out_0 <= sum_result;
                    1: data_out_1 <= sum_result;
                    2: data_out_2 <= sum_result;
                    3: data_out_3 <= sum_result;
                    4: data_out_4 <= sum_result;
                    5: data_out_5 <= sum_result;
                    6: data_out_6 <= sum_result;
                    7: data_out_7 <= sum_result;
                    8: data_out_8 <= sum_result;
                    9: data_out_9 <= sum_result;
                    10: data_out_10 <= sum_result;
                    11: data_out_11 <= sum_result;
                    12: data_out_12 <= sum_result;
                    13: data_out_13 <= sum_result;
                    14: data_out_14 <= sum_result;
                    15: data_out_15 <= sum_result;
                    16: data_out_16 <= sum_result;
                    17: data_out_17 <= sum_result;
                    18: data_out_18 <= sum_result;
                    19: data_out_19 <= sum_result;
                    20: data_out_20 <= sum_result;
                    21: data_out_21 <= sum_result;
                    22: data_out_22 <= sum_result;
                    23: data_out_23 <= sum_result;
                    24: data_out_24 <= sum_result;
                endcase
                
                // 递增计数器
                if (calc_counter < 24) begin
                    calc_counter <= calc_counter + 1;
                end else begin
                    // 完成所有25个元素的计算
                    busy <= 0;
                    internal_busy <= 0;
                    isCalculated <= 1;
                    calc_counter <= 0;
                end
            end else if (!en) begin
                // 复位所有寄存器和输出
                calc_counter <= 0;
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
