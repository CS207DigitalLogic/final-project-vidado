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
always @(posedge clk or posedge reset) begin
    if (reset) begin
        sec_cnt <= 32'd0;
        seconds[7:0] <= 8'd0;
    end else begin
        if (sec_cnt == 32'd49_999_999) begin // 50MHz计数到5000万-1（1秒）
            sec_cnt <= 32'd0;
            if (seconds[7:0] == 8'd99) begin
                seconds[7:0] <= 8'd0; // 99秒后复位到0
            end else begin
                seconds[7:0] <= seconds[7:0] + 8'd1;
            end
        end else begin
            sec_cnt <= sec_cnt + 32'd1;
        end
    end
end
assign seconds[8] = sw_pin[0]; // sw0控制秒显示使能（1=显示，0=不显示）

// -------------------------- 实例化分频器（segmentDisplay依赖） --------------------------
divider u_divider(
    .clk(clk),
    .reset(reset),
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

