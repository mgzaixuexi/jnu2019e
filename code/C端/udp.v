//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           udp
// Last modified Date:  2020/2/18 9:20:14
// Last Version:        V1.0
// Descriptions:        udp模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/18 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module udp(
    input                rst_n       , //复位信号，低电平有效
    //GMII接口
    input                gmii_rx_clk , //GMII接收数据时钟
    input                gmii_rx_dv  , //GMII输入数据有效信号
    input        [7:0]   gmii_rxd    , //GMII输入数据
    //用户接口
    output               rec_pkt_done, //以太网单包数据接收完成信号
    output               rec_en      , //以太网接收的数据使能信号
    output       [ 7:0]  rec_data    , //以太网接收的数据
    output       [15:0]  rec_byte_num, //以太网接收的有效字节数 单位:byte
	output		 [1:0]	 wave_source 	//接收源，01是A端，10是B端
    );

//parameter define
//开发板MAC地址 00-11-22-33-44-55
parameter BOARD_MAC = 48'h00_11_22_33_44_55;    
//开发板IP地址 192.168.1.10     
parameter BOARD_IP  = {8'd192,8'd168,8'd1,8'd10};
//A的MAC地址 ff_ff_ff_ff_ff_ff
parameter  DES_MAC_A  = 48'hff_ff_ff_ff_ff_ff;
//B的MAC地址 ff_ff_ff_ff_ff_ff  
parameter  DES_MAC_B  = 48'hff_ff_ff_ff_ff_ff;

//*****************************************************
//**                    main code
//*****************************************************

//以太网接收模块    
udp_rx 
   #(
    .BOARD_MAC       (BOARD_MAC),         //参数例化
    .BOARD_IP        (BOARD_IP ),
	.DES_MAC_A		 (DES_MAC_A),
	.DES_MAC_B		 (DES_MAC_B)
    )
   u_udp_rx(
    .clk             (gmii_rx_clk ),        
    .rst_n           (rst_n       ),             
    .gmii_rx_dv      (gmii_rx_dv  ),                                 
    .gmii_rxd        (gmii_rxd    ),       
    .rec_pkt_done    (rec_pkt_done),      
    .rec_en          (rec_en      ),            
    .rec_data        (rec_data    ),          
    .rec_byte_num    (rec_byte_num),
	.wave_source	 (wave_source )
    );                                    

endmodule