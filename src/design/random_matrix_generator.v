module random_matrix_generator #(
    parameter WIDTH    = 8,      // 单个随机数位宽
    parameter MAX_DIM  = 5       // 矩阵最大维度（5×5）
)(
    input  clk,                  // 时钟信号
    input  rst_n,                // 低电平复位
    input  [2:0] row,            // 矩阵行数（1~5）
    input  [2:0] col,            // 矩阵列数（1~5）
    input  [WIDTH-1:0] min_val,  // 随机数最小值（输入端口）
    input  [WIDTH-1:0] max_val,  // 随机数最大值（输入端口）
    input  update_en,            // 矩阵更新使能（高电平触发一次刷新）
    output reg [WIDTH-1:0] matrix_out0,
    output reg [WIDTH-1:0] matrix_out1,
    output reg [WIDTH-1:0] matrix_out2,
    output reg [WIDTH-1:0] matrix_out3,
    output reg [WIDTH-1:0] matrix_out4,
    output reg [WIDTH-1:0] matrix_out5,
    output reg [WIDTH-1:0] matrix_out6,
    output reg [WIDTH-1:0] matrix_out7,
    output reg [WIDTH-1:0] matrix_out8,
    output reg [WIDTH-1:0] matrix_out9,
    output reg [WIDTH-1:0] matrix_out10,
    output reg [WIDTH-1:0] matrix_out11,
    output reg [WIDTH-1:0] matrix_out12,
    output reg [WIDTH-1:0] matrix_out13,
    output reg [WIDTH-1:0] matrix_out14,
    output reg [WIDTH-1:0] matrix_out15,
    output reg [WIDTH-1:0] matrix_out16,
    output reg [WIDTH-1:0] matrix_out17,
    output reg [WIDTH-1:0] matrix_out18,
    output reg [WIDTH-1:0] matrix_out19,
    output reg [WIDTH-1:0] matrix_out20,
    output reg [WIDTH-1:0] matrix_out21,
    output reg [WIDTH-1:0] matrix_out22,
    output reg [WIDTH-1:0] matrix_out23,
    output reg [WIDTH-1:0] matrix_out24,
    output reg update_done       // 矩阵更新完成标志（高电平表示数据有效）
);

// 内部临时数组（仅内部使用）
reg [WIDTH-1:0] matrix_temp [0:24];
// 内部信号：新增“更新中”标志，避免重复触发
reg [4:0] cnt;                  // 元素索引计数器（0~24）
reg updating;                   // 刷新中标志（1=正在刷新，0=空闲）
wire [WIDTH-1:0] random_num;    // 单个随机数
wire [2:0] valid_row;
wire [2:0] valid_col;
wire [2:0] curr_row;
wire [2:0] curr_col;
wire valid_pos;

// 行列钳位和有效位置判断
assign valid_row = (row < 1) ? 1 : (row > MAX_DIM) ? MAX_DIM : row;
assign valid_col = (col < 1) ? 1 : (col > MAX_DIM) ? MAX_DIM : col;
assign curr_row = cnt / MAX_DIM;
assign curr_col = cnt % MAX_DIM;
assign valid_pos = (curr_row < valid_row) && (curr_col < valid_col);

// 实例化随机数生成器（传递动态范围输入）
random_num_generator #(
    .WIDTH(WIDTH)
) u_rng (
    .clk(clk),
    .rst_n(rst_n),
    .en(updating),
    .min_val(min_val),  // 动态输入最小值
    .max_val(max_val),  // 动态输入最大值
    .random_num(random_num)
);

// 步骤1：更新触发逻辑（仅在update_en且空闲时启动刷新）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        updating <= 1'b0;
    end else if (update_en && !updating) begin  // 仅在“使能且未刷新”时启动
        updating <= 1'b1;
    end else if (cnt == 24) begin              // 刷新到最后一个元素，停止
        updating <= 1'b0;
    end
end

