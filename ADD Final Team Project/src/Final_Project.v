// Final Project Top-Level Module
/*
================================================================
Course:        ECE 6370 Advanced Digital Design
Author:        Zaki Mir
PeopleSoft ID: 1675819
Project:       Final Project - "Hex Sequence"
File:          Hex_Sequence_top.v
Target:        Terasic DE0-CV (Cyclone V 5CEBA4F23C7N)
Rev:           3  -- Lab 4 style header + named binding
================================================================

Project Description:
  Single-player hex-sequence memory game (Simon-Says variant) on
  the DE0-CV. The player logs in with a 4-digit ID and 4-digit
  password (both stored in ROM, walked by sequential FSMs). After
  picking a difficulty (easy/medium/hard), the player has 99
  seconds to score as many rounds as possible. Each round the
  RNG shows four scrambled nibbles on HEX0 at a difficulty-paced
  interval; the player then re-enters those four nibbles on
  SW[3:0] using KEY[1]. Successful matches add to a difficulty-
  weighted score. At round end, a per-player and global high
  score are written to BRAM. The leaderboard view lets the
  player toggle between their own best and the all-time best.

____________________________________________________________
Inputs:
  CLOCK_50            -- 50 MHz system clock                            (same as Lab 4)
  KEY[0]              -- RESET, active-LOW                               (same as Lab 4)
  KEY[1]              -- game-action button (shaped):                    (modified from Lab 4)
                          -- player digit entry during PLAYING
                          -- leaderboard scroll during LBOARD
  KEY[2]              -- game start / round restart (shaped)             (modified from Lab 4)
  KEY[3]              -- dual-role button:                               (new)
                          -- shaped: ID/PW digit entry during auth
                          -- raw active-LOW: logout from WAIT_FOR_START
                            or LBOARD
  SW[3:0]             -- player nibble input during PLAYING              (same as Lab 4)
  SW[5:4]             -- difficulty select (00=none,                     (new)
                          01=easy/20s, 10=med/15s, 11=hard/10s)
  SW[9:6]             -- ID / password digit entry                       (same as Lab 4)

Outputs:
  HEX5..HEX0  [6:0]   -- six 7-seg displays, layout depends on phase     (modified from Lab 4)
                         (see DisplayCnt.v for state-by-state HEX map;
                          summary: blank during auth, "99" in PRE_GAME,
                          countdown+RNG in PLAYING, "00" in END_GAME,
                          ID+score in LBOARD)
  LEDR[6:0]           -- one-hot phase indicator from gameControl:       (new)
                          LEDR[0]=UNAUTHED, LEDR[1]=ID_IN,
                          LEDR[2]=AUTHED,   LEDR[3]=PRE_GAME,
                          LEDR[4]=PLAYING,  LEDR[5]=END_GAME,
                          LEDR[6]=LBOARD
  LEDR[9:7]           -- tied LOW (unused)                               (modified from Lab 4)

Module Instances:
  btn_shaper x 3      -- shape KEY[1], KEY[2], KEY[3] into single-
                         cycle HIGH pulses on press
                         (KEY[0] passes through raw as reset)
  Authentication     -- ID + PW match against PlayerID_ROM /
                         Password_ROM; emits LoggedIn, ID_passed,
                         PlayerID, NumberID
  gameControl        -- master FSM, 7 states, one-hot display_mode
                         output drives LEDR and DisplayCnt
  twoDigitTimer      -- 99 -> 00 countdown using 1 ms LFSR tick +
                         100 ms counter; emits ones/tens/done
  megaComparator     -- gameplay engine wrapping Comparator (RNG,
                         nibble slicing, player match) +
                         score_unit_rev1 (saturating accumulator)
  scoreRAM_top       -- 32 x 24-bit BRAM + 9-state FSM; per-player
                         high score plus global best
  ScoreRAM_adapter   -- toggles between MyBest and GlobalBest on
                         scroll pulse; opens at MyBest on round end
  DisplayCnt         -- HEX renderer; picks one of 7 layouts based
                         on display_mode

KEY[3] dual-role rationale:
  In UNAUTH and ID_IN, Authentication reads B_in_shaped to advance
  digit entry; gameControl in those states does NOT read
  id_log_inout. In WAIT_FOR_START and LBOARD, gameControl reads
  id_log_inout for logout; Authentication is in PWPASSED in those
  states and does NOT react to B_in_shaped. The two consumers
  are mutually exclusive by state, so a single press of KEY[3]
  is unambiguous in every gameControl state.

KEY[1] dual-role rationale:
  player_load_in is read by Comparator only in CatchPlayerInput
  (active when gameControl is in GAME_RUNNING). game_control_key
  is read by gameControl only in LBOARD. The two states are
  mutually exclusive.

All instantiations use named-port binding to prevent
positional-mismatch errors during integration.
------------------------------------------------------------
*/
module Final_Project(CLOCK_50, KEY, SW, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
	input        CLOCK_50;            // 50 MHz system clock
	input  [3:0] KEY;                 // KEY[0]=RESET, [1]=game action, [2]=start, [3]=auth/logout
	input  [9:0] SW;                  // SW[3:0]=player, [5:4]=difficulty, [9:6]=auth digit
	
	output [9:0] LEDR;                // LEDR[6:0]=display_mode (one-hot phase), [9:7] tied LOW
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;   // driven by DisplayCnt per state
	
	// ============================================================
	// Wire declarations
	// ============================================================
	
	// shaped button outputs
	wire key1_shaped, key2_shaped, key3_shaped;
	
	// switch-derived signals
	wire [3:0] digit_auth   = SW[9:6];   // ID/PW digit (Auth)
	wire [3:0] digit_play   = SW[3:0];   // game nibble (Comparator)
	wire [1:0] difficulty   = SW[5:4];
	//wire       id_log_inout = KEY[3];    // raw active-LOW logout to gameControl
	
	// from Authentication
	wire        LoggedIn, LoggedOut, ID_passed;
	wire [4:0]  PlayerID_to_scoreRAM;
	wire [15:0] NumberID_to_scoreRAM;
	
	// from gameControl
	wire        timer_enable, timer_reconfig;
	wire        enable_mega_compar;
	wire        pulse_w_ram, pulse_scrl_ram;
	wire [1:0]  difficulty_out;
	wire        logout_req;
	wire        score_soft_rst;
	wire [6:0]  display_mode;
	
	// from twoDigitTimer
	wire [3:0] ones_count, tens_count;
	wire       timer_done;
	
	// from megaComparator
	wire [7:0] score;
	wire [3:0] display_random;
	
	// from scoreRAM_top
	wire [23:0] my_best, global_best;
	
	// from ScoreRAM_adapter
	wire [23:0] lboard_entry;
	
	
	// ============================================================
	// Module signature reference (for quick scan of port orders):
	//
	// btn_shaper(clk, rst, b_in, b_out)
	// Authentication(Digit, B_in_shaped, Logout_Req_from_GameCtrl, clk, reset,
	//                LoggedIn, LoggedOut, ID_passed,
	//                PlayerID_to_scoreRAM, NumberID_to_scoreRAM)
	// gameControl(clk, rst, timer_done, id_log_inout, game_start_key,
	//             game_control_key, verified, id_passed, difficulty_in,
	//             timer_enable, timer_reconfig, enable_mega_compar,
	//             pulse_w_ram, pulse_scrl_ram, difficulty_out,
	//             logout_req, score_soft_rst, display_mode)
	// twoDigitTimer(clk, rst, time_reconfig, timer_enable,
	//               ones_count, tens_count, timer_done)
	// megaComparator(clk, rst, enable, difficulty, score_soft_rst,
	//                player_in, player_load_in, score, display_random)
	// scoreRAM_top(pulse_WRAM_from_GameCtrl, pulse_sctrl_RAM_from_GameCtrl,
	//              PlayerID_from_Auth, NumberID_from_Auth, LatestScore,
	//              clk, reset, MyBest_to_DispCnt, GlobalBest_to_DispCnt)
	// ScoreRAM_adapter(clk, rst, pulse_w_ram, pulse_scrl_ram,
	//                  my_best, global_best, lboard_entry)
	// DisplayCnt(clk, rst, display_mode, ones_count, tens_count,
	//            DisplayRandom, lboard_entry, HEX0..HEX5)
	// ============================================================
	
	
	// ============================================================
	// Button shapers -- KEY[0] is reset (no shape), KEY[1..3] shaped
	// ============================================================
	btn_shaper u_bs_key1 (
		.clk   (CLOCK_50),
		.rst   (KEY[0]),
		.b_in  (KEY[1]),
		.b_out (key1_shaped)
	);
	
	btn_shaper u_bs_key2 (
		.clk   (CLOCK_50),
		.rst   (KEY[0]),
		.b_in  (KEY[2]),
		.b_out (key2_shaped)
	);
	
	btn_shaper u_bs_key3 (
		.clk   (CLOCK_50),
		.rst   (KEY[0]),
		.b_in  (KEY[3]),
		.b_out (key3_shaped)
	);
	
	
	// ============================================================
	// Authentication -- 4-digit ID + 4-digit PW match
	//   Digit feed comes from SW[9:6] (digit_auth), separate from
	//   the gameplay SW[3:0] feed. B_in_shaped is the KEY[3]
	//   shaped pulse.
	// ============================================================
	Authentication u_auth (
		.Digit                    (digit_auth),
		.B_in_shaped              (key2_shaped),
		.Logout_Req_from_GameCtrl (logout_req),
		.clk                      (CLOCK_50),
		.reset                    (KEY[0]),
		.LoggedIn                 (LoggedIn),
		.LoggedOut                (LoggedOut),
		.ID_passed                (ID_passed),
		.PlayerID_to_scoreRAM     (PlayerID_to_scoreRAM),
		.NumberID_to_scoreRAM     (NumberID_to_scoreRAM)
	);
	
	
	// ============================================================
	// gameControl -- master FSM. Drives display_mode (one-hot phase)
	// to both DisplayCnt and LEDR[6:0]. game_control_key shares
	// the KEY[1] shaped pulse with player_load_in.
	// ============================================================
	gameControl u_ctrl (
		.clk                (CLOCK_50),
		.rst                (KEY[0]),
		.timer_done         (timer_done),
		.id_log_inout       (key3_shaped),       // raw KEY[3], active-LOW
		.game_start_key     (key2_shaped),
		.game_control_key   (key1_shaped),
		.verified           (LoggedIn),
		.id_passed          (ID_passed),
		.difficulty_in      (difficulty),
		.timer_enable       (timer_enable),
		.timer_reconfig     (timer_reconfig),
		.enable_mega_compar (enable_mega_compar),
		.pulse_w_ram        (pulse_w_ram),
		.pulse_scrl_ram     (pulse_scrl_ram),
		.difficulty_out     (difficulty_out),
		.logout_req         (logout_req),
		.score_soft_rst     (score_soft_rst),
		.display_mode       (display_mode)
	);
	
	
	// ============================================================
	// twoDigitTimer -- 99 -> 00 countdown
	//   Named-port bridge: gameControl drives "timer_reconfig"
	//   but twoDigitTimer's input is "time_reconfig" (no 'r').
	// ============================================================
	twoDigitTimer u_timer (
		.clk            (CLOCK_50),
		.rst            (KEY[0]),
		.time_reconfig  (timer_reconfig),     // <-- name bridge
		.timer_enable   (timer_enable),
		.ones_count     (ones_count),
		.tens_count     (tens_count),
		.timer_done     (timer_done)
	);
	
	
	// ============================================================
	// megaComparator -- gameplay engine (RNG + slicing + match +
	// saturating score). player_load_in shares KEY[1] with the
	// leaderboard scroll signal.
	// ============================================================
	megaComparator u_mega (
		.clk             (CLOCK_50),
		.rst             (KEY[0]),
		.enable          (enable_mega_compar),
		.difficulty      (difficulty_out),
		.score_soft_rst  (score_soft_rst),
		.player_in       (digit_play),          // SW[3:0]
		.player_load_in  (key1_shaped),
		.score           (score),
		.display_random  (display_random)
	);
	
	
	// ============================================================
	// scoreRAM_top -- per-player and global high-score storage
	//   (Tru's module; ZM bug fixes applied: port width,
	//    blocking->non-blocking, MyBest_reg refresh,
	//    BestPlayer_reg init, RAMINIT data 0x000000.)
	// ============================================================
	scoreRAM_top u_scoreram (
		.pulse_WRAM_from_GameCtrl       (pulse_w_ram),
		.pulse_sctrl_RAM_from_GameCtrl  (pulse_scrl_ram),
		.PlayerID_from_Auth             (PlayerID_to_scoreRAM),
		.NumberID_from_Auth             (NumberID_to_scoreRAM),
		.LatestScore                    (score),
		.clk                            (CLOCK_50),
		.reset                          (KEY[0]),
		.MyBest_to_DispCnt              (my_best),
		.GlobalBest_to_DispCnt          (global_best)
	);
	
	
	// ============================================================
	// ScoreRAM_adapter -- bridges Tru's 2 parallel outputs
	// (MyBest + GlobalBest) to DisplayCnt's single lboard_entry
	// input. Internal 1-bit toggle flips on scroll pulse.
	// ============================================================
	ScoreRAM_adapter u_adapter (
		.clk             (CLOCK_50),
		.rst             (KEY[0]),
		.pulse_w_ram     (pulse_w_ram),
		.pulse_scrl_ram  (pulse_scrl_ram),
		.my_best         (my_best),
		.global_best     (global_best),
		.lboard_entry    (lboard_entry)
	);
	
	
	// ============================================================
	// DisplayCnt -- HEX renderer; layout switches on display_mode
	// ============================================================
	DisplayCnt u_disp (
		.clk            (CLOCK_50),
		.rst            (KEY[0]),
		.display_mode   (display_mode),
		.ones_count     (ones_count),
		.tens_count     (tens_count),
		.DisplayRandom  (display_random),
		.lboard_entry   (lboard_entry),
		.HEX0           (HEX0),
		.HEX1           (HEX1),
		.HEX2           (HEX2),
		.HEX3           (HEX3),
		.HEX4           (HEX4),
		.HEX5           (HEX5)
	);
	
	
	// ============================================================
	// LED phase indicator
	// ============================================================
	assign LEDR[6:0] = display_mode;
	reg [7:0] score_at_write;
	always @(posedge CLOCK_50) begin
		 if (KEY[0] == 1'b0)
			  score_at_write <= 8'd0;
		 else if (pulse_w_ram == 1'b1)
			  score_at_write <= score;  // snapshot score the cycle write fires
	end

	assign LEDR[7] = score_at_write[0];
	assign LEDR[8] = score_at_write[1];
	assign LEDR[9] = score_at_write[2];
	
endmodule
