`timescale 1ns / 1ps

//七段数码管显示模块

/*
    输入：
        clk：时钟信号
        reset：复位信号
        menuState：当前菜单状态，2^8支持256种状态
        seconds：当前秒数，最高位标记是否开启倒计时，其余8位使用10进制BCD码，范围0-99
    
    输出：
        tub_sel1~tub_sel8：控制第1~第8个七段数码管的显示，从左侧开始编号
        tub_control1：控制左侧七段数码管显示的内容
        tub_control2：控制右侧七段数码管显示的内容
    menuState定义：
        100：矩阵输入及存储
        200：矩阵生成及存储
        300：矩阵展示
        400：矩阵运算
        410：矩阵转置
        420：矩阵加法
        430：矩阵减法
        440：矩阵数乘
        450：矩阵乘法
        4*1：选择第一个运算数
        4*2：选择第二个运算数

*/
module segment_display (
    input clk, //时钟信号
    input reset,//复位信号
    input [11:0] menuState, //当前菜单状态 使用10进制BCD码
    input [8:0] seconds, //当前秒数，使用10进制BCD码，范围0-99
    output reg tub_sel1, // 从左侧开始编号，控制第1个七段数码管的显示
    output reg tub_sel2, // 左侧第2个七段数码管
    output reg tub_sel3, // 左侧第3个七段数码管
    output reg tub_sel4, // 左侧第4个七段数码管
    output reg tub_sel5, // 左侧第5个七段数码管
    output reg tub_sel6, // 左侧第6个七段数码管
    output reg tub_sel7, // 左侧第7个七段数码管
    output reg tub_sel8, // 左侧第8个七段数码管
    output [7:0] tub_control1, // Output: Control the content displayed on the left side
    output [7:0] tub_control2 // Output: Control the content displayed on the right side
);
    parameter SEG_0 = 8'b00111111; // 显示"0"：a、b、c、d、e、f亮
    parameter SEG_1 = 8'b00000110; // 显示"1"：b、c亮
    parameter SEG_2 = 8'b01011011; // 显示"2"：a、b、d、e、g亮
    parameter SEG_3 = 8'b01001111; // 显示"3"：a、b、c、d、g亮
    parameter SEG_4 = 8'b01100110; // 显示"4"：b、c、f、g亮
    parameter SEG_5 = 8'b01101101; // 显示"5"：a、c、d、f、g亮
    parameter SEG_6 = 8'b01111101; // 显示"6"：a、c、d、e、f、g亮
    parameter SEG_7 = 8'b00000111; // 显示"7"：a、b、c亮
    parameter SEG_8 = 8'b01111111; // 显示"8"：a~g全亮
    parameter SEG_9 = 8'b01101111; // 显示"9"：a、b、c、d、f、g亮
    parameter SEG_OFF = 8'b00000000;
  // -------------------------- 2. 内部信号定义 --------------------------
    reg [2:0] scan_count;
    wire clk_out;
    reg [7:0] seg_code[7:0]; // 存储8个数码管要显示的段码

    // 时钟分频
    wire [13:0] tiaoPin = 14'd30;
    divider newclk(clk, reset, tiaoPin, clk_out);

    // -------------------------- 3. 组合逻辑：确定每个数码管显示的内容 --------------------------
    always @(*) begin
        seg_code[0] = SEG_OFF; // tub_sel1
        seg_code[1] = SEG_OFF; // tub_sel2
        seg_code[2] = SEG_OFF; // tub_sel3
        seg_code[3] = SEG_OFF; // tub_sel4
        seg_code[4] = SEG_OFF; // tub_sel5
        seg_code[5] = SEG_OFF; // tub_sel6
        seg_code[6] = SEG_OFF; // tub_sel7
        seg_code[7] = SEG_OFF; // tub_sel8

        // 根据 menuState 确定左侧数码管显示
        case (menuState)
            12'd100: seg_code[0] = SEG_1; // 显示 "1"
            12'd200: seg_code[0] = SEG_2; // 显示 "2"
            12'd300: seg_code[0] = SEG_3; // 显示 "3"
            12'd400: seg_code[0] = SEG_4; // 显示 "4"
            12'd410: begin seg_code[0] = SEG_4; seg_code[1] = SEG_1; end // 显示 "4" "1"
            12'd420: begin seg_code[0] = SEG_4; seg_code[1] = SEG_2; end // 显示 "4" "2"
            12'd430: begin seg_code[0] = SEG_4; seg_code[1] = SEG_3; end // 显示 "4" "3"
            12'd440: begin seg_code[0] = SEG_4; seg_code[1] = SEG_4; end // 显示 "4" "4"
            12'd450: begin seg_code[0] = SEG_4; seg_code[1] = SEG_5; end // 显示 "4" "5"
            // 可以继续添加其他 menuState 的显示逻辑
            default: ; // 默认保持熄灭
        endcase

        // 根据 seconds 确定右侧数码管显示 (如果 seconds[8] 为1，则显示秒数)
        if (seconds[8]) begin
            case (seconds[7:4])
                4'd0: seg_code[6] = SEG_0;
                4'd1: seg_code[6] = SEG_1;
                4'd2: seg_code[6] = SEG_2;
                4'd3: seg_code[6] = SEG_3;
                4'd4: seg_code[6] = SEG_4;
                4'd5: seg_code[6] = SEG_5;
                4'd6: seg_code[6] = SEG_6;
                4'd7: seg_code[6] = SEG_7;
                4'd8: seg_code[6] = SEG_8;
                4'd9: seg_code[6] = SEG_9;
            endcase
            case (seconds[3:0])
                4'd0: seg_code[7] = SEG_0;
                4'd1: seg_code[7] = SEG_1;
                4'd2: seg_code[7] = SEG_2;
                4'd3: seg_code[7] = SEG_3;
                4'd4: seg_code[7] = SEG_4;
                4'd5: seg_code[7] = SEG_5;
                4'd6: seg_code[7] = SEG_6;
                4'd7: seg_code[7] = SEG_7;
                4'd8: seg_code[7] = SEG_8;
                4'd9: seg_code[7] = SEG_9;
            endcase
        end
    end


    // -------------------------- 4. 时序逻辑：动态扫描 --------------------------
    always @(posedge clk_out or posedge reset) begin
        if (reset) begin
            scan_count <= 3'b000;
        end else begin
            scan_count <= scan_count + 3'b001; // 从0到7循环
        end
    end

    // -------------------------- 5. 输出逻辑 --------------------------
    // 生成位选信号 (高电平有效)
    always @(*) begin
    // 步骤1：默认全 0（避免 latch，必须先赋值所有信号）
    tub_sel1 = 1'b0;
    tub_sel2 = 1'b0;
    tub_sel3 = 1'b0;
    tub_sel4 = 1'b0;
    tub_sel5 = 1'b0;
    tub_sel6 = 1'b0;
    tub_sel7 = 1'b0;
    tub_sel8 = 1'b0;
    
    // 步骤2：根据 scan_count 选择赋值 1
    case(scan_count)
        3'd0: tub_sel1 = 1'b1;
        3'd1: tub_sel2 = 1'b1;
        3'd2: tub_sel3 = 1'b1;
        3'd3: tub_sel4 = 1'b1;
        3'd4: tub_sel5 = 1'b1;
        3'd5: tub_sel6 = 1'b1;
        3'd6: tub_sel7 = 1'b1;
        3'd7: tub_sel8 = 1'b1;
    endcase
end

    // 根据 scan_count 选择要输出的段码
    // 假设 tub_control1 控制 [0..3] (sel1-sel4), tub_control2 控制 [4..7] (sel5-sel8)
    assign tub_control1 = seg_code[scan_count];
    assign tub_control2 = seg_code[scan_count];
endmodule