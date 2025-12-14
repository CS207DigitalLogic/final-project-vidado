`timescale 1ns / 1ps

module matrix_rx_handler(
    input wire clk,
    input wire rst_n,

    // UART RX 接口
    input wire [7:0] rx_data,
    input wire rx_done,

    // Storage 写入接口
    output reg        storage_wr_en,
    output reg [2:0]  storage_target_idx, 
    output reg [2:0]  storage_row,
    output reg [2:0]  storage_col,
    
    // 25个扁平化数据输出
    output reg [7:0] data_flat_0,  output reg [7:0] data_flat_1,  output reg [7:0] data_flat_2,
    output reg [7:0] data_flat_3,  output reg [7:0] data_flat_4,  output reg [7:0] data_flat_5,
    output reg [7:0] data_flat_6,  output reg [7:0] data_flat_7,  output reg [7:0] data_flat_8,
    output reg [7:0] data_flat_9,  output reg [7:0] data_flat_10, output reg [7:0] data_flat_11,
    output reg [7:0] data_flat_12, output reg [7:0] data_flat_13, output reg [7:0] data_flat_14,
    output reg [7:0] data_flat_15, output reg [7:0] data_flat_16, output reg [7:0] data_flat_17,
    output reg [7:0] data_flat_18, output reg [7:0] data_flat_19, output reg [7:0] data_flat_20,
    output reg [7:0] data_flat_21, output reg [7:0] data_flat_22, output reg [7:0] data_flat_23,
    output reg [7:0] data_flat_24,

    output reg save_done_pulse
);

    // 状态定义
    localparam S_IDLE       = 0;
    localparam S_WAIT_COL   = 1;
    localparam S_WAIT_DATA  = 2;
    localparam S_WRITE      = 3;

    reg [2:0] state;
    reg [4:0] data_cnt; // 0~24
    
    // 内部 Buffer
    reg [7:0] matrix_buffer [24:0];
    
    // 辅助函数：判断是否为数字 '0'~'9'
    function is_digit;
        input [7:0] char;
        begin
            is_digit = (char >= "0" && char <= "9");
        end
    endfunction

    // 状态机
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            storage_wr_en <= 0;
            storage_target_idx <= 0;
            storage_row <= 0;
            storage_col <= 0;
            data_cnt <= 0;
            save_done_pulse <= 0;
            // 清空 buffer
            for (i=0; i<25; i=i+1) matrix_buffer[i] <= 0;
        end else begin
            // 默认信号
            storage_wr_en <= 0;
            save_done_pulse <= 0;

            case (state)
                S_IDLE: begin
                    // 接收第1个数字：行数
                    if (rx_done) begin
                        if (is_digit(rx_data)) begin
                            storage_row <= rx_data - "0";
                            state <= S_WAIT_COL;
                        end 
                        // 如果是空格、换行或其他字符，保持状态不变 (相当于忽略)
                    end
                end
                
                S_WAIT_COL: begin
                    // 接收第2个数字：列数
                    if (rx_done) begin
                        if (is_digit(rx_data)) begin
                            storage_col <= rx_data - "0";
                            data_cnt <= 0;
                            state <= S_WAIT_DATA;
                        end
                        // 同理忽略非数字
                    end
                end

                S_WAIT_DATA: begin
                    // 接收矩阵具体内容
                    if (rx_done) begin
                        if (is_digit(rx_data)) begin
                            matrix_buffer[data_cnt] <= rx_data - "0";
                            if (data_cnt == (storage_row * storage_col) - 1) begin
                                state <= S_WRITE;
                            end else begin
                                data_cnt <= data_cnt + 1;
                            end
                        end
                        // 忽略空格和换行，允许用户输入 "1 2 3 4"
                    end
                end

                S_WRITE: begin
                    // 将 buffer 数据输出到 wire 端口
                    data_flat_0 <= matrix_buffer[0]; data_flat_1 <= matrix_buffer[1]; data_flat_2 <= matrix_buffer[2];
                    data_flat_3 <= matrix_buffer[3]; data_flat_4 <= matrix_buffer[4]; data_flat_5 <= matrix_buffer[5];
                    data_flat_6 <= matrix_buffer[6]; data_flat_7 <= matrix_buffer[7]; data_flat_8 <= matrix_buffer[8];
                    data_flat_9 <= matrix_buffer[9]; data_flat_10<= matrix_buffer[10];data_flat_11<= matrix_buffer[11];
                    data_flat_12<= matrix_buffer[12];data_flat_13<= matrix_buffer[13];data_flat_14<= matrix_buffer[14];
                    data_flat_15<= matrix_buffer[15];data_flat_16<= matrix_buffer[16];data_flat_17<= matrix_buffer[17];
                    data_flat_18<= matrix_buffer[18];data_flat_19<= matrix_buffer[19];data_flat_20<= matrix_buffer[20];
                    data_flat_21<= matrix_buffer[21];data_flat_22<= matrix_buffer[22];data_flat_23<= matrix_buffer[23];
                    data_flat_24<= matrix_buffer[24];

                    // 触发写使能
                    storage_wr_en <= 1;
                    
                    // 这里我们不指定 target_idx，让 storage 模块自己决定分配哪个空位
                    // 但是我们需要给一个值防止 latch，暂定为0
                    storage_target_idx <= 0; 
                    
                    save_done_pulse <= 1; // 触发显示
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule