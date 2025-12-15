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
    // 内部信号
    wire order_en;
    wire internal_en;
    reg en_delay;  // en延迟一拍

    // ==================== Order模块实例化 ====================
    wire [DATA_WIDTH-1:0] ordered_data_0;
    wire [DATA_WIDTH-1:0] ordered_data_1;
    wire [DATA_WIDTH-1:0] ordered_data_2;
    wire [DATA_WIDTH-1:0] ordered_data_3;
    wire [DATA_WIDTH-1:0] ordered_data_4;
    wire [DATA_WIDTH-1:0] ordered_data_5;
    wire [DATA_WIDTH-1:0] ordered_data_6;
    wire [DATA_WIDTH-1:0] ordered_data_7;
    wire [DATA_WIDTH-1:0] ordered_data_8;
    wire [DATA_WIDTH-1:0] ordered_data_9;
    wire [DATA_WIDTH-1:0] ordered_data_10;
    wire [DATA_WIDTH-1:0] ordered_data_11;
    wire [DATA_WIDTH-1:0] ordered_data_12;
    wire [DATA_WIDTH-1:0] ordered_data_13;
    wire [DATA_WIDTH-1:0] ordered_data_14;
    wire [DATA_WIDTH-1:0] ordered_data_15;
    wire [DATA_WIDTH-1:0] ordered_data_16;
    wire [DATA_WIDTH-1:0] ordered_data_17;
    wire [DATA_WIDTH-1:0] ordered_data_18;
    wire [DATA_WIDTH-1:0] ordered_data_19;
    wire [DATA_WIDTH-1:0] ordered_data_20;
    wire [DATA_WIDTH-1:0] ordered_data_21;
    wire [DATA_WIDTH-1:0] ordered_data_22;
    wire [DATA_WIDTH-1:0] ordered_data_23;
    wire [DATA_WIDTH-1:0] ordered_data_24;
    matirx_order #(
        .DATA_WIDTH(DATA_WIDTH)
    ) order_inst (
        // 输入端口
        .clk(clk),
        .reset_n(reset_n),
        .r(r),
        .c(c),
        .data_in_0(data_in_0),
        .data_in_1(data_in_1),
        .data_in_2(data_in_2),
        .data_in_3(data_in_3),
        .data_in_4(data_in_4),
        .data_in_5(data_in_5),
        .data_in_6(data_in_6),
        .data_in_7(data_in_7),
        .data_in_8(data_in_8),
        .data_in_9(data_in_9),
        .data_in_10(data_in_10),
        .data_in_11(data_in_11),
        .data_in_12(data_in_12),
        .data_in_13(data_in_13),
        .data_in_14(data_in_14),
        .data_in_15(data_in_15),
        .data_in_16(data_in_16),
        .data_in_17(data_in_17),
        .data_in_18(data_in_18),
        .data_in_19(data_in_19),
        .data_in_20(data_in_20),
        .data_in_21(data_in_21),
        .data_in_22(data_in_22),
        .data_in_23(data_in_23),
        .data_in_24(data_in_24),
        .en(en),
        // 输出端口
        .data_out_0(ordered_data_0),
        .data_out_1(ordered_data_1),
        .data_out_2(ordered_data_2),
        .data_out_3(ordered_data_3),
        .data_out_4(ordered_data_4),
        .data_out_5(ordered_data_5),
        .data_out_6(ordered_data_6),
        .data_out_7(ordered_data_7),
        .data_out_8(ordered_data_8),
        .data_out_9(ordered_data_9),
        .data_out_10(ordered_data_10),
        .data_out_11(ordered_data_11),
        .data_out_12(ordered_data_12),
        .data_out_13(ordered_data_13),
        .data_out_14(ordered_data_14),
        .data_out_15(ordered_data_15),
        .data_out_16(ordered_data_16),
        .data_out_17(ordered_data_17),
        .data_out_18(ordered_data_18),
        .data_out_19(ordered_data_19),
        .data_out_20(ordered_data_20),
        .data_out_21(ordered_data_21),
        .data_out_22(ordered_data_22),
        .data_out_23(ordered_data_23),
        .data_out_24(ordered_data_24),
        .isOrdered(order_en)
    );
    
    // ==================== 标量乘法中转信号 ====================
    reg [DATA_WIDTH-1:0] scalar_data_0;
    reg [DATA_WIDTH-1:0] scalar_data_1;
    reg [DATA_WIDTH-1:0] scalar_data_2;
    reg [DATA_WIDTH-1:0] scalar_data_3;
    reg [DATA_WIDTH-1:0] scalar_data_4;
    reg [DATA_WIDTH-1:0] scalar_data_5;
    reg [DATA_WIDTH-1:0] scalar_data_6;
    reg [DATA_WIDTH-1:0] scalar_data_7;
    reg [DATA_WIDTH-1:0] scalar_data_8;
    reg [DATA_WIDTH-1:0] scalar_data_9;
    reg [DATA_WIDTH-1:0] scalar_data_10;
    reg [DATA_WIDTH-1:0] scalar_data_11;
    reg [DATA_WIDTH-1:0] scalar_data_12;
    reg [DATA_WIDTH-1:0] scalar_data_13;
    reg [DATA_WIDTH-1:0] scalar_data_14;
    reg [DATA_WIDTH-1:0] scalar_data_15;
    reg [DATA_WIDTH-1:0] scalar_data_16;
    reg [DATA_WIDTH-1:0] scalar_data_17;
    reg [DATA_WIDTH-1:0] scalar_data_18;
    reg [DATA_WIDTH-1:0] scalar_data_19;
    reg [DATA_WIDTH-1:0] scalar_data_20;
    reg [DATA_WIDTH-1:0] scalar_data_21;
    reg [DATA_WIDTH-1:0] scalar_data_22;
    reg [DATA_WIDTH-1:0] scalar_data_23;
    reg [DATA_WIDTH-1:0] scalar_data_24;
    
    // ==================== Restore模块实例化 ====================
    wire [DATA_WIDTH-1:0] restored_data_0;
    wire [DATA_WIDTH-1:0] restored_data_1;
    wire [DATA_WIDTH-1:0] restored_data_2;
    wire [DATA_WIDTH-1:0] restored_data_3;
    wire [DATA_WIDTH-1:0] restored_data_4;
    wire [DATA_WIDTH-1:0] restored_data_5;
    wire [DATA_WIDTH-1:0] restored_data_6;
    wire [DATA_WIDTH-1:0] restored_data_7;
    wire [DATA_WIDTH-1:0] restored_data_8;
    wire [DATA_WIDTH-1:0] restored_data_9;
    wire [DATA_WIDTH-1:0] restored_data_10;
    wire [DATA_WIDTH-1:0] restored_data_11;
    wire [DATA_WIDTH-1:0] restored_data_12;
    wire [DATA_WIDTH-1:0] restored_data_13;
    wire [DATA_WIDTH-1:0] restored_data_14;
    wire [DATA_WIDTH-1:0] restored_data_15;
    wire [DATA_WIDTH-1:0] restored_data_16;
    wire [DATA_WIDTH-1:0] restored_data_17;
    wire [DATA_WIDTH-1:0] restored_data_18;
    wire [DATA_WIDTH-1:0] restored_data_19;
    wire [DATA_WIDTH-1:0] restored_data_20;
    wire [DATA_WIDTH-1:0] restored_data_21;
    wire [DATA_WIDTH-1:0] restored_data_22;
    wire [DATA_WIDTH-1:0] restored_data_23;
    wire [DATA_WIDTH-1:0] restored_data_24;
    wire isRestored;
    reg restore_en;
    matrix_restore #(
        .DATA_WIDTH(DATA_WIDTH)
    ) restore_inst (
        .clk(clk),
        .reset_n(reset_n),
        .r(r),
        .c(c),
        .data_in_0(scalar_data_0),
        .data_in_1(scalar_data_1),
        .data_in_2(scalar_data_2),
        .data_in_3(scalar_data_3),
        .data_in_4(scalar_data_4),
        .data_in_5(scalar_data_5),
        .data_in_6(scalar_data_6),
        .data_in_7(scalar_data_7),
        .data_in_8(scalar_data_8),
        .data_in_9(scalar_data_9),
        .data_in_10(scalar_data_10),
        .data_in_11(scalar_data_11),
        .data_in_12(scalar_data_12),
        .data_in_13(scalar_data_13),
        .data_in_14(scalar_data_14),
        .data_in_15(scalar_data_15),
        .data_in_16(scalar_data_16),
        .data_in_17(scalar_data_17),
        .data_in_18(scalar_data_18),
        .data_in_19(scalar_data_19),
        .data_in_20(scalar_data_20),
        .data_in_21(scalar_data_21),
        .data_in_22(scalar_data_22),
        .data_in_23(scalar_data_23),
        .data_in_24(scalar_data_24),
        .en(restore_en),
        .data_out_0(restored_data_0),
        .data_out_1(restored_data_1),
        .data_out_2(restored_data_2),
        .data_out_3(restored_data_3),
        .data_out_4(restored_data_4),
        .data_out_5(restored_data_5),
        .data_out_6(restored_data_6),
        .data_out_7(restored_data_7),
        .data_out_8(restored_data_8),
        .data_out_9(restored_data_9),
        .data_out_10(restored_data_10),
        .data_out_11(restored_data_11),
        .data_out_12(restored_data_12),
        .data_out_13(restored_data_13),
        .data_out_14(restored_data_14),
        .data_out_15(restored_data_15),
        .data_out_16(restored_data_16),
        .data_out_17(restored_data_17),
        .data_out_18(restored_data_18),
        .data_out_19(restored_data_19),
        .data_out_20(restored_data_20),
        .data_out_21(restored_data_21),
        .data_out_22(restored_data_22),
        .data_out_23(restored_data_23),
        .data_out_24(restored_data_24),
        .isRestored(isRestored)
    );
    
    // 第二级：Transpose模块的en（延迟一拍）
    always@(order_en) begin
        en_delay <= order_en;  // 这里其实也是个锁存器
    end
    assign internal_en = en_delay;
    /*
    // busy状态触发器
    always@(en) begin
        if (en) begin
            busy <= 1;
        end
    end 
    */
    
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
                mat_row_0 <= ordered_data_0;
                mat_row_1 <= ordered_data_1;
                mat_row_2 <= ordered_data_2;
                mat_row_3 <= ordered_data_3;
                mat_row_4 <= ordered_data_4;
            end
            3'd1: begin
                mat_row_0 <= ordered_data_5;
                mat_row_1 <= ordered_data_6;
                mat_row_2 <= ordered_data_7;
                mat_row_3 <= ordered_data_8;
                mat_row_4 <= ordered_data_9;
            end
            3'd2: begin
                mat_row_0 <= ordered_data_10;
                mat_row_1 <= ordered_data_11;
                mat_row_2 <= ordered_data_12;
                mat_row_3 <= ordered_data_13;
                mat_row_4 <= ordered_data_14;
            end
            3'd3: begin
                mat_row_0 <= ordered_data_15;
                mat_row_1 <= ordered_data_16;
                mat_row_2 <= ordered_data_17;
                mat_row_3 <= ordered_data_18;
                mat_row_4 <= ordered_data_19;
            end
            3'd4: begin
                mat_row_0 <= ordered_data_20;
                mat_row_1 <= ordered_data_21;
                mat_row_2 <= ordered_data_22;
                mat_row_3 <= ordered_data_23;
                mat_row_4 <= ordered_data_24;
            end
            default: begin
                mat_row_0 <= 0;
                mat_row_1 <= 0;
                mat_row_2 <= 0;
                mat_row_3 <= 0;
                mat_row_4 <= 0;
            end
        endcase
    end
    
    // === 时序控制逻辑 ===
    reg isCalculated;
    reg internal_busy;
    reg isCompleted;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // 复位所有寄存器和输出
            row_counter <= 0;
            busy <= 0;
            internal_busy <= 0;
            r_out <= 0;
            c_out <= 0;
            isCalculated <= 0;
            scalar_reg <= 0;
            restore_en <= 0;
            
            // 复位中转数据
            scalar_data_0 <= 0; scalar_data_1 <= 0; scalar_data_2 <= 0; scalar_data_3 <= 0; scalar_data_4 <= 0;
            scalar_data_5 <= 0; scalar_data_6 <= 0; scalar_data_7 <= 0; scalar_data_8 <= 0; scalar_data_9 <= 0;
            scalar_data_10 <= 0; scalar_data_11 <= 0; scalar_data_12 <= 0; scalar_data_13 <= 0; scalar_data_14 <= 0;
            scalar_data_15 <= 0; scalar_data_16 <= 0; scalar_data_17 <= 0; scalar_data_18 <= 0; scalar_data_19 <= 0;
            scalar_data_20 <= 0; scalar_data_21 <= 0; scalar_data_22 <= 0; scalar_data_23 <= 0; scalar_data_24 <= 0;
            // 清空所有输出
            data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
            data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
            data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
            data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
            data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
        end else begin
            if(en && !isCompleted) begin
                busy <= 1;
            end else begin
                busy <= 0;
            end
            if (internal_en && !internal_busy && !isCalculated) begin
                // 开始新计算：锁存标量值和矩阵维度
                scalar_reg <= scalar;
                r_out <= r;
                c_out <= c;
                internal_busy <= 1;
                row_counter <= 0;
            end else if (internal_busy) begin
                // 忙状态：进行计算和存储
                // 在当前时钟沿，result已经包含了一整行的计算结果
                // 将这5个结果复制到对应的5个输出位置
                case(row_counter)
                    3'd0: begin
                        scalar_data_0 <= result_0;
                        scalar_data_1 <= result_1;
                        scalar_data_2 <= result_2;
                        scalar_data_3 <= result_3;
                        scalar_data_4 <= result_4;
                    end
                    3'd1: begin
                        scalar_data_5 <= result_0;
                        scalar_data_6 <= result_1;
                        scalar_data_7 <= result_2;
                        scalar_data_8 <= result_3;
                        scalar_data_9 <= result_4;
                    end
                    3'd2: begin
                        scalar_data_10 <= result_0;
                        scalar_data_11 <= result_1;
                        scalar_data_12 <= result_2;
                        scalar_data_13 <= result_3;
                        scalar_data_14 <= result_4;
                    end
                    3'd3: begin
                        scalar_data_15 <= result_0;
                        scalar_data_16 <= result_1;
                        scalar_data_17 <= result_2;
                        scalar_data_18 <= result_3;
                        scalar_data_19 <= result_4;
                    end
                    3'd4: begin
                        scalar_data_20 <= result_0;
                        scalar_data_21 <= result_1;
                        scalar_data_22 <= result_2;
                        scalar_data_23 <= result_3;
                        scalar_data_24 <= result_4;
                    end
                endcase
                
                // 递增行计数器（除了最后一行）
                if (row_counter < 4) begin
                    row_counter <= row_counter + 1;
                end else begin
                    // 完成所有5行元素的计算
                    
                    internal_busy <= 0;
                    isCalculated <= 1;
                    row_counter <= 0;
                    restore_en <= 1;
                end
            end else if (isRestored) begin
                // restore完成后，输出最终结果
                data_out_0 <= restored_data_0;
                data_out_1 <= restored_data_1;
                data_out_2 <= restored_data_2;
                data_out_3 <= restored_data_3;
                data_out_4 <= restored_data_4;
                data_out_5 <= restored_data_5;
                data_out_6 <= restored_data_6;
                data_out_7 <= restored_data_7;
                data_out_8 <= restored_data_8;
                data_out_9 <= restored_data_9;
                data_out_10 <= restored_data_10;
                data_out_11 <= restored_data_11;
                data_out_12 <= restored_data_12;
                data_out_13 <= restored_data_13;
                data_out_14 <= restored_data_14;
                data_out_15 <= restored_data_15;
                data_out_16 <= restored_data_16;
                data_out_17 <= restored_data_17;
                data_out_18 <= restored_data_18;
                data_out_19 <= restored_data_19;
                data_out_20 <= restored_data_20;
                data_out_21 <= restored_data_21;
                data_out_22 <= restored_data_22;
                data_out_23 <= restored_data_23;
                data_out_24 <= restored_data_24;
                
                restore_en <= 0;
                isCompleted <= 1;
            end else if (!en) begin
                // 复位所有寄存器和输出
                row_counter <= 0;
                busy <= 0;
                internal_busy <= 0;
                r_out <= 0;
                c_out <= 0;
                isCalculated <= 0;
                restore_en <= 0;
                isCompleted <= 0;
                
                // 复位中转数据
                scalar_data_0 <= 0; scalar_data_1 <= 0; scalar_data_2 <= 0; scalar_data_3 <= 0; scalar_data_4 <= 0;
                scalar_data_5 <= 0; scalar_data_6 <= 0; scalar_data_7 <= 0; scalar_data_8 <= 0; scalar_data_9 <= 0;
                scalar_data_10 <= 0; scalar_data_11 <= 0; scalar_data_12 <= 0; scalar_data_13 <= 0; scalar_data_14 <= 0;
                scalar_data_15 <= 0; scalar_data_16 <= 0; scalar_data_17 <= 0; scalar_data_18 <= 0; scalar_data_19 <= 0;
                scalar_data_20 <= 0; scalar_data_21 <= 0; scalar_data_22 <= 0; scalar_data_23 <= 0; scalar_data_24 <= 0;
                // 复位输出信号
                data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
                data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
                data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
                data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
                data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
            end
        end
    end
endmodule