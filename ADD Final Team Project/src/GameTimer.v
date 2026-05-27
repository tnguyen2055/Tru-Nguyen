module GameTimer (rst, clk, Enable, soft_rst, GameDifficulty, TimeOut);
	input rst, clk;
	input Enable, soft_rst;
	input [1:0] GameDifficulty;

	output TimeOut;
	
	reg TimeOut;
	reg [4:0] count;
	reg [4:0] countTerminal;

	wire OneMSSignal, HundredOut;

	LFSR OneMSLFSR (clk, rst, soft_rst, Enable, OneMSSignal);
	CountTo100 HundredCount ( OneMSSignal, rst, soft_rst, clk, HundredOut);


	always @(posedge clk)
		begin 
			if (rst == 1'b0)
				begin
					TimeOut <= 1'b0;
					count <= 5'b00000;
				end
			else
				begin
					if (soft_rst == 1'b1)
						count <= 5'b00000;

					TimeOut <= 1'b0;
					case (GameDifficulty)
						2'b01: begin
							//countTerminal <= 5'b00011; // commented out 
							countTerminal <= 5'b10100;
						end
			
						2'b10: begin
							//countTerminal <= 5'b00010; // commented out 
							countTerminal <= 5'b01111;
						end
			
						2'b11: begin
							//countTerminal <= 5'b00001; // commented out 
							countTerminal <= 5'b01010;
						end
			
						default: begin
							countTerminal <= 5'b10100;
						end
					endcase
					
					
					if (HundredOut == 1'b1)
						begin
							count <= count + 1;
							if (count == countTerminal) begin
									TimeOut <= 1'b1;
									count <= 5'b00000;
								end
						end
				end
		end
					
endmodule
