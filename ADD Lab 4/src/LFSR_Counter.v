

module LFSR_Counter(enable, clk, reset, Rand_out);
  input enable, clk, reset;
  output [3:0] Rand_out;

  reg [3:0] LFSR;

  wire feedback = LFSR[3];

  always @(posedge clk) begin
    if (reset == 1'b0) begin
      LFSR <= 4'b0000;
    end

    else begin
      if (enable == 1'b1) begin
        LFSR[0] <= feedback;
        LFSR[1] <= LFSR[0] ~^ feedback;
        LFSR[2] <= LFSR[1];
        LFSR[3] <= LFSR[2];
      end
        
    end
  end
 
  assign Rand_out = LFSR;

endmodule
