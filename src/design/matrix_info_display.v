module matrix_info_display#(
    parameter MAX_SIZE = 5,
    parameter CNT_WIDTH = 5 
)(
    input  wire                 clk,
    input  wire                 rst_n,
    
    // 控制接口
    input  wire                 start_req,      
    output reg                  busy,           
    
    // UART 发送接口
    input  wire                 uart_tx_busy,   
    output reg                  uart_tx_start,  
    output reg [7:0]            uart_tx_data,   
    
    // Multi_matrix_storage 查询接口
    output reg [2:0]            qry_row,        
    output reg [2:0]            qry_col,        
    input  wire [CNT_WIDTH-1:0] qry_cnt,        

    // 随机选择输出接口
    output reg [2:0]            random_r,       
    output reg [2:0]            random_c,       
    output reg [CNT_WIDTH-1:0]  random_cnt      
);

    // --- 状态定义 ---
    localparam S_IDLE           = 0;
    localparam S_SCAN_INIT      = 1;
    localparam S_SCAN_SET_ADDR  = 2;
    localparam S_SCAN_WAIT_1    = 3; 
    localparam S_SCAN_WAIT_2    = 15;
    localparam S_SCAN_READ      = 4;
    
    // 打印每行详情的状态
    localparam S_SEND_TOTAL_HI  = 5;
    localparam S_SEND_TOTAL_LO  = 6;
    localparam S_SEND_ROW       = 7;
    localparam S_SEND_X         = 8;
    localparam S_SEND_COL       = 9;
    localparam S_SEND_EQ        = 10;
    localparam S_SEND_NL        = 11;
    localparam S_LIST_CHECK     = 12;
    localparam S_DONE           = 13;
    localparam S_WAIT_RELEASE   = 14; 
    
    // UART 发送子状态
    localparam S_TX_START       = 20;
    localparam S_TX_WAIT_BUSY   = 21;
    localparam S_TX_WAIT_DONE   = 22;
    localparam S_TX_RESET       = 23;

    // [修改] 打印总数状态 (去掉了前缀状态)
    localparam S_PT_NUM_HI      = 34; // 十位
    localparam S_PT_NUM_LO      = 35; // 个位
    localparam S_PT_NL          = 36; // 换行

    reg [5:0] state; 
    reg [5:0] return_state; 

    // 随机数与统计变量
    wire [7:0] rng_out;
    reg  [2:0] rc;               
    reg        scan_pass;        // 0:统计轮, 1:展示轮
    reg  [7:0] total_sum;        // 全局矩阵总数计数器

    // 随机数生成器
    random_num_generator #(
        .WIDTH(8) 
    ) rng_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (1'b1),         
        .min_val    (8'd1),         
        .max_val    (8'd250),         
        .random_num (rng_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            busy <= 0;
            uart_tx_start <= 0;
            uart_tx_data <= 0;
            qry_row <= 1; 
            qry_col <= 1;
            return_state <= S_IDLE;
            random_r <= 0;
            random_c <= 0;
            random_cnt <= 0;
            rc <= 1;
            scan_pass <= 0;
            total_sum <= 0;

        end else begin
            case (state)
                S_IDLE: begin
                    busy <= 0;
                    if (start_req) begin
                        busy <= 1;
                        qry_row <= 1;
                        qry_col <= 1;
                        state <= S_SCAN_INIT;
                        
                        rc <= 1;
                        scan_pass <= 0; // 先进行第0轮(统计)
                        total_sum <= 0; // 清零总数
                    end
                end

                S_SCAN_INIT: begin
                    qry_row <= 1;
                    qry_col <= 1;
                    state <= S_SCAN_SET_ADDR;
                end

                S_SCAN_SET_ADDR: begin
                    state <= S_SCAN_WAIT_1;
                end

                S_SCAN_WAIT_1: begin
                    state <= S_SCAN_WAIT_2;
                end
                
                S_SCAN_WAIT_2: begin
                    state <= S_SCAN_READ;
                end
                
                // 读取状态
                S_SCAN_READ: begin
                    if (scan_pass == 0) begin
                        // --- 第一轮：只统计总数 ---
                        total_sum <= total_sum + qry_cnt;
                        state <= S_LIST_CHECK; 
                    end else begin
                        // --- 第二轮：打印详情 + 随机选择 ---
                        if (qry_cnt > 0) begin
                            // 蓄水池抽样逻辑
                            case (rc)
                                3'd1: begin
                                    random_r <= qry_row; random_c <= qry_col; random_cnt <= qry_cnt;
                                end
                                3'd2: begin
                                    if (rng_out[0] == 1'b0) begin
                                        random_r <= qry_row; random_c <= qry_col; random_cnt <= qry_cnt;
                                    end
                                end
                                3'd3: begin
                                    if (rng_out < 8'd85) begin
                                        random_r <= qry_row; random_c <= qry_col; random_cnt <= qry_cnt;
                                    end
                                end
                                3'd4: begin
                                    if (rng_out[1:0] == 2'b00) begin
                                        random_r <= qry_row; random_c <= qry_col; random_cnt <= qry_cnt;
                                    end
                                end
                                3'd5: begin
                                    if (rng_out < 8'd50) begin
                                        random_r <= qry_row; random_c <= qry_col; random_cnt <= qry_cnt;
                                    end
                                end
                            endcase

                            rc <= rc + 1;
                            
                            // 准备发送行号
                            uart_tx_data <= qry_row + "0";
                            return_state <= S_SEND_X; 
                            state <= S_TX_START; 
                        end else begin
                            state <= S_LIST_CHECK;
                        end
                    end
                end

                // --- 循环检查逻辑 ---
                S_LIST_CHECK: begin
                    if (qry_col < MAX_SIZE) begin
                        qry_col <= qry_col + 1;
                        state <= S_SCAN_SET_ADDR;
                    end else if (qry_row < MAX_SIZE) begin
                        qry_row <= qry_row + 1;
                        qry_col <= 1;
                        state <= S_SCAN_SET_ADDR;
                    end else begin
                        // --- 遍历结束 ---
                        if (scan_pass == 0) begin
                            // 第一轮结束：
                            scan_pass <= 1; // 准备进入第二轮
                            
                            // 重置变量
                            qry_row <= 1; 
                            qry_col <= 1;
                            rc <= 1;      
                            
                            // [修改] 直接跳转到打印数字，跳过 "Tot:"
                            state <= S_PT_NUM_HI; 
                        end else begin
                            // 第二轮结束
                            state <= S_DONE;
                        end
                    end
                end

                // ==========================================
                // 打印总数的状态 (直接打印数字)
                // ==========================================
                S_PT_NUM_HI: begin
                    // 打印十位 (如果没有十位，则直接打个位)
                    if (total_sum > 9) begin
                        uart_tx_data <= (total_sum / 10) + "0";
                        return_state <= S_PT_NUM_LO; 
                    end else begin
                        uart_tx_data <= total_sum + "0";
                        return_state <= S_PT_NL;       
                    end
                    state <= S_TX_START;
                end

                S_PT_NUM_LO: begin
                    uart_tx_data <= (total_sum % 10) + "0";
                    return_state <= S_PT_NL;            
                    state <= S_TX_START;                  
                end

                S_PT_NL: begin
                    uart_tx_data <= 8'h0A; // 换行
                    // 打印完总数后，跳回 SET_ADDR 开始第二轮扫描
                    state <= S_TX_START;
                    return_state <= S_SCAN_SET_ADDR; 
                end

                // ==========================================
                // 单行详情打印 (第二轮用)
                // ==========================================
                S_SEND_X: begin
                     uart_tx_data <= "x";
                     return_state <= S_SEND_COL;
                     state <= S_TX_START;
                end

                S_SEND_COL: begin
                     uart_tx_data <= qry_col + "0";
                     return_state <= S_SEND_EQ;
                     state <= S_TX_START;
                end

                S_SEND_EQ: begin
                     uart_tx_data <= ":";
                     return_state <= S_SEND_TOTAL_HI; 
                     state <= S_TX_START;
                end

                S_SEND_TOTAL_HI: begin
                    if (qry_cnt > 9) begin
                        uart_tx_data <= (qry_cnt / 10) + "0";
                        return_state <= S_SEND_TOTAL_LO; 
                    end else begin
                        uart_tx_data <= qry_cnt + "0";
                        return_state <= S_SEND_NL;       
                    end
                    state <= S_TX_START;
                end

                S_SEND_TOTAL_LO: begin
                    uart_tx_data <= (qry_cnt % 10) + "0";
                    return_state <= S_SEND_NL;            
                    state <= S_TX_START;                  
                end

                S_SEND_NL: begin
                    uart_tx_data <= 8'h0A;
                    return_state <= S_LIST_CHECK;
                    state <= S_TX_START;
                end
                
                // --- 结束处理 ---
                S_DONE: begin
                    busy <= 0;
                    if (start_req) state <= S_WAIT_RELEASE;
                    else state <= S_IDLE;
                end
                
                S_WAIT_RELEASE: begin
                    busy <= 0;
                    if (!start_req) state <= S_IDLE;
                end

                // UART 发送子程序
                S_TX_START: begin
                    uart_tx_start <= 1;
                    state <= S_TX_WAIT_BUSY; 
                end
                
                S_TX_WAIT_BUSY: begin
                    if (uart_tx_busy) state <= S_TX_WAIT_DONE;
                end

                S_TX_WAIT_DONE: begin
                    if (!uart_tx_busy) begin
                        uart_tx_start <= 0;
                        state <= S_TX_RESET;
                    end
                end
                
                S_TX_RESET: begin
                    state <= return_state;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule