`timescale 1ns / 1ps

module matrix_displayer80 #(
    parameter DATA_WIDTH = 9
)(
    input wire clk,
    input wire rst_n,
    
    // 控制信号
    input wire start,
    output reg busy,
    
    // 数据输入：80个端口，对应卷积结果
    input wire [DATA_WIDTH-1:0] d0,  input wire [DATA_WIDTH-1:0] d1,  input wire [DATA_WIDTH-1:0] d2,  input wire [DATA_WIDTH-1:0] d3,  input wire [DATA_WIDTH-1:0] d4,
    input wire [DATA_WIDTH-1:0] d5,  input wire [DATA_WIDTH-1:0] d6,  input wire [DATA_WIDTH-1:0] d7,  input wire [DATA_WIDTH-1:0] d8,  input wire [DATA_WIDTH-1:0] d9,
    input wire [DATA_WIDTH-1:0] d10, input wire [DATA_WIDTH-1:0] d11, input wire [DATA_WIDTH-1:0] d12, input wire [DATA_WIDTH-1:0] d13, input wire [DATA_WIDTH-1:0] d14,
    input wire [DATA_WIDTH-1:0] d15, input wire [DATA_WIDTH-1:0] d16, input wire [DATA_WIDTH-1:0] d17, input wire [DATA_WIDTH-1:0] d18, input wire [DATA_WIDTH-1:0] d19,
    input wire [DATA_WIDTH-1:0] d20, input wire [DATA_WIDTH-1:0] d21, input wire [DATA_WIDTH-1:0] d22, input wire [DATA_WIDTH-1:0] d23, input wire [DATA_WIDTH-1:0] d24,
    input wire [DATA_WIDTH-1:0] d25, input wire [DATA_WIDTH-1:0] d26, input wire [DATA_WIDTH-1:0] d27, input wire [DATA_WIDTH-1:0] d28, input wire [DATA_WIDTH-1:0] d29,
    input wire [DATA_WIDTH-1:0] d30, input wire [DATA_WIDTH-1:0] d31, input wire [DATA_WIDTH-1:0] d32, input wire [DATA_WIDTH-1:0] d33, input wire [DATA_WIDTH-1:0] d34,
    input wire [DATA_WIDTH-1:0] d35, input wire [DATA_WIDTH-1:0] d36, input wire [DATA_WIDTH-1:0] d37, input wire [DATA_WIDTH-1:0] d38, input wire [DATA_WIDTH-1:0] d39,
    input wire [DATA_WIDTH-1:0] d40, input wire [DATA_WIDTH-1:0] d41, input wire [DATA_WIDTH-1:0] d42, input wire [DATA_WIDTH-1:0] d43, input wire [DATA_WIDTH-1:0] d44,
    input wire [DATA_WIDTH-1:0] d45, input wire [DATA_WIDTH-1:0] d46, input wire [DATA_WIDTH-1:0] d47, input wire [DATA_WIDTH-1:0] d48, input wire [DATA_WIDTH-1:0] d49,
    input wire [DATA_WIDTH-1:0] d50, input wire [DATA_WIDTH-1:0] d51, input wire [DATA_WIDTH-1:0] d52, input wire [DATA_WIDTH-1:0] d53, input wire [DATA_WIDTH-1:0] d54,
    input wire [DATA_WIDTH-1:0] d55, input wire [DATA_WIDTH-1:0] d56, input wire [DATA_WIDTH-1:0] d57, input wire [DATA_WIDTH-1:0] d58, input wire [DATA_WIDTH-1:0] d59,
    input wire [DATA_WIDTH-1:0] d60, input wire [DATA_WIDTH-1:0] d61, input wire [DATA_WIDTH-1:0] d62, input wire [DATA_WIDTH-1:0] d63, input wire [DATA_WIDTH-1:0] d64,
    input wire [DATA_WIDTH-1:0] d65, input wire [DATA_WIDTH-1:0] d66, input wire [DATA_WIDTH-1:0] d67, input wire [DATA_WIDTH-1:0] d68, input wire [DATA_WIDTH-1:0] d69,
    input wire [DATA_WIDTH-1:0] d70, input wire [DATA_WIDTH-1:0] d71, input wire [DATA_WIDTH-1:0] d72, input wire [DATA_WIDTH-1:0] d73, input wire [DATA_WIDTH-1:0] d74,
    input wire [DATA_WIDTH-1:0] d75, input wire [DATA_WIDTH-1:0] d76, input wire [DATA_WIDTH-1:0] d77, input wire [DATA_WIDTH-1:0] d78, input wire [DATA_WIDTH-1:0] d79,
    
    // UART 接口 
    input wire       tx_busy,   
    output reg       tx_start,  
    output reg [7:0] tx_data
);

    // 固定参数：8行 10列
    localparam FIXED_ROW = 4'd8;
    localparam FIXED_COL = 4'd10;

    // 状态定义
    localparam S_IDLE           = 0;
    localparam S_PREPARE_DATA   = 1;
    localparam S_CALC_DIGITS    = 2; 
    localparam S_SEND_CHAR_1    = 3;
    localparam S_SEND_CHAR_2    = 4; 
    localparam S_SEND_CHAR_3    = 5;
    localparam S_WAIT_UART      = 6; 
    localparam S_SEND_SEP       = 7;
    localparam S_CHECK_NEXT     = 8; 
    localparam S_DONE           = 9;
    localparam S_WAIT_RELEASE   = 10;

    reg [3:0] state, next_state_after_wait;
    reg [3:0] r_cnt; // 够存 0-7
    reg [3:0] c_cnt; // 够存 0-9
    
    reg [DATA_WIDTH-1:0] current_data;
    
    // 拆分数字用的寄存器
    reg [3:0] digit_hundreds;
    reg [3:0] digit_tens;
    reg [3:0] digit_units;
    
    localparam ASCII_0     = 8'd48;
    localparam ASCII_SPACE = 8'd32;
    localparam ASCII_LF    = 8'd10; 

    // 数据选择 logic
    reg [6:0] idx; // 必须足够大，最大索引79，需要7位 (2^7=128)
    
    // 使用 integer 防止中间计算截断
    integer calc_temp; 

    always @(*) begin

        calc_temp = r_cnt * 10 + c_cnt; // 固定列数 10
        idx = calc_temp[6:0]; 
        
        case(idx)
            7'd0:  current_data = d0;   7'd1:  current_data = d1;   7'd2:  current_data = d2;   7'd3:  current_data = d3;   7'd4:  current_data = d4;
            7'd5:  current_data = d5;   7'd6:  current_data = d6;   7'd7:  current_data = d7;   7'd8:  current_data = d8;   7'd9:  current_data = d9;
            7'd10: current_data = d10;  7'd11: current_data = d11;  7'd12: current_data = d12;  7'd13: current_data = d13;  7'd14: current_data = d14;
            7'd15: current_data = d15;  7'd16: current_data = d16;  7'd17: current_data = d17;  7'd18: current_data = d18;  7'd19: current_data = d19;
            7'd20: current_data = d20;  7'd21: current_data = d21;  7'd22: current_data = d22;  7'd23: current_data = d23;  7'd24: current_data = d24;
            7'd25: current_data = d25;  7'd26: current_data = d26;  7'd27: current_data = d27;  7'd28: current_data = d28;  7'd29: current_data = d29;
            7'd30: current_data = d30;  7'd31: current_data = d31;  7'd32: current_data = d32;  7'd33: current_data = d33;  7'd34: current_data = d34;
            7'd35: current_data = d35;  7'd36: current_data = d36;  7'd37: current_data = d37;  7'd38: current_data = d38;  7'd39: current_data = d39;
            7'd40: current_data = d40;  7'd41: current_data = d41;  7'd42: current_data = d42;  7'd43: current_data = d43;  7'd44: current_data = d44;
            7'd45: current_data = d45;  7'd46: current_data = d46;  7'd47: current_data = d47;  7'd48: current_data = d48;  7'd49: current_data = d49;
            7'd50: current_data = d50;  7'd51: current_data = d51;  7'd52: current_data = d52;  7'd53: current_data = d53;  7'd54: current_data = d54;
            7'd55: current_data = d55;  7'd56: current_data = d56;  7'd57: current_data = d57;  7'd58: current_data = d58;  7'd59: current_data = d59;
            7'd60: current_data = d60;  7'd61: current_data = d61;  7'd62: current_data = d62;  7'd63: current_data = d63;  7'd64: current_data = d64;
            7'd65: current_data = d65;  7'd66: current_data = d66;  7'd67: current_data = d67;  7'd68: current_data = d68;  7'd69: current_data = d69;
            7'd70: current_data = d70;  7'd71: current_data = d71;  7'd72: current_data = d72;  7'd73: current_data = d73;  7'd74: current_data = d74;
            7'd75: current_data = d75;  7'd76: current_data = d76;  7'd77: current_data = d77;  7'd78: current_data = d78;  7'd79: current_data = d79;
            default: current_data = 0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            busy <= 0;
            tx_start <= 0;
            tx_data <= 0;
            r_cnt <= 0;
            c_cnt <= 0;
            digit_hundreds <= 0;
            digit_tens <= 0;
            digit_units <= 0;
            next_state_after_wait <= S_IDLE;
        end else begin
            case (state)
                S_IDLE: begin
                    busy <= 0;
                    if (start) begin
                        busy <= 1;
                        r_cnt <= 0;
                        c_cnt <= 0;
                        state <= S_PREPARE_DATA;
                    end
                end

                S_PREPARE_DATA: begin
                    state <= S_CALC_DIGITS;
                end

                S_CALC_DIGITS: begin
                    digit_hundreds <= current_data / 100;
                    digit_tens     <= (current_data % 100) / 10;
                    digit_units    <= current_data % 10;
                    state <= S_SEND_CHAR_1;
                end

                S_SEND_CHAR_1: begin
                    if (!tx_busy) begin
                        tx_start <= 1;
                        if (current_data >= 100)      tx_data <= digit_hundreds + ASCII_0;
                        else if (current_data >= 10)  tx_data <= digit_tens + ASCII_0;
                        else                          tx_data <= digit_units + ASCII_0;
                        
                        next_state_after_wait <= S_SEND_CHAR_2;
                        state <= S_WAIT_UART;
                    end
                end

                S_SEND_CHAR_2: begin
                    if (!tx_busy) begin 
                        tx_start <= 1;
                        if (current_data >= 100)      tx_data <= digit_tens + ASCII_0;
                        else if (current_data >= 10)  tx_data <= digit_units + ASCII_0;
                        else                          tx_data <= ASCII_SPACE;
                        
                        next_state_after_wait <= S_SEND_CHAR_3;
                        state <= S_WAIT_UART;
                    end
                end

                S_SEND_CHAR_3: begin
                    if (!tx_busy) begin
                        tx_start <= 1;
                        if (current_data >= 100)      tx_data <= digit_units + ASCII_0;
                        else                          tx_data <= ASCII_SPACE;
                        
                        next_state_after_wait <= S_SEND_SEP;
                        state <= S_WAIT_UART;
                    end
                end

                S_WAIT_UART: begin
                    tx_start <= 0;
                    if (tx_busy) begin
                        // wait
                    end else begin
                        state <= next_state_after_wait;
                    end
                end

                S_SEND_SEP: begin
                    if (!tx_busy) begin
                        tx_start <= 1;
                        // 注意这里用 FIXED_COL
                        if (c_cnt == FIXED_COL - 1) 
                            tx_data <= ASCII_LF; // 换行
                        else 
                            tx_data <= ASCII_SPACE; // 空格
                        
                        next_state_after_wait <= S_CHECK_NEXT;
                        state <= S_WAIT_UART;
                    end
                end

                S_CHECK_NEXT: begin
                    // 注意这里用 FIXED_COL 和 FIXED_ROW
                    if (c_cnt == FIXED_COL - 1) begin
                        c_cnt <= 0;
                        if (r_cnt == FIXED_ROW - 1) state <= S_DONE;
                        else begin
                            r_cnt <= r_cnt + 1;
                            state <= S_PREPARE_DATA;
                        end
                    end else begin
                        c_cnt <= c_cnt + 1;
                        state <= S_PREPARE_DATA;
                    end
                end

                S_DONE: begin
                    busy <= 0;
                    state <= S_WAIT_RELEASE;
                end

                S_WAIT_RELEASE: begin
                    if (start == 0) state <= S_IDLE;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule