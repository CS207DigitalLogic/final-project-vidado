module multi_matrix_storage #(
    parameter DATA_WIDTH        = 8,        // 数据位宽
    parameter MAX_SIZE          = 5,        // 单个矩阵最大规模（1~5）
    parameter MATRIX_NUM        = 8,        // 全局最大矩阵数量
    parameter MAX_MATRIX_PER_SIZE = 4       // 每个规模最多存储矩阵数
)(
    input wire                     clk,            // 时钟
    input wire                     rst_n,          // 低有效复位
    // 写入接口（绑定存储规模）
    input wire                     wr_en,          // 写使能
    input wire [MATRIX_IDX_W-1:0]  matrix_idx,     // 全局矩阵索引（写入目标）
    input wire [2:0]               store_row,      // 存储时的矩阵行数（固定）
    input wire [2:0]               store_col,      // 存储时的矩阵列数（固定）
    input wire [ADDR_IN_W-1:0]     wr_addr_in,     // 矩阵内写地址（0~24）
    input wire [DATA_WIDTH-1:0]    wr_data,        // 写数据
    // 选择矩阵接口（两种方式）
    input wire                     sel_by_size,    // 1=按规模选择，0=按全局索引
    input wire [2:0]               sel_row,        // 选择的规模（行数）
    input wire [2:0]               sel_col,        // 选择的规模（列数）
    input wire [SEL_IDX_W-1:0]     sel_idx,        // 同规模下的矩阵索引
    // 读取/输出接口
    input wire                     rd_en,          // 随机读使能
    input wire [ADDR_IN_W-1:0]     rd_addr_in,     // 矩阵内随机读地址
    input wire                     burst_en,       // 连续输出使能（缓存触发）
    output reg [DATA_WIDTH-1:0]    rd_data,        // 读出数据
    output reg                      burst_done,     // 连续输出完成脉冲
    // 状态反馈接口
    output reg [2:0]               curr_store_row, // 当前选中矩阵的存储行数
    output reg [2:0]               curr_store_col, // 当前选中矩阵的存储列数
    output reg [MATRIX_IDX_W-1:0]  curr_matrix_idx, // 当前选中的全局矩阵索引
    // 遍历相关接口（输出目标规模矩阵总数）
    input wire [2:0]               traverse_row,   // 遍历的目标规模（行）
    input wire [2:0]               traverse_col,   // 遍历的目标规模（列）
    output reg [SEL_IDX_W-1:0]     size_cnt_out    // 目标规模下的矩阵总数
);

// ---------------------------
// 局部参数（自动计算）
// ---------------------------
localparam MEM_DEPTH_PER_MATRIX = MAX_SIZE * MAX_SIZE;  // 单个矩阵存储深度（25）
localparam ADDR_IN_W = (MEM_DEPTH_PER_MATRIX <= 1)  ? 1 :  // 1个元素→1位（0）
                      (MEM_DEPTH_PER_MATRIX <= 2)  ? 2 :  // 2个元素→2位（0~1）
                      (MEM_DEPTH_PER_MATRIX <= 4)  ? 3 :  // 3~4个元素→3位（0~3）
                      (MEM_DEPTH_PER_MATRIX <= 8)  ? 4 :  // 5~8个元素→4位（0~7）
                      (MEM_DEPTH_PER_MATRIX <= 16) ? 5 :  // 9~16个元素→5位（0~15）
                      (MEM_DEPTH_PER_MATRIX <= 32) ? 6 :  // 17~32个元素→6位（0~31）
                      (MEM_DEPTH_PER_MATRIX <= 64) ? 7 :  // 33~64个元素→7位（0~63）
                      8;  // 最大支持128个元素（足够MAX_SIZE=10→100个元素）

