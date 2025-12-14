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

