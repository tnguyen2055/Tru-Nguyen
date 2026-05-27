

module LFSR_RNG(RNG_Gen, clk, reset, Rand_Num);
  input RNG_Gen, clk, reset;
  output [3:0] Rand_Num;

  wire enable;
  wire [3:0] Rand_out;
  
  LFSR_Counter LFSR_Counter_top(enable, clk, reset, Rand_out);

  assign enable = ~RNG_Gen;
  assign Rand_Num = Rand_out;
  
endmodule
