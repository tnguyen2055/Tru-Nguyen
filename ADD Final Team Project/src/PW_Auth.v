
// ============================================================
// Edited by Z. Mir (ZM): added NumberID_from_ID_Auth [15:0]
// input and NumberID_to_scoreRAM [15:0] output. PW_Auth now
// passes the user-typed 16-bit ID from ID_Auth down to
// PW_check (which latches it on PWPASSED) and back out to
// scoreRAM. Port positions match Authentication.v's positional
// instantiation order (NumberID interspersed with PlayerID).
// ============================================================
module PW_Auth(matchedID, Digit, B_in_shaped, PlayerID_from_ID_Auth, NumberID_from_ID_Auth, Logout_Req_from_GameCtrl, clk, reset, LoggedIn, LoggedOut, PlayerID_to_scoreRAM, NumberID_to_scoreRAM, Logout_Req_to_ID_check);
  
  input matchedID, B_in_shaped, Logout_Req_from_GameCtrl, clk, reset;
  input [3:0] Digit; 
  input [4:0] PlayerID_from_ID_Auth;
  input [15:0] NumberID_from_ID_Auth;              // ZM: new
  
  output LoggedIn, LoggedOut, Logout_Req_to_ID_check;
  output [4:0] PlayerID_to_scoreRAM;
  output [15:0] NumberID_to_scoreRAM;              // ZM: new
  
  wire [4:0] PW_ROMAddr;
  wire [15:0] PW_ROMdigit;
  
  Password_ROM Password_ROM_top (PW_ROMAddr, clk, PW_ROMdigit);
  PW_check PW_check_top (matchedID, Digit, B_in_shaped, PW_ROMdigit, PlayerID_from_ID_Auth, NumberID_from_ID_Auth, Logout_Req_from_GameCtrl, clk, reset, PW_ROMAddr, LoggedIn, LoggedOut, PlayerID_to_scoreRAM, NumberID_to_scoreRAM, Logout_Req_to_ID_check);   // ZM: added NumberID in/out
  
endmodule