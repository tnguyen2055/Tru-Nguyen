/*
================================================================
Course      : ECE 6370 Advanced Digital Design
Author      : Zaki Mir
PeopleSoft  : 1675819
Project     : Final Project - gameControl
Rev			: 3 
================================================================

***************   Functionality Description   ******************
Master FSM that orchestrates the round lifecycle and produces a
unified one-hot mode signal that drives both the DE0-CV phase
LEDs and the DisplayCnt HEX renderer.

State graph (7 states, 4-bit encoding):
  UNAUTHENTICATED  -- awaiting login from Authentication
  ID_IN            -- ID accepted by Authentication, awaiting PW
  AUTHENTICATED    -- logged in; one-cycle timer reload to 99
  WAIT_FOR_START   -- difficulty locked, awaiting start key
  GAME_RUNNING     -- gameplay active; mega comparator enabled
  END_GAME         -- 1-second hold post-round; ScoreRAM write
                      pulse fires on entry; counter then runs
                      to terminal before advancing to LBOARD
  LBOARD           -- leaderboard view; restart/scroll/logout

display_mode[6:0] -- one-hot phase output (this is the BIG add):
   bit 0  HIGH in UNAUTHENTICATED
   bit 1  HIGH in ID_IN
   bit 2  HIGH in AUTHENTICATED
   bit 3  HIGH in WAIT_FOR_START
   bit 4  HIGH in GAME_RUNNING
   bit 5  HIGH in END_GAME
   bit 6  HIGH in LBOARD
Top-level wires display_mode[6:0] directly to LEDR[6:0]; the same
signal feeds DisplayCnt as its phase input. Single source of
truth for "what mode are we in" -- no inference needed in
DisplayCnt, no separate LED driver module.

END_GAME 1-second hold:
  Internal end_game_counter (26-bit, 0 .. 49_999_999) counts
  50,000,000 clock cycles at 50 MHz = 1.0 s. On entry to
  END_GAME the counter is at 0; it increments each clock until
  END_GAME_HOLD, then advances to LBOARD. pulse_w_ram fires for
  one cycle on entry only -- ScoreRAM gets a single write pulse,
  then has the rest of the second to settle before LBOARD asks
  for the first leaderboard entry.

Inputs added vs. previous version:
  id_passed        -- from Authentication.ID_passed; LOW while
                      entering ID, HIGH once ID matches a ROM
                      entry. Drives UNAUTHENTICATED -> ID_IN.

Outputs removed vs. previous version:
  display_cntrl    -- subsumed by display_mode[6]. Top level
                      should be re-wired accordingly.

Outputs preserved:
  timer_enable, timer_reconfig   -- to twoDigitTimer
  enable_mega_compar             -- to Comparator
  pulse_w_ram, pulse_scrl_ram    -- to ScoreRAM
  difficulty_out                 -- to GameTimer/Comparator
  logout_req                     -- to Authentication
  score_soft_rst                 -- to score_unit_rev1
================================================================
*/
module gameControl(clk, rst, timer_done, id_log_inout, game_start_key, game_control_key,
					verified, id_passed, difficulty_in,
					timer_enable, timer_reconfig, enable_mega_compar,
					pulse_w_ram, pulse_scrl_ram,
					difficulty_out, logout_req, score_soft_rst,
					display_mode);
	
	// ---------------- System ----------------
	input clk, rst;
	
	// ---------------- Inputs from twoDigitTimer ----------------
	input timer_done;
	
	// ---------------- Inputs from raw KEYs / switches ----------------
	input id_log_inout;        // active-LOW: LOW = logout pressed
	input game_start_key;      // shaped pulse; HIGH = "start the round"
	input game_control_key;    // shaped pulse; HIGH = "scroll" / "restart"
	
	// ---------------- Inputs from Authentication ----------------
	input verified;            // HIGH after successful PW (LoggedIn)
	input id_passed;           // HIGH after ID match, before PW pass (NEW)
	
	// ---------------- Inputs from difficulty switches ----------------
	input [1:0] difficulty_in;
	
	// ---------------- Outputs to other modules ----------------
	output reg timer_enable, timer_reconfig;
	output reg enable_mega_compar;
	output reg pulse_w_ram, pulse_scrl_ram;
	output reg [1:0] difficulty_out;
	output reg logout_req;
	output reg score_soft_rst;
	
	// ---------------- One-hot mode output (NEW) ----------------
	output reg [6:0] display_mode;
	
	// ============================================================
	// State encoding
	//   Existing state numbers preserved (UNAUTH=1 .. LBOARD=6);
	//   ID_IN tucked in at 7 to avoid renumbering existing tests.
	// ============================================================
	parameter UNAUTHENTICATED	= 4'd1;
	parameter AUTHENTICATED		= 4'd2;
	parameter WAIT_FOR_START	= 4'd3;
	parameter GAME_RUNNING		= 4'd4;
	parameter END_GAME			= 4'd5;	// renamed from GAME_OVER
	parameter LBOARD			= 4'd6;	// renamed from WAIT_TO_RESTART
	parameter ID_IN				= 4'd7;	// NEW state
	
	// ---------------- Logic-level aliases ----------------
	parameter HIGH = 1'b1;
	parameter LOW  = 1'b0;
	
	// ---------------- Difficulty levels ----------------
	parameter NOT_SELECTED	= 2'b00;
	parameter EASY			= 2'b01;
	parameter MEDIUM		= 2'b10;
	parameter HARD			= 2'b11;
	
	// ---------------- One-hot display_mode patterns ----------------
	parameter MODE_UNAUTHED  = 7'b000_0001;
	parameter MODE_ID_IN     = 7'b000_0010;
	parameter MODE_AUTHED    = 7'b000_0100;
	parameter MODE_PRE_GAME  = 7'b000_1000;
	parameter MODE_PLAYING   = 7'b001_0000;
	parameter MODE_END_GAME  = 7'b010_0000;
	parameter MODE_LBOARD    = 7'b100_0000;
	
	// ============================================================
	// END_GAME hold counter
	//   50,000,000 cycles at 50 MHz = 1.0 s. Sim-speed value
	//   commented for quick simulation runs.
	// ============================================================
	//parameter END_GAME_HOLD = 26'd3;          // sim-speed (4 cycles)
	parameter END_GAME_HOLD = 26'd49_999_999;   // production: 1 s @ 50 MHz
	
	reg [25:0] end_game_counter;
	
	// ---------------- State register ----------------
	reg [3:0] state          = UNAUTHENTICATED;
	reg [1:0] game_difficulty = EASY;
	
	// ============================================================
	// Single-always-block FSM
	// ============================================================
	always @(posedge clk) begin
		// ---------------- Active-low hard reset ----------------
		if (rst == LOW) begin
			state				<= UNAUTHENTICATED;
			timer_enable		<= LOW;
			timer_reconfig		<= LOW;
			enable_mega_compar	<= LOW;
			pulse_w_ram			<= LOW;
			pulse_scrl_ram		<= LOW;
			difficulty_out		<= NOT_SELECTED;
			game_difficulty		<= EASY;
			logout_req			<= LOW;
			score_soft_rst		<= HIGH;
			display_mode		<= MODE_UNAUTHED;
			end_game_counter	<= 26'd0;
		end
		else begin
			case (state)
				
				// ============================================
				// UNAUTHENTICATED -- waiting for ID match
				// ============================================
				UNAUTHENTICATED: begin
					timer_enable		<= LOW;
					timer_reconfig		<= LOW;
					enable_mega_compar	<= LOW;
					pulse_w_ram			<= LOW;
					pulse_scrl_ram		<= LOW;
					difficulty_out		<= NOT_SELECTED;
					logout_req			<= LOW;
					score_soft_rst		<= HIGH;
					display_mode		<= MODE_UNAUTHED;
					end_game_counter	<= 26'd0;
					
					// next state: ID got accepted by Authentication
					if (id_passed == HIGH)
						state <= ID_IN;
					else
						state <= UNAUTHENTICATED;
				end
				
				// ============================================
				// ID_IN -- ID accepted, entering password
				//   Outputs match UNAUTHENTICATED almost exactly
				//   (still pre-auth, pre-game). Only display_mode
				//   changes so the LED moves.
				// ============================================
				ID_IN: begin
					timer_enable		<= LOW;
					timer_reconfig		<= LOW;
					enable_mega_compar	<= LOW;
					pulse_w_ram			<= LOW;
					pulse_scrl_ram		<= LOW;
					difficulty_out		<= NOT_SELECTED;
					logout_req			<= LOW;
					score_soft_rst		<= HIGH;
					display_mode		<= MODE_ID_IN;
					end_game_counter	<= 26'd0;
					
					// next state
					if (verified == HIGH) begin
						// PW just passed -- enter AUTHENTICATED with
						// the one-cycle timer reload.
						state			<= AUTHENTICATED;
						timer_reconfig	<= HIGH;
					end
					else if (id_passed == LOW) begin
						// Authentication reset back to ID phase
						// (4-strike fail or other internal reset)
						state <= UNAUTHENTICATED;
					end
					else begin
						state <= ID_IN;
					end
				end
				
				// ============================================
				// AUTHENTICATED -- one-cycle timer reload
				// ============================================
				AUTHENTICATED: begin
					timer_enable		<= LOW;
					timer_reconfig		<= LOW;	// drop pulse after 1 cycle
					enable_mega_compar	<= LOW;
					pulse_w_ram			<= LOW;
					pulse_scrl_ram		<= LOW;
					difficulty_out		<= NOT_SELECTED;
					logout_req			<= LOW;
					score_soft_rst		<= HIGH;
					display_mode		<= MODE_AUTHED;
					end_game_counter	<= 26'd0;
					
					// next state
					if (verified == LOW)
						state <= UNAUTHENTICATED;	// logout cascade fired
					else
						state <= WAIT_FOR_START;
				end
				
				// ============================================
				// WAIT_FOR_START -- difficulty selection,
				// awaiting start key
				// ============================================
				WAIT_FOR_START: begin
					timer_enable		<= LOW;
					timer_reconfig		<= LOW;
					enable_mega_compar	<= LOW;
					pulse_w_ram			<= LOW;
					pulse_scrl_ram		<= LOW;
					logout_req			<= LOW;
					score_soft_rst		<= HIGH;
					display_mode		<= MODE_PRE_GAME;
					end_game_counter	<= 26'd0;
					
					// latch difficulty from switches
					if (difficulty_in != NOT_SELECTED) begin
						game_difficulty	<= difficulty_in;
						difficulty_out	<= difficulty_in;
					end
					else begin
						difficulty_out	<= game_difficulty;
					end
					
					// next state
					if (id_log_inout == HIGH) begin
						// logout pressed
						state		<= UNAUTHENTICATED;
						logout_req	<= HIGH;
					end
					else if (game_start_key == HIGH && difficulty_in != NOT_SELECTED) begin
						state <= GAME_RUNNING;
					end
					else begin
						state <= WAIT_FOR_START;
					end
				end
				
				// ============================================
				// GAME_RUNNING -- gameplay active
				// ============================================
				GAME_RUNNING: begin
					timer_enable		<= HIGH;
					timer_reconfig		<= LOW;
					enable_mega_compar	<= HIGH;
					pulse_w_ram			<= LOW;
					pulse_scrl_ram		<= LOW;
					difficulty_out		<= game_difficulty;
					logout_req			<= LOW;
					score_soft_rst		<= LOW;
					display_mode		<= MODE_PLAYING;
					end_game_counter	<= 26'd0;
					
					// next state
					if (timer_done == HIGH) begin
						// round timer hit zero -> end of game
						state				<= END_GAME;
						timer_enable		<= LOW;
						enable_mega_compar	<= LOW;
						pulse_w_ram			<= HIGH;	// one-cycle write pulse
					end
					else if (verified == LOW) begin
						// logout cascade fired during play
						state <= UNAUTHENTICATED;
					end
					else begin
						state <= GAME_RUNNING;
					end
				end
				
				// ============================================
				// END_GAME -- 1-second hold before LBOARD
				//   pulse_w_ram was raised on entry from
				//   GAME_RUNNING; drop it back to LOW now so
				//   ScoreRAM sees a single-cycle pulse.
				// ============================================
				END_GAME: begin
					timer_enable		<= LOW;
					timer_reconfig		<= LOW;
					enable_mega_compar	<= LOW;
					pulse_w_ram			<= LOW;	// trailing edge of write pulse
					pulse_scrl_ram		<= LOW;
					difficulty_out		<= game_difficulty;
					logout_req			<= LOW;
					score_soft_rst		<= LOW;	// preserve final score
					display_mode		<= MODE_END_GAME;
					
					// hold counter -> LBOARD when it expires
					if (end_game_counter == END_GAME_HOLD) begin
						state				<= LBOARD;
						end_game_counter	<= 26'd0;
					end
					else begin
						end_game_counter	<= end_game_counter + 1;
					end
				end
				
				// ============================================
				// LBOARD -- leaderboard view
				//   game_control_key = scroll  -> stay, pulse scroll
				//   game_start_key   = restart -> WAIT_FOR_START
				//   id_log_inout HIGH = logout  -> UNAUTHENTICATED
				// ============================================
				LBOARD: begin
					timer_enable		<= LOW;
					timer_reconfig		<= LOW;
					enable_mega_compar	<= LOW;
					pulse_w_ram			<= LOW;
					pulse_scrl_ram		<= LOW;
					difficulty_out		<= game_difficulty;
					logout_req			<= LOW;
					score_soft_rst		<= LOW;	// preserve scores for display
					display_mode		<= MODE_LBOARD;
					end_game_counter	<= 26'd0;
					
					// next state
					if (id_log_inout == HIGH) begin
						// logout pressed -> back to UNAUTHENTICATED
						state		<= UNAUTHENTICATED;
						logout_req	<= HIGH;
					end
					else if (game_start_key == HIGH) begin
						// restart with same difficulty -> back to PRE_GAME
						state			<= WAIT_FOR_START;
						timer_reconfig	<= HIGH;	// reload timer to 99
					end
					else if (game_control_key == HIGH) begin
						// scroll to next leaderboard entry
						state			<= LBOARD;
						pulse_scrl_ram	<= HIGH;	// one-cycle pulse
					end
					else begin
						state <= LBOARD;
					end
				end
				
				// ============================================
				// default -- safety net
				// ============================================
				default: begin
					state				<= UNAUTHENTICATED;
					timer_enable		<= LOW;
					timer_reconfig		<= LOW;
					enable_mega_compar	<= LOW;
					pulse_w_ram			<= LOW;
					pulse_scrl_ram		<= LOW;
					difficulty_out		<= NOT_SELECTED;
					logout_req			<= LOW;
					score_soft_rst		<= HIGH;
					display_mode		<= MODE_UNAUTHED;
					end_game_counter	<= 26'd0;
				end
				
			endcase
		end
	end
	
endmodule
