
module ButtonShaper(B_in, B_out, clk, reset);
  input B_in, clk, reset;
  output B_out;
  reg B_out;
  parameter INIT = 0, PULSE = 1, WAIT = 2;
  reg [1:0] State, NextState;
  
  always @(State, B_in) begin
    case(State)
      INIT: begin
      B_out = 1'b0;
      if (B_in == 1'b0)
        NextState = PULSE;
      else
	NextState = INIT;
      end
      
      PULSE: begin
      B_out = 1'b1;
      NextState = WAIT;
      end

      WAIT: begin
      B_out = 1'b0;
      if (B_in == 1'b0)      
        NextState = WAIT;
      else
        NextState = INIT;
      end
    endcase
  end

  always @(posedge clk) begin
    if (reset == 1'b0)
      State <= INIT;
    else
      State <= NextState;
    end
  
endmodule