// 步骤2：计数器逻辑（仅在“刷新中”时递增，否则暂停）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 5'd0;
    end else if (updating) begin               // 仅刷新中更新计数器
        cnt <= (cnt == 24) ? 5'd0 : cnt + 1'b1;
    end else begin
        cnt <= 5'd0;                           // 空闲时计数器复位
    end
end
integer i;
// 步骤3：填充临时矩阵（仅刷新中赋值，否则保持）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        
        for (i = 0; i < 25; i = i + 1) begin
            matrix_temp[i] <= {WIDTH{1'b0}};
        end
    end else if (updating) begin               // 仅刷新中更新临时矩阵
        matrix_temp[cnt] <= valid_pos ? random_num : {WIDTH{1'b0}};
    end
end

// 步骤4：输出端口赋值（仅刷新中更新，否则保持）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        matrix_out0  <= {WIDTH{1'b0}};
        matrix_out1  <= {WIDTH{1'b0}};
        matrix_out2  <= {WIDTH{1'b0}};
        matrix_out3  <= {WIDTH{1'b0}};
        matrix_out4  <= {WIDTH{1'b0}};
        matrix_out5  <= {WIDTH{1'b0}};
        matrix_out6  <= {WIDTH{1'b0}};
        matrix_out7  <= {WIDTH{1'b0}};
        matrix_out8  <= {WIDTH{1'b0}};
        matrix_out9  <= {WIDTH{1'b0}};
        matrix_out10 <= {WIDTH{1'b0}};
        matrix_out11 <= {WIDTH{1'b0}};
        matrix_out12 <= {WIDTH{1'b0}};
        matrix_out13 <= {WIDTH{1'b0}};
        matrix_out14 <= {WIDTH{1'b0}};
        matrix_out15 <= {WIDTH{1'b0}};
        matrix_out16 <= {WIDTH{1'b0}};
        matrix_out17 <= {WIDTH{1'b0}};
        matrix_out18 <= {WIDTH{1'b0}};
        matrix_out19 <= {WIDTH{1'b0}};
        matrix_out20 <= {WIDTH{1'b0}};
        matrix_out21 <= {WIDTH{1'b0}};
        matrix_out22 <= {WIDTH{1'b0}};
        matrix_out23 <= {WIDTH{1'b0}};
        matrix_out24 <= {WIDTH{1'b0}};
    end else if (updating) begin               // 仅刷新中更新输出端口
        matrix_out0  <= matrix_temp[0];
        matrix_out1  <= matrix_temp[1];
        matrix_out2  <= matrix_temp[2];
        matrix_out3  <= matrix_temp[3];
        matrix_out4  <= matrix_temp[4];
        matrix_out5  <= matrix_temp[5];
        matrix_out6  <= matrix_temp[6];
        matrix_out7  <= matrix_temp[7];
        matrix_out8  <= matrix_temp[8];
        matrix_out9  <= matrix_temp[9];
        matrix_out10 <= matrix_temp[10];
        matrix_out11 <= matrix_temp[11];
        matrix_out12 <= matrix_temp[12];
        matrix_out13 <= matrix_temp[13];
        matrix_out14 <= matrix_temp[14];
        matrix_out15 <= matrix_temp[15];
        matrix_out16 <= matrix_temp[16];
        matrix_out17 <= matrix_temp[17];
        matrix_out18 <= matrix_temp[18];
        matrix_out19 <= matrix_temp[19];
        matrix_out20 <= matrix_temp[20];
        matrix_out21 <= matrix_temp[21];
        matrix_out22 <= matrix_temp[22];
        matrix_out23 <= matrix_temp[23];
        matrix_out24 <= matrix_temp[24];
    end
end

// 步骤5：更新完成标志（刷新到最后一个元素时置1，下次触发前保持）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        update_done <= 1'b0;
    end else if (cnt == 24 && updating) begin  // 最后一个元素刷新完成
        update_done <= 1'b1;
    end else if (update_en) begin              // 新触发时清零，避免误判
        update_done <= 1'b0;
    end
end

endmodule
