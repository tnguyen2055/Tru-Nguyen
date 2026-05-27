/*
Course: ECE 6370 Advanced Digital Design
Author: Zaki Mir 
PeopleSoft ID: 1675819
Porject: Lab 4 LFSRTimer
Project Discription: 
This module implements an FPGA-based LFSR based 1 ms timer.  

____________________________________________________________
********correction from the simulation program**************
	
------------------------------------------------------------
*/
module LFSRTimer(clk, rst, enable, timeout);
	input wire clk, rst, enable;
	output reg timeout; 
	
	reg [15:0] LFSR; 
	wire feedback = LFSR[15];
	
	parameter TERMEND = 16'h1C51;
	
	always @(posedge clk) begin
		if(rst == 1'b0) begin
			LFSR[15:0] <= 16'hFFFF; 
			timeout <= 1'b0; 
		end else begin
			if (enable == 1) begin	// only counting if the enable is one 
				if(LFSR == TERMEND) begin
					timeout <= 1'b1; 
					LFSR[15:0] <= 16'hFFFF; 
				end else begin
					LFSR[0] <= feedback;
					LFSR[1] <= LFSR[0];
					LFSR[2] <= LFSR[1] ^ feedback;
					LFSR[3] <= LFSR[2];
					LFSR[4] <= LFSR[3];
					LFSR[5] <= LFSR[4] ^ feedback;
					LFSR[6] <= LFSR[5] ^ feedback;
					LFSR[7] <= LFSR[6];
					LFSR[8] <= LFSR[7];
					LFSR[9] <= LFSR[8];
					LFSR[10] <= LFSR[9];
					LFSR[11] <= LFSR[10];
					LFSR[12] <= LFSR[11];
					LFSR[13] <= LFSR[12];
					LFSR[14] <= LFSR[13];
					LFSR[15] <= LFSR[14];
					timeout <= 1'b0;
				end
			end else begin				// incrase the count with clock edge if 
				LFSR[15:0] <= LFSR[15:0]; 
				timeout <= 0;
			end 
		end 
	end

endmodule 