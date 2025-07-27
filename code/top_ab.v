`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/27 11:32:13
// Design Name: 
// Module Name: top_ab
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


module top_ab(
    input 				sys_clk,
    input 				sys_rst_n,
	input		[2:0]	key,
    output 				ad_clk,
    input 		[9:0] 	ad_data,
    input 				ad_otr,
    output             	eth_txc   , //RGMII发送数据时钟    
    output             	eth_tx_ctl, //RGMII输出数据有效信号
    output      [3:0]  	eth_txd   , //RGMII输出数据          
    output             	eth_rst_n   //以太网芯片复位信号，低电平有效  
    );
	
wire 				rst_n;
wire				locked1;
wire				locked2;
wire				clk_125m;
wire				clk_1024k;
wire				clk_50m;
wire				clk_500m;
wire				clk_32m;
wire				clk_200m;
wire		[2:0]	key_value;

//开发板MAC地址 00-11-22-33-44-55
parameter  BOARD_MAC = 48'h00_11_22_33_44_55;     
//开发板IP地址 192.168.1.10
parameter  BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};  
//目的MAC地址 ff_ff_ff_ff_ff_ff
parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;    
//目的IP地址 192.168.1.102     
parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};  
//输入数据IO延时,此处为0,即不延时(如果为n,表示延时n*78ps) 
parameter IDELAY_VALUE = 0;

assign rst_n = locked1 & locked2 & sys_rst_n;
assign ad_clk = clk_1024k;
assign eth_rst_n = sys_rst_n;

clk_wiz_0 u_clk_wiz_0
   (
    // Clock out ports
    .clk_out1(clk_32m),     // output clk_out1
    .clk_out2(clk_500m),     // output clk_out2
    .clk_out3(clk_50m),     // output clk_out3
    .clk_out4(clk_125m),     // output clk_out4
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

wire [12:0] wr_data_count;	//写fifo计数
wire		wr_en;			//fifo写使能
wire		rd_en;			//fifo读使能
wire [7:0]	fifo_out;		//fifo读数据

wire 		gmii_tx_clk;	//GMII发送时钟
wire 		gmii_tx_en ;    //GMII发送数据使能信号
wire 		gmii_txd   ;    //GMII发送数据       
wire		udp_gmii_tx_en;	//GMII输出数据有效信号 
wire		udp_gmii_txd;   //GMII输出数据 
wire 		tx_start_en;	//以太网开始发送信号
wire [7:0]	udp_tx_data;    //以太网待发送数据  
wire [15:0]	tx_byte_num;    //以太网发送的有效字节数 单位:byte
wire		udp_tx_done;	//以太网发送完成信号
wire		udp_tx_req ;    //读数据请求信号    
	

//udp控制模块
udp_ctrl u_udp_ctrl(
	.clk_125m(clk_125m),
	.clk_1024k(clk_1024k),
	.clk_500m(clk_500m),
	.rst_n(rst_n),
	.wr_data_count(wr_data_count),	//写fifo计数
	.wr_en(wr_en),					//fifo写使能
	.rd_en(rd_en),		            //fifo读使能
	.fifo_out(fifo_out),            //fifo读数据
	.gmii_tx_en(gmii_tx_en),			//GMII发送数据使能信号
	.gmii_txd(gmii_txd),            //GMII发送数据       
	.udp_gmii_tx_en(udp_gmii_tx_en),      //GMII输出数据有效信号 
	.udp_gmii_txd(udp_gmii_txd),        //GMII输出数据 
	.tx_start_en(tx_start_en),         //以太网开始发送信号
	.udp_tx_data(udp_tx_data),         //以太网待发送数据  
	.tx_byte_num(tx_byte_num),         //以太网发送的有效字节数 单位:byte
	.udp_tx_done(udp_tx_done),	        //以太网发送完成信号
	.udp_tx_req(udp_tx_req)           //读数据请求信号    
	);

//FIFO，8192深度，8位宽度
fifo_8192x8 u_fifo_8192x8 (
  .rst(~rst_n),                      // input wire rst
  .wr_clk(clk_1024k),                // input wire wr_clk
  .rd_clk(clk_125m),                // input wire rd_clk
  .din(ad_data[9:2]),                      // input wire [7 : 0] din
  .wr_en(wr_en),                  // input wire wr_en
  .rd_en(rd_en),                  // input wire rd_en
  .dout(fifo_out),                    // output wire [7 : 0] dout
  .full(),                    // output wire full
  .empty(),                  // output wire empty
  .wr_data_count(wr_data_count),  // output wire [12 : 0] wr_data_count
  .wr_rst_busy(),      // output wire wr_rst_busy
  .rd_rst_busy()      // output wire rd_rst_busy
);

//GMII接口转RGMII接口
gmii_to_rgmii 
    #(
     .IDELAY_VALUE (IDELAY_VALUE)
     )
    u_gmii_to_rgmii(
    .idelay_clk    (clk_200m    ),//IDELAY时钟
	.clk_125m	   (clk_125m),

    .gmii_tx_clk   (gmii_tx_clk ),		//GMII发送时钟
    .gmii_tx_en    (gmii_tx_en  ),  //GMII发送数据使能信号
    .gmii_txd      (gmii_txd    ),  //GMII发送数据        
    
    .rgmii_txc     (eth_txc     ),	//RGMII发送时钟    
    .rgmii_tx_ctl  (eth_tx_ctl  ),  //RGMII发送数据控制信号
    .rgmii_txd     (eth_txd     )   //RGMII发送数据        
    );

//UDP通信
udp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
    )
   u_udp(
	.clk_125m	   (clk_125m),
    .rst_n         (rst_n   ),  
                     
    .gmii_tx_clk   (gmii_tx_clk ), 	//GMII发送数据时钟    
    .gmii_tx_en    (udp_gmii_tx_en),//GMII输出数据有效信号         
    .gmii_txd      (udp_gmii_txd),  //GMII输出数据 

    .tx_start_en   (tx_start_en ),   //以太网开始发送信号     
    .tx_data       (udp_tx_data ),   //以太网待发送数据        
    .tx_byte_num   (tx_byte_num ),   //以太网发送的有效字节数 单位:byte
    .des_mac       (DES_MAC     ),   //发送的目标MAC地址
    .des_ip        (DES_IP      ),   //发送的目标IP地址     
    .tx_done       (udp_tx_done ),   //以太网发送完成信号     
    .tx_req        (udp_tx_req  )    //读数据请求信号           
    ); 
	
endmodule
