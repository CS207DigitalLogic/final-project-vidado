module matrix_info_display#(
    parameter MAX_SIZE = 5,
    parameter CNT_WIDTH = 5 // 足够容纳最大数量
)(
    input  wire                 clk,
    input  wire                 rst_n,
    
    // 控制接口
    input  wire                 start_req,      // 开始显示脉冲 (pulse)
    output reg                  busy,           // 模块忙信号
    
    // UART 发送接口
    input  wire                 uart_tx_busy,   // 来自 uart_tx 的忙信号
    output reg                  uart_tx_start,  // 发送请求
    output reg [7:0]            uart_tx_data,   // 发送数据
    
    // Multi_matrix_storage 查询接口
    output reg [2:0]            qry_row,        // 查询行
    output reg [2:0]            qry_col,        // 查询列
    input  wire [CNT_WIDTH-1:0] qry_cnt,        // 该规格矩阵的数量 (来自 storage 的 scale_matrix_cnt)

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
    localparam S_SCAN_WAIT_MEM  = 3; // 等待 storage 读数据
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
    localparam S_WAIT_RELEASE   = 14; // [新增] 等待启动信号释放
    
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
    wire [2:0] rng_out;          // 随机数生成器实时输出
    reg  [2:0] target_rand_val;  // 锁存的随机目标值 (1-5)
    reg  [2:0] rc;               // 遍历计数器 (Random Count)

    // [新增] 实例化随机数生成器 (1-5)
    random_num_generator #(
        .WIDTH(3) // 3位足够表示 1-5
    ) rng_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (1'b1),         // 使能一直开，保证随机性
        .min_val    (3'd1),         // 最小值 1
        .max_val    (3'd5),         // 最大值 5
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
            
            // [新增] 复位随机输出
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
                        state <= S_SCAN_INIT;
                        
                        // ===========================
                        // [新增] 遍历前赋值 1-5 随机数
                        // ===========================
                        target_rand_val <= rng_out; // 锁存当前的随机数
                        rc <= 1;                    // 计数器初始化为 1
                    end
                end
                // 第一阶段：扫描所有规格并缓存
                S_SCAN_INIT: begin
                    qry_row <= 1;
                    qry_col <= 1;
                    state <= S_SCAN_SET_ADDR;
                end

                S_SCAN_SET_ADDR: begin
                    state <= S_SCAN_WAIT_MEM;
                end

                S_SCAN_WAIT_MEM: begin
                    state <= S_SCAN_READ;
                end

                S_SCAN_READ: begin
                    // qry_cnt 是当前规格 (qry_row x qry_col) 的矩阵数量
                    if (qry_cnt > 0) begin
                        
                        // ===========================
                        // [新增] 随机选取核心逻辑
                        // ===========================
                        // 判断 randomcount 是否等于随机数
                        if (rc == target_rand_val) begin
                            // 若是，则将输出设为当前的行列和数量
                            random_r <= qry_row;
                            random_c <= qry_col;
                            random_cnt <= qry_cnt;
                        end 
                        
                        // 无论是否命中，rc 都 +1 (对应 "若为否 则rc+1")
                        rc <= rc + 1;
                        
                
                        // 准备发送行号
                        uart_tx_data <= qry_row + "0";
                        return_state <= S_SEND_X; // 下一步去发 'x'
                        state <= S_TX_START;      // 跳转到发送子程序
                    end else begin
                        // 数量为0，跳过
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
                     uart_tx_data <= ":"; // 或者 "="
                     return_state <= S_SEND_TOTAL_HI; 
                     state <= S_TX_START;
                end
                // 第二阶段：发送总数
               // --- 发送矩阵数量（十位或个位） ---
                S_SEND_TOTAL_HI: begin
                    if (qry_cnt > 9) begin
                        // 如果大于9，先发十位
                        uart_tx_data <= (qry_cnt / 10) + "0";
                        return_state <= S_SEND_TOTAL_LO; // 下一步去发个位
                    end else begin
                        // 如果小于等于9，直接发个位
                        uart_tx_data <= qry_cnt + "0";
                        return_state <= S_SEND_NL;       // 发完直接换行
                    end
                    state <= S_TX_START; // 触发发送
                end

                // --- 发送矩阵数量（个位，仅在 >9 时进入） ---
                S_SEND_TOTAL_LO: begin
                    uart_tx_data <= (qry_cnt % 10) + "0"; // 取余数发个位
                    return_state <= S_SEND_NL;            // 发完换行
                    state <= S_TX_START;                  // 触发发送
                end

                S_SEND_NL: begin
                    uart_tx_data <= 8'h0A; // 换行
                    return_state <= S_LIST_CHECK;
                    state <= S_TX_START;
                end

                S_LIST_CHECK: begin
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
                    // [修改] 任务结束时，检查 start_req 是否依然为高
                    if (start_req) begin
                        // 如果主机依然拉高启动信号，我们就去等待它变低
                        state <= S_WAIT_RELEASE;
                    end else begin
                        // 如果已经变低了，直接回 IDLE
                        state <= S_IDLE;
                    end
                end
                
                // [新增] 等待释放状态
                S_WAIT_RELEASE: begin
                    busy <= 0;
                    // 只有当 start_req 变回 0 后，才允许回到 IDLE 接受下一次触发
                    if (!start_req) begin
                        state <= S_IDLE;
                    end
                end

                // ===========================
                // UART 发送子程序 (保持原逻辑)
                // ===========================
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