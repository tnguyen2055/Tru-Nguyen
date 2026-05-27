/*
================================================================
Course      : ECE 6370 Advanced Digital Design
Author      : Ajay Doppalapudi
PeopleSoft  :
Project     : Final Project - score tracker module
================================================================

***************   Functionality Description   ******************
Tracks the running score for the current round.

- 'pulse' input adds the current 'multiplier' value to the score.
- 'multiplier[1:0]' is added directly (no lookup); valid values
  are 2'b01, 2'b10, 2'b11 (set by upstream difficulty logic).
- 'soft_rst' clears the score to zero without a system reset
  (used between rounds by GameControl).
- Active-low 'rst' clears the score on system reset.
- Score saturates at 8'd255 (no rollover).
- All behavior is contained in a single sequential procedure.

Personal high, leaderboard, and per-player storage are handled
externally in ScoreRAM, which simply reads 'score' from this
module.
================================================================
*/
module score_unit(clk, rst, soft_rst, pulse, multiplier, score);

    input  clk, rst, soft_rst, pulse;
    input  [1:0] multiplier;
    output reg [7:0] score;

    parameter HIGH = 1'b1;
    parameter LOW  = 1'b0;

    initial begin
        score = 8'd0;
    end

    always @(posedge clk) begin
        if (rst == LOW) begin
            // Hard reset from system
            score <= 8'd0;
        end
        else if (soft_rst == HIGH) begin
            // Internal soft reset (e.g. start of a new round)
            score <= 8'd0;
        end
        else if (pulse == HIGH) begin
            // Saturate at 255 to prevent rollover.
            // Width-extend the threshold so the compare doesn't
            // truncate to 8 bits and miss the overflow case.
            if (score > (8'd255 - {6'b0, multiplier}))
                score <= 8'd255;
            else
                score <= score + multiplier;
        end
    end

endmodule
