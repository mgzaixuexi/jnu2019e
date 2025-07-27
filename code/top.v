module ad_data_controller(
    input         clk,           // 系统时钟（8192kHz）
    input         clk_2560k,     // fft时钟
    input         rst_n,         // 异步复位，低电平有效
    
    input   [9:0] ad_data,       // 输入的AD数据
    input         key,           // 控制按键
    
    // FFT控制接口
    output        wave_freq,     // 波形频率
    output        freq_valid,    // 频率有效信号
    
    // FIFO接口
    output        fifo_wr_en,    // FIFO写使能
    output [9:0]  fifo_data_in   // 写入FIFO的数据
);

// 定义状态
parameter IDLE     = 2'b00;
parameter DETECT   = 2'b01;  // 状态1：频率检测
parameter STORE    = 2'b10;  // 状态2：数据存储

reg [1:0] current_state;
reg [1:0] next_state;

// FFT控制实例化
fft_ctrl fft_controller(
    .clk(clk),
    .clk_2560k(clk_2560k),
    .ad_data(ad_data),
    .key(key),
    .wave_freq(wave_freq),
    .freq_valid(freq_valid)
);

// 状态寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// 状态转移逻辑
always @(*) begin
    case (current_state)
        IDLE: begin
            if (key) begin
                next_state = DETECT;
            end else begin
                next_state = IDLE;
            end
        end
        
        DETECT: begin
            if (freq_valid) begin
                next_state = STORE;
            end else begin
                next_state = DETECT;
            end
        end
        
        STORE: begin
            if (!key) begin
                next_state = IDLE;
            end else begin
                next_state = STORE;
            end
        end
        
        default: next_state = IDLE;
    endcase
end

// 输出逻辑
assign fifo_wr_en = (current_state == STORE);
assign fifo_data_in = ad_data;

endmodule