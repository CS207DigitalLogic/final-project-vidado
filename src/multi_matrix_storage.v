module multi_matrix_storage #(
    parameter DATA_WIDTH        = 8,        // ����λ��
    parameter MAX_SIZE          = 5,        // ������������ģ��1~5��
    parameter MATRIX_NUM        = 8,        // ȫ������������
    parameter MAX_MATRIX_PER_SIZE = 4       // ÿ����ģ���洢������
)(
    input wire                     rst_n,          // ����Ч��λ�������ڳ�ʼ����
    // ---------------------------
    // ����߼�д��ӿ�
    // ---------------------------
    input wire                     wr_en,          // дʹ�ܣ�1=ִ��д�룬����߼�ʵʱ��Ӧ��
    input wire [MATRIX_IDX_W-1:0]  target_idx,     // д��Ŀ�꣺ȫ�־���������0~MATRIX_NUM-1��
    input wire [2:0]               write_row,      // д������������1~MAX_SIZE��
    input wire [2:0]               write_col,      // д������������1~MAX_SIZE��
    input wire [DATA_WIDTH-1:0]    data_in_0,      // д������0����ַ0��
    input wire [DATA_WIDTH-1:0]    data_in_1,      // д������1����ַ1��
    input wire [DATA_WIDTH-1:0]    data_in_2,      // д������2����ַ2��
    input wire [DATA_WIDTH-1:0]    data_in_3,      // д������3����ַ3��
    input wire [DATA_WIDTH-1:0]    data_in_4,      // д������4����ַ4��
    input wire [DATA_WIDTH-1:0]    data_in_5,      // д������5����ַ5��
    input wire [DATA_WIDTH-1:0]    data_in_6,      // д������6����ַ6��
    input wire [DATA_WIDTH-1:0]    data_in_7,      // д������7����ַ7��
    input wire [DATA_WIDTH-1:0]    data_in_8,      // д������8����ַ8��
    input wire [DATA_WIDTH-1:0]    data_in_9,      // д������9����ַ9��
    input wire [DATA_WIDTH-1:0]    data_in_10,     // д������10����ַ10��
    input wire [DATA_WIDTH-1:0]    data_in_11,     // д������11����ַ11��
    input wire [DATA_WIDTH-1:0]    data_in_12,     // д������12����ַ12��
    input wire [DATA_WIDTH-1:0]    data_in_13,     // д������13����ַ13��
    input wire [DATA_WIDTH-1:0]    data_in_14,     // д������14����ַ14��
    input wire [DATA_WIDTH-1:0]    data_in_15,     // д������15����ַ15��
    input wire [DATA_WIDTH-1:0]    data_in_16,     // д������16����ַ16��
    input wire [DATA_WIDTH-1:0]    data_in_17,     // д������17����ַ17��
    input wire [DATA_WIDTH-1:0]    data_in_18,     // д������18����ַ18��
    input wire [DATA_WIDTH-1:0]    data_in_19,     // д������19����ַ19��
    input wire [DATA_WIDTH-1:0]    data_in_20,     // д������20����ַ20��
    input wire [DATA_WIDTH-1:0]    data_in_21,     // д������21����ַ21��
    input wire [DATA_WIDTH-1:0]    data_in_22,     // д������22����ַ22��
    input wire [DATA_WIDTH-1:0]    data_in_23,     // д������23����ַ23��
    input wire [DATA_WIDTH-1:0]    data_in_24,     // д������24����ַ24��
    // ---------------------------
    // ���Ĳ�ѯ���루����ģ+���ѡ�������֮ǰһ�£�
    // ---------------------------
    input wire [2:0]               req_scale_row,  // Ҫ��ľ����ģ���У�1~MAX_SIZE��
    input wire [2:0]               req_scale_col,  // Ҫ��ľ����ģ���У�1~MAX_SIZE��
    input wire [SEL_IDX_W-1:0]     req_idx,        // Ҫ�����ţ�0~MAX_MATRIX_PER_SIZE-1��
    // ---------------------------
    // ����ӿڣ���֮ǰһ�£��ޱ仯��
    // ---------------------------
    output reg [SEL_IDX_W-1:0]     scale_matrix_cnt, // Ŀ���ģ�ľ�������
    output reg [DATA_WIDTH-1:0]    matrix_data_0,  // ����Ԫ��0����ַ0��
    output reg [DATA_WIDTH-1:0]    matrix_data_1,  // ����Ԫ��1����ַ1��
    output reg [DATA_WIDTH-1:0]    matrix_data_2,  // ����Ԫ��2����ַ2��
    output reg [DATA_WIDTH-1:0]    matrix_data_3,  // ����Ԫ��3����ַ3��
    output reg [DATA_WIDTH-1:0]    matrix_data_4,  // ����Ԫ��4����ַ4��
    output reg [DATA_WIDTH-1:0]    matrix_data_5,  // ����Ԫ��5����ַ5��
    output reg [DATA_WIDTH-1:0]    matrix_data_6,  // ����Ԫ��6����ַ6��
    output reg [DATA_WIDTH-1:0]    matrix_data_7,  // ����Ԫ��7����ַ7��
    output reg [DATA_WIDTH-1:0]    matrix_data_8,  // ����Ԫ��8����ַ8��
    output reg [DATA_WIDTH-1:0]    matrix_data_9,  // ����Ԫ��9����ַ9��
    output reg [DATA_WIDTH-1:0]    matrix_data_10, // ����Ԫ��10����ַ10��
    output reg [DATA_WIDTH-1:0]    matrix_data_11, // ����Ԫ��11����ַ11��
    output reg [DATA_WIDTH-1:0]    matrix_data_12, // ����Ԫ��12����ַ12��
    output reg [DATA_WIDTH-1:0]    matrix_data_13, // ����Ԫ��13����ַ13��
    output reg [DATA_WIDTH-1:0]    matrix_data_14, // ����Ԫ��14����ַ14��
    output reg [DATA_WIDTH-1:0]    matrix_data_15, // ����Ԫ��15����ַ15��
    output reg [DATA_WIDTH-1:0]    matrix_data_16, // ����Ԫ��16����ַ16��
    output reg [DATA_WIDTH-1:0]    matrix_data_17, // ����Ԫ��17����ַ17��
    output reg [DATA_WIDTH-1:0]    matrix_data_18, // ����Ԫ��18����ַ18��
    output reg [DATA_WIDTH-1:0]    matrix_data_19, // ����Ԫ��19����ַ19��
    output reg [DATA_WIDTH-1:0]    matrix_data_20, // ����Ԫ��20����ַ20��
    output reg [DATA_WIDTH-1:0]    matrix_data_21, // ����Ԫ��21����ַ21��
    output reg [DATA_WIDTH-1:0]    matrix_data_22, // ����Ԫ��22����ַ22��
    output reg [DATA_WIDTH-1:0]    matrix_data_23, // ����Ԫ��23����ַ23��
    output reg [DATA_WIDTH-1:0]    matrix_data_24, // ����Ԫ��24����ַ24��
    output reg [2:0]               matrix_row,     // ��������ʵ������
    output reg [2:0]               matrix_col,     // ��������ʵ������
    output reg                     matrix_valid    // ������Ч��ǣ�1=�����Ч��
);

