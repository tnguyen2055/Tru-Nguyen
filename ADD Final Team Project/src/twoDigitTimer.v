/*
Course: ECE 6370 Advanced Digital Design
Author: Zaki Mir 
PeopleSoft ID: 1675819
Porject: Lab 2 accessControl
Project Discription: 
This modue combines oneSecTimer + two digitCountDown modules 
it take clk, rst, time_reconfig(accessControl), timer_enable(accessControl)
signal and outputs ones_count[3:0], tens_count[3;0], and timer_done. 
____________________________________________________________
***************                              ***************
	
------------------------------------------------------------
*/

module twoDigitTimer(clk, rst, time_reconfig, timer_enable,
					 ones_count, tens_count, timer_done);
	input 	clk, rst, time_reconfig, timer_enable; 
	output wire [3:0] ones_count;
	output wire [3:0] tens_count;
	output wire timer_done;
	
	
	wire ones_borrowUp, ones_noBorrowDwn;
	wire tens_borrowUp, tens_noBorrowDwn;
	wire timeout;
	
	//oneSecTimer(clk, rst, enable, timeout);
	oneSecTimerLFSR timer(clk, rst, timer_enable, timeout);
	
	// digitTimer(rst, enable, reconfig, borrowDwn, noBorrowUp, borrowUp, noBorrowDwn, count);	
	// ones digit: pulse drives borrowDwn, tens tells it if empty
	digitTimer onesTimer(rst, timer_enable, time_reconfig, timeout, tens_noBorrowDwn, 
						ones_borrowUp, ones_noBorrowDwn, ones_count);
	
	// tens digit: ones borrowUp drives borrowDwn, nothing above
	digitTimer tensTimer(rst, timer_enable, time_reconfig, ones_borrowUp, 1'b1, 
						tens_borrowUp, tens_noBorrowDwn, tens_count);
						
	assign timer_done = (ones_count == 4'b0000) && (tens_count == 4'b0000) && timer_enable;

endmodule 