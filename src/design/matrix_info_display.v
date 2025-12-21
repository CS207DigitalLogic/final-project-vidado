module matrix_info_display#(
    parameter MAX_SIZE = 5,
    parameter CNT_WIDTH = 5 // 足够容纳最大数量
)(
    input  wire                 clk,
    input  wire                 rst_n,
    
    // 控制接口
    input  wire                 start_req,      // 开始显示脉冲
    output reg                  busy,           // 模块忙信号
    
    // UART 发送接口
    input  wire                 uart_tx_busy,   // 来自 uart_tx 的忙信号
    output reg                  uart_tx_start,  // 发送请求
    output reg [7:0]            uart_tx_data,   // 发送数据
    
    // Multi_matrix_storage 查询接口
    output reg [2:0]            qry_row,        // 查询行
    output reg [2:0]            qry_col,        // 查询列
    input  wire [CNT_WIDTH-1:0] qry_cnt,        // 该规格矩阵的数量

    // ==========================================
    // [新增] 随机选择输出接口
    // ==========================================
    output reg [2:0]            random_r,       // 随机选中的行
    output reg [2:0]            random_c,       // 随机选中的列
    output reg [CNT_WIDTH-1:0]  random_cnt      // 随机选中的矩阵数量
);

    // --- 状态定义 ---
    localparam S_IDLE           = 0;
    localparam S_SCAN_INIT      = 1;
    localparam S_SCAN_SET_ADDR  = 2;
    localparam S_SCAN_WAIT_1    = 3; // [修改] 等待周期1
    localparam S_SCAN_WAIT_2    = 15; // [新增] 等待周期2 (确保时序绝对稳健)
    localparam S_SCAN_READ      = 4; // 读取并判断
    localparam S_SEND_TOTAL_HI  = 5;
    localparam S_SEND_TOTAL_LO  = 6;
    localparam S_SEND_ROW       = 7;
    localparam S_SEND_X         = 8;
    localparam S_SEND_COL       = 9;
    localparam S_SEND_EQ        = 10;
    localparam S_SEND_NL        = 11;
    localparam S_LIST_CHECK     = 12; // 检查循环
    localparam S_DONE           = 13;
    localparam S_WAIT_RELEASE   = 14; 
    
    // UART 发送子状态
    localparam S_TX_START       = 20;
    localparam S_TX_WAIT_BUSY   = 21;
    localparam S_TX_WAIT_DONE   = 22;
    localparam S_TX_RESET       = 23;

    reg [4:0] state;       // 主状态机
    reg [4:0] return_state; // 子程序返回状态

    // ==========================================
    // [新增] 随机数逻辑变量
    // ==========================================
    wire [7:0] rng_out_raw; // [修改] 原始随机数输出改为 8 位
    wire [2:0] rng_out;     // 最终我们只取需要的低3位（或者由 min/max 自动限制）       
    reg  [2:0] target_rand_val;  
    reg  [5:0] rc;               // [修改] 稍微加大位宽防止溢出，虽然5位够用

    // 随机数生成器 (保持不变)
    random_num_generator #(
        .WIDTH(8) 
    ) rng_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (1'b1),         
        .min_val    (8'd1),         
        .max_val    (8'd5),         
        .random_num (rng_out_raw)
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
            target_rand_val <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    busy <= 0;
                    if (start_req) begin
                        busy <= 1;
                        qry_row <= 1;
                        qry_col <= 1;
                        state <= S_SCAN_INIT;
                        
                        target_rand_val <= rng_out; 
                        rc <= 1;                    
                    end
                end

                S_SCAN_INIT: begin
                    qry_row <= 1;
                    qry_col <= 1;
                    state <= S_SCAN_SET_ADDR;
                end

                // 设置地址状态
                S_SCAN_SET_ADDR: begin
                    // 地址在上一状态或此状态已经稳定输出
                    state <= S_SCAN_WAIT_1;
                end

                // [重要修改] 增加两个等待周期，确保 storage 读取回来的数据绝对稳定
                S_SCAN_WAIT_1: begin
                    state <= S_SCAN_WAIT_2;
                end
                
                S_SCAN_WAIT_2: begin
                    state <= S_SCAN_READ;
                end

                S_SCAN_READ: begin
                    // 此时 qry_cnt 应该是稳定的
                    if (qry_cnt > 0) begin
                    // 随机数判断逻辑
                    if (rc == target_rand_val) begin
                        random_r <= qry_row;
                        random_c <= qry_col;
                        random_cnt <= qry_cnt;
                    end 
                    rc <= rc + 1;
                    
                    // 准备通过 UART 发送 "Row" 信息
                    uart_tx_data <= qry_row + "0";
                    return_state <= S_SEND_X; 
                    state <= S_TX_START;      
                    
                end else begin
                        // 如果数量为0，直接跳过所有发送步骤，去检查下一个
                        state <= S_LIST_CHECK;
                    end
                end

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

                // 发送数量高位
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

                // 发送数量低位
                S_SEND_TOTAL_LO: begin
                    uart_tx_data <= (qry_cnt % 10) + "0"; 
                    return_state <= S_SEND_NL;            
                    state <= S_TX_START;                  
                end

                S_SEND_NL: begin
                    uart_tx_data <= 8'h0A; // 换行
                    return_state <= S_LIST_CHECK;
                    state <= S_TX_START;
                end

                S_LIST_CHECK: begin
                    // 遍历逻辑：先列后行
                    if (qry_col < MAX_SIZE) begin
                        qry_col <= qry_col + 1;
                        state <= S_SCAN_SET_ADDR;
                    end else if (qry_row < MAX_SIZE) begin
                        qry_row <= qry_row + 1;
                        qry_col <= 1;
                        state <= S_SCAN_SET_ADDR;
                    end else begin
                        state <= S_DONE;
                    end
                end
                
                S_DONE: begin
                    busy <= 0;
                    if (start_req) begin
                        state <= S_WAIT_RELEASE;
                    end else begin
                        state <= S_IDLE;
                    end
                end
                
                S_WAIT_RELEASE: begin
                    busy <= 0;
                    if (!start_req) begin
                        state <= S_IDLE;
                    end
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