// 2. 全局矩阵索引位宽 MATRIX_IDX_W（替代 $clog2(MATRIX_NUM)）
// MATRIX_NUM：全局最大矩阵数量
localparam MATRIX_IDX_W = (MATRIX_NUM <= 1)  ? 1 :  // 1个矩阵→1位（0）
                         (MATRIX_NUM <= 2)  ? 2 :  // 2个矩阵→2位（0~1）
                         (MATRIX_NUM <= 4)  ? 3 :  // 3~4个矩阵→3位（0~3）
                         (MATRIX_NUM <= 8)  ? 3 :  // 5~8个矩阵→3位（0~7）
                         (MATRIX_NUM <= 16) ? 4 :  // 9~16个矩阵→4位（0~15）
                         (MATRIX_NUM <= 32) ? 5 :  // 17~32个矩阵→5位（0~31）
                         6;  // 最大支持64个矩阵（满足绝大多数场景）

// 3. 同规模索引位宽 SEL_IDX_W（替代 $clog2(MAX_MATRIX_PER_SIZE)）
// MAX_MATRIX_PER_SIZE：每个规模最多存储的矩阵数
localparam SEL_IDX_W = (MAX_MATRIX_PER_SIZE <= 1)  ? 1 :  // 1个矩阵→1位（0）
                      (MAX_MATRIX_PER_SIZE <= 2)  ? 2 :  // 2个矩阵→2位（0~1）
                      (MAX_MATRIX_PER_SIZE <= 4)  ? 2 :  // 3~4个矩阵→2位（0~3）
                      (MAX_MATRIX_PER_SIZE <= 8)  ? 3 :  // 5~8个矩阵→3位（0~7）
                      (MAX_MATRIX_PER_SIZE <= 16) ? 4 :  // 9~16个矩阵→4位（0~15）
                      5;  // 最大支持32个矩阵/规模
localparam ROW_RANGE            = MAX_SIZE;  // 行数范围（1~5）
localparam COL_RANGE            = MAX_SIZE;  // 列数范围（1~5）

// ---------------------------
// 内部信号定义
// ---------------------------
// 1. 全局存储：所有矩阵元素
reg [DATA_WIDTH-1:0] mem [0:MATRIX_NUM-1] [0:MEM_DEPTH_PER_MATRIX-1];

// 2. 每个矩阵的自身存储规模（固定，写入时确定）
reg [2:0] row_self [0:MATRIX_NUM-1];  // 矩阵m的存储行数
reg [2:0] col_self [0:MATRIX_NUM-1];  // 矩阵m的存储列数

// 3. 规模-矩阵索引映射表：[行][列][同规模索引] → 全局矩阵索引
reg [MATRIX_IDX_W-1:0] size2matrix [1:ROW_RANGE] [1:COL_RANGE] [0:MAX_MATRIX_PER_SIZE-1];

// 4. 每个规模下的矩阵计数器（记录当前存储个数）
reg [SEL_IDX_W-1:0] size_cnt [1:ROW_RANGE] [1:COL_RANGE];

// 5. 有效选择的全局矩阵索引（处理两种选择方式的越界）
reg [MATRIX_IDX_W-1:0] valid_global_idx;

// 6. 连续输出计数器与当前矩阵总元素数
reg [ADDR_IN_W-1:0] burst_cnt;
wire [ADDR_IN_W-1:0] curr_total;  // 当前矩阵总元素数（row_self * col_self）

assign curr_total = curr_store_row * curr_store_col;

// 处理目标规模越界（无效规模默认1x1）
wire [2:0] r_traverse = (traverse_row >=1 && traverse_row <= MAX_SIZE) ? traverse_row : 1'd1;
wire [2:0] c_traverse = (traverse_col >=1 && traverse_col <= MAX_SIZE) ? traverse_col : 1'd1;

