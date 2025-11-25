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
module segmentDisplay (
    input clk, //时钟信号
    input reset,//复位信号
    input [11:0] menuState, //当前菜单状态 使用10进制BCD码
    input [7:0] seconds, //当前秒数，使用10进制BCD码，范围0-99
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
    reg[7:0] seg_out_reg1; // Control the content displayed on the leftmost four digits
    reg[7:0] seg_out_reg2; // Control the content displayed on the rightmost four digits
    reg[7:0] seg_en_reg; // Control the visibility of the four digits
    reg[2:0] scan_count; // Counter to control digit scanning
    wire clk_out;
    wire [13:0] tiaoPin = 14'd30;
    divider newclk(clk, reset, tiaoPin, clk_out);

    always @(posedge clk_out or posedge reset) begin

        if (reset) begin
            scan_count <= 3'b000;
        end
        else begin
            if(scan_count == 3'b111)
                scan_count <= 3'b000;
            else
                scan_count <= scan_count + 1;
        end


        if (reset) begin
            seg_en_reg <= 8'b00000000;
        end
        else begin
            case (menuState[11:8])
                4'b0001: begin // 模式：矩阵输入及存储
                    seg_en_reg <= 8'b10000000; // 只显示最左侧数码管
                    {seg_out_reg1, seg_out_reg2} <= SEG_1; //显示数字1
                end
                4'b0010: begin // 模式：矩阵生成及存储
                    seg_en_reg <= 8'b10000000; 
                    seg_out_reg2 <= SEG_2; //显示数字2
                end
                4'b0011: begin // 模式：矩阵展示
                 seg_en_reg <= 8'b10000000; 
                    seg_out_reg2 <= SEG_3; //显示数字3
                    end
                4'b0100: begin // 模式：矩阵运算
                case (menuState[7:4])
                    4'b0000: begin // 选择第一个运算数
                        seg_en_reg <= 8'b10000000; // 只显示最左侧数码管
                        seg_out_reg1 <= SEG_4; //显示数字4
                    end
                    4'b0001: begin // 选择第一个运算数
                    case (scan_count)
                        3'b111: begin
                            seg_en_reg <= 8'b1000_0000;
                            seg_out_reg1 <= SEG_1; //显示数字1
                        end 
                        3'b110: begin
                            seg_en_reg <= 8'b0100_0000;
                            seg_out_reg1 <= SEG_2; //显示数字2
                        end
                    endcase
                        seg_en_reg <= 8'b11000000; // 显示最左侧两个数码管
                        seg_out_reg1 <= SEG_4; //显示数字4
                        seg_out_reg2 <= SEG_1; //显示数字1
                    end
                    4'b0010: begin // 选择第二个运算数
                        seg_en_reg <= 8'b11000000; // 显示最左侧两个数码管
                        seg_out_reg1 <= SEG_2; //显示数字2
                        seg_out_reg2 <= SEG_2; //显示数字2
                    end
                    default: begin
                        seg_en_reg <= 8'b00000000; // 不显示任何数码管
                    end
                endcase 
                    case (scan_count)
                        3'b111: begin
                            seg_en_reg <= 8'b1000_0000;
                            case (user)
                                0: seg_out_reg1 <= 8'b11111100; // Digit 0 encoding
                                1: seg_out_reg1 <= 8'b01100000; // Digit 1 encoding
                                2: seg_out_reg1 <= 8'b11011010; // Digit 2 encoding
                                3: seg_out_reg1 <= 8'b11110010; // Digit 3 encoding
                                4: seg_out_reg1 <= 8'b01100110; // Digit 4 encoding
                                5: seg_out_reg1 <= 8'b10110110; // Digit 5 encoding
                                6: seg_out_reg1 <= 8'b10111110; // Digit 6 encoding
                                7: seg_out_reg1 <= 8'b11100000; // Digit 7 encoding
                                default: seg_out_reg1 <= 8'b00000000;
                            endcase
                        end 
                        3'b110: begin
                            seg_en_reg <= 8'b0100_0000;
                            case (order)
                                0: seg_out_reg1 <= 8'b11111100; // Digit 0 encoding
                                1: seg_out_reg1 <= 8'b01100000; // Digit 1 encoding
                                2: seg_out_reg1 <= 8'b11011010; // Digit 2 encoding
                                3: seg_out_reg1 <= 8'b11110010; // Digit 3 encoding
                                4: seg_out_reg1 <= 8'b01100110; // Digit 4 encoding
                                5: seg_out_reg1 <= 8'b10110110; // Digit 5 encoding
                                6: seg_out_reg1 <= 8'b10111110; // Digit 6 encoding
                                7: seg_out_reg1 <= 8'b11100000; // Digit 7 encoding
                                default: seg_out_reg1 <= 8'b00000000;
                            endcase
                        end
                        3'b101: begin
                            seg_en_reg <= 8'b0010_0000;
                            case (timedifference)
                                2'b01: seg_out_reg1 <= 8'b1111_1110; // B
                                2'b10: seg_out_reg1 <= 8'b1110_1110; // A
                                2'b11: seg_out_reg1 <= 8'b1011_0110; // S
                                default: seg_out_reg1 <= 8'b1001_1100; // C
                            endcase
                        end
                        3'b100: begin
                            seg_en_reg <= 8'b0001_0000;
                            case (rank)
                                0: seg_out_reg1 <= 8'b11111100; // Digit 0 encoding
                                1: seg_out_reg1 <= 8'b01100000; // Digit 1 encoding
                                2: seg_out_reg1 <= 8'b11011010; // Digit 2 encoding
                                3: seg_out_reg1 <= 8'b11110010; // Digit 3 encoding
                                4: seg_out_reg1 <= 8'b01100110; // Digit 4 encoding
                                5: seg_out_reg1 <= 8'b10110110; // Digit 5 encoding
                                6: seg_out_reg1 <= 8'b10111110; // Digit 6 encoding
                                7: seg_out_reg1 <= 8'b11100000; // Digit 7 encoding
                                default: seg_out_reg1 <= 8'b00000000;
                            endcase
                        end
                        3'b011: begin
                            seg_en_reg <= 8'b0000_0000; // Do not display
                        end
                        3'b010: begin
                            seg_en_reg <= 8'b0000_0000; // Do not display
                        end
                        3'b001: begin
                            seg_en_reg <= 8'b0000_0000; // Do not display
                        end
                        3'b000 : begin
                            seg_en_reg <= 8'b0000_0001;
                            seg_out_reg2 <= 8'b0001_1100; // L
                        end 
                        default: seg_en_reg <= 8'b0000_0000;
                    endcase
                end
                default: begin // Key adjustment mode
                    seg_en_reg <= 8'b00000001; // Rightmost digit is on
                    seg_out_reg1 <= 8'b10011100; // Display letter 'c' for change mode
                    seg_out_reg2 <= 8'b10011100; // c
                end
            endcase
        end
    end

    assign {tub_sel1, tub_sel2, tub_sel3, tub_sel4, tub_sel5, tub_sel6, tub_sel7, tub_sel8} = seg_en_reg;
    assign tub_control1 = seg_out_reg1;
    assign tub_control2 = seg_out_reg2;

endmodule