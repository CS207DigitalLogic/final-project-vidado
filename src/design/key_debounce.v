/**
 * 按键消抖与脉冲生成模块
 * 功能：对机械按键输入进行同步、消抖处理，并检测下降沿生成单周期脉冲
 * 参数说明：
 *   clk - 系统时钟输入(100MHz)
 *   rst_n - 异步复位信号
 *   btn_trigger - 原始按键输入信号（通常低电平表示按下）
 *   btn_pulse - 按键按下时产生的单周期脉冲，输出高电平
 */
module key_debounce (
    input  wire clk,
    input  wire rst_n,
    input  wire btn_trigger,
    output reg  btn_pulse
);

reg btn_sync1, btn_sync2;
always @(posedge clk) begin
    btn_sync1 <= btn_trigger;
    btn_sync2 <= btn_sync1;
end

reg [19:0] debounce_cnt;  
reg btn_debounced;        
always @(posedge clk) begin
    if (btn_sync2 != btn_debounced) begin  
        debounce_cnt <= debounce_cnt + 1'b1;
        if (debounce_cnt == 20'd1000000 - 1) begin 
            btn_debounced <= btn_sync2; 
            debounce_cnt  <= 20'd0;  
        end
    end else begin 
        debounce_cnt <= 20'd0;
    end
end

reg btn_debounced_prev;  
always @(posedge clk) begin
    btn_debounced_prev <= btn_debounced;
    
   if (btn_debounced_prev == 1'b1 && btn_debounced == 1'b0) begin
            btn_pulse <= 1'b1;
        end else begin
            btn_pulse <= 1'b0;
        end
end


initial begin
    btn_sync1         = 1'b1;
    btn_sync2         = 1'b1;
    debounce_cnt      = 20'd0;
    btn_debounced     = 1'b1;
    btn_debounced_prev= 1'b1;
end
endmodule