module matrix_restore #(
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
    output reg isRestored
);

    // === 计数器控制 ===
    reg [4:0] pos_counter;     // 0-24位置计数器（遍历5×5矩阵）
    reg [4:0] output_count;   // 输出索引计数器（连续存储位置）
    
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
    
    // === 输出数据向量 ===
    reg [DATA_WIDTH-1:0] temp_out [24:0];
    
    // === 状态控制 ===
    reg processing;
    reg initialized;
    
    // === 时序控制逻辑 ===
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // 复位所有状态
            pos_counter <= 0;
            output_count <= 0;
            processing <= 0;
            initialized <= 0;
            isRestored <= 0;
            
            // 复位所有输出为0
            data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
            data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
            data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
            data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
            data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
            
            // 清空临时输出
            temp_out[0] <= 0; temp_out[1] <= 0; temp_out[2] <= 0; temp_out[3] <= 0; temp_out[4] <= 0;
            temp_out[5] <= 0; temp_out[6] <= 0; temp_out[7] <= 0; temp_out[8] <= 0; temp_out[9] <= 0;
            temp_out[10] <= 0; temp_out[11] <= 0; temp_out[12] <= 0; temp_out[13] <= 0; temp_out[14] <= 0;
            temp_out[15] <= 0; temp_out[16] <= 0; temp_out[17] <= 0; temp_out[18] <= 0; temp_out[19] <= 0;
            temp_out[20] <= 0; temp_out[21] <= 0; temp_out[22] <= 0; temp_out[23] <= 0; temp_out[24] <= 0;
        end else begin
            if (en && !processing && !isRestored) begin
                // 开始处理：初始化
                if (!initialized) begin
                    initialized <= 1;
                    processing <= 1;
                    pos_counter <= 0;
                    output_count <= 0;
                    // 复位所有输出为0
                    data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
                    data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
                    data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
                    data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
                    data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
                    // 初始化所有临时输出为0
                    temp_out[0] <= 0; temp_out[1] <= 0; temp_out[2] <= 0; temp_out[3] <= 0; temp_out[4] <= 0;
                    temp_out[5] <= 0; temp_out[6] <= 0; temp_out[7] <= 0; temp_out[8] <= 0; temp_out[9] <= 0;
                    temp_out[10] <= 0; temp_out[11] <= 0; temp_out[12] <= 0; temp_out[13] <= 0; temp_out[14] <= 0;
                    temp_out[15] <= 0; temp_out[16] <= 0; temp_out[17] <= 0; temp_out[18] <= 0; temp_out[19] <= 0;
                    temp_out[20] <= 0; temp_out[21] <= 0; temp_out[22] <= 0; temp_out[23] <= 0; temp_out[24] <= 0;
                end
            end else if (processing) begin
                // 正在处理：执行恢复逻辑
                
                // 检查当前位置是否在有效矩阵范围内
                if (row_idx < r && col_idx < c) begin
                    // 在有效区域内：将当前输入数据复制到连续输出位置
                    if (output_count < 25) begin
                        temp_out[output_count] <= data_vec[pos_counter];
                        output_count <= output_count + 1;
                    end
                end
                // 不在有效区域：不复制数据（保持为0）
                
                // 移动到下一个位置
                if (pos_counter < 24) begin
                    pos_counter <= pos_counter + 1;
                end else begin
                    // 已完成所有25个位置的处理
                    // 将临时输出复制到实际输出
                    data_out_0 <= temp_out[0];
                    data_out_1 <= temp_out[1];
                    data_out_2 <= temp_out[2];
                    data_out_3 <= temp_out[3];
                    data_out_4 <= temp_out[4];
                    data_out_5 <= temp_out[5];
                    data_out_6 <= temp_out[6];
                    data_out_7 <= temp_out[7];
                    data_out_8 <= temp_out[8];
                    data_out_9 <= temp_out[9];
                    data_out_10 <= temp_out[10];
                    data_out_11 <= temp_out[11];
                    data_out_12 <= temp_out[12];
                    data_out_13 <= temp_out[13];
                    data_out_14 <= temp_out[14];
                    data_out_15 <= temp_out[15];
                    data_out_16 <= temp_out[16];
                    data_out_17 <= temp_out[17];
                    data_out_18 <= temp_out[18];
                    data_out_19 <= temp_out[19];
                    data_out_20 <= temp_out[20];
                    data_out_21 <= temp_out[21];
                    data_out_22 <= temp_out[22];
                    data_out_23 <= temp_out[23];
                    data_out_24 <= temp_out[24];
                    
                    // 结束处理
                    processing <= 0;
                    initialized <= 0;
                    isRestored <= 1;
                end
            end else if (!en) begin
                // 当en为低时，重置处理状态
                processing <= 0;
                initialized <= 0;
                isRestored <= 0;
            end
        end
    end
endmodule