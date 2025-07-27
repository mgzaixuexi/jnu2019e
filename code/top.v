module data_processing_fsm (
    input wire clk,                // 系统时钟
    input wire reset_n,            // 低电平复位
    input wire [15:0] ad_data,     // ADC输入数据
    input wire ad_data_valid,      // ADC数据有效标志
    input wire fft_done,           // FFT处理完成信号
    input wire udp_tx_ready,       // UDP发送就绪信号
    input wire fifo_not_full,      // FIFO非满信号
    
    output reg [1:0] state,        // 当前状态输出（调试用）
    output reg fft_start,          // FFT启动信号
    output reg fifo_wr_en,         // FIFO写使能
    output reg udp_tx_start,       // UDP发送启动
    output wire [15:0] fft_data_in // 输出到FFT的数据
);

// 状态定义
localparam STATE_IDLE   = 2'b00;
localparam STATE_FFT    = 2'b01;
localparam STATE_FIFO   = 2'b10;

// 内部信号
reg [31:0] sample_counter;        // 采样计数器
reg [15:0] frequency_result;      // 频率计算结果
reg fft_processing_done;          // FFT处理完成标志

// FFT数据输入直接连接ADC数据
assign fft_data_in = ad_data;

// 状态机主逻辑
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state <= STATE_IDLE;
        fft_start <= 1'b0;
        fifo_wr_en <= 1'b0;
        udp_tx_start <= 1'b0;
        sample_counter <= 32'd0;
        frequency_result <= 16'd0;
        fft_processing_done <= 1'b0;
    end else begin
        case (state)
            STATE_IDLE: begin
                // 等待有效数据到来
                if (ad_data_valid) begin
                    state <= STATE_FFT;
                    fft_start <= 1'b1;
                    sample_counter <= 32'd1;
                end
            end
            
            STATE_FFT: begin
                fft_start <= 1'b0;  // 单周期脉冲
                
                if (ad_data_valid) begin
                    sample_counter <= sample_counter + 1;
                end
                
                // 检测FFT处理完成
                if (fft_done) begin
                    fft_processing_done <= 1'b1;
                    // 这里应该从FFT模块读取频率结果
                    // frequency_result <= ...;
                    state <= STATE_FIFO;
                end
            end
            
            STATE_FIFO: begin
                fft_processing_done <= 1'b0;
                
                // 写入FIFO
                if (ad_data_valid && fifo_not_full) begin
                    fifo_wr_en <= 1'b1;
                end else begin
                    fifo_wr_en <= 1'b0;
                end
                
                // 当FIFO中有足够数据或特定条件时启动UDP发送
                if (/* UDP发送条件，例如FIFO半满或定时触发 */) begin
                    udp_tx_start <= 1'b1;
                end else begin
                    udp_tx_start <= 1'b0;
                end
                
                // 可以根据需要返回STATE_FFT进行新的频率分析
                if (/* 返回FFT状态的条件 */) begin
                    state <= STATE_FFT;
                    fft_start <= 1'b1;
                end
            end
            
            default: state <= STATE_IDLE;
        endcase
    end
end

endmodule