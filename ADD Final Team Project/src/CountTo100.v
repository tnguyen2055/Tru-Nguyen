/*
================================================================
Course      : ECE 6370 Advanced Digital Design
Project     : Final Project - CountTo100 (Stage 2 of GameTimer cascade)
================================================================

***************   Functionality Description   ******************
Counts 100 incoming OneMSSignal pulses (each = 1 ms from the
upstream LFSR) and asserts a single-cycle HundredOut on the 100th,
producing a 100 ms tick that feeds the GameTimer round counter.

Cascade context:
    LFSR (1 ms)  ->  CountTo100 (100 ms)  ->  GameTimer (round timeout)

Reset behavior:
    rst (active-LOW) : full module clear via top-level reset.
    soft_rst         : per-round clear, asserted by Comparator
                       during CatchRNG so each round starts
                       cleanly. Clears BOTH Counter and HundredOut.
================================================================
*/
module CountTo100 (OneMSSignal, rst, soft_rst, clk, HundredOut);
	input  OneMSSignal, rst, clk, soft_rst;
	output HundredOut;
	reg    HundredOut;
	reg [7:0] Counter;

	always @(posedge clk)
		begin
			// Active-LOW hard reset
			if (rst == 1'b0)
				begin
					HundredOut <= 1'b0;
					Counter    <= 8'b0000_0000;
				end
			else
				begin
					// Default: HundredOut idles LOW.
					// Use non-blocking <= here to avoid mixing with
					// the <= overrides below -- mixing blocking and
					// non-blocking on the same reg in one always block
					// is a synthesis hazard. (Was '=' previously.)
					HundredOut <= 1'b0;

					// Per-round soft reset from Comparator.CatchRNG.
					// Clears the count register too, so the next round
					// starts from 0 (not from a partial count carried
					// over from the previous round).
					if (soft_rst == 1'b1) begin
							HundredOut <= 1'b0;
							Counter    <= 8'b0000_0000;
						end

					// Increment on each 1 ms upstream tick;
					// pulse HundredOut on the 100th tick and wrap.
					if (OneMSSignal == 1'b1)
						begin
							Counter <= Counter + 1;
							//if (Counter == 8'b0000_0011) // sim-speed value
							if (Counter == 8'b0110_0100)    // 100 in production
								begin
									HundredOut <= 1'b1;
									Counter    <= 8'b0000_0000;
								end
						end
					else
						begin
							//Nothing
						end
				end
		end
endmodule