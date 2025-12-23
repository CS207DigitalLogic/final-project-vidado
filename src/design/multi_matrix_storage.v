module multi_matrix_storage #(
    parameter DATA_WIDTH        = 5'd8,        // 数据位宽
    parameter MAX_SIZE          = 5'd5,        // 单个矩阵最大规模（1~5）
    parameter MATRIX_NUM        = 5'd25,        // 全局最大矩阵数量
    parameter MAX_MATRIX_PER_SIZE = 5'd4       // 每个规模最多存储矩阵数
)(
    input wire                    clk,
    input wire                    rst_n,

    // ---------------------------
    // 写接口
    // ---------------------------
    input wire                    wr_en,
    input wire [2:0]              write_row,
    input wire [2:0]              write_col,
    input wire [DATA_WIDTH-1:0]   data_in_0,
    input wire [DATA_WIDTH-1:0]   data_in_1,
    input wire [DATA_WIDTH-1:0]   data_in_2,
    input wire [DATA_WIDTH-1:0]   data_in_3,
    input wire [DATA_WIDTH-1:0]   data_in_4,
    input wire [DATA_WIDTH-1:0]   data_in_5,
    input wire [DATA_WIDTH-1:0]   data_in_6,
    input wire [DATA_WIDTH-1:0]   data_in_7,
    input wire [DATA_WIDTH-1:0]   data_in_8,
    input wire [DATA_WIDTH-1:0]   data_in_9,
    input wire [DATA_WIDTH-1:0]   data_in_10,
    input wire [DATA_WIDTH-1:0]   data_in_11,
    input wire [DATA_WIDTH-1:0]   data_in_12,
    input wire [DATA_WIDTH-1:0]   data_in_13,
    input wire [DATA_WIDTH-1:0]   data_in_14,
    input wire [DATA_WIDTH-1:0]   data_in_15,
    input wire [DATA_WIDTH-1:0]   data_in_16,
    input wire [DATA_WIDTH-1:0]   data_in_17,
    input wire [DATA_WIDTH-1:0]   data_in_18,
    input wire [DATA_WIDTH-1:0]   data_in_19,
    input wire [DATA_WIDTH-1:0]   data_in_20,
    input wire [DATA_WIDTH-1:0]   data_in_21,
    input wire [DATA_WIDTH-1:0]   data_in_22,
    input wire [DATA_WIDTH-1:0]   data_in_23,
    input wire [DATA_WIDTH-1:0]   data_in_24,
    
    output reg                    wr_ready,      // 写入就绪
    output reg [MATRIX_IDX_W-1:0] wr_alloc_idx,  // 实际写入的全局索引
    output reg                    wr_overwrite,  // 是否发生了覆写

    // ---------------------------
    // 读接口
    // ---------------------------
    input wire [2:0]              req_scale_row,
    input wire [2:0]              req_scale_col,
    input wire [SEL_IDX_W-1:0]    req_idx,       // 请求的序号 (0 ~ count-1)

    output reg [SEL_IDX_W-1:0]    scale_matrix_cnt,
    output reg [DATA_WIDTH-1:0]   matrix_data_0,
    output reg [DATA_WIDTH-1:0]   matrix_data_1,
    output reg [DATA_WIDTH-1:0]   matrix_data_2,
    output reg [DATA_WIDTH-1:0]   matrix_data_3,
    output reg [DATA_WIDTH-1:0]   matrix_data_4,
    output reg [DATA_WIDTH-1:0]   matrix_data_5,
    output reg [DATA_WIDTH-1:0]   matrix_data_6,
    output reg [DATA_WIDTH-1:0]   matrix_data_7,
    output reg [DATA_WIDTH-1:0]   matrix_data_8,
    output reg [DATA_WIDTH-1:0]   matrix_data_9,
    output reg [DATA_WIDTH-1:0]   matrix_data_10,
    output reg [DATA_WIDTH-1:0]   matrix_data_11,
    output reg [DATA_WIDTH-1:0]   matrix_data_12,
    output reg [DATA_WIDTH-1:0]   matrix_data_13,
    output reg [DATA_WIDTH-1:0]   matrix_data_14,
    output reg [DATA_WIDTH-1:0]   matrix_data_15,
    output reg [DATA_WIDTH-1:0]   matrix_data_16,
    output reg [DATA_WIDTH-1:0]   matrix_data_17,
    output reg [DATA_WIDTH-1:0]   matrix_data_18,
    output reg [DATA_WIDTH-1:0]   matrix_data_19,
    output reg [DATA_WIDTH-1:0]   matrix_data_20,
    output reg [DATA_WIDTH-1:0]   matrix_data_21,
    output reg [DATA_WIDTH-1:0]   matrix_data_22,
    output reg [DATA_WIDTH-1:0]   matrix_data_23,
    output reg [DATA_WIDTH-1:0]   matrix_data_24,
    output reg [2:0]              matrix_row,
    output reg [2:0]              matrix_col,
    output reg                    matrix_valid
);

