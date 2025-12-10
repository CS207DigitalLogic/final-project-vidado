module multi_matrix_storage #(
    parameter DATA_WIDTH        = 8,        // 数据位宽
    parameter MAX_SIZE          = 5,        // 单个矩阵最大规模（1~5）
    parameter MATRIX_NUM        = 8,        // 全局最大矩阵数量
    parameter MAX_MATRIX_PER_SIZE = 4       // 每个规模最多存储矩阵数
)(
    input wire                     clk,            // 时钟信号（时序写入触发）
    input wire                     rst_n,          // 低有效复位（仅用于初始化）
    // ---------------------------
    // 时序逻辑写入接口（wr_en为时钟使能）
    // ---------------------------
    input wire                     wr_en,          // 写使能（1=时钟上升沿执行写入）
    input wire [MATRIX_IDX_W-1:0]  target_idx,     // 写入目标：全局矩阵索引（0~MATRIX_NUM-1）
    input wire [2:0]               write_row,      // 写入矩阵的行数（1~MAX_SIZE）
    input wire [2:0]               write_col,      // 写入矩阵的列数（1~MAX_SIZE）
    input wire [DATA_WIDTH-1:0]    data_in_0,      // 写入数据0（地址0）
    input wire [DATA_WIDTH-1:0]    data_in_1,      // 写入数据1（地址1）
    input wire [DATA_WIDTH-1:0]    data_in_2,      // 写入数据2（地址2）
    input wire [DATA_WIDTH-1:0]    data_in_3,      // 写入数据3（地址3）
    input wire [DATA_WIDTH-1:0]    data_in_4,      // 写入数据4（地址4）
    input wire [DATA_WIDTH-1:0]    data_in_5,      // 写入数据5（地址5）
    input wire [DATA_WIDTH-1:0]    data_in_6,      // 写入数据6（地址6）
    input wire [DATA_WIDTH-1:0]    data_in_7,      // 写入数据7（地址7）
    input wire [DATA_WIDTH-1:0]    data_in_8,      // 写入数据8（地址8）
    input wire [DATA_WIDTH-1:0]    data_in_9,      // 写入数据9（地址9）
    input wire [DATA_WIDTH-1:0]    data_in_10,     // 写入数据10（地址10）
    input wire [DATA_WIDTH-1:0]    data_in_11,     // 写入数据11（地址11）
    input wire [DATA_WIDTH-1:0]    data_in_12,     // 写入数据12（地址12）
    input wire [DATA_WIDTH-1:0]    data_in_13,     // 写入数据13（地址13）
    input wire [DATA_WIDTH-1:0]    data_in_14,     // 写入数据14（地址14）
    input wire [DATA_WIDTH-1:0]    data_in_15,     // 写入数据15（地址15）
    input wire [DATA_WIDTH-1:0]    data_in_16,     // 写入数据16（地址16）
    input wire [DATA_WIDTH-1:0]    data_in_17,     // 写入数据17（地址17）
    input wire [DATA_WIDTH-1:0]    data_in_18,     // 写入数据18（地址18）
    input wire [DATA_WIDTH-1:0]    data_in_19,     // 写入数据19（地址19）
    input wire [DATA_WIDTH-1:0]    data_in_20,     // 写入数据20（地址20）
    input wire [DATA_WIDTH-1:0]    data_in_21,     // 写入数据21（地址21）
    input wire [DATA_WIDTH-1:0]    data_in_22,     // 写入数据22（地址22）
    input wire [DATA_WIDTH-1:0]    data_in_23,     // 写入数据23（地址23）
    input wire [DATA_WIDTH-1:0]    data_in_24,     // 写入数据24（地址24）
    // ---------------------------
    // 核心查询输入（按规模+序号选择矩阵，与之前一致）
    // ---------------------------
    input wire [2:0]               req_scale_row,  // 要求的矩阵规模（行：1~MAX_SIZE）
    input wire [2:0]               req_scale_col,  // 要求的矩阵规模（列：1~MAX_SIZE）
    input wire [SEL_IDX_W-1:0]     req_idx,        // 要求的序号（0~MAX_MATRIX_PER_SIZE-1）
    // ---------------------------
    // 输出接口（与之前一致，无变化）
    // ---------------------------
    output reg [SEL_IDX_W-1:0]     scale_matrix_cnt, // 目标规模的矩阵总数
    output reg [DATA_WIDTH-1:0]    matrix_data_0,  // 矩阵元素0（地址0）
    output reg [DATA_WIDTH-1:0]    matrix_data_1,  // 矩阵元素1（地址1）
    output reg [DATA_WIDTH-1:0]    matrix_data_2,  // 矩阵元素2（地址2）
    output reg [DATA_WIDTH-1:0]    matrix_data_3,  // 矩阵元素3（地址3）
    output reg [DATA_WIDTH-1:0]    matrix_data_4,  // 矩阵元素4（地址4）
    output reg [DATA_WIDTH-1:0]    matrix_data_5,  // 矩阵元素5（地址5）
    output reg [DATA_WIDTH-1:0]    matrix_data_6,  // 矩阵元素6（地址6）
    output reg [DATA_WIDTH-1:0]    matrix_data_7,  // 矩阵元素7（地址7）
    output reg [DATA_WIDTH-1:0]    matrix_data_8,  // 矩阵元素8（地址8）
    output reg [DATA_WIDTH-1:0]    matrix_data_9,  // 矩阵元素9（地址9）
    output reg [DATA_WIDTH-1:0]    matrix_data_10, // 矩阵元素10（地址10）
    output reg [DATA_WIDTH-1:0]    matrix_data_11, // 矩阵元素11（地址11）
    output reg [DATA_WIDTH-1:0]    matrix_data_12, // 矩阵元素12（地址12）
    output reg [DATA_WIDTH-1:0]    matrix_data_13, // 矩阵元素13（地址13）
    output reg [DATA_WIDTH-1:0]    matrix_data_14, // 矩阵元素14（地址14）
    output reg [DATA_WIDTH-1:0]    matrix_data_15, // 矩阵元素15（地址15）
    output reg [DATA_WIDTH-1:0]    matrix_data_16, // 矩阵元素16（地址16）
    output reg [DATA_WIDTH-1:0]    matrix_data_17, // 矩阵元素17（地址17）
    output reg [DATA_WIDTH-1:0]    matrix_data_18, // 矩阵元素18（地址18）
    output reg [DATA_WIDTH-1:0]    matrix_data_19, // 矩阵元素19（地址19）
    output reg [DATA_WIDTH-1:0]    matrix_data_20, // 矩阵元素20（地址20）
    output reg [DATA_WIDTH-1:0]    matrix_data_21, // 矩阵元素21（地址21）
    output reg [DATA_WIDTH-1:0]    matrix_data_22, // 矩阵元素22（地址22）
    output reg [DATA_WIDTH-1:0]    matrix_data_23, // 矩阵元素23（地址23）
    output reg [DATA_WIDTH-1:0]    matrix_data_24, // 矩阵元素24（地址24）
    output reg [2:0]               matrix_row,     // 输出矩阵的实际行数
    output reg [2:0]               matrix_col,     // 输出矩阵的实际列数
    output reg                     matrix_valid    // 矩阵有效标记（1=序号有效）
);

