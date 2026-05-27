

module RNG(RNG_Gen, clk, reset, Rand_Numb);
  input RNG_Gen, clk, reset;
  output [3:0] Rand_Numb;

  wire Count;
  wire [3:0] Count_out;

  Counter Counter_top(Count, clk, reset, Count_out);

  assign Count = ~RNG_Gen;
  assign Rand_Numb = Count_out;

endmodule
