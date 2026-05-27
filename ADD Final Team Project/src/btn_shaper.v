/*
================================================================
Course      : ECE 6370 Advanced Digital Design
Author      : Zaki Mir
PeopleSoft  : 1675819
Project     : Final Project - btn_shaper
================================================================

***************   Functionality Description   ******************
Active-HIGH single-cycle button shaper for shared KEY1 routing.

DE0-CV KEYs are active-LOW. This shaper takes the raw key signal
and produces a one-clock-cycle HIGH pulse on the falling edge of
the input (i.e. the moment the player presses), then re-arms only
after the player releases.

Used for KEY1, which feeds:
  - Authentication.B_in_shaped (during login flow)
  - Comparator.PlayerLoad_in   (during gameplay)
Both consumers expect active-HIGH pulses, so this is the correct
polarity for the shaped path. gameControl reads RAW KEY1 directly
(active-LOW) on its own path -- those routes do NOT pass through
this shaper.

State machine:
  IDLE  : output LOW; waiting for press (b_in falling edge)
  PULSE : output HIGH for exactly one clock cycle
  WAIT  : output LOW; waiting for release (b_in rising edge)

Polarity-flipped, registered-output rework of Lab 2 sim_bs.v.
Output is registered so it's glitch-free for downstream
synchronous consumers.
================================================================
*/
module btn_shaper(clk, rst, b_in, b_out);
    input  clk, rst, b_in;
    output reg b_out;            // active-HIGH 1-cycle pulse on press

    parameter HIGH = 1'b1;
    parameter LOW  = 1'b0;

    parameter IDLE  = 2'd0;
    parameter PULSE = 2'd1;
    parameter WAIT  = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst == LOW) begin
            state <= IDLE;
            b_out <= LOW;
        end
        else begin
            case (state)
                IDLE: begin
                    b_out <= LOW;
                    // raw b_in is active-LOW; press = HIGH->LOW edge
                    if (b_in == LOW) begin
                        state <= PULSE;
                    end
                end

                PULSE: begin
                    b_out <= HIGH;            // single-cycle output
                    state <= WAIT;
                end

                WAIT: begin
                    b_out <= LOW;
                    if (b_in == HIGH) begin   // re-arm after release
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                    b_out <= LOW;
                end
            endcase
        end
    end
endmodule