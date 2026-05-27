/*
================================================================
Course      : ECE 6370 Advanced Digital Design
Author      : Zaki Mir
PeopleSoft  : 1675819
Project     : Final Project - ScoreRAM_adapter
================================================================

***************   Functionality Description   ******************
Selector module that sits between Tru's scoreRAM_top (which
exposes two 24-bit packed outputs simultaneously) and the
DisplayCnt LBOARD renderer (which accepts a single 24-bit
lboard_entry input). Resolves the interface mismatch without
modifying either side.

Inputs from scoreRAM_top:
  my_best     [23:0]   MyBest_to_DispCnt:     {NumberID, MyBest_reg}
  global_best [23:0]   GlobalBest_to_DispCnt: {BestPlayer_reg, GlobalBest_reg}

Inputs from gameControl:
  pulse_w_ram          one-cycle write pulse, fires on entry to
                       END_GAME. Used here to reset the view
                       selector back to MyBest so the next LBOARD
                       opens at the player's own record.
  pulse_scrl_ram       one-cycle scroll pulse, fires when the
                       scroll key is pressed during LBOARD. Flips
                       the view selector between MyBest and
                       GlobalBest.

Output to DisplayCnt:
  lboard_entry[23:0]   selected 24-bit packed entry, sliced into
                       six HEX nibbles by DisplayCnt in LBOARD mode.

Selector behavior (single 1-bit register):
  view_sel = 0  ->  lboard_entry = my_best
  view_sel = 1  ->  lboard_entry = global_best

  pulse_w_ram      => view_sel <= 0  (open at MyBest)
  pulse_scrl_ram   => view_sel <= ~view_sel  (flip)
  neither          => view_sel unchanged

Pulses are guaranteed by gameControl to be single-cycle and
mutually exclusive (pulse_w_ram fires in END_GAME, pulse_scrl_ram
fires in LBOARD -- different states, can't overlap). The
defensive priority below (write-pulse wins over scroll-pulse
if both fire) is just belt-and-suspenders for future changes.

Output is registered (one-cycle latency) so it's glitch-free into
DisplayCnt's already-registered HEX path. Total scroll-to-HEX lag
is 3 clocks at 50 MHz = 60 ns, invisible on the displays.
================================================================
*/
module ScoreRAM_adapter(
	clk, rst,
	pulse_w_ram, pulse_scrl_ram,
	my_best, global_best,
	lboard_entry
);
	// ---------------- system ----------------
	input clk, rst;
	
	// ---------------- from gameControl ----------------
	input pulse_w_ram;
	input pulse_scrl_ram;
	
	// ---------------- from scoreRAM_top ----------------
	input [23:0] my_best;
	input [23:0] global_best;
	
	// ---------------- to DisplayCnt ----------------
	output reg [23:0] lboard_entry;
	
	// ---------------- logic-level aliases ----------------
	parameter HIGH = 1'b1;
	parameter LOW  = 1'b0;
	
	// ---------------- view selector ----------------
	//   0 = show my_best, 1 = show global_best
	reg view_sel;
	
	always @(posedge clk) begin
		if (rst == LOW) begin
			view_sel     <= 1'b0;
			lboard_entry <= 24'h000000;
		end
		else begin
			// ----------------------------------------------------
			// View selector update.
			// pulse_w_ram has priority over pulse_scrl_ram --
			// gameControl never asserts both in the same cycle
			// today, but if it ever did, opening LBOARD at MyBest
			// is the desired behavior.
			// ----------------------------------------------------
			if (pulse_w_ram == HIGH) begin
				view_sel <= 1'b0;
			end
			else if (pulse_scrl_ram == HIGH) begin
				view_sel <= ~view_sel;
			end
			
			// ----------------------------------------------------
			// Output mux. Reads view_sel from the start of this
			// cycle (non-blocking semantics), so the output reflects
			// the OLD selector value -- updated selector takes
			// effect on the next clock. This is the standard pattern
			// and is fine; the 1-cycle lag is invisible at 50 MHz.
			// ----------------------------------------------------
			if (view_sel == 1'b0)
				lboard_entry <= my_best;
			else
				lboard_entry <= global_best;
		end
	end
	
endmodule
