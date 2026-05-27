/*
================================================================
Course      : ECE 6370 Advanced Digital Design
Author      : Zaki Mir
PeopleSoft  : 1675819
Project     : Final Project - megaComparator wrapper
================================================================

***************   Functionality Description   ******************
megaComparator is the integration wrapper for the gameplay
engine. It contains:

  - Comparator (teammate): the round FSM that samples a 16-bit
    RNG, slices it into four scrambled nibbles, displays them on
    DisplayRandom one at a time at the difficulty-controlled
    interval, then collects the player's four inputs on
    PlayerLoad_in pulses and emits ScorePulse for one cycle on a
    successful match. Comparator instantiates its own RNG_Comparator
    (free-running LFSR) and GameTimer (difficulty-controlled
    inter-display timer) internally, so this wrapper does not need
    to wire those.

  - score_unit (Ajay): saturating 8-bit accumulator that adds
    'difficulty' to 'score' on each ScorePulse, clamped at 255.
    Cleared between rounds by score_soft_rst from gameControl.

----------------------------------------------------------------
*********  Input / Output Signal Map & Description   ***********

INPUTS:
  {common}
    clk, rst             <-- system clock, active-low reset

  {from gameControl}
    enable               <-- gameControl.enable_mega_compar
    difficulty[1:0]      <-- gameControl.difficulty_out
                             (01=easy, 10=med, 11=hard;
                              gameControl floors to 01 internally)
    score_soft_rst       <-- gameControl.score_soft_rst
                             (HIGH between rounds, LOW during play;
                              clears the running round score)

  {from external pins}
    player_in[3:0]       <-- DE0-CV SW3:SW0 (player's hex digit)
    player_load_in       <-- shaped KEY1 pulse (1-cycle HIGH on
                             press; produced by btn_shaper)

OUTPUTS:
  {to ScoreRAM}
    score[7:0]           --> running round score, saturates at 255

  {to DisplayCnt}
    display_random[3:0]  --> currently displayed RNG nibble
                             (or 4'h8 idle pattern between
                             displays / outside of gameplay)

----------------------------------------------------------------
Internal:
    score_pulse  <- Comparator.ScorePulse, 1-cycle on each match,
                    fed straight into score_unit.pulse
================================================================
*/
module megaComparator(
    clk, rst,
    enable, difficulty, score_soft_rst,
    player_in, player_load_in,
    score, display_random
);
    // ---- common ----
    input  clk, rst;

    // ---- from gameControl ----
    input        enable;
    input  [1:0] difficulty;
    input        score_soft_rst;

    // ---- from external pins ----
    input  [3:0] player_in;
    input        player_load_in;

    // ---- outputs ----
    output [7:0] score;
    output [3:0] display_random;

    // ---- internal pulse: Comparator -> score_unit ----
    wire score_pulse;

    // ---- Comparator: round FSM (RNG + GameTimer embedded) ----
    Comparator u_comparator(
        .rst           (rst),
        .clk           (clk),
        .Enable        (enable),
        .GameDifficulty(difficulty),
        .Player_in     (player_in),
        .PlayerLoad_in (player_load_in),
        .ScorePulse    (score_pulse),
        .DisplayRandom (display_random)
    );

    // ---- score_unit: saturating accumulator ----
    score_unit u_score_unit(
        .clk       (clk),
        .rst       (rst),
        .soft_rst  (score_soft_rst),
        .pulse     (score_pulse),
        .multiplier(difficulty),
        .score     (score)
    );

endmodule