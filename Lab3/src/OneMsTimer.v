// ECE 6370
// Author: Tru Nguyen
// Module name: OneMsTimer
// Function: generates a 1 millisecond timeout pulse by counting clock cycles when enabled. When the internal counter reaches its maximum value, it resets and asserts OneMsTimeOut for one clock cycle.

module OneMsTimer(enable, clk, reset, OneMsTimeOut, Count_out);
  input enable, clk, reset;
  output reg OneMsTimeOut;
  output reg [15:0] Count_out;
  //output [2:0] Count_out; // for sim only
  //reg OneMsTimeOut;
  //reg [15:0] Count_out;
  //reg [2:0] Count_out; // for sim only

  always @(posedge clk) begin
    if (reset == 1'b0) begin
      Count_out <= 16'd0;
      OneMsTimeOut <= 1'b0;
    end
    else begin
      if (enable == 1'b1) begin
	if (Count_out == 16'd50000) begin
	  Count_out <= 16'd0;
	  OneMsTimeOut <= 1'b1;
	end
	else begin
	  Count_out <= Count_out+1;
	  OneMsTimeOut <= 1'b0;
	end
      end
    end
  end

endmodule
