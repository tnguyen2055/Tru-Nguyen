/*
================================================================
Course      : ECE 6370 Advanced Digital Design
Author      : Ajay Doppalapudi
PeopleSoft  : 2383998
Project     : Final Project - rng module
================================================================

***************   Functionality Description   ******************
16-bit LFSR random number generator.

- LFSR runs continuously (advances every clock cycle).
- Power-up state is 16'hFFFF via initial block (no system input
  required to start).
- Optional active-low rst forces state back to 16'hFFFF.
- A single 'pulse' input captures the current LFSR state into the
  output register, where it is held until the next pulse.
- Maximal-length polynomial: x^16 + x^14 + x^13 + x^11 + 1
  (taps on bits 15, 13, 12, 10), 65535-state cycle.
================================================================
*/
module lfsr_rng(clk, rst, pulse, rng_out);

    input  clk, rst, pulse;
    output reg [15:0] rng_out;

    parameter HIGH = 1'b1;
    parameter LOW  = 1'b0;
    parameter SEED = 16'hFFFF;

    reg [15:0] lfsr_reg;

    // Power-up initialization (no input required from system)
    initial begin
        lfsr_reg = SEED;
        rng_out  = SEED;
    end

    always @(posedge clk) begin
        if (rst == LOW) begin
            lfsr_reg <= SEED;
            rng_out  <= SEED;
        end
        else begin
            // LFSR shifts every cycle -- continuously running
            lfsr_reg <= {lfsr_reg[14:0],
                         lfsr_reg[15] ^ lfsr_reg[13] ^
                         lfsr_reg[12] ^ lfsr_reg[10]};

            // Output captures the LFSR state on pulse and holds
            // it until the next pulse arrives.
            if (pulse == HIGH) begin
                rng_out <= lfsr_reg;
            end
        end
    end

endmodule
