`timescale 1ns / 1ps

module matrix_displayer(
    input wire clk,
    input wire rst_n,
    
    // 控制信号
    input wire start,           // 开始显示的脉冲
    output reg busy,            // 模块忙信号
    
    // 矩阵参数输入
    input wire [2:0] matrix_row, // 矩阵行数
    input wire [2:0] matrix_col, // 矩阵列数
    
    // 来自 Storage 的 25 个数据
    input wire [7:0] d0,  input wire [7:0] d1,  input wire [7:0] d2,  input wire [7:0] d3,  input wire [7:0] d4,
    input wire [7:0] d5,  input wire [7:0] d6,  input wire [7:0] d7,  input wire [7:0] d8,  input wire [7:0] d9,
    input wire [7:0] d10, input wire [7:0] d11, input wire [7:0] d12, input wire [7:0] d13, input wire [7:0] d14,
    input wire [7:0] d15, input wire [7:0] d16, input wire [7:0] d17, input wire [7:0] d18, input wire [7:0] d19,
    input wire [7:0] d20, input wire [7:0] d21, input wire [7:0] d22, input wire [7:0] d23, input wire [7:0] d24,

    // UART TX 接口
    output reg [7:0] tx_data,
    output reg       tx_start,
    input  wire      tx_busy
);

    // 状态机定义
    localparam S_IDLE       = 0;
    localparam S_PREPARE    = 1;
    localparam S_SEND_DIGIT = 2;
    localparam S_WAIT_DIGIT = 3;
    localparam S_SEND_SEP   = 4;
    localparam S_WAIT_SEP   = 5;
    localparam S_DONE       = 6; 
    localparam S_WAIT_RELEASE = 7; 
    reg [3:0] state;
    reg [2:0] r_cnt; // 行计数
    reg [2:0] c_cnt; // 列计数
    
    // 内部数据缓存（防止显示过程中 storage 变了）
    reg [7:0] data_cache [24:0]; 
    reg [7:0] current_val;

    // 数据选择逻辑：根据 (r, c) 选出对应的数据
    wire [4:0] current_index = r_cnt * matrix_col + c_cnt;

    // 整数转ASCII
    function [7:0] int2ascii;
        input [7:0] val;
        begin
            int2ascii = val + "0"; // 简单处理0-9，如果支持两位数需要更复杂逻辑
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            busy <= 0;
            tx_start <= 0;
            tx_data <= 0;
            r_cnt <= 0;
            c_cnt <= 0;
        end else begin
            // 默认拉低 Start
            tx_start <= 0;

            case (state)
                S_IDLE: begin
                busy <= 0;
                if (start) begin
                    // 边界检查：如果是 0x0 或无效尺寸，直接不启动
                    if (matrix_row == 0 || matrix_col == 0) begin
                       
                        state <= S_IDLE; 
                    end else begin
                        // 正常启动逻辑
                        busy <= 1;
                        r_cnt <= 0;
                        c_cnt <= 0;
                        state <= S_SEND_DIGIT;
                    end
                end
            end

                S_PREPARE: begin
                    // 将输入端口的数据锁存到内部缓存，保证显示时数据稳定
                    data_cache[0]<=d0;   data_cache[1]<=d1;   data_cache[2]<=d2;   data_cache[3]<=d3;   data_cache[4]<=d4;
                    data_cache[5]<=d5;   data_cache[6]<=d6;   data_cache[7]<=d7;   data_cache[8]<=d8;   data_cache[9]<=d9;
                    data_cache[10]<=d10; data_cache[11]<=d11; data_cache[12]<=d12; data_cache[13]<=d13; data_cache[14]<=d14;
                    data_cache[15]<=d15; data_cache[16]<=d16; data_cache[17]<=d17; data_cache[18]<=d18; data_cache[19]<=d19;
                    data_cache[20]<=d20; data_cache[21]<=d21; data_cache[22]<=d22; data_cache[23]<=d23; data_cache[24]<=d24;
                    
                    r_cnt <= 0;
                    c_cnt <= 0;
                    state <= S_SEND_DIGIT;
                end

                S_SEND_DIGIT: begin
                    if (!tx_busy) begin
                        // 1. 取出当前数字并转ASCII
                        current_val = data_cache[current_index];
                        tx_data <= int2ascii(current_val);
                        tx_start <= 1;
                        state <= S_WAIT_DIGIT;
                    end
                end

                S_WAIT_DIGIT: begin
                    // 等待串口忙碌起来，或者发送完成
                    // 一般这里只要发了start，下一周期tx_busy就会变高，或者我们可以简单给点延时
                    // 这里采用简单的状态跳转，因为 tx_busy 逻辑通常是立刻响应
                    tx_start <= 1'b0;
                    state <= S_SEND_SEP;
                end

                S_SEND_SEP: begin
                    if (!tx_busy) begin
                        // 判断是行末还是中间
                        if (c_cnt == matrix_col - 1) begin
                            tx_data <= 8'h0A; // 换行 (Line Feed)
                            // 某些终端可能需要 0D 0A，这里简化为 \n
                        end else begin
                            tx_data <= 8'h20; // 空格
                        end
                        tx_start <= 1;
                        state <= S_WAIT_SEP;
                    end
                end

                S_WAIT_SEP: begin
                    tx_start <= 1'b0;
                    if (!tx_busy) begin // 等待分隔符发完
                        // 更新计数器
                        if (c_cnt == matrix_col - 1) begin
                            c_cnt <= 0;
                            if (r_cnt == matrix_row - 1) begin
                                state <= S_DONE;
                            end else begin
                                r_cnt <= r_cnt + 1;
                                state <= S_SEND_DIGIT;
                            end
                        end else begin
                            c_cnt <= c_cnt + 1;
                            state <= S_SEND_DIGIT;
                        end
                    end
                end

                S_DONE: begin
                    busy <= 0;
                    state <= S_WAIT_RELEASE;
                end

                S_WAIT_RELEASE: begin
                    if (start == 1'b0) begin
                        // 只有当外界把 start 撤销了，才回到原点
                        state <= S_IDLE;
                    end
                end


                
            endcase
        end
    end

endmodule