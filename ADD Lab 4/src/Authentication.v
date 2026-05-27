

module Authentication(Pwd_digit, B_Pwd_shaped, Logout_Req, clk, reset, LoggedIn, LoggedOut, Passed);
  input [3:0] Pwd_digit;
  input B_Pwd_shaped, Logout_Req, clk, reset;

  output LoggedIn, LoggedOut, Passed;

  wire [4:0] ROM_in; 
  wire [3:0] ROM_out;

  ROM_Authentication Top_ROM_Auth(Pwd_digit, B_Pwd_shaped, ROM_out, Logout_Req, clk, reset, ROM_in, LoggedIn, LoggedOut, Passed);
  ROM_Password Top_ROM_Pwd(ROM_in, clk, ROM_out);

endmodule
