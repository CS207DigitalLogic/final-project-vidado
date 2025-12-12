`timescale 1ns/1ps

module tb_matrix_system;

    // ---------------------------------------------------------
    // 1. 参数定义
    // ---------------------------------------------------------
    // 为了加快仿真速度，我们使用 10MHz 的波特率（实际硬件用115200）
    parameter CLK_FREQ  = 100_000_000; // 100MHz
    parameter BAUD_RATE = 10_000_000;  // 仿真专用高速波特率
    
    // 计算比特周期 (ns) 用于 UART 解码
    localparam BIT_PERIOD_NS = 1_000_000_000 / BAUD_RATE;

    // ---------------------------------------------------------
    // 2. 信号声明
    // ---------------------------------------------------------
    reg clk;
    reg rst_n;
    
    // 写入接口
    reg matrix_wr_en;
    reg [2:0] matrix_idx;      // 假设 MATRIX_IDX_W=3 (8个矩阵)
    reg [2:0] store_row;
    reg [2:0] store_col;
    reg [5:0] wr_addr_in;      // 假设 ADDR_IN_W=6 (最大32-64个元素)
    reg [7:0] matrix_wr_data;
    
    // 遍历控制
    reg traverse_trig;         // 手动单次触发
    reg all_traverse_trig;     // 全部遍历触发 (按键)
    reg [2:0] traverse_row;
    reg [2:0] traverse_col;
    
    // 输出观测
    wire traverse_busy;
    wire traverse_done;
    wire uart_tx;

    // ---------------------------------------------------------
    // 3. 待测模块实例化 (DUT)
    // ---------------------------------------------------------
    test_matrix_storage #(
        .DATA_WIDTH(8),
        .MAX_SIZE(5),
        .MATRIX_NUM(8),
        .MAX_MATRIX_PER_SIZE(4),
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE) // 覆盖参数以加速仿真
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .matrix_wr_en(matrix_wr_en),
        .matrix_idx(matrix_idx),
        .store_row(store_row),
        .store_col(store_col),
        .wr_addr_in(wr_addr_in),
        .matrix_wr_data(matrix_wr_data),
        .traverse_trig(traverse_trig),
        .all_traverse_trig(all_traverse_trig), // 连接上一轮新增的接口
        .traverse_row(traverse_row),
        .traverse_col(traverse_col),
        .traverse_busy(traverse_busy),
        .traverse_done(traverse_done),
        .uart_tx(uart_tx)
    );

    // ---------------------------------------------------------
    // 4. 时钟生成
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz (周期10ns)
    end

    // ---------------------------------------------------------
    // 5. UART 软件解码器 (用于在仿真控制台打印输出)
    // ---------------------------------------------------------
    reg [7:0] rx_byte;
    integer i;
    
    initial begin
        $display("\n--- UART Monitor Started (Baud: %0d) ---\n", BAUD_RATE);
        forever begin
            // 1. 等待起始位 (下降沿)
            @(negedge uart_tx);
            
            // 2. 等待半个 bit 周期，定位到起始位中间
            #(BIT_PERIOD_NS / 2);
            
            // 3. 再次确认是否为低电平 (抗干扰，虽然仿真里不需要)
            if (uart_tx == 0) begin
                // 4. 延迟 1 个 bit 周期进入数据位 LSb
                #(BIT_PERIOD_NS);
                
                // 5. 接收 8 bits
                for (i = 0; i < 8; i = i + 1) begin
                    rx_byte[i] = uart_tx;
                    #(BIT_PERIOD_NS);
                end
                
                // 6. 打印字符 (处理换行符以便显示整洁)
                if (rx_byte == 8'h0A) 
                    $write("\n"); // 换行
                else 
                    $write("%c", rx_byte); // 打印 ASCII 字符
            end
        end
    end

    // ---------------------------------------------------------
    // 6. 辅助任务：写入矩阵
    // ---------------------------------------------------------
    task write_matrix;
        input [2:0] idx;
        input [2:0] r;
        input [2:0] c;
        input [7:0] start_val;
        integer k;
        begin
            $display("Writing Matrix[%0d]: Size %0dx%0d", idx, r, c);
            @(posedge clk);
            matrix_wr_en = 1;
            matrix_idx = idx;
            store_row = r;
            store_col = c;
            
            // 写入所有元素
            for (k = 0; k < r*c; k = k + 1) begin
                wr_addr_in = k;
                matrix_wr_data = start_val + k;
                @(posedge clk); 
            end
            
            matrix_wr_en = 0;
            @(posedge clk);
        end
    endtask

    // ---------------------------------------------------------
    // 7. 主测试流程
    // ---------------------------------------------------------
    initial begin
        // --- 初始化 ---
        rst_n = 0;
        matrix_wr_en = 0;
        traverse_trig = 0;
        all_traverse_trig = 0;
        traverse_row = 0;
        traverse_col = 0;
        matrix_idx = 0;
        wr_addr_in = 0;
        matrix_wr_data = 0;
        store_row = 0;
        store_col = 0;

        #200;
        rst_n = 1;
        #200;

        $display("==================================================");
        $display("Test 1: Manual Trigger (Check Pre-loaded Data)");
        $display("Expect: Output of 2x3 matrices (stored at reset)");
        $display("==================================================");

        [cite_start]// 手动触发读取 2x3 矩阵 (根据底层代码[cite: 232], 复位后预存了3个2x3矩阵)
        @(posedge clk);
        traverse_row = 3'd2;
        traverse_col = 3'd3;
        traverse_trig = 1;
        @(posedge clk);
        traverse_trig = 0;

        // 等待直到 busy 信号拉高再拉低
        wait(traverse_busy);
        wait(!traverse_busy);
        #1000;

        $display("\n==================================================");
        $display("Test 2: Write New Matrix (2x2)");
        $display("==================================================");
        
        // 在索引 4 的位置写入一个 2x2 矩阵 (前4个位置0-3已被预存占用)
        // 数据从 0xA0 开始
        write_matrix(3'd4, 3'd2, 3'd2, 8'hA0);
        #100;

        $display("==================================================");
        $display("Test 3: ALL TRAVERSE TRIGGER (Button Press)");
        $display("Expect: 2x2 (new), then 2x3 (pre-loaded), then 3x4 (pre-loaded)");
        $display("Note: Order depends on size iteration (1x1 -> 5x5)");
        $display("==================================================");

        // 模拟按下按键
        @(posedge clk);
        all_traverse_trig = 1;
        #100; // 按住一段时间
        all_traverse_trig = 0;

        // 等待整个过程完成
        // 由于是自动连续触发，我们简单的等待足够长的时间，或者监测 busy
        // 注意：all_traverse 状态机在不同规模切换间隙 busy 可能会短暂变低
        
        // 简单策略：等待直到状态机回到 IDLE 且不再 Busy
        // 在这里我们等待较长时间观察输出即可
        #200000; 

        $display("\n==================================================");
        $display("Test Finished.");
        $display("==================================================");
        $stop;
    end

endmodule