module wave_freq (
    input wire clk,          // 50MHz 时钟
    input wire rst_n,        // 低电平复位
    input wire en,           // 使能信号（上升沿触发检测）
    input wire key,          // 按键（重置检测）
    input wire [15:0] rd_data, // FFT 取模幅频数据
    input wire [9:0] rd_addr,  // RAM 地址（对应频点 k）
    output reg [15:0] wave_freq, // 检测到的频率（单位 Hz，需×100）
    output reg freq_vaild    // 频率有效信号
);

// 内部状态和寄存器
reg [15:0] max_mag;          // 当前最大幅值
reg [9:0] max_index;         // 最大幅值对应的频点 k
reg en_prev;                 // 用于检测 en 的上升沿
reg search_done;             // 频率搜索完成标志

// 检测 en 的上升沿
wire en_rise = en && !en_prev;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位初始化
        en_prev <= 1'b0;
        max_mag <= 16'd0;
        max_index <= 10'd0;
        search_done <= 1'b0;
        wave_freq <= 16'd0;
        freq_vaild <= 1'b0;
    end else begin
        en_prev <= en;  // 记录 en 的前一状态

        // 按键重置检测过程
        if (key) begin
            max_mag <= 16'd0;
            max_index <= 10'd0;
            search_done <= 1'b0;
            freq_vaild <= 1'b0;
        end

        // 检测 en 上升沿，开始搜索频率
        else if (en_rise) begin
            max_mag <= 16'd0;     // 重置最大值
            max_index <= 10'd0;   // 重置频点
            search_done <= 1'b0;   // 重置完成标志
            freq_vaild <= 1'b0;    // 无效化输出
        end

        // 正在搜索频率（en=1）
        else if (en && !search_done) begin
            // 比较当前幅值 rd_data 和最大值 max_mag
            if (rd_data > max_mag) begin
                max_mag <= rd_data;      // 更新最大值
                max_index <= rd_addr;    // 更新频点
            end

            // 假设 FFT 数据是顺序读取的，当 rd_addr 遍历完成后结束搜索
            // 这里假设 rd_addr 从 0 递增到 N-1（N=1024）
            if (rd_addr == 10'd1023) begin
                search_done <= 1'b1;     // 搜索完成
                wave_freq <= max_index;  // 输出频率（k × 1kHz）
                freq_vaild <= 1'b1;      // 拉高有效信号
            end
        end
    end
end

endmodule