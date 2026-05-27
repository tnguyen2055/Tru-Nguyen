//This is a free running timer, Not constrained by an Enable signal
//This LFSR will continue to run and shift, at an unknown time, the
//Comparator Top Module will request a 16 bit sample of the LFSR.
//The comparator will use this 16 bit number to display.

module RNG_Comparator (rst, clk, Sample_req, RandomNums);
	input rst, clk;
	input Sample_req;
	output [15:0] RandomNums;
	reg [15:0] RandomNums;
	
	reg [15:0] LFSR;
	wire feedback = LFSR[15];

	always @(posedge clk)
	begin
		if (rst == 1'b0)
			begin
				RandomNums <= 16'h0000;
				LFSR <= 16'hFFFF;
			end
		else
			begin
				LFSR[0] <= feedback;
				LFSR[1] <= LFSR[0];
				LFSR[2] <= LFSR[1] ^ feedback;
				LFSR[3] <= LFSR[2] ^ feedback;
				LFSR[4] <= LFSR[3];
				LFSR[5] <= LFSR[4] ^ feedback;
				LFSR[6] <= LFSR[5];
				LFSR[7] <= LFSR[6];
				LFSR[8] <= LFSR[7];
				LFSR[9] <= LFSR[8];
				LFSR[10] <= LFSR[9];
				LFSR[11] <= LFSR[10];
				LFSR[12] <= LFSR[11];
				LFSR[13] <= LFSR[12];
				LFSR[14] <= LFSR[13];
				LFSR[15] <= LFSR[14];
				if ( Sample_req == 1'b1)
					begin
						RandomNums <= LFSR;
					end
			end
	end


endmodule