// ---------------------------
// 局部参数（与原逻辑一致，无变化）
// ---------------------------
localparam MEM_DEPTH_PER_MATRIX = MAX_SIZE * MAX_SIZE;  // 单个矩阵存储深度（25）
localparam MATRIX_IDX_W = (MATRIX_NUM <= 1)  ? 1 :
                         (MATRIX_NUM <= 2)  ? 2 :
                         (MATRIX_NUM <= 4)  ? 3 :
                         (MATRIX_NUM <= 8)  ? 3 :
                         (MATRIX_NUM <= 16) ? 4 :
                         (MATRIX_NUM <= 32) ? 5 :
                         6;
localparam SEL_IDX_W = (MAX_MATRIX_PER_SIZE <= 1)  ? 1 :
                      (MAX_MATRIX_PER_SIZE <= 2)  ? 2 :
                      (MAX_MATRIX_PER_SIZE <= 4)  ? 2 :
                      (MAX_MATRIX_PER_SIZE <= 8)  ? 3 :
                      (MAX_MATRIX_PER_SIZE <= 16) ? 4 :
                      5;

// ---------------------------
// 内部核心数组（与原逻辑一致，无变化）
// ---------------------------
reg [DATA_WIDTH-1:0] mem [0:MATRIX_NUM-1] [0:MEM_DEPTH_PER_MATRIX-1];  // 全局矩阵存储
reg [2:0] row_self [0:MATRIX_NUM-1];  // 每个矩阵的实际行数
reg [2:0] col_self [0:MATRIX_NUM-1];  // 每个矩阵的实际列数
reg [MATRIX_IDX_W-1:0] size2matrix [1:MAX_SIZE] [1:MAX_SIZE] [0:MAX_MATRIX_PER_SIZE-1];  // 规模→全局索引映射
reg [SEL_IDX_W-1:0] size_cnt [1:MAX_SIZE] [1:MAX_SIZE];  // 每个规模的矩阵计数
reg [0:MATRIX_NUM-1] matrix_init_flag;  // 矩阵初始化标记

