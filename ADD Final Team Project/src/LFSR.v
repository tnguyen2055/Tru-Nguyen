module LFSR(clk, rst, soft_rst, Enable, TimeOut);
	input clk, rst;
	input Enable, soft_rst;
	output TimeOut;
	reg TimeOut;
	reg [15:0] LFSR;
	wire feedback = LFSR[15];

	always @(posedge clk)
	begin
		if (rst == 1'b0)
			begin
				LFSR <= 16'hFFFF;
				TimeOut <= 1'b0;
			end
		else
			begin
				TimeOut <= 1'b0;
				if (soft_rst == 1'b1) begin
						LFSR <= 16'hFFFF;
						TimeOut <= 1'b0;
					end
				else if (Enable == 1'b1)
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
						//if (LFSR == 16'hff3b) // commented out 
						if ( LFSR == 16'h6db6)
							begin
								LFSR <= 16'hFFFF;
								TimeOut <= 1'b1;
							end
					end
			end
	end
endmodule