// ---------------------------
// 参数计算与定义
// ---------------------------
localparam MEM_DEPTH_PER_MATRIX = MAX_SIZE * MAX_SIZE;
localparam MATRIX_IDX_W = (MATRIX_NUM <= 1)  ? 1 :
                          (MATRIX_NUM <= 2)  ? 2 :
                          (MATRIX_NUM <= 4)  ? 3 :
                          (MATRIX_NUM <= 8)  ? 3 :
                          (MATRIX_NUM <= 16) ? 4 :
                          (MATRIX_NUM <= 32) ? 5 : 6;
localparam SEL_IDX_W = (MAX_MATRIX_PER_SIZE <= 1)  ? 1 :
                       (MAX_MATRIX_PER_SIZE <= 2)  ? 2 :
                       (MAX_MATRIX_PER_SIZE <= 4)  ? 2 :
                       (MAX_MATRIX_PER_SIZE <= 8)  ? 3 :
                       (MAX_MATRIX_PER_SIZE <= 16) ? 4 : 5;

// ---------------------------
// 内部存储与寄存器
// ---------------------------
reg [DATA_WIDTH-1:0] mem [0:MATRIX_NUM-1] [0:MEM_DEPTH_PER_MATRIX-1];
reg [2:0] row_self [0:MATRIX_NUM-1];
reg [2:0] col_self [0:MATRIX_NUM-1];

// 映射表: [Row][Col][Local_Index] -> Global_Index
reg [MATRIX_IDX_W-1:0] size2matrix [1:MAX_SIZE] [1:MAX_SIZE] [0:MAX_MATRIX_PER_SIZE-1];
// 计数器: 当前每个规模存储了多少个矩阵
reg [SEL_IDX_W-1:0] size_cnt [1:MAX_SIZE] [1:MAX_SIZE];
// 初始化标记
reg [0:MATRIX_NUM-1] matrix_init_flag;

// 【关键变量】每个规模的循环写指针 (0 -> MAX-1 -> 0)
reg [SEL_IDX_W-1:0] wr_ptr [1:MAX_SIZE] [1:MAX_SIZE];

// ---------------------------
// 组合逻辑临时变量
// ---------------------------
wire [2:0]               r_store_comb;
wire [2:0]               c_store_comb;
wire                     need_overwrite_comb;
reg [MATRIX_IDX_W-1:0]   free_global_idx_comb;
wire [SEL_IDX_W-1:0]     curr_cnt_comb;
wire [SEL_IDX_W-1:0]     curr_wr_ptr_comb;
wire [MATRIX_IDX_W-1:0]  target_idx_comb;

reg wr_en_d;

// ---------------------------
// Step 1: 写入逻辑预处理
// ---------------------------
assign r_store_comb = (write_row >= 1 && write_row <= MAX_SIZE) ? write_row : 3'd1;
assign c_store_comb = (write_col >= 1 && write_col <= MAX_SIZE) ? write_col : 3'd1;
assign curr_cnt_comb = size_cnt[r_store_comb][c_store_comb];
assign curr_wr_ptr_comb = wr_ptr[r_store_comb][c_store_comb];

// 判断是否需要覆写：如果计数已满，则必须覆写
assign need_overwrite_comb = (curr_cnt_comb >= MAX_MATRIX_PER_SIZE);

// 搜索全局空闲索引 (用于新增模式)
reg [5:0] i;
reg       find_free;
always @(*) begin
    free_global_idx_comb = {MATRIX_IDX_W{1'b0}};
    find_free = 1'b0;
    for(i = 0; i < MATRIX_NUM; i = i + 1) begin
        if(!matrix_init_flag[i] && !find_free) begin
            free_global_idx_comb = i;
            find_free = 1'b1;
        end
    end
end

// 【核心逻辑】确定目标写入位置
// 覆写时：查表直接获取 wr_ptr 指向的旧矩阵ID (实现 FIFO 覆盖)
// 新增时：使用搜索到的空闲 ID
assign target_idx_comb = need_overwrite_comb ? 
                         size2matrix[r_store_comb][c_store_comb][curr_wr_ptr_comb] : 
                         free_global_idx_comb;

// Ready 信号逻辑
always @(*) begin
    if (need_overwrite_comb)
        wr_ready = (target_idx_comb < MATRIX_NUM); // 确保旧ID有效
    else
        wr_ready = (free_global_idx_comb < MATRIX_NUM); // 确保有新空间
end

// ---------------------------
// Step 2: 时序逻辑 (Reset & Write)
// ---------------------------
integer m, d, r, c, s;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 2.1 初始化清零
        for (m = 0; m < MATRIX_NUM; m = m + 1) begin
            for (d = 0; d < MEM_DEPTH_PER_MATRIX; d = d + 1) mem[m][d] <= 0;
            row_self[m] <= 1;
            col_self[m] <= 1;
            matrix_init_flag[m] <= 0;
        end
        for (r = 1; r <= MAX_SIZE; r = r + 1) begin
            for (c = 1; c <= MAX_SIZE; c = c + 1) begin
                size_cnt[r][c] <= 0;
                wr_ptr[r][c] <= 0; // 指针复位
                for (s = 0; s < MAX_MATRIX_PER_SIZE; s = s + 1) size2matrix[r][c][s] <= 0;
            end
        end
        wr_en_d <= 0;
        wr_alloc_idx <= 0;
        wr_overwrite <= 0;

    end else begin
        wr_en_d <= wr_en;
        wr_alloc_idx <= 0;
        wr_overwrite <= 0;

        if (wr_en) begin
            if (wr_ready) begin
                // 输出状态信号
                wr_overwrite <= need_overwrite_comb;
                wr_alloc_idx <= target_idx_comb;

                // 2.2 写入矩阵数据 (共25个元素)
                mem[target_idx_comb][0]  <= data_in_0;
                mem[target_idx_comb][1]  <= data_in_1;
                mem[target_idx_comb][2]  <= data_in_2;
                mem[target_idx_comb][3]  <= data_in_3;
                mem[target_idx_comb][4]  <= data_in_4;
                mem[target_idx_comb][5]  <= data_in_5;
                mem[target_idx_comb][6]  <= data_in_6;
                mem[target_idx_comb][7]  <= data_in_7;
                mem[target_idx_comb][8]  <= data_in_8;
                mem[target_idx_comb][9]  <= data_in_9;
                mem[target_idx_comb][10] <= data_in_10;
                mem[target_idx_comb][11] <= data_in_11;
                mem[target_idx_comb][12] <= data_in_12;
                mem[target_idx_comb][13] <= data_in_13;
                mem[target_idx_comb][14] <= data_in_14;
                mem[target_idx_comb][15] <= data_in_15;
                mem[target_idx_comb][16] <= data_in_16;
                mem[target_idx_comb][17] <= data_in_17;
                mem[target_idx_comb][18] <= data_in_18;
                mem[target_idx_comb][19] <= data_in_19;
                mem[target_idx_comb][20] <= data_in_20;
                mem[target_idx_comb][21] <= data_in_21;
                mem[target_idx_comb][22] <= data_in_22;
                mem[target_idx_comb][23] <= data_in_23;
                mem[target_idx_comb][24] <= data_in_24;

                // 2.3 更新元数据
                row_self[target_idx_comb] <= r_store_comb;
                col_self[target_idx_comb] <= c_store_comb;
                matrix_init_flag[target_idx_comb] <= 1'b1;

                // ============================================
                // 【核心修改】循环指针更新
                // ============================================
                
                // 1. 写指针总是循环递增：0->1->2->3->0...
                if (curr_wr_ptr_comb == MAX_MATRIX_PER_SIZE - 1) begin
                    wr_ptr[r_store_comb][c_store_comb] <= {SEL_IDX_W{1'b0}};
                end else begin
                    wr_ptr[r_store_comb][c_store_comb] <= curr_wr_ptr_comb + 1'd1;
                end

                // 2. 只有在【新增模式】下才更新映射表和计数器
                // 覆写模式下：ID复用，计数已满，无需变动
                if (!need_overwrite_comb) begin
                    size2matrix[r_store_comb][c_store_comb][curr_wr_ptr_comb] <= target_idx_comb;
                    size_cnt[r_store_comb][c_store_comb] <= curr_cnt_comb + 1'd1;
                end
            end
        end
    end
end

// ---------------------------
// Step 3: 读取/查询逻辑 (组合逻辑)
// ---------------------------
reg [2:0] valid_scale_r, valid_scale_c;
reg [MATRIX_IDX_W-1:0] target_global_idx;
reg [SEL_IDX_W-1:0] valid_req_idx;

always @(*) begin
    // 3.1 输入校验
    valid_scale_r = (req_scale_row >= 1 && req_scale_row <= MAX_SIZE) ? req_scale_row : 3'd1;
    valid_scale_c = (req_scale_col >= 1 && req_scale_col <= MAX_SIZE) ? req_scale_col : 3'd1;
    valid_req_idx = (req_idx < MAX_MATRIX_PER_SIZE) ? req_idx : {SEL_IDX_W{1'b0}};

    // 3.2 获取当前规模的矩阵总数
    scale_matrix_cnt = size_cnt[valid_scale_r][valid_scale_c];

    // 3.3 查找目标全局索引
    if (scale_matrix_cnt > 0 && valid_req_idx < scale_matrix_cnt) begin
        target_global_idx = size2matrix[valid_scale_r][valid_scale_c][valid_req_idx];
        matrix_valid = 1'b1;
    end else begin
        target_global_idx = {MATRIX_IDX_W{1'b0}};
        matrix_valid = 1'b0;
    end

    // 3.4 数据输出
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
    
    matrix_row = row_self[target_global_idx];
    matrix_col = col_self[target_global_idx];
end

endmodule