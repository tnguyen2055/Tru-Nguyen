module Comparator(rst, clk, Enable, GameDifficulty, Player_in, PlayerLoad_in, ScorePulse, DisplayRandom);
	input rst, clk, Enable, PlayerLoad_in;
	input [1:0] GameDifficulty;
	input [3:0] Player_in;

	output ScorePulse;
	output [3:0] DisplayRandom;

	reg ScorePulse;
	reg [3:0] DisplayRandom;

	reg [15:0] FullPlayer_in;
	reg Random_req;
	reg soft_rst;

	reg [1:0] DisplayCount;
	reg [1:0] PlayerCount;

	wire [15:0] RandomNum;
	wire DisplayTime;

	reg [15:0] RNG;
	reg DisplayTimeOut;
	
	reg [3:0] State;

	parameter Init=0, RequestedRNG=1, CatchRNG=2, DisplayRNG=3, CatchPlayerInput=4, Compare=5, PulseToScoreTracker=6;


	GameTimer RNGDisplayTimer(rst, clk, Enable, soft_rst, GameDifficulty, DisplayTime);
	RNG_Comparator RandomGenerator(rst, clk, Random_req, RandomNum);

	always @(posedge clk)
		begin
			if (rst == 1'b0) begin
				ScorePulse <= 1'b0;
				DisplayRandom <= 4'b1000;
				FullPlayer_in <= 16'b0000_0000_0000_0000;
				Random_req <= 1'b0;
				soft_rst <= 1'b0;
				DisplayCount <= 3'b000;
				PlayerCount <= 3'b000;
				State <= Init;
			end
			// ============================================================
			// Enable-drop guard (Rev 2 fix)
			//   Without this, the FSM stays in whatever state it was in
			//   (often CatchPlayerInput) when gameControl drops
			//   enable_mega_compar at END_GAME or on logout. The next
			//   round then picks up with stale player input and stale
			//   RNG, producing a corrupted round. Force-return to Init
			//   so each new round starts from a known state.
			// ============================================================
			else if (Enable == 1'b0) begin
				ScorePulse <= 1'b0;
				DisplayRandom <= 4'b1000;
				FullPlayer_in <= 16'b0000_0000_0000_0000;
				Random_req <= 1'b0;
				soft_rst <= 1'b0;
				DisplayCount <= 2'b00;
				PlayerCount <= 2'b00;
				State <= Init;
			end
			else begin
				case (State)
					Init: begin
							ScorePulse <= 1'b0;
							DisplayRandom <= 4'b1000;
							FullPlayer_in <= 16'b0000_0000_0000_0000;
							Random_req <= 1'b0;
							soft_rst <= 1'b0;
							DisplayCount <= 2'b00;
							PlayerCount <= 2'b00;
							if (Enable == 1'b1) begin
									Random_req <= 1'b1;
									State <= RequestedRNG;
								end
							else begin
									State <= Init;
								end
						end

					RequestedRNG: begin
							Random_req <= 1'b0;
							State <= CatchRNG;
							end

					CatchRNG: begin
							RNG <= RandomNum;
							soft_rst <= 1'b1;
							State <= DisplayRNG;
						end
					
					DisplayRNG: begin
							soft_rst <=1'b0;
							DisplayTimeOut <= DisplayTime;
							case (DisplayCount)
									2'b00: begin
											DisplayRandom <= {RNG[1], RNG[9], RNG[13], RNG[12]};
										end
									2'b01: begin
											DisplayRandom <= {RNG[11], RNG[2], RNG[6], RNG[10]}; 
										end
									2'b10: begin
											DisplayRandom <= {RNG[7], RNG[15], RNG[3], RNG[4]};
										end
									2'b11: begin
											DisplayRandom <= {RNG[5], RNG[14], RNG[8], RNG[0]};
										end
									default: begin
											DisplayRandom <=4'b1000;
										end
								endcase
							if (DisplayTimeOut == 1'b1 && DisplayCount == 2'b11)
								begin
									DisplayRandom <= 4'b1000;
									State <= CatchPlayerInput;
								end
							else begin
									if (DisplayTimeOut == 1'b1) begin
											DisplayCount <= DisplayCount + 1;
											State <= DisplayRNG;
										end
									else
											State <= DisplayRNG;
								end
						end

					CatchPlayerInput: begin
							if (PlayerLoad_in == 1'b1) begin
									case (PlayerCount)
											2'b00: begin
													FullPlayer_in[15:12] <= Player_in;
												end
											2'b01: begin
													FullPlayer_in[11:8] <= Player_in;
												end
											2'b10: begin
													FullPlayer_in[7:4] <= Player_in;
												end
											2'b11: begin
													FullPlayer_in[3:0] <= Player_in;
												end
											default: begin
													FullPlayer_in <= 16'h0000;
												end
										endcase

									if (PlayerCount == 2'b11)
										State <= Compare;
									else
										PlayerCount <= PlayerCount + 1;
								end
						end

					Compare: begin
							if ( RNG == FullPlayer_in)
								ScorePulse <= 1'b1;
							
							State <= PulseToScoreTracker;
						end

					PulseToScoreTracker: begin
							ScorePulse <= 1'b0;
							State <= Init;
						end
			
					default: begin
							ScorePulse <= 1'b0;
							DisplayRandom <= 4'b1000;
							FullPlayer_in <= 16'b0000_0000_0000_0000;
							Random_req <= 1'b0;
							soft_rst <= 1'b0;
							DisplayCount <= 2'b00;
							PlayerCount <= 2'b00;
							
							State <= Init;
						end
					
				endcase
			end
		end

endmodule
