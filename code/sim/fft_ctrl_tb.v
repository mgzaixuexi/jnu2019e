`timescale 1ns / 1ps

module fft_ctrl_tb;

// 输入信号
reg          clk;          // 系统时钟（50MHz）
reg          clk_2560k;    // 
reg          clk_20M;
reg          clk_10M;    // 10.24M时钟
reg          rst_n;        // 异步复位，低电平有效
reg  [9:0]   ad_data;      // 输入的AD数据
reg          key;          // 控制按键

// 输出信号
wire [15:0]       wave_freq;    // 波形频率
wire         freq_vaild;   // 频率有效信号
// wire         fifo_wr_en;   // FIFO写使能
// wire [9:0]   fifo_data_in; // 写入FIFO的数据

// 时钟参数
localparam CLK_PERIOD = 20;      // 20ns
localparam CLK_2560K_PERIOD = 390; // 2560kHz时钟周期 ≈390ns (1/2560000 ≈390ns)
localparam CLK_20M_PERIOD = 50; // 20MHz时钟周期 
localparam CLK_10M_PERIOD = 98; // 10.24MHz时钟周期 
// 实例化被测模块
fft_ctrl uut (
    .clk_50m(clk),
    .fft_clk(clk_10M),
    .rst_n(rst_n),
    .ad_data(ad_data),
    .key(key),
    .wave_freq(wave_freq),
    .freq_vaild(freq_vaild)
);

// 生成系统时钟（8192kHz）
initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end
initial begin
    clk_2560k = 1'b0;
    forever #(CLK_2560K_PERIOD/2) clk_2560k = ~clk_2560k;
end
initial begin
    clk_20M = 1'b0;
    forever #(CLK_20M_PERIOD/2) clk_20M = ~clk_20M;
end
initial begin
    clk_10M = 1'b0;
    forever #(CLK_10M_PERIOD/2) clk_10M = ~clk_10M;
end

// 初始化与复位
initial begin
    rst_n = 0;
    key = 0;
    ad_data = 10'b0;
    
    // 复位释放
    #100;
    rst_n = 1;
    
    // 模拟按键按下（启动信号）
    #200;
    key = 1;
    #100;
    key = 0;
    
    // 等待频率检测完成
    wait(freq_vaild == 1);
    //$display("Frequency detected at time %t", $time);
    
    // 再次按下按键进入存储状态
    #500;
    key = 1;
    #100;
    key = 0;
    
    // 仿真运行时间
    #10000000;
    $finish;
end

// 模拟AD数据输入（正弦波）
integer i;
reg [15:0] mem [0:3999];

initial begin
    // 读取数据文件（示例使用正弦波数据）
    $readmemb("D:/vivado/project/ti/jnu2019e_test/code/sim/sine_wave_5kHz_unsigned.txt", mem);
    
    // 等待复位完成
    wait(rst_n == 1);
    #100;
    
    // // 在系统时钟下更新AD数据
    // forever begin
    //     @(posedge clk_20M);
    //     ad_data = mem[i][9:0];
    //     i = (i < 3999) ? i + 1 : 0;
    // end
    for (i = 0; i < 3999; ) begin
        @(posedge clk_20M);
        ad_data = mem[i][9:0];
        i <= (i<3998)?i + 1:0;
        
    end

end

endmodule