// ---------------------------
// �ֲ���������ԭ�߼�һ�£��ޱ仯��
// ---------------------------
localparam MEM_DEPTH_PER_MATRIX = MAX_SIZE * MAX_SIZE;  // ��������洢��ȣ�25��
localparam MATRIX_IDX_W = (MATRIX_NUM <= 1)  ? 1 :
                         (MATRIX_NUM <= 2)  ? 2 :
                         (MATRIX_NUM <= 4)  ? 3 :
                         (MATRIX_NUM <= 8)  ? 3 :
                         (MATRIX_NUM <= 16) ? 4 :
                         (MATRIX_NUM <= 32) ? 5 :
                         6;
localparam SEL_IDX_W = (MAX_MATRIX_PER_SIZE <= 1) ? 1 :
                       (MAX_MATRIX_PER_SIZE <= 3) ? 2 : // 3个以下用2位
                       (MAX_MATRIX_PER_SIZE <= 7) ? 3 : // 4到7个必须用3位！
                       (MAX_MATRIX_PER_SIZE <= 15) ? 4 :
                       5;

// ---------------------------
// �ڲ��������飨��ԭ�߼�һ�£��ޱ仯��
// ---------------------------
reg [DATA_WIDTH-1:0] mem [0:MATRIX_NUM-1] [0:MEM_DEPTH_PER_MATRIX-1];  // ȫ�־���洢
reg [2:0] row_self [0:MATRIX_NUM-1];  // ÿ�������ʵ������
reg [2:0] col_self [0:MATRIX_NUM-1];  // ÿ�������ʵ������
reg [MATRIX_IDX_W-1:0] size2matrix [1:MAX_SIZE] [1:MAX_SIZE] [0:MAX_MATRIX_PER_SIZE-1];  // ��ģ��ȫ������ӳ��
reg [SEL_IDX_W-1:0] size_cnt [1:MAX_SIZE] [1:MAX_SIZE];  // ÿ����ģ�ľ������
reg [0:MATRIX_NUM-1] matrix_init_flag;  // �����ʼ�����

