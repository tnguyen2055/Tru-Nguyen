
// ============================================================
// Edited by Z. Mir (ZM): added NumberID_to_PW [15:0] output.
// Pass-through wrapper extension -- ID_check now exposes the
// user-typed 16-bit ID, ID_Auth just propagates it up.
// ============================================================
module ID_Auth(Digit, B_in_shaped, Logout_Req_from_PW, clk, reset, matchedID, ID_passed, PlayerID_to_PW, NumberID_to_PW);
  input [3:0] Digit;
  input B_in_shaped, Logout_Req_from_PW, clk, reset;

  output matchedID, ID_passed;
  output [4:0] PlayerID_to_PW;
  output [15:0] NumberID_to_PW;                    // ZM: new
 
  wire [15:0] ID_ROMdata;
  wire [4:0] ID_ROMAddr;

  ID_check ID_check_top(Digit, B_in_shaped, Logout_Req_from_PW, ID_ROMdata, clk, reset, matchedID, PlayerID_to_PW, ID_ROMAddr, NumberID_to_PW);   // ZM: added NumberID_to_PW

  PlayerID_ROM PlayerID_ROM_top(ID_ROMAddr, clk, ID_ROMdata);

  assign ID_passed = matchedID;
  
endmodule
