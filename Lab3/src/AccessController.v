// ECE 6370
// Author: Tru Nguyen - 1032
// Module name: AccessController
// Function: Implement a 4-digit password-based login system utilizing the 1-procedure FSM method

module AccessController(Pwd_GameStart_Restart_Shaped, Pwd_And_GamePlay_Digit, Load_P_in, RNG_Button, timeout, clk, reset, LoggedIn, LoggedOut, Load_P_out, RNG_Gen_out, GoodUntilNow, timer_reconfig, timer_enable);
  input Pwd_GameStart_Restart_Shaped, Load_P_in, RNG_Button, clk, reset, timeout;
  input [3:0] Pwd_And_GamePlay_Digit;
  output reg LoggedIn, LoggedOut, Load_P_out, RNG_Gen_out, GoodUntilNow, timer_reconfig, timer_enable;

  parameter DIGIT1 = 0, DIGIT2 = 1, DIGIT3 = 2, DIGIT4 = 3, VERIFY = 4, RECONFIGTIMER = 5, WAITFORGAMESTART = 6, GAMEPLAY = 7, GAMEOVER = 8;
  
  reg [3:0] State;
 
  always @(posedge clk) begin
    if (reset == 1'b0) begin
      LoggedIn <= 1'b0;  
      LoggedOut <= 1'b1;
      Load_P_out <= 1'b0;
      RNG_Gen_out <= 1'b1;
      GoodUntilNow <= 1'b1;
      State <= DIGIT1;
    end
    
    else begin
      case(State)
	DIGIT1: begin
          LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Load_P_out <= 1'b0;
          RNG_Gen_out <= 1'b1;
          GoodUntilNow <= 1'b1;
          timer_reconfig <= 1'b0;
	  timer_enable <= 1'b0;

          if (Pwd_GameStart_Restart_Shaped == 1'b1) begin
            if (Pwd_And_GamePlay_Digit == 4'b0001) begin       // check if first digit is 1 (last 4 digits of ID = 1032)
               // correct digit
	       // DO NOT TOUCH GoodUntilNow
	    end
	    else begin
	      GoodUntilNow <= 1'b0; // wrong digit
   	    end
            State <= DIGIT2;
	  end
	  else begin
	    State <= DIGIT1;
	  end
         
        end
      
        DIGIT2: begin
	  LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Load_P_out <= 1'b0;
          RNG_Gen_out <= 1'b1;
          timer_reconfig <= 1'b0;
	  timer_enable <= 1'b0;
          
	  if (Pwd_GameStart_Restart_Shaped == 1'b1) begin
            if (Pwd_And_GamePlay_Digit == 4'b0000) begin       // check if second digit is 0 (last 4 digits of ID = 1032)
              // correct digit
	        // DO NOT TOUCH GoodUntilNow
	    end   
	    else begin
	      GoodUntilNow <= 1'b0; // wrong digit
            end
            State <= DIGIT3;
	  end
	  else begin
	    State <= DIGIT2;
	  end
	  
        end    

        DIGIT3: begin
	  LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Load_P_out <= 1'b0;
          RNG_Gen_out <= 1'b1;
          timer_reconfig <= 1'b0;
	  timer_enable <= 1'b0;
          
	  if (Pwd_GameStart_Restart_Shaped == 1'b1) begin
            if (Pwd_And_GamePlay_Digit == 4'b0011) begin       // check if third digit is 3 (last 4 digits of ID = 1032)
               // correct digit
	        // DO NOT TOUCH GoodUntilNow
	    end   
	    else begin
	      GoodUntilNow <= 1'b0; // wrong digit
            end
            State <= DIGIT4;
	  end
	  else begin
	    State <= DIGIT3;
	  end
	  
        end    

        DIGIT4: begin
	  LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Load_P_out <= 1'b0;
          RNG_Gen_out <= 1'b1;
          timer_reconfig <= 1'b0;
	  timer_enable <= 1'b0;
          
	  if (Pwd_GameStart_Restart_Shaped == 1'b1) begin
            if (Pwd_And_GamePlay_Digit == 4'b0010) begin       // check if last digit is 2 (last 4 digits of ID = 1032)
               // correct digit
	        // DO NOT TOUCH GoodUntilNow
	    end   
	    else begin
	      GoodUntilNow <= 1'b0; // wrong digit
            end
            State <= VERIFY;
	  end
	  else begin
	    State <= DIGIT4;
	  end
	  
        end    

        VERIFY: begin
	  LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Load_P_out <= 1'b0;
          RNG_Gen_out <= 1'b1;
          timer_reconfig <= 1'b0;
	  timer_enable <= 1'b0;
          
	  if (GoodUntilNow == 1'b1) begin
            State <= RECONFIGTIMER; // all four digits are correct
	  end
	  else begin
	    State <= DIGIT1; // at least one digit is wrong, reset the password entry
	  end
	  
        end    

        RECONFIGTIMER: begin // loggedin and display 99 on timer but still block all input access	
	  LoggedIn <= 1'b1;  
          LoggedOut <= 1'b0;
          Load_P_out <= 1'b0;
	  RNG_Gen_out <= 1'b1;
          timer_reconfig <= 1'b1;
	  timer_enable <= 1'b0;

          State <= WAITFORGAMESTART;
	  
        
	end    

	WAITFORGAMESTART: begin
	  LoggedIn <= 1'b1;  
          LoggedOut <= 1'b0;
          Load_P_out <= 1'b0;
	  RNG_Gen_out <= 1'b1;
	  timer_reconfig <= 1'b0;

	  if (Pwd_GameStart_Restart_Shaped == 1'b1) begin
	    timer_enable <= 1'b1;
	    State <= GAMEPLAY;
	  end
	
	  else begin
	    timer_enable <= 1'b0;
	    State <= WAITFORGAMESTART;
	  end

	end

	GAMEPLAY: begin
	  LoggedIn <= 1'b1;  
          LoggedOut <= 1'b0;
          Load_P_out <= Load_P_in;
	  RNG_Gen_out <= RNG_Button;
	  timer_enable <= 1'b1;
	  timer_reconfig <= 1'b0;

	  if (timeout == 1'b1) begin
	    State <= GAMEOVER;
	  end

	  else begin
	    State <= GAMEPLAY;
	  end

	end

	GAMEOVER: begin
	  LoggedIn <= 1'b1;  
          LoggedOut <= 1'b0;
          Load_P_out <= 1'b0;
	  RNG_Gen_out <= 1'b1;
	  timer_reconfig <= 1'b0;
	  timer_enable <= 1'b0;

	  if (Pwd_GameStart_Restart_Shaped == 1'b1) begin 
	    State <= RECONFIGTIMER;
	  end
	
	  else begin
	    State <= GAMEOVER;
	  end
	end

	default: begin // DIGIT1 state
	  LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Load_P_out <= 1'b0;
          RNG_Gen_out <= 1'b1;
          GoodUntilNow <= 1'b1;
         
          if (Pwd_GameStart_Restart_Shaped == 1'b1) begin
            if (Pwd_And_GamePlay_Digit == 4'b0001) begin      // check if first digit is 1 (last 4 digits of ID = 1032)
               // correct digit
	        // DO NOT TOUCH GoodUntilNow
	    end   
	    else begin
	      GoodUntilNow <= 1'b0; // wrong digit
            end
            State <= DIGIT2;
	  end
	  else begin
	    State <= DIGIT1;
	  end
         
        end

      endcase   
    end


  end 

endmodule