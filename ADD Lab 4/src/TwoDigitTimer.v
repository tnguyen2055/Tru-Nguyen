


module TwoDigitTimer(reconfig, timer_enable, clk, reset, timeout, ones_digit_out, tens_digit_out);
  input reconfig, timer_enable, clk, reset;
  output [3:0] ones_digit_out, tens_digit_out;
  output timeout;
  
  wire BorrowUp_OnesToTens, BorrowUp_Tens;
  wire NoBorrowDN_Ones, NoBorrowDN_Tens; // BorrowUp_Tens is left floating; NoBorrowUp_Tens is wired to logic high 1'b1
  wire OneSecTimeOut;
  
  digitTimer Ones_Digit(reconfig, OneSecTimeOut, NoBorrowDN_Tens, clk, reset, ones_digit_out, BorrowUp_OnesToTens, NoBorrowDN_Ones);  
  
  digitTimer Tens_Digit(reconfig, BorrowUp_OnesToTens, 1'b1, clk, reset, tens_digit_out, BorrowUp_Tens, NoBorrowDN_Tens);  

  OneSecTimer One_Sec_Timer(timer_enable, clk, reset, OneSecTimeOut);

  assign timeout = NoBorrowDN_Ones;
endmodule
