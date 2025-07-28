`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/27 15:51:16
// Design Name: 
// Module Name: da_ctrl
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


module da_ctrl(
	input				clk			,
	input				rst_n		,	
					                
	input				rec_pkt_done,	//��̫���������ݽ�������ź�  
	input				udp_rec_en	,	     //��̫�����յ�����ʹ���ź�   
	input	    [7:0]	udp_rec_data,	   //��̫�����յ�����       
	input	    [15:0]	rec_byte_num,	   //��̫�����յ���Ч�ֽ��� ��λ:byte
    input	    [1:0]	wave_source	,       //����Դ��01��A�ˣ�10��B��
	
    input		[12:0]	wr_data_count_a	,   
    output 	reg			wr_en_a		,   		//fifo_aдʹ��
    output 	reg			rd_en_a		,           //fifo_a��ʹ��
    output  reg	[7:0]   fifo_in_a	,	      	//fifo_aд����
	
    input		[12:0]	wr_data_count_b	,                                         
    output 	reg	      	wr_en_b		,   		//fifo_bдʹ��
    output 	reg	      	rd_en_b		,              //fifo_b��ʹ��
    output 	reg	[7:0]   fifo_in_b	,	          //fifo_bд����
	
	output reg [12:0]	freq_a		,
	output reg [12:0]	freq_b		
    );
	
reg 		a_flag 	;	//�˿�A�������Ƶ�ʱ�־λ
reg 		b_flag 	; 	//�˿�B�������Ƶ�ʱ�־λ
reg [15:0]	freq   	;
reg [10:0]	rec_cnt	;	
	
//�������Ƶ�ʱ�־λ
always @(posedge clk or negedge rst_n)
	if(~rst_n)begin
		a_flag <= 0;
	    b_flag <= 0;
		end
	else if((rec_pkt_done) & (~a_flag))
		a_flag <= 1;
	else if((rec_pkt_done) & (~b_flag))
		b_flag <= 1;
	else begin
		a_flag <= a_flag ;
		b_flag <= b_flag ;
		end
		
//fifo_a��ʹ�ܿ���
always @(posedge clk or negedge rst_n)
	if(~rst_n)
		rd_en_a <= 0;
	else if(wr_data_count_a >=10)
		rd_en_a <= 1;
	else 
		rd_en_a <= 0;
		
//fifo_b��ʹ�ܿ���
always @(posedge clk or negedge rst_n)
	if(~rst_n)
		rd_en_b <= 0;
	else if(wr_data_count_a >=10)
		rd_en_b <= 1;
	else 
		rd_en_b <= 0;
		
//fifo_a��fifo_bд����ƣ��Լ����ջ���Ƶ�ʺͼ���
always @(posedge clk or negedge rst_n)
	if(~rst_n)begin
		freq_a 	<= 0;
	    freq_b 	<= 0;
		freq 	<= 0;
		rec_cnt <= 0;
		wr_en_a		<= 0;
		fifo_in_a   <= 0;
		wr_en_b		<= 0;
		fifo_in_b   <= 0;
		end
	else if(udp_rec_en)begin
		rec_cnt <= rec_cnt + 1;
		case(wave_source)
			2'b01:	if(~a_flag)
						if(rec_cnt < 11'd2)
							freq <= {freq[7:0],udp_rec_data};
						else
							freq_a <= (freq<<2)/5;
					else if(a_flag)begin
						wr_en_a <= 1;
						fifo_in_a <= udp_rec_data;
						end
					else begin
						wr_en_a <= wr_en_a;
						fifo_in_a <= fifo_in_a;
						freq_a <= freq_a;
						freq <= freq;
						end
			2'b10:	if(~b_flag)
			        	if(rec_cnt < 11'd2)
			        		freq <= {freq[7:0],udp_rec_data};
			        	else
			        		freq_b <= (freq<<2)/5;
					else if(a_flag)begin
						wr_en_b <= 1;
						fifo_in_b <= udp_rec_data;
						end
			        else begin
						wr_en_b <= wr_en_b;
						fifo_in_b <= fifo_in_b;
			        	freq_b <= freq_b;
			        	freq <= freq;
			        	end
			default:begin	
					wr_en_a <= wr_en_a;
			        fifo_in_a <= fifo_in_a;
					wr_en_b <= wr_en_b;
					fifo_in_b <= fifo_in_b;
			        freq_a <= freq_a;
			        freq_b <= freq_b;
			        freq <= freq;
			        end			
		endcase
		end
	else begin
		rec_cnt <= 0;
		wr_en_a <= wr_en_a;
		fifo_in_a <= fifo_in_a;
		wr_en_b <= wr_en_b;
		wr_en_b <= wr_en_b;
		fifo_in_b <= fifo_in_b;
		freq_a <= freq_a;
		freq_b <= freq_b;
		freq <= freq;
		end
	
endmodule
