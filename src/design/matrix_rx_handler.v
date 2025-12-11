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
    
    // 25个扁平化数据输出，连接到 storage
    output wire [7:0] data_flat_0,  output wire [7:0] data_flat_1,  output wire [7:0] data_flat_2,
    output wire [7:0] data_flat_3,  output wire [7:0] data_flat_4,  output wire [7:0] data_flat_5,
    output wire [7:0] data_flat_6,  output wire [7:0] data_flat_7,  output wire [7:0] data_flat_8,
    output wire [7:0] data_flat_9,  output wire [7:0] data_flat_10, output wire [7:0] data_flat_11,
    output wire [7:0] data_flat_12, output wire [7:0] data_flat_13, output wire [7:0] data_flat_14,
    output wire [7:0] data_flat_15, output wire [7:0] data_flat_16, output wire [7:0] data_flat_17,
    output wire [7:0] data_flat_18, output wire [7:0] data_flat_19, output wire [7:0] data_flat_20,
    output wire [7:0] data_flat_21, output wire [7:0] data_flat_22, output wire [7:0] data_flat_23,
    output wire [7:0] data_flat_24,
    
    // 控制信号：通知顶层接收并保存完毕
    output reg save_done_pulse
);

    // 状态机
    localparam S_IDLE      = 0;
    localparam S_WAIT_ROW  = 1;
    localparam S_WAIT_COL  = 2;
    localparam S_WAIT_DATA = 3;
    localparam S_WRITE     = 4;

    reg [2:0] state;
    reg [7:0] matrix_buffer [24:0];
    reg [4:0] data_cnt;

    // Buffer 映射到输出
    assign data_flat_0 = matrix_buffer[0];   assign data_flat_1 = matrix_buffer[1];
    assign data_flat_2 = matrix_buffer[2];   assign data_flat_3 = matrix_buffer[3];
    assign data_flat_4 = matrix_buffer[4];   assign data_flat_5 = matrix_buffer[5];
    assign data_flat_6 = matrix_buffer[6];   assign data_flat_7 = matrix_buffer[7];
    assign data_flat_8 = matrix_buffer[8];   assign data_flat_9 = matrix_buffer[9];
    assign data_flat_10 = matrix_buffer[10]; assign data_flat_11 = matrix_buffer[11];
    assign data_flat_12 = matrix_buffer[12]; assign data_flat_13 = matrix_buffer[13];
    assign data_flat_14 = matrix_buffer[14]; assign data_flat_15 = matrix_buffer[15];
    assign data_flat_16 = matrix_buffer[16]; assign data_flat_17 = matrix_buffer[17];
    assign data_flat_18 = matrix_buffer[18]; assign data_flat_19 = matrix_buffer[19];
    assign data_flat_20 = matrix_buffer[20]; assign data_flat_21 = matrix_buffer[21];
    assign data_flat_22 = matrix_buffer[22]; assign data_flat_23 = matrix_buffer[23];
    assign data_flat_24 = matrix_buffer[24];

    function is_digit;
        input [7:0] char;
        begin
            is_digit = (char >= "0" && char <= "9");
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            storage_wr_en <= 0;
            storage_target_idx <= 0;
            save_done_pulse <= 0;
            data_cnt <= 0;
            storage_row <= 0;
            storage_col <= 0;
        end else begin
            storage_wr_en <= 0;
            save_done_pulse <= 0;

            case (state)
                S_IDLE: begin
                    // 接收第1个数字：行数
                    if (rx_done && is_digit(rx_data)) begin
                        storage_row <= rx_data - "0";
                        state <= S_WAIT_COL;
                    end
                end
                
                S_WAIT_COL: begin
                    // 接收第2个数字：列数
                    if (rx_done && is_digit(rx_data)) begin
                        storage_col <= rx_data - "0";
                        data_cnt <= 0;
                        state <= S_WAIT_DATA;
                    end
                end

                S_WAIT_DATA: begin
                    // 接收矩阵具体内容
                    if (rx_done && is_digit(rx_data)) begin
                        matrix_buffer[data_cnt] <= rx_data - "0";
                        if (data_cnt == (storage_row * storage_col) - 1) begin
                            state <= S_WRITE;
                        end else begin
                            data_cnt <= data_cnt + 1;
                        end
                    end
                end

                S_WRITE: begin
                    // 写入存储模块
                    storage_wr_en <= 1;
                    // 这里你可以设置逻辑改变 target_idx，比如存到 0, 1, 2...
                    // 暂时默认存到位置 0
                    storage_target_idx <= 0; 
                    
                    save_done_pulse <= 1; // 告诉 Top 模块：写完了，可以显示了
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule