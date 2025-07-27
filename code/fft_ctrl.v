module fft_ctrl(
    input         clk_50m,           // 系统时钟�?50MHz�?
    input         fft_clk,       // fft时钟
    input         rst_n,  // 添加复位信号

    input   [9:0] ad_data,
    input         key,

    output  reg  [15:0]     wave_freq,
    output   reg  freq_vaild

);



// FFT输入接口（驱动信号改为reg�??
wire [15:0] fft_s_data_tdata;  // 输入数据（实部）
assign fft_s_data_tdata = {5'b0,ad_data};  
wire       fft_s_data_tvalid; // 数据有效
wire       fft_s_data_tlast;  // 数据结束标志

// FFT输出接口（保持为wire�??
wire       fft_s_data_tready; // FFT准备好接收数�??
wire [47:0] fft_m_data_tdata; // 频谱输出数据
wire        fft_m_data_tvalid;

// 配置接口
reg [7:0]  fft_s_config_tdata;
reg        fft_s_config_tvalid;
wire       fft_s_config_tready;

wire 		fft_shutdown;
wire		fft_valid;//fft重置信号



//虽然采样频率�?20.48M，但是FFT用低频，提高频率分辨率，8分频�?2.56M的话，频率分辨率为：2.56M/25600=200Hz�?
// FFT IP核实例化
xfft_0 u_fft(
    .aclk(fft_clk),
    .aresetn(fft_valid&rst_n),//fft重置信号
    .s_axis_config_tdata(8'd1),
    .s_axis_config_tvalid(1'b1),
    .s_axis_config_tready(fft_s_config_tready),  // 悬空
	
    .s_axis_data_tdata({16'h0000, fft_s_data_tdata}), // 虚部�??0，实部为输入数据
    .s_axis_data_tvalid(1'b1),//原版本完全没逻辑就放在这里了,我不如置1
    .s_axis_data_tready(fft_s_data_tready),
    .s_axis_data_tlast(fft_s_data_tlast),
	
    .m_axis_data_tdata(fft_m_data_tdata),
    //.m_axis_data_tuser(),
    .m_axis_data_tvalid(fft_m_data_tvalid),
    .m_axis_data_tready(1'b1), // 假设从设备始终准备好接收
    .m_axis_data_tlast(),

    //.m_axis_status_tdata(),                  // output wire [7 : 0] m_axis_status_tdata
    //.m_axis_status_tvalid(),                // output wire m_axis_status_tvalid
    //.m_axis_status_tready(1'b0),                // input wire m_axis_status_tready	
    // 其他事件信号悬空
    .event_frame_started(),
    .event_tlast_unexpected(),
    .event_tlast_missing(),
    .event_status_channel_halt(),
    .event_data_in_channel_halt(),
    .event_data_out_channel_halt()
);


wire [15:0] data_modulus;
wire [15:0] wr_data;
wire [11:0] wr_addr;
wire wr_en;
wire wr_done;
wire data_valid;
// 实部fft_m_data_tdata[15:0],   是否为有符号数仍�??进一步验�??
// 虚部fft_m_data_tdata[31:16]); 
//eop信号都是不要的，全部悬空
data_modulus u_data_modulus(
	.clk(clk_50m),
	.rst_n(rst_n),
	//.key(key_value[0]),                       //键控重置，就是题目里的启动键，不是复�??
	//FFT ST接口 
    .source_real(fft_m_data_tdata[15:0]),   //实部 有符号数 
    .source_imag(fft_m_data_tdata[31:16]),   //虚部 有符号数 
	.source_eop(),
    .source_valid(fft_m_data_tvalid),  //输出有效信号，FFT变换完成后，此信号置�?? 
	.data_modulus(data_modulus),  // 取模结果
	.data_eop(),      // 结果帧结�??
	.data_valid(data_valid)     // 结果有效信号
);
						

// 内部状�?�和寄存�?
reg [15:0] max_mag;          // 当前�?大幅�?
reg [12:0] max_index;         // �?大幅值对应的频点 k,乘上1250.
reg [12:0] fft_index;



always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        // 复位初始�?
        max_mag <= 16'd0;
        max_index <= 10'd0;
        freq_vaild <= 1'b0;
        wave_freq <= 16'd0;
    end else begin
        // 按键重置�?测过�?
        if (key) begin
            max_mag <= 16'd0;
            max_index <= 10'd0;
            freq_vaild <= 1'b0;
        end
        else if(fft_index==12'd8191) begin
            freq_vaild <= 1'b1;   // 重置完成标志
            wave_freq <= {max_index,3'd0};           
        end
        // �?�? en 上升沿，�?始搜索频�?
        else if (data_valid) begin
            fft_index <= fft_index + 1;            
            max_mag <= data_modulus?(data_modulus>max_mag):max_mag;     // 重置�?大�??
            max_index <= fft_index?(data_modulus>max_mag):max_index;   // 频点
            freq_vaild <= 1'b0;   // 重置完成标志
        end
    end
end


endmodule