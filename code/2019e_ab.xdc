#------------------------------系统时钟和复位-----------------------------------
create_clock -period 20.000 -name sys_clk [get_ports sys_clk]

set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports sys_clk]
 
set_property -dict {PACKAGE_PIN AD19 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

set_property -dict {PACKAGE_PIN AF20 IOSTANDARD LVCMOS33} [get_ports key[0]]
set_property -dict {PACKAGE_PIN AE20 IOSTANDARD LVCMOS33} [get_ports key[1]]
set_property -dict {PACKAGE_PIN AE21 IOSTANDARD LVCMOS33} [get_ports key[2]]

set_property -dict {PACKAGE_PIN W14  IOSTANDARD LVCMOS33} [get_ports seg_sel[0]]
set_property -dict {PACKAGE_PIN W15  IOSTANDARD LVCMOS33} [get_ports seg_sel[1]]
set_property -dict {PACKAGE_PIN Y15  IOSTANDARD LVCMOS33} [get_ports seg_sel[2]]
set_property -dict {PACKAGE_PIN AC16 IOSTANDARD LVCMOS33} [get_ports seg_sel[3]]
set_property -dict {PACKAGE_PIN AF22 IOSTANDARD LVCMOS33} [get_ports seg_sel[4]]  

set_property -dict {PACKAGE_PIN U14  IOSTANDARD LVCMOS33} [get_ports seg_led[0]]
set_property -dict {PACKAGE_PIN R16  IOSTANDARD LVCMOS33} [get_ports seg_led[1]]
set_property -dict {PACKAGE_PIN N16  IOSTANDARD LVCMOS33} [get_ports seg_led[2]]
set_property -dict {PACKAGE_PIN U15  IOSTANDARD LVCMOS33} [get_ports seg_led[3]]
set_property -dict {PACKAGE_PIN T14  IOSTANDARD LVCMOS33} [get_ports seg_led[4]] 
set_property -dict {PACKAGE_PIN T15  IOSTANDARD LVCMOS33} [get_ports seg_led[5]]
set_property -dict {PACKAGE_PIN V14  IOSTANDARD LVCMOS33} [get_ports seg_led[6]]
set_property -dict {PACKAGE_PIN P16  IOSTANDARD LVCMOS33} [get_ports seg_led[7]] 

#-----------------------------------以太网-----------------------------------------
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets eth_rxc]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sys_clk]
create_clock -period 8.000 -name eth_rxc [get_ports eth_rxc]
set_property -dict {PACKAGE_PIN H7 IOSTANDARD LVCMOS33} [get_ports eth_rst_n]
set_property -dict {PACKAGE_PIN G8 IOSTANDARD LVCMOS33} [get_ports eth_rxc]
set_property -dict {PACKAGE_PIN G7 IOSTANDARD LVCMOS33} [get_ports eth_rx_ctl]
set_property -dict {PACKAGE_PIN E6 IOSTANDARD LVCMOS33 PULLUP true}   [get_ports eth_rxd[0]]
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33 PULLUP true}   [get_ports eth_rxd[1]]
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports eth_rxd[2]]
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports eth_rxd[3]]

set_property -dict {PACKAGE_PIN E5 IOSTANDARD LVCMOS33} [get_ports eth_txc]
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports eth_tx_ctl]
set_property -dict {PACKAGE_PIN F5 IOSTANDARD LVCMOS33} [get_ports eth_txd[0]]
set_property -dict {PACKAGE_PIN G5 IOSTANDARD LVCMOS33} [get_ports eth_txd[1]]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports eth_txd[2]]
set_property -dict {PACKAGE_PIN D3 IOSTANDARD LVCMOS33} [get_ports eth_txd[3]]

####------ADC J5
set_property -dict {PACKAGE_PIN L25  IOSTANDARD LVCMOS33} [get_ports ad_clk]
set_property -dict {PACKAGE_PIN D26  IOSTANDARD LVCMOS33} [get_ports ad_data[0]]
set_property -dict {PACKAGE_PIN D24  IOSTANDARD LVCMOS33} [get_ports ad_data[1]]
set_property -dict {PACKAGE_PIN E26  IOSTANDARD LVCMOS33} [get_ports ad_data[2]]
set_property -dict {PACKAGE_PIN D25  IOSTANDARD LVCMOS33} [get_ports ad_data[3]]
set_property -dict {PACKAGE_PIN F25  IOSTANDARD LVCMOS33} [get_ports ad_data[4]] 
set_property -dict {PACKAGE_PIN E25  IOSTANDARD LVCMOS33} [get_ports ad_data[5]]
set_property -dict {PACKAGE_PIN G25  IOSTANDARD LVCMOS33} [get_ports ad_data[6]]
set_property -dict {PACKAGE_PIN G26  IOSTANDARD LVCMOS33} [get_ports ad_data[7]]  
set_property -dict {PACKAGE_PIN J25  IOSTANDARD LVCMOS33} [get_ports ad_data[8]]
set_property -dict {PACKAGE_PIN H26  IOSTANDARD LVCMOS33} [get_ports ad_data[9]]
set_property -dict {PACKAGE_PIN K25  IOSTANDARD LVCMOS33} [get_ports ad_otr]