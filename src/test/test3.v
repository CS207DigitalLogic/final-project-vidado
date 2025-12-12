module test3(output wire [7:0]    dbg_matrix_data_0,  // 调试用矩阵数据0
    input  wire clk,
    input  wire rst_n,
    input  wire btn_trigger
);
wire       btn_pulse;
key_debounce u_keydebounce (
    .clk(clk),
    .rst_n(rst_n),
    .btn_trigger(btn_trigger),
    .btn_pulse(btn_pulse)
);

random_num_generator #(
    .WIDTH(8)
) u_rng2 (
    .clk(clk),
    .rst_n(rst_n),
    .en(btn_pulse),
    .min_val(8'b00000000),  // 动态输入最小值
    .max_val(8'b00001111),  // 动态输入最大值
    .random_num(dbg_matrix_data_0)
);

endmodule

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