// ---------------------------
// 1. 复位初始化（所有寄存器清零）
// ---------------------------
integer m;
integer d;
integer r;
integer c;
integer s;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 全局存储初始化
    if (!rst_n) 
    begin
        
    // 遍历矩阵编号（m）+ 单个矩阵内的深度（d）
    for (m = 0; m < MATRIX_NUM; m = m + 1) 
    begin
        for (d = 0; d < MEM_DEPTH_PER_MATRIX; d = d + 1) 
        begin
            // 完整索引：mem[矩阵编号][矩阵内深度]
            mem[m][d] <= {DATA_WIDTH{1'b0}}; 
        end
    end
end
        // 规模映射表和计数器初始化
        for ( r= 1; r <= ROW_RANGE; r=r+1) 
        begin
            for (c = 1; c <= COL_RANGE; c=c+1) 
            begin
                size_cnt[r][c] <= {SEL_IDX_W{1'b0}};
                for (s = 0; s < MAX_MATRIX_PER_SIZE; s=s+1) 
                begin
                    size2matrix[r][c][s] <= {MATRIX_IDX_W{1'b0}};
                end
            end
        end
        // 输出相关初始化
        valid_global_idx <= {MATRIX_IDX_W{1'b0}};
        curr_store_row <= 1'd1;
        curr_store_col <= 1'd1;
        curr_matrix_idx <= {MATRIX_IDX_W{1'b0}};
        burst_cnt <= {ADDR_IN_W{1'b0}};
        burst_done <= 1'b0;
        rd_data <= {DATA_WIDTH{1'b0}};
        size_cnt_out <= {SEL_IDX_W{1'b0}};
    end
end

// ---------------------------
// 2. 目标规模矩阵总数输出（时序逻辑）
// ---------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        size_cnt_out <= {SEL_IDX_W{1'b0}};
    end else begin
        size_cnt_out <= size_cnt[r_traverse][c_traverse]; // 从规模计数器中读取
    end
end

// ---------------------------
// 3. 矩阵选择逻辑（两种方式：全局索引 / 规模+同规模索引）
// ---------------------------
reg [2:0] r_valid, c_valid;
reg [SEL_IDX_W-1:0] s_valid;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_global_idx <= {MATRIX_IDX_W{1'b0}};
    end else begin
        if (sel_by_size) begin
            // 方式1：按规模选择（sel_row x sel_col）+ 同规模索引（sel_idx）
            
            // 处理规模越界（无效规模默认1x1）
            r_valid = (sel_row >= 1 && sel_row <= MAX_SIZE) ? sel_row : 1'd1;
            c_valid = (sel_col >= 1 && sel_col <= MAX_SIZE) ? sel_col : 1'd1;
            // 处理同规模索引越界（默认选中第0个）
            s_valid = (sel_idx < size_cnt[r_valid][c_valid]) ? sel_idx : {SEL_IDX_W{1'b0}};
            // 从映射表中获取全局索引
            valid_global_idx <= size2matrix[r_valid][c_valid][s_valid];
        end else begin
            // 方式2：按全局索引选择（原有方式，处理越界）
            valid_global_idx <= (matrix_idx < MATRIX_NUM) ? matrix_idx : {MATRIX_IDX_W{1'b0}};
        end
    end
end

// 更新当前选中矩阵的存储规模和全局索引（组合逻辑，实时同步）
always @(*) begin
    curr_matrix_idx = valid_global_idx;
    curr_store_row = row_self[valid_global_idx];
    curr_store_col = col_self[valid_global_idx];
end

// ---------------------------
// 4. 矩阵写入逻辑（绑定存储规模，更新映射表）
// ---------------------------
reg [2:0] r_store, c_store;
reg [SEL_IDX_W-1:0] curr_cnt;
always @(posedge clk) begin
    if (wr_en && (matrix_idx < MATRIX_NUM)) 
    begin
        // 4.1 写入矩阵元素（地址越界时不写）
        if (wr_addr_in < MEM_DEPTH_PER_MATRIX) 
        begin
            mem[matrix_idx][wr_addr_in] <= wr_data;
        end
        // 4.2 记录该矩阵的存储规模（处理无效存储规模，默认1x1）
        r_store = (store_row >= 1 && store_row <= MAX_SIZE) ? store_row : 1'd1;
        c_store = (store_col >= 1 && store_col <= MAX_SIZE) ? store_col : 1'd1;
        row_self[matrix_idx] <= r_store;
        col_self[matrix_idx] <= c_store;
        // 4.3 将矩阵索引加入对应规模的映射表（未达上限时）
        if (size_cnt[r_store][c_store] < MAX_MATRIX_PER_SIZE) 
        begin
            curr_cnt = size_cnt[r_store][c_store];
            size2matrix[r_store][c_store][curr_cnt] <= matrix_idx;
            size_cnt[r_store][c_store] <= curr_cnt + 1'd1;
        end
    end
end

// ---------------------------
// 5. 连续输出计数器控制（按存储规模输出所有元素）
// ---------------------------
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) 
    begin
        burst_cnt <= {ADDR_IN_W{1'b0}};
        burst_done <= 1'b0;
    end 
    else 
    begin
        burst_done <= 1'b0;
        if (burst_en) 
        begin
            if (burst_cnt < (curr_total - 1'd1)) 
            begin
                burst_cnt <= burst_cnt + 1'd1;
            end 
            else 
            begin
                burst_cnt <= {ADDR_IN_W{1'b0}};
                burst_done <= 1'b1;  // 输出完成脉冲
            end
        end 
        else 
        begin
            burst_cnt <= {ADDR_IN_W{1'b0}};
        end
    end
end

// ---------------------------
// 6. 读数据选择（随机读/连续输出，按存储规模）
// ---------------------------
always @(*) begin
    if (burst_en) begin
        // 连续输出：按存储规模的总元素数，读取当前选中矩阵的元素
        rd_data = (burst_cnt < curr_total) ? mem[valid_global_idx][burst_cnt] : {DATA_WIDTH{1'b0}};
    end else if (rd_en && (rd_addr_in < MEM_DEPTH_PER_MATRIX)) begin
        // 随机读：读取当前选中矩阵的指定元素
        rd_data = mem[valid_global_idx][rd_addr_in];
    end else begin
        rd_data = {DATA_WIDTH{1'b0}};
    end
end

// 在复位逻辑中添加预存矩阵（复位后自动存储3个2x3矩阵、1个3x4矩阵）
integer gg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 原有初始化代码...
        
        // 预存2x3矩阵0（全局索引0，数据0x01~0x06）
        mem[0][0] <= 8'h01; mem[0][1] <= 8'h02; mem[0][2] <= 8'h03;
        mem[0][3] <= 8'h04; mem[0][4] <= 8'h05; mem[0][5] <= 8'h06;
        row_self[0] <= 3'd2; col_self[0] <= 3'd3;
        
        // 预存2x3矩阵1（全局索引1，数据0x11~0x16）
        mem[1][0] <= 8'h11; mem[1][1] <= 8'h12; mem[1][2] <= 8'h13;
        mem[1][3] <= 8'h14; mem[1][4] <= 8'h15; mem[1][5] <= 8'h16;
        row_self[1] <= 3'd2; col_self[1] <= 3'd3;
        
        // 预存2x3矩阵2（全局索引2，数据0x21~0x26）
        mem[2][0] <= 8'h21; mem[2][1] <= 8'h22; mem[2][2] <= 8'h23;
        mem[2][3] <= 8'h24; mem[2][4] <= 8'h25; mem[2][5] <= 8'h26;
        row_self[2] <= 3'd2; col_self[2] <= 3'd3;
        
        // 预存3x4矩阵（全局索引3，数据0x31~0x3C）
        for (gg=0; gg<12; gg=gg+1) mem[3][gg] <= 8'h31 + gg;
        row_self[3] <= 3'd3; col_self[3] <= 3'd4;
        
        // 更新规模映射表和计数器（2x3规模有3个矩阵，3x4有1个）
        size2matrix[2][3][0] <= 3'd0; size2matrix[2][3][1] <= 3'd1; size2matrix[2][3][2] <= 3'd2;
        size_cnt[2][3] <= 3'd3;
        size2matrix[3][4][0] <= 3'd3;
        size_cnt[3][4] <= 3'd1;
    end
end



endmodule