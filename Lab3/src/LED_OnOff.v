// ECE 6370
// Author: Tru Nguyen, 1032
// Module: A verification design to check if the sum of two 4-bit binary numbers equals F
// This module takes one 4-bit binary input signal Sum, checks if Sum equals F, if so, light up the left-most LED, otherwise light up the right-most LED.

module LED_OnOff(Sum, M_LED, NM_LED);
  input [3:0] Sum;
  output M_LED, NM_LED;
  reg M_LED, NM_LED;

  always @(Sum)
    begin
	   if (Sum == 4'b1111)
		  begin
		    M_LED = 1'b1;
			 NM_LED = 1'b0;
		  end
		else
		  begin
		    M_LED = 1'b0;
			 NM_LED = 1'b1;
		  end
	 end	
endmodule
