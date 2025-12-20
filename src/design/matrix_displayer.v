`timescale 1ns / 1ps

module matrix_displayer(
    input wire clk,
    input wire rst_n,
    
    // 控制信号
    input wire start,           // 保持名字不变
    output reg busy,            // 保持名字不变
    
    // 矩阵参数输入
    input wire [2:0] matrix_row,
    input wire [2:0] matrix_col,
    
    // 来自 Storage 的 25 个数据
    //这里必须改为 [8:0] 才能接收 405，名字和顺序严格保持不变
    input wire [8:0] d0,  input wire [8:0] d1,  input wire [8:0] d2,  input wire [8:0] d3,  input wire [8:0] d4,
    input wire [8:0] d5,  input wire [8:0] d6,  input wire [8:0] d7,  input wire [8:0] d8,  input wire [8:0] d9,
    input wire [8:0] d10, input wire [8:0] d11, input wire [8:0] d12, input wire [8:0] d13, input wire [8:0] d14,
    input wire [8:0] d15, input wire [8:0] d16, input wire [8:0] d17, input wire [8:0] d18, input wire [8:0] d19,
    input wire [8:0] d20, input wire [8:0] d21, input wire [8:0] d22, input wire [8:0] d23, input wire [8:0] d24,
    
    // UART 接口 
    input wire       tx_busy,   
    output reg       tx_start,  
    output reg [7:0] tx_data    // 推测：配套的数据端口名
);

    // 状态定义
    localparam S_IDLE           = 0;
    localparam S_PREPARE_DATA   = 1;
    localparam S_CALC_DIGITS    = 2; 
    localparam S_SEND_CHAR_1    = 3; 
    localparam S_SEND_CHAR_2    = 4; 
    localparam S_SEND_CHAR_3    = 5; 
    localparam S_WAIT_UART      = 6; 
    localparam S_SEND_SEP       = 7; 
    localparam S_CHECK_NEXT     = 8; 
    localparam S_DONE           = 9;
    localparam S_WAIT_RELEASE   = 10;

    reg [3:0] state, next_state_after_wait;
    reg [2:0] r_cnt;
    reg [2:0] c_cnt;
    
    reg [8:0] current_data; // 改为 9 位
    
    // 拆分数字用的寄存器
    reg [3:0] digit_hundreds;
    reg [3:0] digit_tens;
    reg [3:0] digit_units;
    
    localparam ASCII_0     = 8'd48;
    localparam ASCII_SPACE = 8'd32;
    localparam ASCII_LF    = 8'd10; 

    // 数据选择 logic
    reg [4:0] idx; 
    always @(*) begin
        idx = (r_cnt * 5) + c_cnt; 
        case(idx)
            5'd0:  current_data = d0;  5'd1:  current_data = d1;  5'd2:  current_data = d2;  5'd3:  current_data = d3;  5'd4:  current_data = d4;
            5'd5:  current_data = d5;  5'd6:  current_data = d6;  5'd7:  current_data = d7;  5'd8:  current_data = d8;  5'd9:  current_data = d9;
            5'd10: current_data = d10; 5'd11: current_data = d11; 5'd12: current_data = d12; 5'd13: current_data = d13; 5'd14: current_data = d14;
            5'd15: current_data = d15; 5'd16: current_data = d16; 5'd17: current_data = d17; 5'd18: current_data = d18; 5'd19: current_data = d19;
            5'd20: current_data = d20; 5'd21: current_data = d21; 5'd22: current_data = d22; 5'd23: current_data = d23; 5'd24: current_data = d24;
            default: current_data = 9'd0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            busy <= 0;
            tx_start <= 0;
            tx_data <= 0;
            r_cnt <= 0;
            c_cnt <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    busy <= 0;
                    if (start) begin
                        busy <= 1;
                        r_cnt <= 0;
                        c_cnt <= 0;
                        state <= S_PREPARE_DATA;
                    end
                end

                S_PREPARE_DATA: begin
                    state <= S_CALC_DIGITS;
                end

                S_CALC_DIGITS: begin
                    // 拆分 (0-511)
                    digit_hundreds <= current_data / 100;
                    digit_tens     <= (current_data % 100) / 10;
                    digit_units    <= current_data % 10;
                    state <= S_SEND_CHAR_1;
                end

                // --- 左对齐逻辑 ---
                
                // 1. 发第一个字符
                S_SEND_CHAR_1: begin
                    if (!tx_busy) begin
                        tx_start <= 1;
                        if (current_data >= 100)      tx_data <= digit_hundreds + ASCII_0; // 405 -> '4'
                        else if (current_data >= 10)  tx_data <= digit_tens + ASCII_0;     // 45  -> '4'
                        else                          tx_data <= digit_units + ASCII_0;    // 5   -> '5'
                        
                        next_state_after_wait <= S_SEND_CHAR_2;
                        state <= S_WAIT_UART;
                    end
                end

                // 2. 发第二个字符
                S_SEND_CHAR_2: begin
                    if (!tx_busy) begin 
                        tx_start <= 1;
                        if (current_data >= 100)      tx_data <= digit_tens + ASCII_0;     // 405 -> '0'
                        else if (current_data >= 10)  tx_data <= digit_units + ASCII_0;    // 45  -> '5'
                        else                          tx_data <= ASCII_SPACE;              // 5   -> ' ' (补空)
                        
                        next_state_after_wait <= S_SEND_CHAR_3;
                        state <= S_WAIT_UART;
                    end
                end

                // 3. 发第三个字符
                S_SEND_CHAR_3: begin
                    if (!tx_busy) begin
                        tx_start <= 1;
                        if (current_data >= 100)      tx_data <= digit_units + ASCII_0;    // 405 -> '5'
                        else                          tx_data <= ASCII_SPACE;              // 其他补空
                        
                        next_state_after_wait <= S_SEND_SEP;
                        state <= S_WAIT_UART;
                    end
                end

                S_WAIT_UART: begin
                    tx_start <= 0;
                    // 简单握手：只要忙了或者已经不忙了(脉冲发完)就继续
                    // 这里为了稳妥，配合你的 top 逻辑，等待 busy 过去
                    // 假设 UART 模块接收到 start 后会立刻拉高 busy
                    if (tx_busy) begin
                        // wait
                    end else begin
                        state <= next_state_after_wait;
                    end
                end

                S_SEND_SEP: begin
                    if (!tx_busy) begin
                        tx_start <= 1;
                        if (c_cnt == matrix_col - 1) 
                            tx_data <= ASCII_LF; // 换行
                        else 
                            tx_data <= ASCII_SPACE; // 空格
                        
                        next_state_after_wait <= S_CHECK_NEXT;
                        state <= S_WAIT_UART;
                    end
                end

                S_CHECK_NEXT: begin
                    if (c_cnt == matrix_col - 1) begin
                        c_cnt <= 0;
                        if (r_cnt == matrix_row - 1) state <= S_DONE;
                        else begin
                            r_cnt <= r_cnt + 1;
                            state <= S_PREPARE_DATA;
                        end
                    end else begin
                        c_cnt <= c_cnt + 1;
                        state <= S_PREPARE_DATA;
                    end
                end

                S_DONE: begin
                    busy <= 0;
                    state <= S_WAIT_RELEASE;
                end

                S_WAIT_RELEASE: begin
                    if (start == 0) state <= S_IDLE;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule