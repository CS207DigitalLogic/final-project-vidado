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
    input  wire [CNT_WIDTH-1:0] qry_cnt         // 该规格矩阵的数量 (来自 storage 的 scale_matrix_cnt)
);

    // --- 状态定义 ---
    localparam S_IDLE           = 0;
    // 扫描阶段
    localparam S_SCAN_INIT      = 1;
    localparam S_SCAN_SET_ADDR  = 2;
    localparam S_SCAN_WAIT_MEM  = 3;
    localparam S_SCAN_READ      = 4;
    // 发送总数
    localparam S_SEND_TOTAL_HI  = 5;
    localparam S_SEND_TOTAL_LO  = 6;
    localparam S_SEND_SPACE_1   = 7;
    // 发送列表循环
    localparam S_LIST_CHECK     = 8;
    localparam S_SEND_R         = 9;
    localparam S_SEND_X1        = 10; // '*'
    localparam S_SEND_C         = 11;
    localparam S_SEND_X2        = 12; // '*'
    localparam S_SEND_CNT       = 13;
    localparam S_SEND_SPACE_2   = 14;
    localparam S_LIST_NEXT      = 15;
    // 结束
    localparam S_DONE           = 16;
    
    // UART 子任务状态
    localparam S_TX_START       = 20; // 拉高 start
    localparam S_TX_WAIT_BUSY   = 21; // 等待 busy 变高
    localparam S_TX_WAIT_DONE   = 22; // 等待 busy 变低
    localparam S_TX_RESET       = 23; // 拉低 start 并等待

    reg [4:0] state, next_state, return_state;
    
    // 内部寄存器
    reg [2:0] r_idx, c_idx;
    reg [CNT_WIDTH-1:0] stored_counts [0:24]; // 缓存 5x5 的计数结果
    reg [7:0] total_matrix_count;
    
    wire [4:0] flat_idx = (r_idx - 1) * 5 + (c_idx - 1);

    // --- 主状态机 ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            busy <= 0;
            uart_tx_start <= 0;
            uart_tx_data <= 0;
            qry_row <= 1;
            qry_col <= 1;
            total_matrix_count <= 0;
            r_idx <= 1;
            c_idx <= 1;
        end else begin
            case (state)
                S_IDLE: begin
                    busy <= 0;
                    if (start_req) begin
                        busy <= 1;
                        state <= S_SCAN_INIT;
                    end
                end

                // ===========================
                // 第一阶段：扫描所有规格并缓存
                // ===========================
                S_SCAN_INIT: begin
                    r_idx <= 1;
                    c_idx <= 1;
                    total_matrix_count <= 0;
                    state <= S_SCAN_SET_ADDR;
                end

                S_SCAN_SET_ADDR: begin
                    qry_row <= r_idx;
                    qry_col <= c_idx;
                    state <= S_SCAN_WAIT_MEM; 
                end
                
                S_SCAN_WAIT_MEM: begin
                    // 预留一拍给 Memory 读取 (即便 storage 是组合逻辑输出，加一拍更稳健)
                    state <= S_SCAN_READ;
                end

                S_SCAN_READ: begin
                    stored_counts[flat_idx] <= qry_cnt;
                    total_matrix_count <= total_matrix_count + qry_cnt;
                    
                    // 循环逻辑: 1,1 -> 1,2 ... -> 5,5
                    if (c_idx < MAX_SIZE) begin
                        c_idx <= c_idx + 1;
                        state <= S_SCAN_SET_ADDR;
                    end else if (r_idx < MAX_SIZE) begin
                        r_idx <= r_idx + 1;
                        c_idx <= 1;
                        state <= S_SCAN_SET_ADDR;
                    end else begin
                        // 扫描结束，准备发送
                        state <= S_SEND_TOTAL_HI;
                    end
                end

                // ===========================
                // 第二阶段：发送总数
                // ===========================
                S_SEND_TOTAL_HI: begin
                    if (total_matrix_count >= 10) begin
                        uart_tx_data <= 8'h30 + (total_matrix_count / 10);
                        return_state <= S_SEND_TOTAL_LO;
                        state <= S_TX_START;
                    end else begin
                        // 如果只有一位数，直接发个位
                        state <= S_SEND_TOTAL_LO; 
                    end
                end

                S_SEND_TOTAL_LO: begin
                    uart_tx_data <= 8'h30 + (total_matrix_count % 10);
                    return_state <= S_SEND_SPACE_1;
                    state <= S_TX_START;
                end

                S_SEND_SPACE_1: begin
                    uart_tx_data <= " ";
                    return_state <= S_LIST_CHECK;
                    state <= S_TX_START;
                    
                    // 重置索引用于遍历缓存
                    r_idx <= 1;
                    c_idx <= 1;
                end

                // ===========================
                // 第三阶段：发送规格列表
                // ===========================
                S_LIST_CHECK: begin
                    // 检查当前规格是否有矩阵
                    if (stored_counts[flat_idx] > 0) begin
                        state <= S_SEND_R;
                    end else begin
                        state <= S_LIST_NEXT;
                    end
                end

                S_SEND_R: begin // 发送行数
                    uart_tx_data <= 8'h30 + r_idx;
                    return_state <= S_SEND_X1;
                    state <= S_TX_START;
                end

                S_SEND_X1: begin // 发送 '*'
                    uart_tx_data <= "*";
                    return_state <= S_SEND_C;
                    state <= S_TX_START;
                end

                S_SEND_C: begin // 发送列数
                    uart_tx_data <= 8'h30 + c_idx;
                    return_state <= S_SEND_X2;
                    state <= S_TX_START;
                end
                
                S_SEND_X2: begin // 发送 '*'
                    uart_tx_data <= "*";
                    return_state <= S_SEND_CNT;
                    state <= S_TX_START;
                end

                S_SEND_CNT: begin // 发送该规格的数量 (假设<10)
                    uart_tx_data <= 8'h30 + stored_counts[flat_idx];
                    return_state <= S_SEND_SPACE_2;
                    state <= S_TX_START;
                end
                
                S_SEND_SPACE_2: begin // 发送尾部空格
                    uart_tx_data <= " ";
                    return_state <= S_LIST_NEXT;
                    state <= S_TX_START;
                end

                S_LIST_NEXT: begin
                    if (c_idx < MAX_SIZE) begin
                        c_idx <= c_idx + 1;
                        state <= S_LIST_CHECK;
                    end else if (r_idx < MAX_SIZE) begin
                        r_idx <= r_idx + 1;
                        c_idx <= 1;
                        state <= S_LIST_CHECK;
                    end else begin
                        state <= S_DONE;
                    end
                end
                
                S_DONE: begin
                    busy <= 0;
                    state <= S_IDLE;
                end

                // ===========================
                // UART 发送子程序 (适应 isCompleted 锁存)
                // ===========================
                S_TX_START: begin
                    uart_tx_start <= 1;
                    // 等待 busy 变高，说明 TX 模块已经响应了 start
                    // 为了防止速度过快，也可以直接跳等待
                    state <= S_TX_WAIT_BUSY; 
                end
                
                S_TX_WAIT_BUSY: begin
                    // 你的 uart_tx 是一检测到 start 就拉高 busy
                    if (uart_tx_busy) state <= S_TX_WAIT_DONE;
                end

                S_TX_WAIT_DONE: begin
                    // 等待传输完成
                    if (!uart_tx_busy) begin
                        uart_tx_start <= 0; // 拉低 start
                        state <= S_TX_RESET;
                    end
                end
                
                S_TX_RESET: begin
                    // 这是一个安全缓冲状态
                    // 确保 uart_tx 内部的 isCompleted 被 start=0 复位
                    state <= return_state; 
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule