module uart_tx #(
    parameter CLK_FREQ  = 100000000, // 系统时钟频率（100MHz）
    parameter BAUD_RATE = 115200     // UART波特率（115200bps）
)(
    input wire         clk,          // 系统时钟
    input wire         rst_n,        // 低有效复位
    input wire         tx_start,     // 发送触发信号（高电平有效）
    input wire [7:0]   tx_data,      // 待发送的8位并行数据
    output reg         tx,           // UART串行发送引脚
    output reg         tx_busy       // 发送忙状态（高电平=忙）
);

// 计算波特率分频系数：clk_freq / baud_rate
localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;
localparam BAUD_DIV_W = (BAUD_DIV <= 1)      ? 1 :   // 分频系数≤1 → 1位（0）
                       (BAUD_DIV <= 2)      ? 2 :   // 2 → 2位（0~1）
                       (BAUD_DIV <= 4)      ? 3 :   // 3~4 → 3位（0~3）
                       (BAUD_DIV <= 8)      ? 4 :   // 5~8 → 4位（0~7）
                       (BAUD_DIV <= 16)     ? 5 :   // 9~16 → 5位
                       (BAUD_DIV <= 32)     ? 6 :   // 17~32 → 6位
                       (BAUD_DIV <= 64)     ? 7 :   // 33~64 → 7位
                       (BAUD_DIV <= 128)    ? 8 :   // 65~128 → 8位
                       (BAUD_DIV <= 256)    ? 9 :   // 129~256 → 9位
                       (BAUD_DIV <= 512)    ? 10 :  // 257~512 → 10位
                       (BAUD_DIV <= 1024)   ? 11 :  // 513~1024 → 11位
                       (BAUD_DIV <= 2048)   ? 12 :  // 1025~2048 → 12位
                       (BAUD_DIV <= 4096)   ? 13 :  // 2049~4096 → 13位
                       (BAUD_DIV <= 8192)   ? 14 :  // 4097~8192 → 14位
                       (BAUD_DIV <= 16384)  ? 15 :  // 8193~16384 → 15位
                       (BAUD_DIV <= 32768)  ? 16 :  // 16385~32768 → 16位
                       (BAUD_DIV <= 65536)  ? 17 :  // 32769~65536 → 17位
                       18; 

// 内部信号
reg [BAUD_DIV_W-1:0] baud_cnt; // 波特率分频计数器
reg [3:0] bit_cnt; // 比特计数器（0=起始位，1~8=数据位，9=停止位）
reg [7:0] tx_data_buf; // 待发送数据缓存

// 状态定义
localparam IDLE  = 2'd0; // 空闲状态
localparam START = 2'd1; // 发送起始位
localparam DATA  = 2'd2; // 发送数据位
localparam STOP  = 2'd3; // 发送停止位

reg [1:0] curr_state;
reg [1:0] next_state;

// ---------------------------
// 1. 状态机寄存器（时序逻辑）
// ---------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        curr_state <= IDLE;
        tx_data_buf <= 8'h00;
    end else begin
        curr_state <= next_state;
        if (tx_start && curr_state == IDLE) begin
            tx_data_buf <= tx_data; // 锁存待发送数据
        end
    end
end

// ---------------------------
// 2. 状态转移逻辑（组合逻辑）
// ---------------------------
always @(*) begin
    next_state = curr_state;
    case (curr_state)
        IDLE: begin
            if (tx_start) begin
                next_state = START; // 触发发送，进入起始位状态
            end
        end
        START: begin
            if (baud_cnt == BAUD_DIV - 1) begin
                next_state = DATA; // 起始位发送完成，进入数据位状态
            end
        end
        DATA: begin
            if (baud_cnt == BAUD_DIV - 1 && bit_cnt == 8) begin
                next_state = STOP; // 8位数据发送完成，进入停止位状态
            end
        end
        STOP: begin
            if (baud_cnt == BAUD_DIV - 1) begin
                next_state = IDLE; // 停止位发送完成，回到空闲状态
            end
        end
    endcase
end

// ---------------------------
// 3. 波特率计数器（时序逻辑）
// ---------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_cnt <= {BAUD_DIV_W{1'b0}};
    end else begin
        if (curr_state == IDLE) begin
            baud_cnt <= {BAUD_DIV_W{1'b0}};
        end else begin
            if (baud_cnt == BAUD_DIV - 1) begin
                baud_cnt <= {BAUD_DIV_W{1'b0}};
            end else begin
                baud_cnt <= baud_cnt + 1'b1;
            end
        end
    end
end

// ---------------------------
// 4. 比特计数器（时序逻辑）
// ---------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt <= 4'd0;
    end else begin
        if (curr_state == DATA) begin
            if (baud_cnt == BAUD_DIV - 1) begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        end else begin
            bit_cnt <= 4'd0;
        end
    end
end

// ---------------------------
// 5. UART发送引脚控制（时序逻辑）
// ---------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx <= 1'b1; // 空闲状态为高电平
        tx_busy <= 1'b0;
    end else begin
        case (curr_state)
            IDLE: begin
                tx <= 1'b1;
                tx_busy <= 1'b0;
            end
            START: begin
                tx <= 1'b0; // 起始位为低电平
                tx_busy <= 1'b1;
            end
            DATA: begin
                tx <= tx_data_buf[bit_cnt]; // 按比特发送数据（LSB先行）
                tx_busy <= 1'b1;
            end
            STOP: begin
                tx <= 1'b1; // 停止位为高电平
                tx_busy <= 1'b1;
            end
        endcase
    end
end

endmodule