// ECE 6370
// Author: Tru Nguyen
// Function: A clocked 16-bit LFSR-based timer. When enable=1, it advances the 16-bit LFSR state every posedge clk. 
// When the LFSR reaches the terminal count 9363, it asserts timeout signal for one cycle 
// and resets LFSR back to 0 to start the timing interval again.

module OneMsLFSR(enable, clk, reset, OneMsTimeOut);
  input enable, clk, reset;
  output reg OneMsTimeOut;
  
  reg [15:0] LFSR;
  wire feedback = LFSR[15];

  always @(posedge clk) begin
    if (reset == 1'b0) begin
      LFSR <= 16'd0;
      OneMsTimeOut <= 1'b0;
    end
    else begin
      OneMsTimeOut <= 1'b0;
      if (enable == 1'b1) begin
	if (LFSR == 16'd37449) begin
	  LFSR <= 16'd0;
	  OneMsTimeOut <= 1'b1;
	end

	else begin
	  LFSR[0] <= feedback;
          LFSR[1] <= LFSR[0];
    	  LFSR[2] <= LFSR[1] ~^ feedback;
    	  LFSR[3] <= LFSR[2] ~^ feedback;
    	  LFSR[4] <= LFSR[3];
    	  LFSR[5] <= LFSR[4] ~^ feedback;
    	  LFSR[6] <= LFSR[5];
    	  LFSR[7] <= LFSR[6];
   	  LFSR[8] <= LFSR[7];
    	  LFSR[9] <= LFSR[8];
    	  LFSR[10] <= LFSR[9];
    	  LFSR[11] <= LFSR[10];
    	  LFSR[12] <= LFSR[11];
    	  LFSR[13] <= LFSR[12];
    	  LFSR[14] <= LFSR[13];
     	  LFSR[15] <= LFSR[14];
	end
      end
    end
  end
endmodule
