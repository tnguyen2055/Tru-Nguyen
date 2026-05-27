// ECE 6370
// Author: Tru Nguyen
// Module name: countTo100
// Function: counts incoming 1 ms timeout pulses and generates a 100 ms timeout signal. When the count reaches its limit, it resets and produces a one-cycle output pulse.
// (Note: Counter size is reduced for simulation purposes.)

module countTo100(OneMsTimeOut, clk, reset, HundredMsTimeOut, Count_out);
  input OneMsTimeOut, clk, reset;
  output reg HundredMsTimeOut;
  output reg [6:0] Count_out;
  //output [1:0] Count_out; // for sim only
  //reg HundredMsTimeOut;
  //reg [6:0] Count_out;
  //reg [1:0] Count_out; // for sim only

  always @(posedge clk) begin
    if (reset == 1'b0) begin
      Count_out <= 7'd0;
      HundredMsTimeOut <= 1'b0;
    end
    else begin
      if (OneMsTimeOut == 1'b1) begin
        if (Count_out == 7'd100) begin
 	  Count_out <= 7'd0;
 	  HundredMsTimeOut <= 1'b1;
	end
	else begin
	  Count_out <= Count_out+1;
	  HundredMsTimeOut <= 1'b0;
	end
      end
      else begin
	HundredMsTimeOut <= 1'b0;
      end
    end
  end


endmodule
