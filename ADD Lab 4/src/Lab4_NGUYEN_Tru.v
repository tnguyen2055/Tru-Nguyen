

module Lab4_NGUYEN_Tru(PNum, Pwd_Digit, B_in_P, B_in_Pwd_G, B_RNG, clk, reset, Decoder_out_P, D_RNG_out, D_Sum_out, D_ones_out, D_tens_out, M_LED_top, NM_LED_top, LoggedIn, LoggedOut);
  input [3:0] PNum, Pwd_Digit;
  input B_in_P, B_in_Pwd_G, B_RNG, clk, reset;
  output [6:0] Decoder_out_P, D_RNG_out, D_Sum_out, D_ones_out, D_tens_out;
  output M_LED_top, NM_LED_top, LoggedIn, LoggedOut;
  
  wire [3:0] Sum, P_LR_out, Rand_Num, tens_digit, ones_digit;
  wire Pwd_GameStart_Restart_Shaped, Load_P_in, Load_P_out, RNG_Gen_out, timer_reconfig, timer_enable, timeout;  

  SevenSegDecoder P_Decoder (P_LR_out, Decoder_out_P);
  SevenSegDecoder Sum_Decoder (Sum, D_Sum_out);
  SevenSegDecoder RNG_Decoder (Rand_Num, D_RNG_out);
  SevenSegDecoder ones_Decoder (ones_digit, D_ones_out);
  SevenSegDecoder tens_Decoder (tens_digit, D_tens_out);

  FourBitAdder FourBit_Adder (P_LR_out, Rand_Num, Sum);
    
  LED_OnOff LED_Check (Sum, M_LED_top, NM_LED_top);

  ButtonShaper P_ButtonShaper (B_in_P, Load_P_in, clk, reset); //
  ButtonShaper Pwd_Game_BS (B_in_Pwd_G, Pwd_GameStart_Restart_Shaped, clk, reset);//

  LoadRegister P_LoadReg (PNum, P_LR_out, clk, reset, Load_P_out);//
  
  TwoDigitTimer Two_digit_timer_top (timer_reconfig, timer_enable, clk, reset, timeout, ones_digit, tens_digit);

  LFSR_RNG RNG_top (RNG_Gen_out, clk, reset, Rand_Num);//

  AccessController Access_top (Pwd_GameStart_Restart_Shaped, Pwd_Digit, Load_P_in, B_RNG, timeout, clk, reset, LoggedIn, LoggedOut, Load_P_out, RNG_Gen_out, timer_reconfig, timer_enable);



endmodule