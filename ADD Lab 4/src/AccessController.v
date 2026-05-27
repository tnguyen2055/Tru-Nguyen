
module AccessController(Pwd_GameStart_Restart_Shaped, Pwd_digit, Load_P_in, B_RNG, timeout, clk, reset, LoggedIn, LoggedOut, Load_P_out, RNG_Gen_out, timer_reconfig, timer_enable);
  input Pwd_GameStart_Restart_Shaped, Load_P_in, B_RNG, timeout, clk, reset;
  input [3:0] Pwd_digit;
  output LoggedIn, LoggedOut, Load_P_out, RNG_Gen_out, timer_reconfig, timer_enable;

  wire Passed, Logout_Req;

  Authentication Top_Auth(Pwd_digit, Pwd_GameStart_Restart_Shaped, Logout_Req, clk, reset, LoggedIn, LoggedOut, Passed);
  GameController Top_GameCtrl(Pwd_GameStart_Restart_Shaped, B_RNG, Load_P_in, timeout, Passed, clk, reset, Load_P_out, RNG_Gen_out, timer_reconfig, timer_enable, Logout_Req);

endmodule
