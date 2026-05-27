module LoadRegister(D_in, D_out, clk, reset, Load);
  input [3:0] D_in;
  output [3:0] D_out;
  input clk, reset, Load;
  reg [3:0] D_out;

  always@(posedge clk) // sequential logic "always" blocks only include clk or sometimes reset in the sensitivity list
    begin
      if (reset == 1'b0)
	begin
          D_out <= 4'b0000;
        end
      else
	begin
	  if (Load == 1'b1)
            begin
	      D_out <= D_in;
	    end
        end  // "else" statement in an "if" statement is optional in sequential logic
    end
endmodule
