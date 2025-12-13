module matirx_order#(
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
    output reg [DATA_WIDTH-1:0] data_out_24,
    output reg isOrdered
    );
    // === 计数器控制 ===
    reg [4:0] pos_counter;     // 0-24位置计数器
    
    // === 行列坐标计算 ===
    wire [2:0] row_idx;
    wire [2:0] col_idx;
    assign row_idx = pos_counter / 5;  // 行号 = counter ÷ 5
    assign col_idx = pos_counter % 5;  // 列号 = counter % 5
    
    // === 输入数据向量（便于索引）===
    wire [DATA_WIDTH-1:0] data_vec [24:0];
    
    // 连接所有输入到向量
    assign data_vec[0] = data_in_0;
    assign data_vec[1] = data_in_1;
    assign data_vec[2] = data_in_2;
    assign data_vec[3] = data_in_3;
    assign data_vec[4] = data_in_4;
    assign data_vec[5] = data_in_5;
    assign data_vec[6] = data_in_6;
    assign data_vec[7] = data_in_7;
    assign data_vec[8] = data_in_8;
    assign data_vec[9] = data_in_9;
    assign data_vec[10] = data_in_10;
    assign data_vec[11] = data_in_11;
    assign data_vec[12] = data_in_12;
    assign data_vec[13] = data_in_13;
    assign data_vec[14] = data_in_14;
    assign data_vec[15] = data_in_15;
    assign data_vec[16] = data_in_16;
    assign data_vec[17] = data_in_17;
    assign data_vec[18] = data_in_18;
    assign data_vec[19] = data_in_19;
    assign data_vec[20] = data_in_20;
    assign data_vec[21] = data_in_21;
    assign data_vec[22] = data_in_22;
    assign data_vec[23] = data_in_23;
    assign data_vec[24] = data_in_24;
    
    // === 输入索引指针 ===
    reg [4:0] input_idx;        // 当前已使用的输入索引 (0-24)
    
    // === 临时输出寄存器 ===
    reg [DATA_WIDTH-1:0] temp_out_0, temp_out_1, temp_out_2, temp_out_3, temp_out_4;
    reg [DATA_WIDTH-1:0] temp_out_5, temp_out_6, temp_out_7, temp_out_8, temp_out_9;
    reg [DATA_WIDTH-1:0] temp_out_10, temp_out_11, temp_out_12, temp_out_13, temp_out_14;
    reg [DATA_WIDTH-1:0] temp_out_15, temp_out_16, temp_out_17, temp_out_18, temp_out_19;
    reg [DATA_WIDTH-1:0] temp_out_20, temp_out_21, temp_out_22, temp_out_23, temp_out_24;
    
    // === 状态控制 ===
    reg processing;
    reg initialized;
    
    // === 时序控制逻辑 ===
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // 复位所有状态
            pos_counter <= 0;
            input_idx <= 0;
            processing <= 0;
            initialized <= 0;
            isOrdered <= 0;
            
            // 复位所有输出为0
            data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
            data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
            data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
            data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
            data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
            
            // 清空临时输出
            temp_out_0 <= 0; temp_out_1 <= 0; temp_out_2 <= 0; temp_out_3 <= 0; temp_out_4 <= 0;
            temp_out_5 <= 0; temp_out_6 <= 0; temp_out_7 <= 0; temp_out_8 <= 0; temp_out_9 <= 0;
            temp_out_10 <= 0; temp_out_11 <= 0; temp_out_12 <= 0; temp_out_13 <= 0; temp_out_14 <= 0;
            temp_out_15 <= 0; temp_out_16 <= 0; temp_out_17 <= 0; temp_out_18 <= 0; temp_out_19 <= 0;
            temp_out_20 <= 0; temp_out_21 <= 0; temp_out_22 <= 0; temp_out_23 <= 0; temp_out_24 <= 0;
        end else begin
            if (en && !processing && !isOrdered) begin
                // 开始处理：初始化所有临时输出为0
                if (!initialized) begin
                    initialized <= 1;
                    processing <= 1;
                    pos_counter <= 0;
                    input_idx <= 0;
                    // 初始化临时输出
                    temp_out_0 <= 0; temp_out_1 <= 0; temp_out_2 <= 0; temp_out_3 <= 0; temp_out_4 <= 0;
                    temp_out_5 <= 0; temp_out_6 <= 0; temp_out_7 <= 0; temp_out_8 <= 0; temp_out_9 <= 0;
                    temp_out_10 <= 0; temp_out_11 <= 0; temp_out_12 <= 0; temp_out_13 <= 0; temp_out_14 <= 0;
                    temp_out_15 <= 0; temp_out_16 <= 0; temp_out_17 <= 0; temp_out_18 <= 0; temp_out_19 <= 0;
                    temp_out_20 <= 0; temp_out_21 <= 0; temp_out_22 <= 0; temp_out_23 <= 0; temp_out_24 <= 0;
                end
            end else if (processing) begin
                // 正在处理：执行您的算法逻辑
                // 检查当前位置是否在有效矩阵范围内
                if (row_idx < r && col_idx < c) begin
                    // 在有效区域内
                    if (input_idx < 25) begin
                       case(pos_counter)
                            0: temp_out_0 <= data_vec[input_idx];
                            1: temp_out_1 <= data_vec[input_idx];
                            2: temp_out_2 <= data_vec[input_idx];
                            3: temp_out_3 <= data_vec[input_idx];
                            4: temp_out_4 <= data_vec[input_idx];
                            5: temp_out_5 <= data_vec[input_idx];
                            6: temp_out_6 <= data_vec[input_idx];
                            7: temp_out_7 <= data_vec[input_idx];
                            8: temp_out_8 <= data_vec[input_idx];
                            9: temp_out_9 <= data_vec[input_idx];
                            10: temp_out_10 <= data_vec[input_idx];
                            11: temp_out_11 <= data_vec[input_idx];
                            12: temp_out_12 <= data_vec[input_idx];
                            13: temp_out_13 <= data_vec[input_idx];
                            14: temp_out_14 <= data_vec[input_idx];
                            15: temp_out_15 <= data_vec[input_idx];
                            16: temp_out_16 <= data_vec[input_idx];
                            17: temp_out_17 <= data_vec[input_idx];
                            18: temp_out_18 <= data_vec[input_idx];
                            19: temp_out_19 <= data_vec[input_idx];
                            20: temp_out_20 <= data_vec[input_idx];
                            21: temp_out_21 <= data_vec[input_idx];
                            22: temp_out_22 <= data_vec[input_idx];
                            23: temp_out_23 <= data_vec[input_idx];
                            24: temp_out_24 <= data_vec[input_idx];
                        endcase
                        input_idx <= input_idx + 1;
                    end
                end
                // 否则：保持为0（已经在初始化中设置）
                
                // 移动到下一个位置
                if (pos_counter < 24) begin
                    pos_counter <= pos_counter + 1;
                end else begin
                    // 已完成所有25个位置的处理
                    // 将临时输出复制到实际输出
                    data_out_0 <= temp_out_0;
                    data_out_1 <= temp_out_1;
                    data_out_2 <= temp_out_2;
                    data_out_3 <= temp_out_3;
                    data_out_4 <= temp_out_4;
                    data_out_5 <= temp_out_5;
                    data_out_6 <= temp_out_6;
                    data_out_7 <= temp_out_7;
                    data_out_8 <= temp_out_8;
                    data_out_9 <= temp_out_9;
                    data_out_10 <= temp_out_10;
                    data_out_11 <= temp_out_11;
                    data_out_12 <= temp_out_12;
                    data_out_13 <= temp_out_13;
                    data_out_14 <= temp_out_14;
                    data_out_15 <= temp_out_15;
                    data_out_16 <= temp_out_16;
                    data_out_17 <= temp_out_17;
                    data_out_18 <= temp_out_18;
                    data_out_19 <= temp_out_19;
                    data_out_20 <= temp_out_20;
                    data_out_21 <= temp_out_21;
                    data_out_22 <= temp_out_22;
                    data_out_23 <= temp_out_23;
                    data_out_24 <= temp_out_24;
                    
                    // 结束处理
                    processing <= 0;
                    initialized <= 0;
                    isOrdered <= 1;
                end
            end else if (!en) begin
                // 当en为低时，重置处理状态
                processing <= 0;
                initialized <= 0;
                isOrdered <= 0;
            end
        end
    end
endmodule
