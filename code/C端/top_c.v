`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/27 14:34:25
// Design Name: 
// Module Name: top_c
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_c(
	input 				sys_clk,
	input 				sys_rst_n,
	input		[2:0]	key,
	output 				da_clk_a,
	output 		[9:0]	da_data_a,
	output 				da_clk_b,
	output 		[9:0]	da_data_b,
	input              	eth_rxc   , //RGMII接收数据时钟
    input              	eth_rx_ctl, //RGMII输入数据有效信号
    input       [3:0]  	eth_rxd   , //RGMII输入数据
    output             	eth_txc   , //RGMII发送数据时钟    
    output             	eth_tx_ctl, //RGMII输出数据有效信号
    output      [3:0]  	eth_txd   , //RGMII输出数据          
    output             	eth_rst_n,   //以太网芯片复位信号，低电平有效   
	output 		[4:0]	seg_sel,
	output		[7:0] 	seg_led
    );
	
wire 				rst_n;
wire				locked1;
wire				locked2;
wire				clk_1024k;
wire				clk_50m;
wire				clk_32m;
wire 				clk_200m;
wire		[2:0]	key_value;

//开发板MAC地址 00-11-22-33-44-55
parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
//开发板IP地址 192.168.1.10
parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};  
//A的MAC地址 ff_ff_ff_ff_ff_ff
parameter  DES_MAC_A  = 48'hff_ff_ff_ff_ff_ff;
//B的MAC地址 ff_ff_ff_ff_ff_ff  
parameter  DES_MAC_B  = 48'hff_ff_ff_ff_ff_dd;
//输入数据IO延时,此处为0,即不延时(如果为n,表示延时n*78ps) 
parameter IDELAY_VALUE = 0;

assign rst_n = sys_rst_n & locked2 & locked1;
assign da_clk_a = clk_1024k;
assign da_clk_b = clk_1024k;
assign eth_rst_n = sys_rst_n;


clk_wiz_0 u_clk_wiz_0
   (
    // Clock out ports
    .clk_out1(clk_32m),     // output clk_out1
    .clk_out2(clk_50m),     // output clk_out2
	.clk_out3(clk_200m),     // output clk_out3
    // Status and control signals
    .reset(~sys_rst_n), // input reset
    .locked(locked1),       // output locked
   // Clock in ports
    .clk_in1(sys_clk));      // input clk_in1
	
	
clk_wiz_1 u_clk_wiz_1
   (
    // Clock out ports
    .clk_out1(clk_1024k),     // output clk_out1
    // Status and control signals
    .reset(~sys_rst_n), // input reset
    .locked(locked2),       // output locked
   // Clock in ports
    .clk_in1(clk_32m));      // input clk_in1
	
// 按键防抖模块
key_debounce u_key_debounce(
    .clk(clk_50m),
    .rst_n(rst_n),
    .key(key),
    .key_value(key_value)
);


wire		gmii_rx_clk;
wire		gmii_rx_dv;
wire [7:0]	gmii_rxd;  
wire		rec_pkt_done;
wire		udp_rec_en;  
wire [7:0]	udp_rec_data;
wire [15:0]	rec_byte_num;
wire [1:0]	wave_source;	

assign eth_txc    = gmii_rx_clk;
assign eth_tx_ctl = 0;
assign eth_txd    = 0;

//GMII接口转RGMII接口
gmii_to_rgmii 
    #(
     .IDELAY_VALUE (IDELAY_VALUE)
     )
    u_gmii_to_rgmii(
    .idelay_clk    (clk_200m    ),	//IDELAY时钟
                                    
    .gmii_rx_clk   (gmii_rx_clk ),  //GMII接收时钟
    .gmii_rx_dv    (gmii_rx_dv  ),  //GMII接收数据有效信号
    .gmii_rxd      (gmii_rxd    ),  //GMII接收数据         
                                    
    .rgmii_rxc     (eth_rxc     ),  //RGMII接收时钟
    .rgmii_rx_ctl  (eth_rx_ctl  ),  //RGMII接收数据控制信号
    .rgmii_rxd     (eth_rxd     )   //RGMII接收数据        
    );

//UDP通信
udp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC_A     (DES_MAC_A  ),
    .DES_MAC_B     (DES_MAC_B  )
    )
   u_udp(
    .rst_n         (rst_n   	),  //复位信号，低电平有效
                                    
    .gmii_rx_clk   (gmii_rx_clk ),  //GMII接收数据时钟         
    .gmii_rx_dv    (gmii_rx_dv  ),  //GMII输入数据有效信号       
    .gmii_rxd      (gmii_rxd    ),  //GMII输入数据                 
                                    
    .rec_pkt_done  (rec_pkt_done),  //以太网单包数据接收完成信号  
    .rec_en        (udp_rec_en  ),  //以太网接收的数据使能信号   
    .rec_data      (udp_rec_data),  //以太网接收的数据       
    .rec_byte_num  (rec_byte_num),  //以太网接收的有效字节数 单位:byte   
	.wave_source   (wave_source	)	//接收源，01是A端，10是B端
    ); 
	
//FIFO_A端口
wire [12:0] wr_data_count_a;	//写fifo_a计数
wire		wr_en_a		;			//fifo_a写使能
wire		rd_en_a		;			//fifo_a读使能
wire [7:0]	fifo_in_a	;			//fifo_a写数据
wire [7:0]	fifo_out_a	;			//fifo_a读数据

//FIFO_B端口
wire [12:0] wr_data_count_b;	//写fifo_b计数
wire		wr_en_b;			//fifo_b写使能
wire		rd_en_b;			//fifo_b读使能
wire [7:0]	fifo_in_b;			//fifo_b写数据
wire [7:0]	fifo_out_b;			//fifo_b读数据
	
//FIFO_A，8192深度，8位宽度
fifo_8192x8 u_fifo_8192x8_A (
  .rst(~rst_n),                      // input wire rst
  .wr_clk(gmii_rx_clk),                // input wire wr_clk
  .rd_clk(clk_1024k),                // input wire rd_clk
  .din(fifo_in_a),                      // input wire [7 : 0] din
  .wr_en(wr_en_a),                  // input wire wr_en
  .rd_en(rd_en_a),                  // input wire rd_en
  .dout(fifo_out_a),                    // output wire [7 : 0] dout
  .full(),                    // output wire full
  .empty(),                  // output wire empty
  .wr_data_count(wr_data_count_a),  // output wire [12 : 0] wr_data_count
  .wr_rst_busy(),      // output wire wr_rst_busy
  .rd_rst_busy()      // output wire rd_rst_busy
);

//FIFO_B，8192深度，8位宽度
fifo_8192x8 u_fifo_8192x8_B (
  .rst(~rst_n),                      // input wire rst
  .wr_clk(gmii_rx_clk),                // input wire wr_clk
  .rd_clk(clk_1024k),                // input wire rd_clk
  .din(fifo_in_b),                      // input wire [7 : 0] din
  .wr_en(wr_en_b),                  // input wire wr_en
  .rd_en(rd_en_b),                  // input wire rd_en
  .dout(fifo_out_b),                    // output wire [7 : 0] dout
  .full(),                    // output wire full
  .empty(),                  // output wire empty
  .wr_data_count(wr_data_count_b),  // output wire [12 : 0] wr_data_count
  .wr_rst_busy(),      // output wire wr_rst_busy
  .rd_rst_busy()      // output wire rd_rst_busy
);
	
assign da_data_a = rd_en_a ? {fifo_out_a,2'b00} : 512;
assign da_data_b = rd_en_b ? {fifo_out_b,2'b00} : 512;	

wire [12:0] freq_a ;
wire [12:0] freq_b ;

da_ctrl u_da_ctrl(
	.clk			(gmii_rx_clk),
    .rst_n			(rst_n),
	
    .rec_pkt_done	(rec_pkt_done),	//以太网单包数据接收完成信号  
    .udp_rec_en		(udp_rec_en),        //以太网接收的数据使能信号   
    .udp_rec_data	(udp_rec_data),    //以太网接收的数据       
    .rec_byte_num	(rec_byte_num),    //以太网接收的有效字节数 单位:byte 
    .wave_source	(wave_source),      //接收源，01是A端，10是B端
	
	.wr_data_count_a(wr_data_count_a),
    .wr_en_a		(wr_en_a),				//fifo_a写使能
    .rd_en_a		(rd_en_a),              //fifo_a读使能
    .fifo_in_a		(fifo_in_a),          	//fifo_a写数据
	
	.wr_data_count_b(wr_data_count_b),
    .wr_en_b		(wr_en_b),				//fifo_b写使能
    .rd_en_b		(rd_en_b),                 //fifo_b读使能
    .fifo_in_b		(fifo_in_b),              //fifo_b写数据
	
    .freq_a			(freq_a),
    .freq_b			(freq_b)
);

seg_led u_seg_led(
    .sys_clk(clk_50m),
    .sys_rst_n(rst_n),
	.key(key_value[2]),
	.num1(freq_a),
	.num2(freq_b),
    .seg_sel(seg_sel),
    .seg_led(seg_led)
);
	
endmodule
