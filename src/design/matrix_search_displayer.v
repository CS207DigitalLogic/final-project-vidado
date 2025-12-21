`timescale 1ns / 1ps

module matrix_search_displayer #(
    parameter MAX_MATRICES = 8, 
    parameter DATA_WIDTH   = 9   // 默认位宽改为9以适配 top4
)(
    input wire clk,
    input wire rst_n,
    
    // --- 控制信号 ---
    input wire start,              // 启动脉冲
    output reg busy,               // 忙信号
    
    // --- 用户搜索条件 ---
    input wire [2:0] target_row,   // 目标行数
    input wire [2:0] target_col,   // 目标列数
    
    // --- 与 multi_matrix_storage 的接口 ---
    // 输出查询请求
    output reg [2:0]  req_scale_row,
    output reg [2:0]  req_scale_col,
    output reg [2:0]  req_idx,
    
    // 从存储读取的信息
    input  wire [2:0] scale_matrix_cnt,      // 该规格下有多少个矩阵
    input  wire [25*DATA_WIDTH-1:0] read_data, // 扁平化的矩阵数据 (需在top层拼接)
    
    // --- UART TX 接口 ---
    output reg [7:0] tx_data,
    output reg       tx_start,
    input  wire      tx_busy
);

    // 状态机定义
    localparam S_IDLE        = 0;
    localparam S_INIT_REQ    = 1; // 初始化查询请求
    localparam S_WAIT_CNT    = 2; // 等待 count 稳定
    localparam S_CHECK_LOOP  = 3; // 检查循环条件
    localparam S_READ_MAT    = 4; // 请求特定 index 的矩阵
    localparam S_WAIT_DATA   = 5; // 等待数据稳定
    localparam S_LATCH_DATA  = 6; // 锁存数据
    
    localparam S_SEND_IDX    = 7; // 发送 Index 字符
    localparam S_SEND_IDX_NL = 8; // 发送 Index 后的换行
    
    localparam S_CALC_DIGIT  = 9; // 计算当前元素的十进制位
    localparam S_SEND_DIGIT_3= 10; // 发送百位
    localparam S_SEND_DIGIT_2= 11; // 发送十位
    localparam S_SEND_DIGIT_1= 12; // 发送个位
    localparam S_SEND_SEP    = 13; // 发送分隔符 (空格/换行)
    
    localparam S_MAT_NL      = 14; // 矩阵输出完后的换行
    localparam S_NEXT_MAT    = 15; // 准备下一个矩阵
    localparam S_DONE        = 16;

    reg [4:0] state;
    
    reg [2:0] curr_idx;    // 当前正在处理的矩阵索引 (0~MAX)
    reg [2:0] total_cnt;   // 锁存的总数
    
    // 矩阵遍历计数器
    reg [2:0] r_cnt;
    reg [2:0] c_cnt;
    
    // 数据缓存
    reg [DATA_WIDTH-1:0] mat_cache [0:24];
    reg [DATA_WIDTH-1:0] current_val; // 当前要发送的数值
    
    // 十进制转换缓存
    reg [3:0] digit_hundreds;
    reg [3:0] digit_tens;
    reg [3:0] digit_ones;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            busy <= 0;
            tx_start <= 0;
            req_scale_row <= 0;
            req_scale_col <= 0;
            req_idx <= 0;
            tx_data <= 0;
        end else begin
            // 自动清除 tx_start
            if (tx_start && !tx_busy) tx_start <= 0; 
            
            case (state)
                S_IDLE: begin
                    busy <= 0;
                    if (start) begin
                        busy <= 1;
                        state <= S_INIT_REQ;
                    end
                end

                // 1. 设置查询维度
                S_INIT_REQ: begin
                    req_scale_row <= target_row;
                    req_scale_col <= target_col;
                    req_idx <= 0; // 先指向0，顺便获取 count
                    state <= S_WAIT_CNT;
                end
                
                // 2. 等待 Storage 输出 count (假设组合逻辑，1拍即可，多等一拍保险)
                S_WAIT_CNT: begin
                    state <= S_CHECK_LOOP;
                end

                // 3. 检查是否有矩阵需要输出
                S_CHECK_LOOP: begin
                    total_cnt <= scale_matrix_cnt; // 锁存总数
                    if (scale_matrix_cnt == 0) begin
                        state <= S_DONE;
                    end else begin
                        curr_idx <= 0;
                        state <= S_READ_MAT;
                    end
                end

                // 4. 读取当前 idx 的矩阵
                S_READ_MAT: begin
                    req_idx <= curr_idx;
                    state <= S_WAIT_DATA;
                end
                
                S_WAIT_DATA: begin
                    // 等待 storage 输出数据稳定
                    state <= S_LATCH_DATA; 
                end

                S_LATCH_DATA: begin
                    // 将扁平数据锁存到本地 cache
                    // 注意：top层拼接时需保证顺序：{data24, ..., data0} 或根据实际情况
                    // 这里假设低位是 data0
                    for (i=0; i<25; i=i+1) begin
                        mat_cache[i] <= read_data[i*DATA_WIDTH +: DATA_WIDTH];
                    end
                    r_cnt <= 0;
                    c_cnt <= 0;
                    state <= S_SEND_IDX;
                end

                // 5. 发送编号 (Index + 1)
                S_SEND_IDX: begin
                    if (!tx_busy && !tx_start) begin
                        tx_data <= (curr_idx + 1'b1) + "0"; // 转换为ASCII (假设数量<=9)
                        tx_start <= 1;
                        state <= S_SEND_IDX_NL;
                    end
                end

                S_SEND_IDX_NL: begin
                    if (!tx_busy && !tx_start) begin
                        tx_data <= 8'h0A; // \n
                        tx_start <= 1;
                        state <= S_CALC_DIGIT;
                    end
                end

                // 6. 准备发送矩阵元素
                S_CALC_DIGIT: begin
                    // 取出当前元素
                    current_val = mat_cache[ {2'b0, r_cnt} * {2'b0, target_col} + {2'b0, c_cnt} ];
                    
                    // 简单的二进制转BCD (支持 0~999)
                    digit_hundreds = current_val / 100;
                    digit_tens     = (current_val % 100) / 10;
                    digit_ones     = current_val % 10;
                    
                    state <= S_SEND_DIGIT_3; // 从百位开始判断
                end

                // 发送百位 (如果为0则不发，除非数值本身就是0且这是最后一位? 不，这里简化逻辑：
                // 如果百位>0，发百位。如果百位=0，不发)
                // 为了对齐美观，如果不发百位，可以发空格？用户未要求，这里仅做非零打印或简单打印。
                // 采用逻辑：
                // >99: 发百位, 十位, 个位
                // >9:  发十位, 个位
                // else: 发个位
                
                S_SEND_DIGIT_3: begin 
                    if (current_val >= 100) begin
                        if (!tx_busy && !tx_start) begin
                            tx_data <= digit_hundreds + "0";
                            tx_start <= 1;
                            state <= S_SEND_DIGIT_2;
                        end
                    end else begin
                        state <= S_SEND_DIGIT_2; // 跳过百位
                    end
                end

                S_SEND_DIGIT_2: begin
                    if (current_val >= 10) begin
                        if (!tx_busy && !tx_start) begin
                            tx_data <= digit_tens + "0";
                            tx_start <= 1;
                            state <= S_SEND_DIGIT_1;
                        end
                    end else begin
                        state <= S_SEND_DIGIT_1; // 跳过十位
                    end
                end

                S_SEND_DIGIT_1: begin
                    if (!tx_busy && !tx_start) begin
                        tx_data <= digit_ones + "0";
                        tx_start <= 1;
                        state <= S_SEND_SEP;
                    end
                end

                // 7. 发送分隔符 (行内用空格，行末用换行)
                S_SEND_SEP: begin
                    if (!tx_busy && !tx_start) begin
                        if (c_cnt == target_col - 1) begin
                            tx_data <= 8'h0A; // 行末换行
                        end else begin
                            tx_data <= 8'h20; // 元素间空格
                        end
                        tx_start <= 1;
                        
                        // 更新循环变量
                        if (c_cnt == target_col - 1) begin
                            c_cnt <= 0;
                            if (r_cnt == target_row - 1) begin
                                state <= S_MAT_NL; // 矩阵发完了
                            end else begin
                                r_cnt <= r_cnt + 1;
                                state <= S_CALC_DIGIT;
                            end
                        end else begin
                            c_cnt <= c_cnt + 1;
                            state <= S_CALC_DIGIT;
                        end
                    end
                end
                
                // 8. 矩阵后的额外换行
                S_MAT_NL: begin
                    if (!tx_busy && !tx_start) begin
                        tx_data <= 8'h0A; // \n
                        tx_start <= 1;
                        state <= S_NEXT_MAT;
                    end
                end

                // 9. 寻找下一个矩阵
                S_NEXT_MAT: begin
                    if (curr_idx == total_cnt - 1) begin
                        state <= S_DONE;
                    end else begin
                        curr_idx <= curr_idx + 1;
                        state <= S_READ_MAT; // 回去读下一个
                    end
                end

                S_DONE: begin
                    busy <= 0;
                    if (start == 1'b0) begin
                        // 只有当外界把 start 撤销了，才回到原点
                        state <= S_IDLE;
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule