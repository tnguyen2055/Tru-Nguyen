// ECE 6370
// Author: Tru Nguyen, 1032
// Module: A design of a 4-bit binary adder
// This module takes two 4-bit binary input signals P1Num and P2Num, calculating the sum of the input signals, and store
// the 4-bit binary result to the output signal Sum

module FourBitAdder(P1Num, P2Num, Sum);
  input [3:0] P1Num, P2Num;
  output [3:0] Sum;
  reg [3:0] Sum;
  
  always @(P1Num, P2Num)
    begin
      Sum = P1Num + P2Num;

    end
	 
endmodule