// ---------------------------
// �ڲ���ʱ���������б��������ⲿ�������ޱ仯��
// ---------------------------
// д���߼����
reg [2:0] r_store, c_store;                          // ��Ч�洢��ģ����/�У�
reg [MATRIX_IDX_W-1:0] valid_target_idx;             // ��ЧĿ���������߽籣����
reg [SEL_IDX_W-1:0] curr_cnt;                        // ͬ��ģ��ǰ����

// ��ѯ������
reg [2:0] valid_scale_r, valid_scale_c;               // ��Ч��ѯ��ģ
reg [MATRIX_IDX_W-1:0] target_global_idx;             // Ŀ�����ȫ������
reg [SEL_IDX_W-1:0] valid_req_idx;                   // ��Ч��ѯ���

// ---------------------------
// 1. ��λ��ʼ����ʱ���߼�������λʱִ�У��ޱ仯��
// ---------------------------
integer m, d, r, c, s, gg;
always @(posedge rst_n or negedge rst_n) begin  // �첽��λ��ȷ����ʼ���ɿ�
    if (!rst_n) begin
        // 1.1 ȫ�ִ洢��ʼ��������Ԫ����0��
        for (m = 0; m < MATRIX_NUM; m = m + 1) begin
            for (d = 0; d < MEM_DEPTH_PER_MATRIX; d = d + 1) begin
                mem[m][d] <= {DATA_WIDTH{1'b0}};
            end
        end

        // 1.2 �����ģ+��ʼ����ǳ�ʼ��
        for (m = 0; m < MATRIX_NUM; m = m + 1) begin
            row_self[m] <= 1'd1;
            col_self[m] <= 1'd1;
            matrix_init_flag[m] <= 1'b0;
        end

        // 1.3 ��ģӳ����ͼ�������ʼ��
        for (r = 1; r <= MAX_SIZE; r = r + 1) begin
            for (c = 1; c <= MAX_SIZE; c = c + 1) begin
                size_cnt[r][c] <= {SEL_IDX_W{1'b0}};
                for (s = 0; s < MAX_MATRIX_PER_SIZE; s = s + 1) begin
                    size2matrix[r][c][s] <= {MATRIX_IDX_W{1'b0}};
                end
            end
        end

        // 1.4 Ԥ������ʼ����ʾ�����ݣ����������룩
        // Ԥ��2x3����0��ȫ������0��
        mem[0][0] <= 8'h01; mem[0][1] <= 8'h02; mem[0][2] <= 8'hFB;
        mem[0][3] <= 8'h04; mem[0][4] <= 8'h05; mem[0][5] <= 8'h06;
        row_self[0] <= 3'd2; col_self[0] <= 3'd3;
        matrix_init_flag[0] <= 1'b1;

        // Ԥ��2x3����1��ȫ������1��
        mem[1][0] <= 8'h11; mem[1][1] <= 8'h12; mem[1][2] <= 8'h80;
        mem[1][3] <= 8'h14; mem[1][4] <= 8'h15; mem[1][5] <= 8'h16;
        row_self[1] <= 3'd2; col_self[1] <= 3'd3;
        matrix_init_flag[1] <= 1'b1;

        // Ԥ��2x3����2��ȫ������2��
        mem[2][0] <= 8'h21; mem[2][1] <= 8'h22; mem[2][2] <= 8'hFF;
        mem[2][3] <= 8'h24; mem[2][4] <= 8'h25; mem[2][5] <= 8'h26;
        row_self[2] <= 3'd2; col_self[2] <= 3'd3;
        matrix_init_flag[2] <= 1'b1;

        // Ԥ��3x4����ȫ������3��
        for (gg = 0; gg < 12; gg = gg + 1) begin
            mem[3][gg] <= 8'h31 + gg;
        end
        row_self[3] <= 3'd3; col_self[3] <= 3'd4;
        matrix_init_flag[3] <= 1'b1;

        // 1.5 ����Ԥ�����Ĺ�ģӳ����ͼ�����
        size2matrix[2][3][0] <= 3'd0;
        size2matrix[2][3][1] <= 3'd1;
        size2matrix[2][3][2] <= 3'd2;
        size_cnt[2][3] <= 3'd3;

        size2matrix[3][4][0] <= 3'd3;
        size_cnt[3][4] <= 3'd1;
    end
end

// ---------------------------
// 2. ��������߼�д�루��ʱ�ӣ�wr_en��Ч��ִ�У�
// ---------------------------
always @(*) begin
    // ---------------------------
    // 2.1 ����߽籣����������Чд�룩
    // ---------------------------
    // ��ЧĿ��������������Χ��Ĭ��0
    valid_target_idx = (target_idx < MATRIX_NUM) ? target_idx : {MATRIX_IDX_W{1'b0}};
    // ��Ч�洢��ģ������1~MAX_SIZE��Ĭ��1x1
    r_store = (write_row >= 1 && write_row <= MAX_SIZE) ? write_row : 1'd1;
    c_store = (write_col >= 1 && write_col <= MAX_SIZE) ? write_col : 1'd1;
    // ��ǰ��ģ�ľ������
    curr_cnt = size_cnt[r_store][c_store];

    // ---------------------------
    // 2.2 ����߼�д�루wr_en��Чʱִ�У����򱣳�ԭ״̬��
    // ---------------------------
    if (wr_en) begin
        // 2.2.1 д��25������Ԫ�أ�ֱ��ӳ���ַ0~24���޵�ַ���룩
        mem[valid_target_idx][0]  = data_in_0;
        mem[valid_target_idx][1]  = data_in_1;
        mem[valid_target_idx][2]  = data_in_2;
        mem[valid_target_idx][3]  = data_in_3;
        mem[valid_target_idx][4]  = data_in_4;
        mem[valid_target_idx][5]  = data_in_5;
        mem[valid_target_idx][6]  = data_in_6;
        mem[valid_target_idx][7]  = data_in_7;
        mem[valid_target_idx][8]  = data_in_8;
        mem[valid_target_idx][9]  = data_in_9;
        mem[valid_target_idx][10] = data_in_10;
        mem[valid_target_idx][11] = data_in_11;
        mem[valid_target_idx][12] = data_in_12;
        mem[valid_target_idx][13] = data_in_13;
        mem[valid_target_idx][14] = data_in_14;
        mem[valid_target_idx][15] = data_in_15;
        mem[valid_target_idx][16] = data_in_16;
        mem[valid_target_idx][17] = data_in_17;
        mem[valid_target_idx][18] = data_in_18;
        mem[valid_target_idx][19] = data_in_19;
        mem[valid_target_idx][20] = data_in_20;
        mem[valid_target_idx][21] = data_in_21;
        mem[valid_target_idx][22] = data_in_22;
        mem[valid_target_idx][23] = data_in_23;
        mem[valid_target_idx][24] = data_in_24;

        // 2.2.2 ���¾���ʵ����/����
        row_self[valid_target_idx] = r_store;
        col_self[valid_target_idx] = c_store;

        // 2.2.3 ��ʼ��������ģӳ������£����״�д��ʱִ�У�
        if (!matrix_init_flag[valid_target_idx] && (curr_cnt < MAX_MATRIX_PER_SIZE)) begin
            // �������󵽹�ģӳ���
            size2matrix[r_store][c_store][curr_cnt] = valid_target_idx;
            // ������ǰ��ģ�ľ������
            size_cnt[r_store][c_store] = curr_cnt + 1'd1;
            // ��Ǿ����ѳ�ʼ��
            matrix_init_flag[valid_target_idx] = 1'b1;
        end else begin
            // ���״�д�룺����ӳ����ͼ������䣬���������ݺ͹�ģ
            size2matrix[r_store][c_store][curr_cnt] = size2matrix[r_store][c_store][curr_cnt];
            size_cnt[r_store][c_store] = curr_cnt;
            matrix_init_flag[valid_target_idx] = matrix_init_flag[valid_target_idx];
        end
    end else begin
        // 2.2.4 дʹ����Ч�������ڲ����鱣��ԭ״̬����latch��
        mem[valid_target_idx][0]  = mem[valid_target_idx][0];
        mem[valid_target_idx][1]  = mem[valid_target_idx][1];
        mem[valid_target_idx][2]  = mem[valid_target_idx][2];
        mem[valid_target_idx][3]  = mem[valid_target_idx][3];
        mem[valid_target_idx][4]  = mem[valid_target_idx][4];
        mem[valid_target_idx][5]  = mem[valid_target_idx][5];
        mem[valid_target_idx][6]  = mem[valid_target_idx][6];
        mem[valid_target_idx][7]  = mem[valid_target_idx][7];
        mem[valid_target_idx][8]  = mem[valid_target_idx][8];
        mem[valid_target_idx][9]  = mem[valid_target_idx][9];
        mem[valid_target_idx][10] = mem[valid_target_idx][10];
        mem[valid_target_idx][11] = mem[valid_target_idx][11];
        mem[valid_target_idx][12] = mem[valid_target_idx][12];
        mem[valid_target_idx][13] = mem[valid_target_idx][13];
        mem[valid_target_idx][14] = mem[valid_target_idx][14];
        mem[valid_target_idx][15] = mem[valid_target_idx][15];
        mem[valid_target_idx][16] = mem[valid_target_idx][16];
        mem[valid_target_idx][17] = mem[valid_target_idx][17];
        mem[valid_target_idx][18] = mem[valid_target_idx][18];
        mem[valid_target_idx][19] = mem[valid_target_idx][19];
        mem[valid_target_idx][20] = mem[valid_target_idx][20];
        mem[valid_target_idx][21] = mem[valid_target_idx][21];
        mem[valid_target_idx][22] = mem[valid_target_idx][22];
        mem[valid_target_idx][23] = mem[valid_target_idx][23];
        mem[valid_target_idx][24] = mem[valid_target_idx][24];

        row_self[valid_target_idx] = row_self[valid_target_idx];
        col_self[valid_target_idx] = col_self[valid_target_idx];
        size2matrix[r_store][c_store][curr_cnt] = size2matrix[r_store][c_store][curr_cnt];
        size_cnt[r_store][c_store] = curr_cnt;
        matrix_init_flag[valid_target_idx] = matrix_init_flag[valid_target_idx];
    end
end

// ---------------------------
// 3. ���Ĳ�ѯ����߼�������߼�����֮ǰһ�£��ޱ仯��
// ---------------------------
always @(*) begin
    // 3.1 ����߽籣��
    valid_scale_r = (req_scale_row >= 1 && req_scale_row <= MAX_SIZE) ? req_scale_row : 1'd1;
    valid_scale_c = (req_scale_col >= 1 && req_scale_col <= MAX_SIZE) ? req_scale_col : 1'd1;
    valid_req_idx = (req_idx < MAX_MATRIX_PER_SIZE) ? req_idx : {SEL_IDX_W{1'b0}};

    // 3.2 ���Ŀ���ģ�ľ�������
    scale_matrix_cnt = size_cnt[valid_scale_r][valid_scale_c];

    // 3.3 ����Ŀ������ȫ������
    if (scale_matrix_cnt > 0 && valid_req_idx < scale_matrix_cnt) begin
        target_global_idx = size2matrix[valid_scale_r][valid_scale_c][valid_req_idx];
        matrix_valid = 1'b1;
    end else begin
        target_global_idx = {MATRIX_IDX_W{1'b0}};
        matrix_valid = 1'b0;
    end

    // 3.4 ���Ŀ������25��Ԫ��
    matrix_data_0  = mem[target_global_idx][0];
    matrix_data_1  = mem[target_global_idx][1];
    matrix_data_2  = mem[target_global_idx][2];
    matrix_data_3  = mem[target_global_idx][3];
    matrix_data_4  = mem[target_global_idx][4];
    matrix_data_5  = mem[target_global_idx][5];
    matrix_data_6  = mem[target_global_idx][6];
    matrix_data_7  = mem[target_global_idx][7];
    matrix_data_8  = mem[target_global_idx][8];
    matrix_data_9  = mem[target_global_idx][9];
    matrix_data_10 = mem[target_global_idx][10];
    matrix_data_11 = mem[target_global_idx][11];
    matrix_data_12 = mem[target_global_idx][12];
    matrix_data_13 = mem[target_global_idx][13];
    matrix_data_14 = mem[target_global_idx][14];
    matrix_data_15 = mem[target_global_idx][15];
    matrix_data_16 = mem[target_global_idx][16];
    matrix_data_17 = mem[target_global_idx][17];
    matrix_data_18 = mem[target_global_idx][18];
    matrix_data_19 = mem[target_global_idx][19];
    matrix_data_20 = mem[target_global_idx][20];
    matrix_data_21 = mem[target_global_idx][21];
    matrix_data_22 = mem[target_global_idx][22];
    matrix_data_23 = mem[target_global_idx][23];
    matrix_data_24 = mem[target_global_idx][24];

    // 3.5 ���Ŀ������ʵ����/����
    matrix_row = row_self[target_global_idx];
    matrix_col = col_self[target_global_idx];
    matrix_row = (matrix_row >= 1 && matrix_row <= MAX_SIZE) ? matrix_row : 1'd1;
    matrix_col = (matrix_col >= 1 && matrix_col <= MAX_SIZE) ? matrix_col : 1'd1;
end

endmodule