`timescale 1ns / 1ps

module countdown (
    clk, 
    reset, 
    en, 
    load_seconds, 
    seconds_display, 
    done,
    led1,
    led2,
    current_time
);

    // ---------------- 参数定义 ----------------
    parameter CLK_FREQ = 100000000; 
    // 定义 done 信号保持的高电平周期数（例如保持 5 个时钟周期）
    parameter DONE_HOLD_CYCLES = 5;

    // ---------------- 端口定义 ----------------
    input clk;
    input reset;
    input en;
    input [7:0] load_seconds;
    
    output [8:0] seconds_display;
    output done;
    output reg led1;
    output reg led2;
    output reg [7:0] current_time;

    // ---------------- 内部寄存器 ----------------
    reg [31:0] clk_cnt;
    reg        is_active;
    reg        done_reg;
    
    // 【新增】用于控制 done 信号保持时间的计数器
    reg [3:0]  done_hold_cnt; 

    // ---------------- 时序逻辑 ----------------
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            clk_cnt       <= 0;
            current_time  <= 0;
            is_active     <= 0;
            done_reg      <= 0;
            led1          <= 0;
            led2          <= 0;
            done_hold_cnt <= 0; // 复位保持计数器
        end 
        else begin
            // ---------------- 1. 启动逻辑 ----------------
            if (en) begin
                current_time  <= load_seconds;
                is_active     <= 1;
                done_reg      <= 0;
                clk_cnt       <= 0;
                done_hold_cnt <= 0; // 清零保持计数器
                
                led1 <= 1; // 启动时点亮 LED1
                led2 <= 0; // 重置 LED2
            end 
            // ---------------- 2. 倒计时运行逻辑 ----------------
            else if (is_active) begin
                // 1秒计时到达
                if (clk_cnt == CLK_FREQ - 1) begin
                    clk_cnt <= 0;
                    led2    <= ~led2; // 建议：让 LED2 翻转闪烁，而不是常亮
                    
                    if (current_time > 0) begin
                        current_time <= current_time - 1;
                    end 
                    else begin
                        // 倒计时刚刚结束的那个瞬间
                        is_active     <= 0; 
                        done_reg      <= 1; // 拉高 done
                        // 【关键】装载保持计数器，设定 done 保持的时钟周期数
                        done_hold_cnt <= DONE_HOLD_CYCLES; 
                        
                        led1 <= 0; // 结束时熄灭 LED1
                    end
                end 
                else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
            // ---------------- 3. 倒计时结束后的处理逻辑 ----------------
            else begin
                clk_cnt <= 0;
                
                // 如果保持计数器大于 0，说明 done 还需要保持高电平
                if (done_hold_cnt > 0) begin
                    done_hold_cnt <= done_hold_cnt - 1; // 计数器递减
                    
                    // 当计数器减到 1 时，拉低 done 信号
                    if (done_hold_cnt == 1) begin
                        done_reg <= 0;
                    end
                end
                else begin
                    // 确保稳态时为 0
                    done_reg <= 0;
                end
            end
        end
    end

    // ---------------- 输出赋值 ----------------
    assign done = done_reg;

    wire [3:0] tens;
    wire [3:0] ones;
    assign tens = current_time / 10;
    assign ones = current_time % 10;
    
    assign seconds_display = {is_active, tens, ones};

endmodule