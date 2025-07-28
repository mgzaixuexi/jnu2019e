//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//�?术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料�?
//版权�?有，盗版必究�?
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           eth_ctrl
// Last modified Date:  2020/2/18 9:20:14
// Last Version:        V1.0
// Descriptions:        以太网控制模�?
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/18 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module udp_ctrl(
    input              clk_125m       		,    //时钟
	input              clk_10240k       		,    //时钟
	input              clk_500m       		,    //时钟
    input              rst_n     		,    //系统复位信号，低电平有效 
    //FIFO相关端口信号                                   
	input 			   wr_data_count,	//写fifo计数
	output 			   wr_en,					//fifo写使�?
	output 		reg	   rd_en,		            //fifo读使�?
	input 			   fifo_out,            //fifo读数�?

    //GMII发�?�引�?                  	   
    output reg         gmii_tx_en		,    //GMII输出数据有效信号 
    output reg [7:0]   gmii_txd        	, 	 //GMII输出数据 

    //UDP相关端口信号
    output              tx_start_en  ,	 //UDP�?始发送信�?
    input              udp_tx_done      ,	 //UDP发�?�完成信�?
    input              udp_gmii_tx_en   ,	 //UDP GMII输出数据有效信号  
    input     [7:0]    udp_gmii_txd     ,	 //UDP GMII输出数据   
	//UDP fifo接口信号
	input			   udp_tx_req		,  	 //UDP读数据请求信�?
	output	 reg  [7:0]   udp_tx_data		,  	 //UDP待发送数�?
	output	 reg  [15:0]  tx_byte_num		,	//以太网发送的有效字节�? 单位:byte

	input	   [15:0]  wave_freq		,
	input			   freq_valid		,
	output		reg	   state_change
    );


//*****************************************************
//**                    main code
//*****************************************************

//状�?�定�?
localparam IDLE      = 3'd0;
localparam FREQ_SEND   = 3'd1;
localparam FIFO_SEND   = 3'd2;
reg [2:0] state;
//协议的切�?
always @(posedge clk_125m or negedge rst_n) begin
    if(!rst_n) begin
		gmii_tx_en <= 1'd0;
		gmii_txd   <= 8'd0;
	end
	else begin
		gmii_tx_en <= udp_gmii_tx_en;
		gmii_txd   <= udp_gmii_txd  ;		
	end
end	
reg freq_valid_d0;//传前八位
reg freq_valid_d1;//传后八位�?
reg freq_valid_d2;//
assign	wr_en = freq_valid_d2 ? 1'b1:1'b0;
reg [15:0] fifo_count;
//assign	rd_en = freq_valid_d2 ? 1'b1:1'b0;					
//发�?�状态机
always @(posedge clk_125m or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
		udp_tx_data <= 0;
		tx_byte_num <= 0;
		rd_en <= 0;
		freq_valid_d0<=0;
		freq_valid_d1<=0;
		freq_valid_d2<=0;
		state_change <= 0;
    end
    else begin
        case(state)
            IDLE: begin
				udp_tx_data <= 0;
				tx_byte_num <= 0;
				rd_en <= 0;
				state_change <= 0;
                if(freq_valid) begin
                    state <= FREQ_SEND;
					freq_valid_d0<=1'd1;
					tx_byte_num<=16'd2;
                end
            end
			FREQ_SEND:begin
				udp_tx_data <= freq_valid_d1?wave_freq[15:8]:wave_freq[7:0];
				freq_valid_d1<=freq_valid_d0;
				freq_valid_d2<=freq_valid_d1;
				if(freq_valid_d1)begin
					tx_byte_num <= 16'd1024;//瞎写�?
				end
			end
			FIFO_SEND:begin
				udp_tx_data <= fifo_out;
				// if((wr_data_count>fifo_count)?(wr_data_count - fifo_count> 16'd1024):(wr_data_count + 16'd8192 - fifo_count> 16'd1024))begin
				// 	rd_en <= 1'b1;
				// end
				// else if((wr_data_count>fifo_count)?(wr_data_count - fifo_count < 10):((wr_data_count + 16'd8192 - fifo_count < 10)))begin
				// 	rd_en <= 1'b0;
				// end
				// if(rd_en == 1'b1)begin
				// 	fifo_count = fifo_count + 1'b1;
				// end
				if(wr_data_count>15'd2000)begin
					state_change <= 1'b1;
				end
				else if(udp_tx_done == 1'b1)begin
					state_change <= 1'b0;
				end
				else begin
					state_change <= state_change;
				end

				if(udp_tx_req == 1'b1 )begin
					rd_en <= 1'b1;
				end
				else begin
					rd_en <= 1'b0;
				end
			end
		endcase
	end
end
assign tx_start_en = rd_en;



endmodule