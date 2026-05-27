
module Authentication(Digit, B_in_shaped, Logout_Req_from_GameCtrl, clk, reset, LoggedIn, LoggedOut, ID_passed, PlayerID_to_scoreRAM, NumberID_to_scoreRAM);

  input [3:0] Digit;
  input B_in_shaped, Logout_Req_from_GameCtrl, clk, reset;
  
  output LoggedIn, LoggedOut, ID_passed;
  output [4:0] PlayerID_to_scoreRAM;
  output [15:0] NumberID_to_scoreRAM;
  
  wire matchedID, Logout_Req_between_ID_PW;
  wire [4:0] PlayerID_between_ID_PW;
  wire [15:0] NumberID_between_ID_PW;
  
  PW_Auth PW_Auth_top(matchedID, Digit, B_in_shaped, PlayerID_between_ID_PW, NumberID_between_ID_PW, Logout_Req_from_GameCtrl, clk, reset, LoggedIn, LoggedOut, PlayerID_to_scoreRAM, NumberID_to_scoreRAM, Logout_Req_between_ID_PW);

  ID_Auth ID_Auth_top(Digit, B_in_shaped, Logout_Req_between_ID_PW, clk, reset, matchedID, ID_passed, PlayerID_between_ID_PW, NumberID_between_ID_PW);
  
endmodule