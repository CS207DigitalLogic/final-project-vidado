`timescale 1ns / 1ps

module testSegmentDisplay(
    // 系统时钟与复位
    input sys_clk_in,       // 系统时钟，50MHz (P17)
    input sys_rst_n,        // 系统复位，低电平有效 (P15)
    
    // 测试用输入（按键+拨码开关）
    input [4:0] btn_pin,    // 5个按键，用于切换menuState (R11/R17/R15/V1/U4)
    input [7:0] sw_pin,     // 8个拨码开关，sw0控制秒显示使能 (P5/P4/P3/...)
    
    // 数码管输出（对应开发板引脚）
    output [7:0] seg_cs_pin,// 8个数码管位选 (G2/C2/C1/H1/G1/F1/E1/G6)
    output [7:0] seg_data_0_pin, // 数码管段选0 (B4/A4/A3/B1/A1/B3/B2/D5)
    output [7:0] seg_data_1_pin  // 数码管段选1 (D4/E3/D3/F4/F3/E2/D2/H2)
);

// -------------------------- 内部信号定义 --------------------------
wire clk;                  // 系统时钟（50MHz）
wire reset;                // 高电平有效复位（sys_rst_n取反）
wire [13:0] tiaoPin = 14'd30; // 分频参数（与segmentDisplay一致）
wire clk_out;              // 数码管扫描时钟（分频后）

reg [11:0] menuState;      // 菜单状态（100/200/300/400/410~450）
reg [8:0] seconds;         // 秒数（seconds[8]为显示使能，[7:0]为0~99秒）
reg [31:0] sec_cnt;        // 秒计数器（50MHz计数到50_000_000为1秒）

// 按键消抖相关信号
reg [20:0] key_cnt;        // 按键消抖计数器（20ms）
reg key_sync1, key_sync2;  // 按键同步寄存器
wire key_neg;              // 按键消抖后有效信号（上升沿触发）

// -------------------------- 时钟与复位处理 --------------------------
assign clk = sys_clk_in;
assign reset = ~sys_rst_n; // 低电平复位转高电平复位

// -------------------------- 按键消抖（btn_pin[0]） --------------------------
always @(posedge clk or posedge reset) begin
    if (reset) begin
        key_sync1 <= 1'b1;
        key_sync2 <= 1'b1;
        key_cnt <= 21'd0;
    end else begin
        key_sync1 <= btn_pin[0];  // 同步按键信号
        key_sync2 <= key_sync1;
        
        // 检测按键上升沿（松开时），开始消抖计数
        if (key_sync2 == 1'b0 && key_sync1 == 1'b1) begin
            key_cnt <= 21'd1_000_000; // 50MHz * 20ms = 1e6个时钟周期
        end else if (key_cnt > 21'd0) begin
            key_cnt <= key_cnt - 21'd1;
        end
    end
end
assign key_neg = (key_cnt == 21'd1) ? 1'b1 : 1'b0; // 消抖后有效信号

// -------------------------- menuState切换逻辑 --------------------------
always @(posedge clk or posedge reset) begin
    if (reset) begin
        menuState <= 12'd100; // 初始状态：100（矩阵输入及存储）
    end else if (key_neg) begin
        // 按键切换状态：100→200→300→400→410→420→430→440→450→100
        case (menuState)
            12'd100: menuState <= 12'd200;
            12'd200: menuState <= 12'd300;
            12'd300: menuState <= 12'd400;
            12'd400: menuState <= 12'd410;
            12'd410: menuState <= 12'd420;
            12'd420: menuState <= 12'd430;
            12'd430: menuState <= 12'd440;
            12'd440: menuState <= 12'd450;
            12'd450: menuState <= 12'd100;
            default: menuState <= 12'd100;
        endcase
    end
end

// -------------------------- 秒计数器（0~99秒循环） --------------------------
// 显式声明所有信号（规范写法）
reg  [3:0]    sec_tens_bcd; // 秒的十位 BCD 码（4位：0000~1001 → 0~9）
reg  [3:0]    sec_units_bcd;// 秒的个位 BCD 码（4位：0000~1001 → 0~9）

// 异步复位的时序逻辑：50MHz→1秒分频 + BCD码秒递减计数（99~00循环）
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // 复位：分频计数器清零，BCD码初始化为 99（可按需改为其他初始值，如 59）
        sec_cnt        <= 32'd0;
        sec_tens_bcd   <= 4'd9;  // 十位 BCD 码：9（1001）
        sec_units_bcd  <= 4'd9;  // 个位 BCD 码：9（1001）
        seconds[7:0]        <= 8'h99; // 8位 BCD 码：99（1001_1001）
    end else begin
        if (sec_cnt == 32'd99_999_999) begin // 50MHz 计满1秒
            sec_cnt <= 32'd0; // 分频计数器清零，重新计数
            
            // --------------------------sw_pin
            // 核心：BCD码秒数递减逻辑（借位+合法BCD保障）
            // --------------------------
            if (sec_units_bcd == 4'd0) begin // 个位 BCD 码为0，需向十位借位
                sec_units_bcd <= 4'd9;      // 个位借位后变为9（合法BCD）
                if (sec_tens_bcd == 4'd0) begin // 十位也为0（00 BCD）
                    sec_tens_bcd <= 4'd9;  // 十位借位后变为9（循环回99）
                end else begin
                    sec_tens_bcd <= sec_tens_bcd - 4'd1; // 十位减1（合法BCD）
                end
            end else begin
                sec_units_bcd <= sec_units_bcd - 4'd1; // 个位直接减1（合法BCD）
            end
            
            // 拼接十位/个位 BCD 码，生成8位 BCD 码 seconds
            seconds[7:0] <= {sec_tens_bcd, sec_units_bcd};
        end else begin
            sec_cnt <= sec_cnt + 32'd1; // 未计满1秒，分频计数器累加
        end
    end
end

always@(*) seconds[8] = sw_pin[0]; // sw0控制秒显示使能（1=显示，0=不显示）

// -------------------------- 实例化分频器（segmentDisplay依赖） --------------------------
divider u_divider(
    .clk(clk),
    .rst_n(reset),
    .tiaoPin(tiaoPin),
    .clk_out(clk_out)
);

// -------------------------- 实例化七段数码管显示模块 --------------------------
segmentDisplay u_segmentDisplay(
    .clk(clk),
    .reset(reset),
    .menuState(menuState),
    .seconds(seconds),
    // 数码管位选：tub_sel1~8对应seg_cs_pin[0]~[7]
    .tub_sel1(seg_cs_pin[0]),
    .tub_sel2(seg_cs_pin[1]),
    .tub_sel3(seg_cs_pin[2]),
    .tub_sel4(seg_cs_pin[3]),
    .tub_sel5(seg_cs_pin[4]),
    .tub_sel6(seg_cs_pin[5]),
    .tub_sel7(seg_cs_pin[6]),
    .tub_sel8(seg_cs_pin[7]),
    // 数码管段选：tub_control1→seg_data_0_pin，tub_control2→seg_data_1_pin
    .tub_control1(seg_data_0_pin),
    .tub_control2(seg_data_1_pin)
);

endmodule

