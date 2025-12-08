module matrix_size_traverse #(
    parameter SEL_IDX_W        = 2,        // 同规模索引位宽（对应MAX_MATRIX_PER_SIZE）
    parameter CLK_FREQ         = 100000000 // 系统时钟频率
)(
    input wire                     clk,
    input wire                     rst_n,
    // 遍历配置接口
    input wire                     traverse_trig,  // 遍历触发（高电平有效，仅触发一次）
    input wire [2:0]               traverse_row,   // 目标遍历规模（行）
    input wire [2:0]               traverse_col,   // 目标遍历规模（列）
    // 从矩阵模块获取的信息
    input wire [SEL_IDX_W-1:0]     size_cnt_out,   // 目标规模下的矩阵总数
    // 与矩阵模块的控制接口
    output reg                     sel_by_size,    // 强制按规模选择
    output reg [2:0]               sel_row,        // 选择的规模（行）
    output reg [2:0]               sel_col,        // 选择的规模（列）
    output reg [SEL_IDX_W-1:0]     sel_idx,        // 当前遍历的同规模索引
    // 与缓冲区/发送模块的控制接口
    output reg                     matrix_burst_en,// 矩阵缓存触发
    output reg                     send_trig,      // UART发送触发
    // 状态反馈接口
    input wire                     buf_full,       // 缓冲区已满
    input wire                     send_done,      // 单个矩阵发送完成
    output reg                     traverse_busy,  // 遍历中
    output reg                     traverse_done   // 遍历完成（脉冲）
);

// 遍历状态机定义
localparam IDLE          = 3'd0;  // 空闲
localparam WAIT_SIZE_CNT = 3'd1;  // 等待读取规模矩阵总数
localparam TRAVERSE_NEXT = 3'd2;  // 准备遍历下一个矩阵
localparam BUFFER_MATRIX = 3'd3;  // 触发矩阵缓存
localparam WAIT_BUF_FULL = 3'd4;  // 等待缓存满
localparam SEND_MATRIX   = 3'd5;  // 触发UART发送
localparam WAIT_SEND_DONE= 3'd6;  // 等待发送完成
localparam TRAVERSE_FINISH=3'd7;  // 遍历完成

reg [2:0] curr_state;
reg [2:0] next_state;
reg [SEL_IDX_W-1:0] total_matrix;  // 目标规模下的矩阵总数（缓存）
reg [SEL_IDX_W-1:0] curr_traverse_idx;  // 当前遍历索引（0~total_matrix-1）

// ---------------------------
// 1. 状态机寄存器（时序逻辑）
// ---------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        curr_state <= IDLE;
        total_matrix <= {SEL_IDX_W{1'b0}};
        curr_traverse_idx <= {SEL_IDX_W{1'b0}};
    end else begin
        curr_state <= next_state;
        case (curr_state)
            IDLE: begin
                if (traverse_trig) begin
                    curr_traverse_idx <= {SEL_IDX_W{1'b0}}; // 遍历索引从0开始
                end
            end
            WAIT_SIZE_CNT: begin
                total_matrix <= size_cnt_out; // 缓存目标规模的矩阵总数
            end
            TRAVERSE_NEXT: begin
                // 发送完成后，遍历索引自增
                if (send_done) begin
                    curr_traverse_idx <= curr_traverse_idx + 1'd1;
                end
            end
            TRAVERSE_FINISH: begin
                curr_traverse_idx <= {SEL_IDX_W{1'b0}}; // 重置遍历索引
                total_matrix <= {SEL_IDX_W{1'b0}};
            end
            default: ;
        endcase
    end
end

// ---------------------------
// 2. 状态转移逻辑（组合逻辑）
// ---------------------------
always @(*) begin
    next_state = curr_state;
    case (curr_state)
        IDLE: begin
            // 触发遍历，且当前无遍历任务
            if (traverse_trig && !traverse_busy) begin
                next_state = WAIT_SIZE_CNT;
            end
        end
        WAIT_SIZE_CNT: begin
            // 读取到矩阵总数后，判断是否有矩阵需要遍历
            if (total_matrix == 0) begin
                next_state = TRAVERSE_FINISH; // 无矩阵，直接完成
            end else begin
                next_state = BUFFER_MATRIX;   // 有矩阵，开始缓存第一个
            end
        end
        BUFFER_MATRIX: begin
            // 触发缓存后，等待缓存满
            next_state = WAIT_BUF_FULL;
        end
        WAIT_BUF_FULL: begin
            // 缓存满，触发发送
            if (buf_full) begin
                next_state = SEND_MATRIX;
            end
        end
        SEND_MATRIX: begin
            // 触发发送后，等待发送完成
            next_state = WAIT_SEND_DONE;
        end
        WAIT_SEND_DONE: begin
            // 发送完成，判断是否遍历完所有矩阵
            if (send_done) begin
                if (curr_traverse_idx == total_matrix - 1'd1) begin
                    next_state = TRAVERSE_FINISH; // 所有矩阵遍历完成
                end else begin
                    next_state = TRAVERSE_NEXT; // 遍历下一个矩阵
                end
            end
        end
        TRAVERSE_NEXT: begin
            // 切换到下一个矩阵，触发缓存
            next_state = BUFFER_MATRIX;
        end
        TRAVERSE_FINISH: begin
            // 遍历完成，回到空闲
            next_state = IDLE;
        end
    endcase
end

// ---------------------------
// 3. 输出控制逻辑（组合逻辑）
// ---------------------------
always @(*) begin
    // 默认输出
    sel_by_size = 1'b1;  // 遍历过程中强制按规模选择
    sel_row = traverse_row;
    sel_col = traverse_col;
    sel_idx = curr_traverse_idx;
    matrix_burst_en = 1'b0;
    send_trig = 1'b0;
    traverse_busy = 1'b0;
    traverse_done = 1'b0;

    case (curr_state)
        WAIT_SIZE_CNT, BUFFER_MATRIX, WAIT_BUF_FULL, SEND_MATRIX, WAIT_SEND_DONE, TRAVERSE_NEXT: begin
            traverse_busy = 1'b1; // 这些状态表示遍历中
        end
        BUFFER_MATRIX: begin
            matrix_burst_en = 1'b1; // 触发矩阵缓存
        end
        SEND_MATRIX: begin
            send_trig = 1'b1; // 触发UART发送
        end
        TRAVERSE_FINISH: begin
            traverse_done = 1'b1; // 遍历完成脉冲
        end
        default: ;
    endcase
end

endmodule