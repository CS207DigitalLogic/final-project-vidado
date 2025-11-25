`timescale 1ns / 1ps

//七段数码管显示模块

/*
    输入：
        clk：时钟信号
        reset：复位信号
        menuState：当前菜单状态，2^8支持256种状态
        seconds：当前秒数，范围0-99
    
    输出：
        tub_sel1~tub_sel8：控制第1~第8个七段数码管的显示，从左侧开始编号
        tub_control1：控制左侧七段数码管显示的内容
        tub_control2：控制右侧七段数码管显示的内容
    menuState定义：
        1：矩阵输入及存储
        2：矩阵生成及存储
        3：矩阵展示
        4：矩阵运算
        41：矩阵转置
        42：矩阵加法
        43：矩阵减法
        44：矩阵数乘
        45：矩阵乘法
        4*1：选择第一个运算数
        4*2：选择第二个运算数

*/
module segmentDisplay (
    input clk, //时钟信号
    input reset,//复位信号
    input [8:0] menuState, //当前菜单状态 2^9支持512种状态
    input [6:0] seconds, //当前秒数，范围0-99
    output tub_sel1, // 从左侧开始编号，控制第1个七段数码管的显示
    output tub_sel2, // 左侧第2个七段数码管
    output tub_sel3, // 左侧第3个七段数码管
    output tub_sel4, // 左侧第4个七段数码管
    output tub_sel5, // 左侧第5个七段数码管
    output tub_sel6, // 左侧第6个七段数码管
    output tub_sel7, // 左侧第7个七段数码管
    output tub_sel8, // 左侧第8个七段数码管
    output [7:0] tub_control1, // Output: Control the content displayed on the left side
    output [7:0] tub_control2 // Output: Control the content displayed on the right side
);
    parameter SEG_0 = 8'b11111100; // 显示"0"：a、b、c、d、e、f亮
    parameter SEG_1 = 8'b01100000; // 显示"1"：b、c亮
    parameter SEG_2 = 8'b11011010; // 显示"2"：a、b、d、e、g亮
    parameter SEG_3 = 8'b11110010; // 显示"3"：a、b、c、d、g亮
    parameter SEG_4 = 8'b01100110; // 显示"4"：b、c、f、g亮
    parameter SEG_5 = 8'b10110110; // 显示"5"：a、c、d、f、g亮
    parameter SEG_6 = 8'b10111110; // 显示"6"：a、c、d、e、f、g亮
    parameter SEG_7 = 8'b11100000; // 显示"7"：a、b、c亮
    parameter SEG_8 = 8'b11111110; // 显示"8"：a~g全亮
    parameter SEG_9 = 8'b11100110; // 显示"9"：a、b、c、f、g亮
endmodule