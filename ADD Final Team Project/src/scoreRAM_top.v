
module scoreRAM_top(pulse_WRAM_from_GameCtrl, pulse_sctrl_RAM_from_GameCtrl, PlayerID_from_Auth, NumberID_from_Auth, LatestScore, clk, reset, MyBest_to_DispCnt, GlobalBest_to_DispCnt);

  input pulse_WRAM_from_GameCtrl, pulse_sctrl_RAM_from_GameCtrl, clk, reset;
  input [4:0] PlayerID_from_Auth;
  input [15:0] NumberID_from_Auth;
  input [7:0] LatestScore;

  // ZM: was [7:0] -- truncated the top 16 bits (NumberID) off the concatenated
  // {NumberID_from_Auth, MyBest_reg} signal that scoreRAM_Ctrl outputs.
  // Widened to [23:0] to carry the full 24-bit packed value (16-bit ID + 8-bit score).
  output [23:0] MyBest_to_DispCnt, GlobalBest_to_DispCnt;

  wire [23:0] data_fromRAM, data_toRAM;
  wire R_W_en;
  wire [4:0] RAMAddr;

  scoreRAM_Ctrl scoreRAM_Ctrl_top(pulse_WRAM_from_GameCtrl, pulse_sctrl_RAM_from_GameCtrl, PlayerID_from_Auth, NumberID_from_Auth, LatestScore, data_fromRAM, clk, reset, R_W_en, RAMAddr, data_toRAM, MyBest_to_DispCnt, GlobalBest_to_DispCnt);

  score_RAM score_RAM_top(RAMAddr, clk, data_toRAM, R_W_en, data_fromRAM);


endmodule