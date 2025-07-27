module fft_ctrl(
    input         clk,           // 系统时钟（8192kHz）
    input         clk_2560k,       // fft时钟

    input   [9:0] ad_data,
    input         key,

    output        wave_freq,
    output        freq_vaild

);


reg key_d0;
reg key_d1;

wire start;

assign start = ~key_d0 & key_d1 ;//下降沿检测

always @(posedge clk or negedge  rst_n)begin
	if(~rst_n)begin
		key_d0 <= 1;
		key_d1 <= 1;
	end
	else begin
		key_d0 <= key;
		key_d1 <= key_d0;
	end
end

always @(posedge clk or negedge rst_n)begin
	if(~rst_n)
		fft_valid <= 0;
	else if(start)//按键按下，启动fft
		fft_valid <= 1;
	else if(fft_shutdown)
		fft_valid <= 0;//ram写入完成，重置fft
	else 
		fft_valid <= fft_valid;
end

// FFT输入接口（驱动信号改为reg�?
wire [15:0] fft_s_data_tdata;  // 输入数据（实部）
assign fft_s_data_tdata = {5'b0,ad_data};  
wire       fft_s_data_tvalid; // 数据有效
wire       fft_s_data_tlast;  // 数据结束标志

// FFT输出接口（保持为wire�?
wire       fft_s_data_tready; // FFT准备好接收数�?
wire [47:0] fft_m_data_tdata; // 频谱输出数据
wire        fft_m_data_tvalid;

// 配置接口
reg [7:0]  fft_s_config_tdata;
reg        fft_s_config_tvalid;
wire       fft_s_config_tready;

wire 		fft_shutdown;
wire		fft_valid;//fft重置信号



//虽然采样频率为20.48M，但是FFT用低频，提高频率分辨率，8分频为2.56M的话，频率分辨率为：2.56M/25600=200Hz。
// FFT IP核实例化
xfft_0 u_fft(
    .aclk(clk_2560k),
    .aresetn(fft_valid&rst_n),//fft重置信号
    .s_axis_config_tdata(8'd1),
    .s_axis_config_tvalid(1'b1),
    .s_axis_config_tready(fft_s_config_tready),  // 悬空
	
    .s_axis_data_tdata({16'h0000, fft_s_data_tdata}), // 虚部�?0，实部为输入数据
    .s_axis_data_tvalid(1'b1),//原版本完全没逻辑就放在这里了,我不如置1
    .s_axis_data_tready(fft_s_data_tready),
    .s_axis_data_tlast(fft_s_data_tlast),
	
    .m_axis_data_tdata(fft_m_data_tdata),
    .m_axis_data_tuser(),
    .m_axis_data_tvalid(fft_m_data_tvalid),
    .m_axis_data_tready(1'b1), // 假设从设备始终准备好接收
    .m_axis_data_tlast(),

    .m_axis_status_tdata(),                  // output wire [7 : 0] m_axis_status_tdata
    .m_axis_status_tvalid(),                // output wire m_axis_status_tvalid
    .m_axis_status_tready(1'b0),                // input wire m_axis_status_tready	
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

// 实部fft_m_data_tdata[15:0],   是否为有符号数仍�?进一步验�?
// 虚部fft_m_data_tdata[31:16]); 
//eop信号都是不要的，全部悬空
data_modulus u_data_modulus(
	.clk(clk_50m),
	.rst_n(rst_n),
	//.key(key_value[0]),                       //键控重置，就是题目里的启动键，不是复�?
	//FFT ST接口 
    .source_real(fft_m_data_tdata[15:0]),   //实部 有符号数 
    .source_imag(fft_m_data_tdata[31:16]),   //虚部 有符号数 
	.source_eop(),
    .source_valid(fft_m_data_tvalid),  //输出有效信号，FFT变换完成后，此信号置�? 
	.data_modulus(data_modulus),  // 取模结果
	.data_eop(),      // 结果帧结�?
	.data_valid(data_valid)     // 结果有效信号
 	.fft_en(fft_en)		 //fft的使能，接到数据有效或�?�时钟有效都�?
    //取模运算后的数据接口 
    .data_modulus(data_modulus),  //取模后的数据 
	.wr_addr(wr_addr),	 //写ram地址
	.wr_en(wr_en),		 //写使�?	
	.wr_done(wr_done)		 //分离模块使能 
);
						
ram_wr_ctrl u_ram_wr_ctrl(
	.clk(clk_2560k),//fft时钟
	.rst_n(rst_n & key_value[0]),//复位，接（rst_n&key）key是启动键
	.data_modulus(data_modulus),    
    .data_valid(data_valid),
	.wr_data(wr_data),
	.wr_addr(wr_addr),
	.wr_en(wr_en),
	.wr_done(wr_done),
	.fft_shutdown(fft_shutdown)//关闭fft，高有效
);


wire [11:0] rd_addr;
wire [15:0] rd_data;
wire wave_vaild;

ram_25600x16 u_ram_25600x16 (
  .clka(clk_2560k),    // fft时钟
  .wea(wr_en),      // input wire [0 : 0] wea
  .addra(wr_addr),  // input wire [11 : 0] addra
  .dina(wr_data),    // input wire [15 : 0] dina
  .clkb(clk_50m),    // 分离模块时钟
  .addrb(rd_addr),  // input wire [11 : 0] addrb
  .doutb(rd_data)  // output wire [15 : 0] doutb
);

wave_freq u_wave_freq
	(
    .clk(clk_50m),
    .rst_n(rst_n),
    .en(wr_done),//使能，上升沿有效，fft取模数据写入ram完成再拉�?
	.key(key_value[0]),//启动按键，重置识�?
    .rd_data(rd_data),//fft取模数据
    .rd_addr(rd_addr),//ram地址
    .wave_freq(wave_freq),//波A频率，要乘100
    .freq_vaild(freq_vaild)//数据有效信号，高有效
    );




endmodule