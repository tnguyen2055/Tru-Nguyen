/*
================================================================
Course      : ECE 6370 Advanced Digital Design
Author      : Zaki Mir
PeopleSoft  : 1675819
Project     : Final Project - DisplayCnt
Rev			: 3
================================================================

***************   Functionality Description   ******************
DE0-CV 7-segment HEX renderer for the Hex Sequence game. Acts
as a pure slave to gameControl: the one-hot display_mode[6:0]
signal selects which HEX layout to drive. No phase inference,
no internal FSM -- DisplayCnt only knows what to draw, not what
state the system is in.

LED phase indicators are driven directly from gameControl's
display_mode at the top level (LEDR[6:0] <= display_mode[6:0]).
DisplayCnt is HEX-only.

display_mode encoding (matches gameControl):
  bit 0  UNAUTHED   -- entering ID
  bit 1  ID_IN      -- ID accepted, entering password
  bit 2  AUTHED     -- logged in, no difficulty yet
  bit 3  PRE_GAME   -- difficulty locked, awaiting start
  bit 4  PLAYING    -- gameplay
  bit 5  END_GAME   -- 1-second post-round pause
  bit 6  LBOARD     -- leaderboard view

HEX layout per mode (HEX5 leftmost, HEX0 rightmost):

                HEX5    HEX4   HEX3      HEX2      HEX1   HEX0
  UNAUTHED  :   blank   blank  blank     blank     blank  blank
  ID_IN     :   blank   blank  blank     blank     blank  blank
  AUTHED    :   blank   blank  blank     blank     blank  blank
  PRE_GAME  :   '9'     '9'    blank     blank     blank  blank
  PLAYING   :   tens    ones   blank     blank     blank  RNG
  END_GAME  :   tens=0  ones=0 blank     blank     blank  blank
  LBOARD    :   id[15:12] id[11:8] id[7:4] id[3:0] sc[7:4] sc[3:0]

LBOARD slices the 24-bit lboard_entry input:
   lboard_entry[23:8]  = 4-digit ID
   lboard_entry[7:0]   = 2-digit score
ScoreRAM owns scrolling internally (advances on pulse_scrl_ram
from gameControl); DisplayCnt is dumb -- shows whatever 24-bit
entry is currently presented.

7-seg outputs are active-LOW per the DE0-CV pin manual.
Bit mapping per segment: HEX[6:0] = {g, f, e, d, c, b, a}.

Outputs are registered (1-cycle latency). At 50 MHz that's
20 ns -- invisible on the 7-seg displays.

Hex-to-7seg decoding is inlined as nested case statements per
the course constraint of one always block, no functions.
================================================================
*/
module DisplayCnt(
	clk, rst,
	display_mode,
	ones_count, tens_count,
	DisplayRandom,
	lboard_entry,
	HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);
	// ---------------- System ----------------
	input clk, rst;
	
	// ---------------- One-hot phase from gameControl ----------------
	input [6:0] display_mode;
	
	// ---------------- Game data ----------------
	input [3:0] ones_count, tens_count;  // from twoDigitTimer
	input [3:0] DisplayRandom;           // from Comparator
	input [23:0] lboard_entry;           // from ScoreRAM, packed {ID[15:0], score[7:0]}
	
	// ---------------- DE0-CV 7-seg outputs (active-LOW) ----------------
	output reg [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	
	// ---------------- One-hot mode patterns (match gameControl) ----------------
	parameter MODE_UNAUTHED  = 7'b000_0001;
	parameter MODE_ID_IN     = 7'b000_0010;
	parameter MODE_AUTHED    = 7'b000_0100;
	parameter MODE_PRE_GAME  = 7'b000_1000;
	parameter MODE_PLAYING   = 7'b001_0000;
	parameter MODE_END_GAME  = 7'b010_0000;
	parameter MODE_LBOARD    = 7'b100_0000;
	
	// ---------------- Logic-level aliases ----------------
	parameter HIGH = 1'b1;
	parameter LOW  = 1'b0;
	
	// ---------------- 7-seg patterns (active-LOW; bit[6]=g, bit[0]=a) ----------------
	parameter SEG_0     = 7'b1000000;
	parameter SEG_1     = 7'b1111001;
	parameter SEG_2     = 7'b0100100;
	parameter SEG_3     = 7'b0110000;
	parameter SEG_4     = 7'b0011001;
	parameter SEG_5     = 7'b0010010;
	parameter SEG_6     = 7'b0000010;
	parameter SEG_7     = 7'b1111000;
	parameter SEG_8     = 7'b0000000;
	parameter SEG_9     = 7'b0010000;
	parameter SEG_A     = 7'b0001000;
	parameter SEG_B     = 7'b0000011;
	parameter SEG_C     = 7'b1000110;
	parameter SEG_D     = 7'b0100001;
	parameter SEG_E     = 7'b0000110;
	parameter SEG_F     = 7'b0001110;
	parameter SEG_BLANK = 7'b1111111;
	
	// ============================================================
	// Single-always-block FSM
	//   Cases on display_mode (one-hot from gameControl).
	//   Each branch drives all six HEX outputs.
	//   Hex-to-7seg conversion is inlined as nested case
	//   statements (no helper function).
	// ============================================================
	always @(posedge clk) begin
		if (rst == LOW) begin
			HEX0 <= SEG_BLANK;
			HEX1 <= SEG_BLANK;
			HEX2 <= SEG_BLANK;
			HEX3 <= SEG_BLANK;
			HEX4 <= SEG_BLANK;
			HEX5 <= SEG_BLANK;
		end
		else begin
			case (display_mode)
				
				// ============================================
				// UNAUTHED / ID_IN / AUTHED
				//   Pre-difficulty phases -- all HEX blank.
				//   Player phase is communicated via the LEDs
				//   (driven from display_mode at top level).
				// ============================================
				MODE_UNAUTHED, MODE_ID_IN, MODE_AUTHED: begin
					HEX0 <= SEG_BLANK;
					HEX1 <= SEG_BLANK;
					HEX2 <= SEG_BLANK;
					HEX3 <= SEG_BLANK;
					HEX4 <= SEG_BLANK;
					HEX5 <= SEG_BLANK;
				end
				
				// ============================================
				// PRE_GAME
				//   Show "99" on HEX5/HEX4 as a preview of the
				//   round timer. Other HEX blank.
				// ============================================
				MODE_PRE_GAME: begin
					HEX5 <= SEG_9;
					HEX4 <= SEG_9;
					HEX3 <= SEG_BLANK;
					HEX2 <= SEG_BLANK;
					HEX1 <= SEG_BLANK;
					HEX0 <= SEG_BLANK;
				end
				
				// ============================================
				// PLAYING
				//   HEX5/HEX4 = round timer (tens, ones).
				//   HEX0 = current Comparator RNG nibble.
				//   HEX3/HEX2/HEX1 stay blank.
				// ============================================
				MODE_PLAYING: begin
					HEX3 <= SEG_BLANK;
					HEX2 <= SEG_BLANK;
					HEX1 <= SEG_BLANK;
					
					// HEX5: tens_count hex decode
					case (tens_count)
						4'h0:    HEX5 <= SEG_0;
						4'h1:    HEX5 <= SEG_1;
						4'h2:    HEX5 <= SEG_2;
						4'h3:    HEX5 <= SEG_3;
						4'h4:    HEX5 <= SEG_4;
						4'h5:    HEX5 <= SEG_5;
						4'h6:    HEX5 <= SEG_6;
						4'h7:    HEX5 <= SEG_7;
						4'h8:    HEX5 <= SEG_8;
						4'h9:    HEX5 <= SEG_9;
						4'hA:    HEX5 <= SEG_A;
						4'hB:    HEX5 <= SEG_B;
						4'hC:    HEX5 <= SEG_C;
						4'hD:    HEX5 <= SEG_D;
						4'hE:    HEX5 <= SEG_E;
						4'hF:    HEX5 <= SEG_F;
						default: HEX5 <= SEG_BLANK;
					endcase
					
					// HEX4: ones_count hex decode
					case (ones_count)
						4'h0:    HEX4 <= SEG_0;
						4'h1:    HEX4 <= SEG_1;
						4'h2:    HEX4 <= SEG_2;
						4'h3:    HEX4 <= SEG_3;
						4'h4:    HEX4 <= SEG_4;
						4'h5:    HEX4 <= SEG_5;
						4'h6:    HEX4 <= SEG_6;
						4'h7:    HEX4 <= SEG_7;
						4'h8:    HEX4 <= SEG_8;
						4'h9:    HEX4 <= SEG_9;
						4'hA:    HEX4 <= SEG_A;
						4'hB:    HEX4 <= SEG_B;
						4'hC:    HEX4 <= SEG_C;
						4'hD:    HEX4 <= SEG_D;
						4'hE:    HEX4 <= SEG_E;
						4'hF:    HEX4 <= SEG_F;
						default: HEX4 <= SEG_BLANK;
					endcase
					
					// HEX0: DisplayRandom hex decode
					case (DisplayRandom)
						4'h0:    HEX0 <= SEG_0;
						4'h1:    HEX0 <= SEG_1;
						4'h2:    HEX0 <= SEG_2;
						4'h3:    HEX0 <= SEG_3;
						4'h4:    HEX0 <= SEG_4;
						4'h5:    HEX0 <= SEG_5;
						4'h6:    HEX0 <= SEG_6;
						4'h7:    HEX0 <= SEG_7;
						4'h8:    HEX0 <= SEG_8;
						4'h9:    HEX0 <= SEG_9;
						4'hA:    HEX0 <= SEG_A;
						4'hB:    HEX0 <= SEG_B;
						4'hC:    HEX0 <= SEG_C;
						4'hD:    HEX0 <= SEG_D;
						4'hE:    HEX0 <= SEG_E;
						4'hF:    HEX0 <= SEG_F;
						default: HEX0 <= SEG_BLANK;
					endcase
				end
				
				// ============================================
				// END_GAME
				//   1-second pause before LBOARD. Shows the
				//   timer at its final value (which is 00 since
				//   timer_done just fired). Other HEX blank.
				// ============================================
				MODE_END_GAME: begin
					HEX3 <= SEG_BLANK;
					HEX2 <= SEG_BLANK;
					HEX1 <= SEG_BLANK;
					HEX0 <= SEG_BLANK;
					
					// HEX5: tens_count hex decode (will be 0)
					case (tens_count)
						4'h0:    HEX5 <= SEG_0;
						4'h1:    HEX5 <= SEG_1;
						4'h2:    HEX5 <= SEG_2;
						4'h3:    HEX5 <= SEG_3;
						4'h4:    HEX5 <= SEG_4;
						4'h5:    HEX5 <= SEG_5;
						4'h6:    HEX5 <= SEG_6;
						4'h7:    HEX5 <= SEG_7;
						4'h8:    HEX5 <= SEG_8;
						4'h9:    HEX5 <= SEG_9;
						4'hA:    HEX5 <= SEG_A;
						4'hB:    HEX5 <= SEG_B;
						4'hC:    HEX5 <= SEG_C;
						4'hD:    HEX5 <= SEG_D;
						4'hE:    HEX5 <= SEG_E;
						4'hF:    HEX5 <= SEG_F;
						default: HEX5 <= SEG_BLANK;
					endcase
					
					// HEX4: ones_count hex decode (will be 0)
					case (ones_count)
						4'h0:    HEX4 <= SEG_0;
						4'h1:    HEX4 <= SEG_1;
						4'h2:    HEX4 <= SEG_2;
						4'h3:    HEX4 <= SEG_3;
						4'h4:    HEX4 <= SEG_4;
						4'h5:    HEX4 <= SEG_5;
						4'h6:    HEX4 <= SEG_6;
						4'h7:    HEX4 <= SEG_7;
						4'h8:    HEX4 <= SEG_8;
						4'h9:    HEX4 <= SEG_9;
						4'hA:    HEX4 <= SEG_A;
						4'hB:    HEX4 <= SEG_B;
						4'hC:    HEX4 <= SEG_C;
						4'hD:    HEX4 <= SEG_D;
						4'hE:    HEX4 <= SEG_E;
						4'hF:    HEX4 <= SEG_F;
						default: HEX4 <= SEG_BLANK;
					endcase
				end
				
				// ============================================
				// LBOARD
				//   24-bit lboard_entry sliced into 6 nibbles,
				//   one per HEX. Format:
				//     HEX5/4/3/2 = 4-digit ID  (entry[23:8])
				//     HEX1/0     = 2-digit score (entry[7:0])
				// ============================================
				MODE_LBOARD: begin
					// HEX5: lboard_entry[23:20] -- ID digit 1
					case (lboard_entry[23:20])
						4'h0:    HEX5 <= SEG_0;
						4'h1:    HEX5 <= SEG_1;
						4'h2:    HEX5 <= SEG_2;
						4'h3:    HEX5 <= SEG_3;
						4'h4:    HEX5 <= SEG_4;
						4'h5:    HEX5 <= SEG_5;
						4'h6:    HEX5 <= SEG_6;
						4'h7:    HEX5 <= SEG_7;
						4'h8:    HEX5 <= SEG_8;
						4'h9:    HEX5 <= SEG_9;
						4'hA:    HEX5 <= SEG_A;
						4'hB:    HEX5 <= SEG_B;
						4'hC:    HEX5 <= SEG_C;
						4'hD:    HEX5 <= SEG_D;
						4'hE:    HEX5 <= SEG_E;
						4'hF:    HEX5 <= SEG_F;
						default: HEX5 <= SEG_BLANK;
					endcase
					
					// HEX4: lboard_entry[19:16] -- ID digit 2
					case (lboard_entry[19:16])
						4'h0:    HEX4 <= SEG_0;
						4'h1:    HEX4 <= SEG_1;
						4'h2:    HEX4 <= SEG_2;
						4'h3:    HEX4 <= SEG_3;
						4'h4:    HEX4 <= SEG_4;
						4'h5:    HEX4 <= SEG_5;
						4'h6:    HEX4 <= SEG_6;
						4'h7:    HEX4 <= SEG_7;
						4'h8:    HEX4 <= SEG_8;
						4'h9:    HEX4 <= SEG_9;
						4'hA:    HEX4 <= SEG_A;
						4'hB:    HEX4 <= SEG_B;
						4'hC:    HEX4 <= SEG_C;
						4'hD:    HEX4 <= SEG_D;
						4'hE:    HEX4 <= SEG_E;
						4'hF:    HEX4 <= SEG_F;
						default: HEX4 <= SEG_BLANK;
					endcase
					
					// HEX3: lboard_entry[15:12] -- ID digit 3
					case (lboard_entry[15:12])
						4'h0:    HEX3 <= SEG_0;
						4'h1:    HEX3 <= SEG_1;
						4'h2:    HEX3 <= SEG_2;
						4'h3:    HEX3 <= SEG_3;
						4'h4:    HEX3 <= SEG_4;
						4'h5:    HEX3 <= SEG_5;
						4'h6:    HEX3 <= SEG_6;
						4'h7:    HEX3 <= SEG_7;
						4'h8:    HEX3 <= SEG_8;
						4'h9:    HEX3 <= SEG_9;
						4'hA:    HEX3 <= SEG_A;
						4'hB:    HEX3 <= SEG_B;
						4'hC:    HEX3 <= SEG_C;
						4'hD:    HEX3 <= SEG_D;
						4'hE:    HEX3 <= SEG_E;
						4'hF:    HEX3 <= SEG_F;
						default: HEX3 <= SEG_BLANK;
					endcase
					
					// HEX2: lboard_entry[11:8] -- ID digit 4
					case (lboard_entry[11:8])
						4'h0:    HEX2 <= SEG_0;
						4'h1:    HEX2 <= SEG_1;
						4'h2:    HEX2 <= SEG_2;
						4'h3:    HEX2 <= SEG_3;
						4'h4:    HEX2 <= SEG_4;
						4'h5:    HEX2 <= SEG_5;
						4'h6:    HEX2 <= SEG_6;
						4'h7:    HEX2 <= SEG_7;
						4'h8:    HEX2 <= SEG_8;
						4'h9:    HEX2 <= SEG_9;
						4'hA:    HEX2 <= SEG_A;
						4'hB:    HEX2 <= SEG_B;
						4'hC:    HEX2 <= SEG_C;
						4'hD:    HEX2 <= SEG_D;
						4'hE:    HEX2 <= SEG_E;
						4'hF:    HEX2 <= SEG_F;
						default: HEX2 <= SEG_BLANK;
					endcase
					
					// HEX1: lboard_entry[7:4] -- score digit 1 (tens)
					case (lboard_entry[7:4])
						4'h0:    HEX1 <= SEG_0;
						4'h1:    HEX1 <= SEG_1;
						4'h2:    HEX1 <= SEG_2;
						4'h3:    HEX1 <= SEG_3;
						4'h4:    HEX1 <= SEG_4;
						4'h5:    HEX1 <= SEG_5;
						4'h6:    HEX1 <= SEG_6;
						4'h7:    HEX1 <= SEG_7;
						4'h8:    HEX1 <= SEG_8;
						4'h9:    HEX1 <= SEG_9;
						4'hA:    HEX1 <= SEG_A;
						4'hB:    HEX1 <= SEG_B;
						4'hC:    HEX1 <= SEG_C;
						4'hD:    HEX1 <= SEG_D;
						4'hE:    HEX1 <= SEG_E;
						4'hF:    HEX1 <= SEG_F;
						default: HEX1 <= SEG_BLANK;
					endcase
					
					// HEX0: lboard_entry[3:0] -- score digit 2 (ones)
					case (lboard_entry[3:0])
						4'h0:    HEX0 <= SEG_0;
						4'h1:    HEX0 <= SEG_1;
						4'h2:    HEX0 <= SEG_2;
						4'h3:    HEX0 <= SEG_3;
						4'h4:    HEX0 <= SEG_4;
						4'h5:    HEX0 <= SEG_5;
						4'h6:    HEX0 <= SEG_6;
						4'h7:    HEX0 <= SEG_7;
						4'h8:    HEX0 <= SEG_8;
						4'h9:    HEX0 <= SEG_9;
						4'hA:    HEX0 <= SEG_A;
						4'hB:    HEX0 <= SEG_B;
						4'hC:    HEX0 <= SEG_C;
						4'hD:    HEX0 <= SEG_D;
						4'hE:    HEX0 <= SEG_E;
						4'hF:    HEX0 <= SEG_F;
						default: HEX0 <= SEG_BLANK;
					endcase
				end
				
				// ============================================
				// default -- safety net
				//   Catches any invalid display_mode value
				//   (e.g. multi-bit set, all-zero). Drives all
				//   HEX blank.
				// ============================================
				default: begin
					HEX0 <= SEG_BLANK;
					HEX1 <= SEG_BLANK;
					HEX2 <= SEG_BLANK;
					HEX3 <= SEG_BLANK;
					HEX4 <= SEG_BLANK;
					HEX5 <= SEG_BLANK;
				end
				
			endcase
		end
	end
	
endmodule
