// ECE 6370
// Author: Tru Nguyen
// Module name: countTo10
// Function: counts 100 ms timeout pulses and generates a 1 second timeout signal. Once the count limit is reached, it resets and asserts OneSecTimeOut for one clock cycle.
// (Note: Counter size is reduced for simulation purposes.)

module countTo10(HundredMsTimeOut, clk, reset, OneSecTimeOut, Count_out);
  input HundredMsTimeOut, clk, reset;
  output reg OneSecTimeOut;
  output reg [3:0] Count_out;
  //output [1:0] Count_out; // for sim only
  //reg OneSecTimeOut;
  //reg [3:0] Count_out;
  //reg [1:0] Count_out; // for sim only

  always @(posedge clk) begin
    if (reset == 1'b0) begin
      Count_out <= 4'd0;
      OneSecTimeOut <= 1'b0;
    end
    else begin
      if (HundredMsTimeOut == 1'b1) begin
        if (Count_out == 4'd9) begin
 	  Count_out <= 4'd0;
 	  OneSecTimeOut <= 1'b1;
	end
	else begin
	  Count_out <= Count_out+1;
	  OneSecTimeOut <= 1'b0;
	end
      end
      else begin
        OneSecTimeOut <= 1'b0;
      end
    end
  end


endmodule
