/*	oneSecTimerLFSR.v is the implementation of one sec timer 
	how it works:
		we chain three small couters togather 
		
		clk (every rising edge wile enable = 1)
			coutn += 1; 
		LFSRTimer - LFSRTimer clock ticks then pulse t_1ms
		
		countTo3 - counts 3 t_1ms pulses, then pulse t_100ms
		
		countTo2 - counts 2 t_100ms pulses, then pulse timeout. 
*/ 

module oneSecTimerLFSR(clk, rst, enable, timeout);
	input clk, rst, enable;
	output timeout;
	
	wire t_1ms;		// timeout from coutnTo4
	wire t_100ms;	// timeout from countTo3
	
	// LFSRTimer(clk, rst, enable, timeout);
	LFSRTimer u_LFSRTimer(clk, rst, enable, t_1ms);
	
	// t_1ms enables the contTO3 and it start to count when 
	countTo3 u_countTo3(clk, rst, t_1ms, t_100ms);
	
	// t_100ms enables the contTO3 and it start to count when 
	countTo2 u_countTo2(clk, rst, t_100ms, timeout);
	
endmodule 