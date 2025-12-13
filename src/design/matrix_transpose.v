module matrix_transpose #(
    parameter DATA_WIDTH = 9
) (
    input clk,
    input reset_n,
    input [2:0] r,
    input [2:0] c,
    input [DATA_WIDTH-1:0] data_in_0,
    input [DATA_WIDTH-1:0] data_in_1,
    input [DATA_WIDTH-1:0] data_in_2,
    input [DATA_WIDTH-1:0] data_in_3,
    input [DATA_WIDTH-1:0] data_in_4,
    input [DATA_WIDTH-1:0] data_in_5,
    input [DATA_WIDTH-1:0] data_in_6,
    input [DATA_WIDTH-1:0] data_in_7,
    input [DATA_WIDTH-1:0] data_in_8,
    input [DATA_WIDTH-1:0] data_in_9,
    input [DATA_WIDTH-1:0] data_in_10,
    input [DATA_WIDTH-1:0] data_in_11,
    input [DATA_WIDTH-1:0] data_in_12,
    input [DATA_WIDTH-1:0] data_in_13,
    input [DATA_WIDTH-1:0] data_in_14,
    input [DATA_WIDTH-1:0] data_in_15,
    input [DATA_WIDTH-1:0] data_in_16,
    input [DATA_WIDTH-1:0] data_in_17,
    input [DATA_WIDTH-1:0] data_in_18,
    input [DATA_WIDTH-1:0] data_in_19,
    input [DATA_WIDTH-1:0] data_in_20,
    input [DATA_WIDTH-1:0] data_in_21,
    input [DATA_WIDTH-1:0] data_in_22,
    input [DATA_WIDTH-1:0] data_in_23,
    input [DATA_WIDTH-1:0] data_in_24,
    input en,
    output reg [2:0] r_out,
    output reg [2:0] c_out,
    output reg [DATA_WIDTH-1:0] data_out_0,
    output reg [DATA_WIDTH-1:0] data_out_1,
    output reg [DATA_WIDTH-1:0] data_out_2,
    output reg [DATA_WIDTH-1:0] data_out_3,
    output reg [DATA_WIDTH-1:0] data_out_4,
    output reg [DATA_WIDTH-1:0] data_out_5,
    output reg [DATA_WIDTH-1:0] data_out_6,
    output reg [DATA_WIDTH-1:0] data_out_7,
    output reg [DATA_WIDTH-1:0] data_out_8,
    output reg [DATA_WIDTH-1:0] data_out_9,
    output reg [DATA_WIDTH-1:0] data_out_10,
    output reg [DATA_WIDTH-1:0] data_out_11,
    output reg [DATA_WIDTH-1:0] data_out_12,
    output reg [DATA_WIDTH-1:0] data_out_13,
    output reg [DATA_WIDTH-1:0] data_out_14,
    output reg [DATA_WIDTH-1:0] data_out_15,
    output reg [DATA_WIDTH-1:0] data_out_16,
    output reg [DATA_WIDTH-1:0] data_out_17,
    output reg [DATA_WIDTH-1:0] data_out_18,
    output reg [DATA_WIDTH-1:0] data_out_19,
    output reg [DATA_WIDTH-1:0] data_out_20,
    output reg [DATA_WIDTH-1:0] data_out_21,
    output reg [DATA_WIDTH-1:0] data_out_22,
    output reg [DATA_WIDTH-1:0] data_out_23,
    output reg [DATA_WIDTH-1:0] data_out_24,
    output reg busy
);

    // Order模块的信号声明
    wire [DATA_WIDTH-1:0] ordered_data_0;
    wire [DATA_WIDTH-1:0] ordered_data_1;
    wire [DATA_WIDTH-1:0] ordered_data_2;
    wire [DATA_WIDTH-1:0] ordered_data_3;
    wire [DATA_WIDTH-1:0] ordered_data_4;
    wire [DATA_WIDTH-1:0] ordered_data_5;
    wire [DATA_WIDTH-1:0] ordered_data_6;
    wire [DATA_WIDTH-1:0] ordered_data_7;
    wire [DATA_WIDTH-1:0] ordered_data_8;
    wire [DATA_WIDTH-1:0] ordered_data_9;
    wire [DATA_WIDTH-1:0] ordered_data_10;
    wire [DATA_WIDTH-1:0] ordered_data_11;
    wire [DATA_WIDTH-1:0] ordered_data_12;
    wire [DATA_WIDTH-1:0] ordered_data_13;
    wire [DATA_WIDTH-1:0] ordered_data_14;
    wire [DATA_WIDTH-1:0] ordered_data_15;
    wire [DATA_WIDTH-1:0] ordered_data_16;
    wire [DATA_WIDTH-1:0] ordered_data_17;
    wire [DATA_WIDTH-1:0] ordered_data_18;
    wire [DATA_WIDTH-1:0] ordered_data_19;
    wire [DATA_WIDTH-1:0] ordered_data_20;
    wire [DATA_WIDTH-1:0] ordered_data_21;
    wire [DATA_WIDTH-1:0] ordered_data_22;
    wire [DATA_WIDTH-1:0] ordered_data_23;
    wire [DATA_WIDTH-1:0] ordered_data_24;
    
    // 内部信号
    wire order_en;
    wire transpose_en;
    reg en_delay;  // en延迟一拍
    
    // 实例化Order模块
    matirx_order #(
        .DATA_WIDTH(DATA_WIDTH)
    ) order_inst (
        // 输入端口
        .clk(clk),
        .reset_n(reset_n),
        .r(r),
        .c(c),
        .data_in_0(data_in_0),
        .data_in_1(data_in_1),
        .data_in_2(data_in_2),
        .data_in_3(data_in_3),
        .data_in_4(data_in_4),
        .data_in_5(data_in_5),
        .data_in_6(data_in_6),
        .data_in_7(data_in_7),
        .data_in_8(data_in_8),
        .data_in_9(data_in_9),
        .data_in_10(data_in_10),
        .data_in_11(data_in_11),
        .data_in_12(data_in_12),
        .data_in_13(data_in_13),
        .data_in_14(data_in_14),
        .data_in_15(data_in_15),
        .data_in_16(data_in_16),
        .data_in_17(data_in_17),
        .data_in_18(data_in_18),
        .data_in_19(data_in_19),
        .data_in_20(data_in_20),
        .data_in_21(data_in_21),
        .data_in_22(data_in_22),
        .data_in_23(data_in_23),
        .data_in_24(data_in_24),
        .en(en),
        .data_out_0(ordered_data_0),
        .data_out_1(ordered_data_1),
        .data_out_2(ordered_data_2),
        .data_out_3(ordered_data_3),
        .data_out_4(ordered_data_4),
        .data_out_5(ordered_data_5),
        .data_out_6(ordered_data_6),
        .data_out_7(ordered_data_7),
        .data_out_8(ordered_data_8),
        .data_out_9(ordered_data_9),
        .data_out_10(ordered_data_10),
        .data_out_11(ordered_data_11),
        .data_out_12(ordered_data_12),
        .data_out_13(ordered_data_13),
        .data_out_14(ordered_data_14),
        .data_out_15(ordered_data_15),
        .data_out_16(ordered_data_16),
        .data_out_17(ordered_data_17),
        .data_out_18(ordered_data_18),
        .data_out_19(ordered_data_19),
        .data_out_20(ordered_data_20),
        .data_out_21(ordered_data_21),
        .data_out_22(ordered_data_22),
        .data_out_23(ordered_data_23),
        .data_out_24(ordered_data_24),
        .isOrdered(order_en)
    );
    
    // 第二级：Transpose模块的en（延迟一拍）
    always@(order_en) begin
        en_delay <= order_en;  // 这里其实也是个锁存器
    end
    assign transpose_en = en_delay;
    
    // 重排状态判断机
    reg count;
    always@(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            busy <= 0;
        end else begin
            // 开始运算且排序未完成
            if (en && !order_en) begin
                busy <= 1;
            end else if (!en) begin
                busy <= 0;
            end else begin
                if (busy && count < 1) begin
                    count <= count + 1;
                end else begin
                    busy <= 0;
                    count <= 0;
                end
            end
        end
    end

    // 只在en从0变化到1的时候单次赋值，即使输入出现变化，只要en没有被清零就不会改变输出
    // 所以en初始值为0，在使用该模块时先确保输入data正确，后将en赋1，离开转置运算时将en重置
    always@(transpose_en) begin
        if(transpose_en) begin
            r_out = c;
            c_out = r;
            
            // 第一行：原矩阵的第一列
            data_out_0 = ordered_data_0;   // [0][0] → [0][0]
            data_out_1 = ordered_data_5;   // [1][0] → [0][1]
            data_out_2 = ordered_data_10;  // [2][0] → [0][2]
            data_out_3 = ordered_data_15;  // [3][0] → [0][3]
            data_out_4 = ordered_data_20;  // [4][0] → [0][4]
            
            // 第二行：原矩阵的第二列
            data_out_5 = ordered_data_1;   // [0][1] → [1][0]
            data_out_6 = ordered_data_6;   // [1][1] → [1][1]
            data_out_7 = ordered_data_11;  // [2][1] → [1][2]
            data_out_8 = ordered_data_16;  // [3][1] → [1][3]
            data_out_9 = ordered_data_21;  // [4][1] → [1][4]
            
            // 第三行：原矩阵的第三列
            data_out_10 = ordered_data_2;  // [0][2] → [2][0]
            data_out_11 = ordered_data_7;  // [1][2] → [2][1]
            data_out_12 = ordered_data_12; // [2][2] → [2][2]
            data_out_13 = ordered_data_17; // [3][2] → [2][3]
            data_out_14 = ordered_data_22; // [4][2] → [2][4]
            
            // 第四行：原矩阵的第四列
            data_out_15 = ordered_data_3;  // [0][3] → [3][0]
            data_out_16 = ordered_data_8;  // [1][3] → [3][1]
            data_out_17 = ordered_data_13; // [2][3] → [3][2]
            data_out_18 = ordered_data_18; // [3][3] → [3][3]
            data_out_19 = ordered_data_23; // [4][3] → [3][4]
            
            // 第五行：原矩阵的第五列
            data_out_20 = ordered_data_4;  // [0][4] → [4][0]
            data_out_21 = ordered_data_9;  // [1][4] → [4][1]
            data_out_22 = ordered_data_14; // [2][4] → [4][2]
            data_out_23 = ordered_data_19; // [3][4] → [4][3]
            data_out_24 = ordered_data_24; // [4][4] → [4][4]
        end
        else begin
            r_out = 0;
            c_out = 0;
            data_out_0 = 0;
            data_out_1 = 0;
            data_out_2 = 0;
            data_out_3 = 0;
            data_out_4 = 0;
            data_out_5 = 0;
            data_out_6 = 0;
            data_out_7 = 0;
            data_out_8 = 0;
            data_out_9 = 0;
            data_out_10 = 0;
            data_out_11 = 0;
            data_out_12 = 0;
            data_out_13 = 0;
            data_out_14 = 0;
            data_out_15 = 0;
            data_out_16 = 0;
            data_out_17 = 0;
            data_out_18 = 0;
            data_out_19 = 0;
            data_out_20 = 0;
            data_out_21 = 0;
            data_out_22 = 0;
            data_out_23 = 0;
            data_out_24 = 0;
        end
    end
endmodule
