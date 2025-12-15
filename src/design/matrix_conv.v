module matrix_conv#(
    parameter DATA_WIDTH = 9
) (
    input clk,
    input reset_n,
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
    output reg [DATA_WIDTH-1:0] data_out_25,
    output reg [DATA_WIDTH-1:0] data_out_26,
    output reg [DATA_WIDTH-1:0] data_out_27,
    output reg [DATA_WIDTH-1:0] data_out_28,
    output reg [DATA_WIDTH-1:0] data_out_29,
    output reg [DATA_WIDTH-1:0] data_out_30,
    output reg [DATA_WIDTH-1:0] data_out_31,
    output reg [DATA_WIDTH-1:0] data_out_32,
    output reg [DATA_WIDTH-1:0] data_out_33,
    output reg [DATA_WIDTH-1:0] data_out_34,
    output reg [DATA_WIDTH-1:0] data_out_35,
    output reg [DATA_WIDTH-1:0] data_out_36,
    output reg [DATA_WIDTH-1:0] data_out_37,
    output reg [DATA_WIDTH-1:0] data_out_38,
    output reg [DATA_WIDTH-1:0] data_out_39,
    output reg [DATA_WIDTH-1:0] data_out_40,
    output reg [DATA_WIDTH-1:0] data_out_41,
    output reg [DATA_WIDTH-1:0] data_out_42,
    output reg [DATA_WIDTH-1:0] data_out_43,
    output reg [DATA_WIDTH-1:0] data_out_44,
    output reg [DATA_WIDTH-1:0] data_out_45,
    output reg [DATA_WIDTH-1:0] data_out_46,
    output reg [DATA_WIDTH-1:0] data_out_47,
    output reg [DATA_WIDTH-1:0] data_out_48,
    output reg [DATA_WIDTH-1:0] data_out_49,
    output reg [DATA_WIDTH-1:0] data_out_50,
    output reg [DATA_WIDTH-1:0] data_out_51,
    output reg [DATA_WIDTH-1:0] data_out_52,
    output reg [DATA_WIDTH-1:0] data_out_53,
    output reg [DATA_WIDTH-1:0] data_out_54,
    output reg [DATA_WIDTH-1:0] data_out_55,
    output reg [DATA_WIDTH-1:0] data_out_56,
    output reg [DATA_WIDTH-1:0] data_out_57,
    output reg [DATA_WIDTH-1:0] data_out_58,
    output reg [DATA_WIDTH-1:0] data_out_59,
    output reg [DATA_WIDTH-1:0] data_out_60,
    output reg [DATA_WIDTH-1:0] data_out_61,
    output reg [DATA_WIDTH-1:0] data_out_62,
    output reg [DATA_WIDTH-1:0] data_out_63,
    output reg [DATA_WIDTH-1:0] data_out_64,
    output reg [DATA_WIDTH-1:0] data_out_65,
    output reg [DATA_WIDTH-1:0] data_out_66,
    output reg [DATA_WIDTH-1:0] data_out_67,
    output reg [DATA_WIDTH-1:0] data_out_68,
    output reg [DATA_WIDTH-1:0] data_out_69,
    output reg [DATA_WIDTH-1:0] data_out_70,
    output reg [DATA_WIDTH-1:0] data_out_71,
    output reg [DATA_WIDTH-1:0] data_out_72,
    output reg [DATA_WIDTH-1:0] data_out_73,
    output reg [DATA_WIDTH-1:0] data_out_74,
    output reg [DATA_WIDTH-1:0] data_out_75,
    output reg [DATA_WIDTH-1:0] data_out_76,
    output reg [DATA_WIDTH-1:0] data_out_77,
    output reg [DATA_WIDTH-1:0] data_out_78,
    output reg [DATA_WIDTH-1:0] data_out_79,
    output reg busy
    );
    // === ROM 定义 ===
    reg [3:0] rom [0:119];
    
    // === 位置索引 ===
    reg [6:0] conv_counter;      // 0-79计数器，对应80个输出位置
    reg [3:0] row_start_idx;     // 当前卷积窗口左上角行位置 (0-7)
    reg [3:0] col_start_idx;     // 当前卷积窗口左上角列位置 (0-9)
    
    // === 从ROM中提取3×3窗口 ===
    reg [3:0] rom_window_0, rom_window_1, rom_window_2;   // 第一行
    reg [3:0] rom_window_3, rom_window_4, rom_window_5;   // 第二行
    reg [3:0] rom_window_6, rom_window_7, rom_window_8;   // 第三行
    
    // === 9个并行乘法器 ===
    wire [DATA_WIDTH-1:0] kernel_val_0, kernel_val_1, kernel_val_2;
    wire [DATA_WIDTH-1:0] kernel_val_3, kernel_val_4, kernel_val_5;
    wire [DATA_WIDTH-1:0] kernel_val_6, kernel_val_7, kernel_val_8;
    
    // 卷积核值
    assign kernel_val_0 = data_in_0;  // (0,0)
    assign kernel_val_1 = data_in_1;  // (0,1)
    assign kernel_val_2 = data_in_2;  // (0,2)
    assign kernel_val_3 = data_in_3;  // (1,0)
    assign kernel_val_4 = data_in_4;  // (1,1)
    assign kernel_val_5 = data_in_5;  // (1,2)
    assign kernel_val_6 = data_in_6;  // (2,0)
    assign kernel_val_7 = data_in_7;  // (2,1)
    assign kernel_val_8 = data_in_8;  // (2,2)
    
    // 乘法结果
    wire [DATA_WIDTH-1:0] mul_result_0, mul_result_1, mul_result_2;
    wire [DATA_WIDTH-1:0] mul_result_3, mul_result_4, mul_result_5;
    wire [DATA_WIDTH-1:0] mul_result_6, mul_result_7, mul_result_8;
    
    // 9个并行乘法
    assign mul_result_0 = kernel_val_0 * rom_window_0;
    assign mul_result_1 = kernel_val_1 * rom_window_1;
    assign mul_result_2 = kernel_val_2 * rom_window_2;
    assign mul_result_3 = kernel_val_3 * rom_window_3;
    assign mul_result_4 = kernel_val_4 * rom_window_4;
    assign mul_result_5 = kernel_val_5 * rom_window_5;
    assign mul_result_6 = kernel_val_6 * rom_window_6;
    assign mul_result_7 = kernel_val_7 * rom_window_7;
    assign mul_result_8 = kernel_val_8 * rom_window_8;
    
    // === 加法树（9个数求和） ===
    wire [DATA_WIDTH-1:0] final_sum;  // 最终和
    
    // 第一级加法：分成3组，每组3个
    wire [DATA_WIDTH-1:0] sum_group0, sum_group1, sum_group2;
    assign sum_group0 = mul_result_0 + mul_result_1 + mul_result_2;
    assign sum_group1 = mul_result_3 + mul_result_4 + mul_result_5;
    assign sum_group2 = mul_result_6 + mul_result_7 + mul_result_8;
    
    // 第二级加法：3组相加
    assign final_sum = sum_group0 + sum_group1 + sum_group2;
    
    // 初始化 ROM 内容
    initial begin
    // 第 1 行: 3 7 2 9 0 5 1 8 4 6 3 2
    rom[0] = 4'd3; rom[1] = 4'd7; rom[2] = 4'd2; rom[3] = 4'd9;
    rom[4] = 4'd0; rom[5] = 4'd5; rom[6] = 4'd1; rom[7] = 4'd8;
    rom[8] = 4'd4; rom[9] = 4'd6; rom[10] = 4'd3; rom[11] = 4'd2;
    // 第 2 行: 8 1 6 4 7 3 9 0 5 2 8 1
    rom[12] = 4'd8; rom[13] = 4'd1; rom[14] = 4'd6; rom[15] = 4'd4;
    rom[16] = 4'd7; rom[17] = 4'd3; rom[18] = 4'd9; rom[19] = 4'd0;
    rom[20] = 4'd5; rom[21] = 4'd2; rom[22] = 4'd8; rom[23] = 4'd1;
    // 第 3 行: 4 9 0 2 6 8 3 5 7 1 4 9
    rom[24] = 4'd4; rom[25] = 4'd9; rom[26] = 4'd0; rom[27] = 4'd2;
    rom[28] = 4'd6; rom[29] = 4'd8; rom[30] = 4'd3; rom[31] = 4'd5;
    rom[32] = 4'd7; rom[33] = 4'd1; rom[34] = 4'd4; rom[35] = 4'd9;
    // 第 4 行: 7 3 8 5 1 4 9 2 0 6 7 3
    rom[36] = 4'd7; rom[37] = 4'd3; rom[38] = 4'd8; rom[39] = 4'd5;
    rom[40] = 4'd1; rom[41] = 4'd4; rom[42] = 4'd9; rom[43] = 4'd2;
    rom[44] = 4'd0; rom[45] = 4'd6; rom[46] = 4'd7; rom[47] = 4'd3;
    // 第 5 行: 2 6 4 0 8 7 5 3 1 9 2 4
    rom[48] = 4'd2; rom[49] = 4'd6; rom[50] = 4'd4; rom[51] = 4'd0;
    rom[52] = 4'd8; rom[53] = 4'd7; rom[54] = 4'd5; rom[55] = 4'd3;
    rom[56] = 4'd1; rom[57] = 4'd9; rom[58] = 4'd2; rom[59] = 4'd4;
    // 第 6 行: 9 0 7 3 5 2 8 6 4 1 9 0
    rom[60] = 4'd9; rom[61] = 4'd0; rom[62] = 4'd7; rom[63] = 4'd3;
    rom[64] = 4'd5; rom[65] = 4'd2; rom[66] = 4'd8; rom[67] = 4'd6;
    rom[68] = 4'd4; rom[69] = 4'd1; rom[70] = 4'd9; rom[71] = 4'd0;
    // 第 7 行: 5 8 1 6 4 9 2 7 3 0 5 8
    rom[72] = 4'd5; rom[73] = 4'd8; rom[74] = 4'd1; rom[75] = 4'd6;
    rom[76] = 4'd4; rom[77] = 4'd9; rom[78] = 4'd2; rom[79] = 4'd7;
    rom[80] = 4'd3; rom[81] = 4'd0; rom[82] = 4'd5; rom[83] = 4'd8;
    // 第 8 行: 1 4 9 2 7 0 6 8 5 3 1 4
    rom[84] = 4'd1; rom[85] = 4'd4; rom[86] = 4'd9; rom[87] = 4'd2;
    rom[88] = 4'd7; rom[89] = 4'd0; rom[90] = 4'd6; rom[91] = 4'd8;
    rom[92] = 4'd5; rom[93] = 4'd3; rom[94] = 4'd1; rom[95] = 4'd4;
    // 第 9 行: 6 2 5 8 3 1 7 4 9 0 6 2
    rom[96] = 4'd6; rom[97] = 4'd2; rom[98] = 4'd5; rom[99] = 4'd8;
    rom[100] = 4'd3; rom[101] = 4'd1; rom[102] = 4'd7; rom[103] = 4'd4;
    rom[104] = 4'd9; rom[105] = 4'd0; rom[106] = 4'd6; rom[107] = 4'd2;
    // 第 10 行: 0 7 3 9 5 6 4 1 8 2 0 7
    rom[108] = 4'd0; rom[109] = 4'd7; rom[110] = 4'd3; rom[111] = 4'd9;
    rom[112] = 4'd5; rom[113] = 4'd6; rom[114] = 4'd4; rom[115] = 4'd1;
    rom[116] = 4'd8; rom[117] = 4'd2; rom[118] = 4'd0; rom[119] = 4'd7;
    end
    
    // 计算当前窗口的9个元素在ROM中的地址
    integer base_addr;  // 窗口左上角的地址
    integer addr_r0_c0, addr_r0_c1, addr_r0_c2;
    integer addr_r1_c0, addr_r1_c1, addr_r1_c2;
    integer addr_r2_c0, addr_r2_c1, addr_r2_c2;
    // === 组合逻辑：从ROM提取当前3×3窗口 ===
    always @(row_start_idx, col_start_idx) begin
        base_addr <= row_start_idx * 12 + col_start_idx;  // ROM是12列宽的
        
        // 第一行三个元素
        addr_r0_c0 <= base_addr;
        addr_r0_c1 <= base_addr + 1;
        addr_r0_c2 <= base_addr + 2;
        
        // 第二行三个元素（向下移动一行）
        addr_r1_c0 <= base_addr + 12;
        addr_r1_c1 <= base_addr + 12 + 1;
        addr_r1_c2 <= base_addr + 12 + 2;
        
        // 第三行三个元素（再向下移动一行）
        addr_r2_c0 <= base_addr + 24;
        addr_r2_c1 <= base_addr + 24 + 1;
        addr_r2_c2 <= base_addr + 24 + 2;
        
        // 从ROM读取值
        rom_window_0 <= rom[addr_r0_c0];
        rom_window_1 <= rom[addr_r0_c1];
        rom_window_2 <= rom[addr_r0_c2];
        rom_window_3 <= rom[addr_r1_c0];
        rom_window_4 <= rom[addr_r1_c1];
        rom_window_5 <= rom[addr_r1_c2];
        rom_window_6 <= rom[addr_r2_c0];
        rom_window_7 <= rom[addr_r2_c1];
        rom_window_8 <= rom[addr_r2_c2];
    end
    
    // === 时序控制逻辑 ===
    reg isCalculated;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // 复位所有寄存器和输出
            conv_counter <= 0;
            row_start_idx <= 0;
            col_start_idx <= 0;
            busy <= 0;
            isCalculated <= 0;
            
            // 清空所有输出
            data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
            data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
            data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
            data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
            data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
            data_out_25 <= 0; data_out_26 <= 0; data_out_27 <= 0; data_out_28 <= 0; data_out_29 <= 0;
            data_out_30 <= 0; data_out_31 <= 0; data_out_32 <= 0; data_out_33 <= 0; data_out_34 <= 0;
            data_out_35 <= 0; data_out_36 <= 0; data_out_37 <= 0; data_out_38 <= 0; data_out_39 <= 0;
            data_out_40 <= 0; data_out_41 <= 0; data_out_42 <= 0; data_out_43 <= 0; data_out_44 <= 0;
            data_out_45 <= 0; data_out_46 <= 0; data_out_47 <= 0; data_out_48 <= 0; data_out_49 <= 0;
            data_out_50 <= 0; data_out_51 <= 0; data_out_52 <= 0; data_out_53 <= 0; data_out_54 <= 0;
            data_out_55 <= 0; data_out_56 <= 0; data_out_57 <= 0; data_out_58 <= 0; data_out_59 <= 0;
            data_out_60 <= 0; data_out_61 <= 0; data_out_62 <= 0; data_out_63 <= 0; data_out_64 <= 0;
            data_out_65 <= 0; data_out_66 <= 0; data_out_67 <= 0; data_out_68 <= 0; data_out_69 <= 0;
            data_out_70 <= 0; data_out_71 <= 0; data_out_72 <= 0; data_out_73 <= 0; data_out_74 <= 0;
            data_out_75 <= 0; data_out_76 <= 0; data_out_77 <= 0; data_out_78 <= 0; data_out_79 <= 0;
        end else begin
            if (en && !busy && !isCalculated) begin
                // 开始新计算
                busy <= 1;
                conv_counter <= 0;
                row_start_idx <= 0;
                col_start_idx <= 0;
            end else if (busy) begin
                // 正在计算：存储上一个时钟周期的卷积结果
                case(conv_counter)
                    // 第一行输出 (8个)
                    0: data_out_0 <= final_sum[DATA_WIDTH-1:0];
                    1: data_out_1 <= final_sum[DATA_WIDTH-1:0];
                    2: data_out_2 <= final_sum[DATA_WIDTH-1:0];
                    3: data_out_3 <= final_sum[DATA_WIDTH-1:0];
                    4: data_out_4 <= final_sum[DATA_WIDTH-1:0];
                    5: data_out_5 <= final_sum[DATA_WIDTH-1:0];
                    6: data_out_6 <= final_sum[DATA_WIDTH-1:0];
                    7: data_out_7 <= final_sum[DATA_WIDTH-1:0];
                    
                    // 第二行输出
                    8: data_out_8 <= final_sum[DATA_WIDTH-1:0];
                    9: data_out_9 <= final_sum[DATA_WIDTH-1:0];
                    10: data_out_10 <= final_sum[DATA_WIDTH-1:0];
                    11: data_out_11 <= final_sum[DATA_WIDTH-1:0];
                    12: data_out_12 <= final_sum[DATA_WIDTH-1:0];
                    13: data_out_13 <= final_sum[DATA_WIDTH-1:0];
                    14: data_out_14 <= final_sum[DATA_WIDTH-1:0];
                    15: data_out_15 <= final_sum[DATA_WIDTH-1:0];
                    
                    // 第三行输出
                    16: data_out_16 <= final_sum[DATA_WIDTH-1:0];
                    17: data_out_17 <= final_sum[DATA_WIDTH-1:0];
                    18: data_out_18 <= final_sum[DATA_WIDTH-1:0];
                    19: data_out_19 <= final_sum[DATA_WIDTH-1:0];
                    20: data_out_20 <= final_sum[DATA_WIDTH-1:0];
                    21: data_out_21 <= final_sum[DATA_WIDTH-1:0];
                    22: data_out_22 <= final_sum[DATA_WIDTH-1:0];
                    23: data_out_23 <= final_sum[DATA_WIDTH-1:0];
                    
                    // 第四行输出
                    24: data_out_24 <= final_sum[DATA_WIDTH-1:0];
                    25: data_out_25 <= final_sum[DATA_WIDTH-1:0];
                    26: data_out_26 <= final_sum[DATA_WIDTH-1:0];
                    27: data_out_27 <= final_sum[DATA_WIDTH-1:0];
                    28: data_out_28 <= final_sum[DATA_WIDTH-1:0];
                    29: data_out_29 <= final_sum[DATA_WIDTH-1:0];
                    30: data_out_30 <= final_sum[DATA_WIDTH-1:0];
                    31: data_out_31 <= final_sum[DATA_WIDTH-1:0];
                    
                    // 第五行输出
                    32: data_out_32 <= final_sum[DATA_WIDTH-1:0];
                    33: data_out_33 <= final_sum[DATA_WIDTH-1:0];
                    34: data_out_34 <= final_sum[DATA_WIDTH-1:0];
                    35: data_out_35 <= final_sum[DATA_WIDTH-1:0];
                    36: data_out_36 <= final_sum[DATA_WIDTH-1:0];
                    37: data_out_37 <= final_sum[DATA_WIDTH-1:0];
                    38: data_out_38 <= final_sum[DATA_WIDTH-1:0];
                    39: data_out_39 <= final_sum[DATA_WIDTH-1:0];
                    
                    // 第六行输出
                    40: data_out_40 <= final_sum[DATA_WIDTH-1:0];
                    41: data_out_41 <= final_sum[DATA_WIDTH-1:0];
                    42: data_out_42 <= final_sum[DATA_WIDTH-1:0];
                    43: data_out_43 <= final_sum[DATA_WIDTH-1:0];
                    44: data_out_44 <= final_sum[DATA_WIDTH-1:0];
                    45: data_out_45 <= final_sum[DATA_WIDTH-1:0];
                    46: data_out_46 <= final_sum[DATA_WIDTH-1:0];
                    47: data_out_47 <= final_sum[DATA_WIDTH-1:0];
                    
                    // 第七行输出
                    48: data_out_48 <= final_sum[DATA_WIDTH-1:0];
                    49: data_out_49 <= final_sum[DATA_WIDTH-1:0];
                    50: data_out_50 <= final_sum[DATA_WIDTH-1:0];
                    51: data_out_51 <= final_sum[DATA_WIDTH-1:0];
                    52: data_out_52 <= final_sum[DATA_WIDTH-1:0];
                    53: data_out_53 <= final_sum[DATA_WIDTH-1:0];
                    54: data_out_54 <= final_sum[DATA_WIDTH-1:0];
                    55: data_out_55 <= final_sum[DATA_WIDTH-1:0];
                    
                    // 第八行输出
                    56: data_out_56 <= final_sum[DATA_WIDTH-1:0];
                    57: data_out_57 <= final_sum[DATA_WIDTH-1:0];
                    58: data_out_58 <= final_sum[DATA_WIDTH-1:0];
                    59: data_out_59 <= final_sum[DATA_WIDTH-1:0];
                    60: data_out_60 <= final_sum[DATA_WIDTH-1:0];
                    61: data_out_61 <= final_sum[DATA_WIDTH-1:0];
                    62: data_out_62 <= final_sum[DATA_WIDTH-1:0];
                    63: data_out_63 <= final_sum[DATA_WIDTH-1:0];
                    
                    // 第九行输出
                    64: data_out_64 <= final_sum[DATA_WIDTH-1:0];
                    65: data_out_65 <= final_sum[DATA_WIDTH-1:0];
                    66: data_out_66 <= final_sum[DATA_WIDTH-1:0];
                    67: data_out_67 <= final_sum[DATA_WIDTH-1:0];
                    68: data_out_68 <= final_sum[DATA_WIDTH-1:0];
                    69: data_out_69 <= final_sum[DATA_WIDTH-1:0];
                    70: data_out_70 <= final_sum[DATA_WIDTH-1:0];
                    71: data_out_71 <= final_sum[DATA_WIDTH-1:0];
                    
                    // 第十行输出
                    72: data_out_72 <= final_sum[DATA_WIDTH-1:0];
                    73: data_out_73 <= final_sum[DATA_WIDTH-1:0];
                    74: data_out_74 <= final_sum[DATA_WIDTH-1:0];
                    75: data_out_75 <= final_sum[DATA_WIDTH-1:0];
                    76: data_out_76 <= final_sum[DATA_WIDTH-1:0];
                    77: data_out_77 <= final_sum[DATA_WIDTH-1:0];
                    78: data_out_78 <= final_sum[DATA_WIDTH-1:0];
                    79: data_out_79 <= final_sum[DATA_WIDTH-1:0];
                endcase
                
                // 更新卷积窗口位置
                if (conv_counter < 79) begin
                    conv_counter <= conv_counter + 1;
                    
                    // 移动窗口：先向右移动，到达最右边后换行
                    if (col_start_idx < 9) begin
                        // 还在当前行，向右移动一列
                        col_start_idx <= col_start_idx + 1;
                    end else begin
                        // 移动到下一行的最左边
                        col_start_idx <= 0;
                        row_start_idx <= row_start_idx + 1;
                    end
                end else begin
                    // 完成所有80个输出
                    busy <= 0;
                    isCalculated <= 1;
                    conv_counter <= 0;
                    row_start_idx <= 0;
                    col_start_idx <= 0;
                end
            end else if (!en) begin
                // 复位所有寄存器和输出
                conv_counter <= 0;
                row_start_idx <= 0;
                col_start_idx <= 0;
                busy <= 0;
                isCalculated <= 0;
                
                // 清空所有输出
                data_out_0 <= 0; data_out_1 <= 0; data_out_2 <= 0; data_out_3 <= 0; data_out_4 <= 0;
                data_out_5 <= 0; data_out_6 <= 0; data_out_7 <= 0; data_out_8 <= 0; data_out_9 <= 0;
                data_out_10 <= 0; data_out_11 <= 0; data_out_12 <= 0; data_out_13 <= 0; data_out_14 <= 0;
                data_out_15 <= 0; data_out_16 <= 0; data_out_17 <= 0; data_out_18 <= 0; data_out_19 <= 0;
                data_out_20 <= 0; data_out_21 <= 0; data_out_22 <= 0; data_out_23 <= 0; data_out_24 <= 0;
                data_out_25 <= 0; data_out_26 <= 0; data_out_27 <= 0; data_out_28 <= 0; data_out_29 <= 0;
                data_out_30 <= 0; data_out_31 <= 0; data_out_32 <= 0; data_out_33 <= 0; data_out_34 <= 0;
                data_out_35 <= 0; data_out_36 <= 0; data_out_37 <= 0; data_out_38 <= 0; data_out_39 <= 0;
                data_out_40 <= 0; data_out_41 <= 0; data_out_42 <= 0; data_out_43 <= 0; data_out_44 <= 0;
                data_out_45 <= 0; data_out_46 <= 0; data_out_47 <= 0; data_out_48 <= 0; data_out_49 <= 0;
                data_out_50 <= 0; data_out_51 <= 0; data_out_52 <= 0; data_out_53 <= 0; data_out_54 <= 0;
                data_out_55 <= 0; data_out_56 <= 0; data_out_57 <= 0; data_out_58 <= 0; data_out_59 <= 0;
                data_out_60 <= 0; data_out_61 <= 0; data_out_62 <= 0; data_out_63 <= 0; data_out_64 <= 0;
                data_out_65 <= 0; data_out_66 <= 0; data_out_67 <= 0; data_out_68 <= 0; data_out_69 <= 0;
                data_out_70 <= 0; data_out_71 <= 0; data_out_72 <= 0; data_out_73 <= 0; data_out_74 <= 0;
                data_out_75 <= 0; data_out_76 <= 0; data_out_77 <= 0; data_out_78 <= 0; data_out_79 <= 0;
            end
        end
    end
    
endmodule