// ---------------------------
// 内部临时变量（关键修改：新增组合逻辑预处理变量）
// ---------------------------
// 组合逻辑预处理变量（写入输入的边界保护）
wire [2:0]               r_store_comb;       // 组合逻辑计算的有效存储行规模
wire [2:0]               c_store_comb;       // 组合逻辑计算的有效存储列规模
wire [MATRIX_IDX_W-1:0]  valid_target_idx_comb; // 组合逻辑计算的有效目标索引
wire [SEL_IDX_W-1:0]     curr_cnt_comb;      // 组合逻辑计算的当前规模计数

// 查询输出相关（无修改）
reg [2:0] valid_scale_r, valid_scale_c;               // 有效查询规模
reg [MATRIX_IDX_W-1:0] target_global_idx;             // 目标矩阵全局索引
reg [SEL_IDX_W-1:0] valid_req_idx;                   // 有效查询序号

// ---------------------------
// 关键修改1：组合逻辑预处理写入输入（避免时序块内旧值问题）
// ---------------------------
assign valid_target_idx_comb = (target_idx < MATRIX_NUM) ? target_idx : {MATRIX_IDX_W{1'b0}};
assign r_store_comb = (write_row >= 1 && write_row <= MAX_SIZE) ? write_row : 1'd1;
assign c_store_comb = (write_col >= 1 && write_col <= MAX_SIZE) ? write_col : 1'd1;
assign curr_cnt_comb = size_cnt[r_store_comb][c_store_comb]; // 直接取当前规模的最新计数

// ---------------------------
// 1. 复位初始化 + 时序写入逻辑（异步复位，时钟触发写入）
// ---------------------------
integer m, d, r, c, s, gg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 1.1 全局存储初始化（所有元素清0）
        for (m = 0; m < MATRIX_NUM; m = m + 1) begin
            for (d = 0; d < MEM_DEPTH_PER_MATRIX; d = d + 1) begin
                mem[m][d] <= {DATA_WIDTH{1'b0}};
            end
        end

        // 1.2 矩阵规模+初始化标记初始化
        for (m = 0; m < MATRIX_NUM; m = m + 1) begin
            row_self[m] <= 1'd1;
            col_self[m] <= 1'd1;
            matrix_init_flag[m] <= 1'b0;
        end

        // 1.3 规模映射表和计数器初始化
        for (r = 1; r <= MAX_SIZE; r = r + 1) begin
            for (c = 1; c <= MAX_SIZE; c = c + 1) begin
                size_cnt[r][c] <= {SEL_IDX_W{1'b0}};
                for (s = 0; s < MAX_MATRIX_PER_SIZE; s = s + 1) begin
                    size2matrix[r][c][s] <= {MATRIX_IDX_W{1'b0}};
                end
            end
        end
/*
        // 1.4 预存矩阵初始化（示例数据，含负数补码）
        // 预存2x3矩阵0（全局索引0）
        mem[0][0] <= 8'h01; mem[0][1] <= 8'h02; mem[0][2] <= 8'hFB;
        mem[0][3] <= 8'h04; mem[0][4] <= 8'h05; mem[0][5] <= 8'h06;
        row_self[0] <= 3'd2; col_self[0] <= 3'd3;
        matrix_init_flag[0] <= 1'b1;

        // 预存2x3矩阵1（全局索引1）
        mem[1][0] <= 8'h11; mem[1][1] <= 8'h12; mem[1][2] <= 8'h80;
        mem[1][3] <= 8'h14; mem[1][4] <= 8'h15; mem[1][5] <= 8'h16;
        row_self[1] <= 3'd2; col_self[1] <= 3'd3;
        matrix_init_flag[1] <= 1'b1;

        // 预存2x3矩阵2（全局索引2）
        mem[2][0] <= 8'h21; mem[2][1] <= 8'h22; mem[2][2] <= 8'hFF;
        mem[2][3] <= 8'h24; mem[2][4] <= 8'h25; mem[2][5] <= 8'h26;
        row_self[2] <= 3'd2; col_self[2] <= 3'd3;
        matrix_init_flag[2] <= 1'b1;

        // 预存3x4矩阵（全局索引3）
        for (gg = 0; gg < 12; gg = gg + 1) begin
            if (gg < MEM_DEPTH_PER_MATRIX) begin // 新增越界保护
                mem[3][gg] <= 8'h31 + gg;
            end
        end
        row_self[3] <= 3'd3; col_self[3] <= 3'd4;
        matrix_init_flag[3] <= 1'b1;

        // 1.5 更新预存矩阵的规模映射表和计数器
        size2matrix[2][3][0] <= 3'd0;
        size2matrix[2][3][1] <= 3'd1;
        size2matrix[2][3][2] <= 3'd2;
        size_cnt[2][3] <= 3'd3;

        size2matrix[3][4][0] <= 3'd3;
        size_cnt[3][4] <= 3'd1;
        */
    end else begin
        // ---------------------------
        // 2. 时序写入逻辑（仅wr_en有效时执行）
        // ---------------------------
        if (wr_en) begin
            // 2.1 写入25个矩阵元素（使用组合逻辑预处理的有效索引）
            mem[valid_target_idx_comb][0]  <= data_in_0;
            mem[valid_target_idx_comb][1]  <= data_in_1;
            mem[valid_target_idx_comb][2]  <= data_in_2;
            mem[valid_target_idx_comb][3]  <= data_in_3;
            mem[valid_target_idx_comb][4]  <= data_in_4;
            mem[valid_target_idx_comb][5]  <= data_in_5;
            mem[valid_target_idx_comb][6]  <= data_in_6;
            mem[valid_target_idx_comb][7]  <= data_in_7;
            mem[valid_target_idx_comb][8]  <= data_in_8;
            mem[valid_target_idx_comb][9]  <= data_in_9;
            mem[valid_target_idx_comb][10] <= data_in_10;
            mem[valid_target_idx_comb][11] <= data_in_11;
            mem[valid_target_idx_comb][12] <= data_in_12;
            mem[valid_target_idx_comb][13] <= data_in_13;
            mem[valid_target_idx_comb][14] <= data_in_14;
            mem[valid_target_idx_comb][15] <= data_in_15;
            mem[valid_target_idx_comb][16] <= data_in_16;
            mem[valid_target_idx_comb][17] <= data_in_17;
            mem[valid_target_idx_comb][18] <= data_in_18;
            mem[valid_target_idx_comb][19] <= data_in_19;
            mem[valid_target_idx_comb][20] <= data_in_20;
            mem[valid_target_idx_comb][21] <= data_in_21;
            mem[valid_target_idx_comb][22] <= data_in_22;
            mem[valid_target_idx_comb][23] <= data_in_23;
            mem[valid_target_idx_comb][24] <= data_in_24;

            // 2.2 更新矩阵实际行/列数（使用组合逻辑预处理的有效规模）
            row_self[valid_target_idx_comb] <= r_store_comb;
            col_self[valid_target_idx_comb] <= c_store_comb;

            // 2.3 初始化标记与规模映射表更新（仅首次写入时执行）
            // 关键修复：curr_cnt_comb是组合逻辑计算的当前规模最新计数
            if (!matrix_init_flag[valid_target_idx_comb] && (curr_cnt_comb < MAX_MATRIX_PER_SIZE)) begin
                size2matrix[r_store_comb][c_store_comb][curr_cnt_comb] <= valid_target_idx_comb;
                size_cnt[r_store_comb][c_store_comb] <= curr_cnt_comb + 1'd1;
                matrix_init_flag[valid_target_idx_comb] <= 1'b1;
            end
            // 新增：越界保护（避免size2matrix索引超出范围）
            else if (!matrix_init_flag[valid_target_idx_comb] && (curr_cnt_comb >= MAX_MATRIX_PER_SIZE)) begin
            end
        end
        // wr_en无效时，所有寄存器保持原值（时序逻辑天然特性）
    end
end

// ---------------------------
// 3. 核心查询输出逻辑（与原逻辑一致，无变化）
// ---------------------------
always @(*) begin
    // 3.1 输入边界保护
    valid_scale_r = (req_scale_row >= 1 && req_scale_row <= MAX_SIZE) ? req_scale_row : 1'd1;
    valid_scale_c = (req_scale_col >= 1 && req_scale_col <= MAX_SIZE) ? req_scale_col : 1'd1;
    valid_req_idx = (req_idx < MAX_MATRIX_PER_SIZE) ? req_idx : {SEL_IDX_W{1'b0}};

    // 3.2 输出目标规模的矩阵总数
    scale_matrix_cnt = size_cnt[valid_scale_r][valid_scale_c];

    // 3.3 计算目标矩阵的全局索引
    if (scale_matrix_cnt > 0 && valid_req_idx < scale_matrix_cnt) begin
        target_global_idx = size2matrix[valid_scale_r][valid_scale_c][valid_req_idx];
        matrix_valid = 1'b1;
    end else begin
        target_global_idx = {MATRIX_IDX_W{1'b0}};
        matrix_valid = 1'b0;
    end

    // 3.4 输出目标矩阵的25个元素
    matrix_data_0  = mem[target_global_idx][0];
    matrix_data_1  = mem[target_global_idx][1];
    matrix_data_2  = mem[target_global_idx][2];
    matrix_data_3  = mem[target_global_idx][3];
    matrix_data_4  = mem[target_global_idx][4];
    matrix_data_5  = mem[target_global_idx][5];
    matrix_data_6  = mem[target_global_idx][6];
    matrix_data_7  = mem[target_global_idx][7];
    matrix_data_8  = mem[target_global_idx][8];
    matrix_data_9  = mem[target_global_idx][9];
    matrix_data_10 = mem[target_global_idx][10];
    matrix_data_11 = mem[target_global_idx][11];
    matrix_data_12 = mem[target_global_idx][12];
    matrix_data_13 = mem[target_global_idx][13];
    matrix_data_14 = mem[target_global_idx][14];
    matrix_data_15 = mem[target_global_idx][15];
    matrix_data_16 = mem[target_global_idx][16];
    matrix_data_17 = mem[target_global_idx][17];
    matrix_data_18 = mem[target_global_idx][18];
    matrix_data_19 = mem[target_global_idx][19];
    matrix_data_20 = mem[target_global_idx][20];
    matrix_data_21 = mem[target_global_idx][21];
    matrix_data_22 = mem[target_global_idx][22];
    matrix_data_23 = mem[target_global_idx][23];
    matrix_data_24 = mem[target_global_idx][24];

    // 3.5 输出目标矩阵的实际行/列数
    matrix_row = row_self[target_global_idx];
    matrix_col = col_self[target_global_idx];
    matrix_row = (matrix_row >= 1 && matrix_row <= MAX_SIZE) ? matrix_row : 1'd1;
    matrix_col = (matrix_col >= 1 && matrix_col <= MAX_SIZE) ? matrix_col : 1'd1;
end

endmodule