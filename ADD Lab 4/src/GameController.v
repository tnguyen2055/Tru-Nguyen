
module GameController(B_GamePlay_Shaped, B_RNG, Load_P_in, timeout, Passed, clk, reset, Load_P_out, RNG_Gen_out, timer_reconfig, timer_enable, Logout_Req);
  
  input B_GamePlay_Shaped, B_RNG, Load_P_in, timeout, Passed, clk, reset;

  output reg Load_P_out, RNG_Gen_out, timer_reconfig, timer_enable, Logout_Req;

  parameter INIT = 0, RECONFIGTIMER = 1, WAITFORGAMESTART = 2, GAMEPLAY = 3, GAMEOVER = 4, LOGOUTWAIT = 5;
  
  reg [2:0] State;

  always @(posedge clk) begin
    if (reset == 1'b0) begin
      Load_P_out <= 1'b0;  
      RNG_Gen_out <= 1'b0;
      timer_reconfig <= 1'b0;
      timer_enable <= 1'b0;
      Logout_Req <= 1'b0;
      State <= INIT;
    end

    else begin
      case(State)
	INIT: begin
          Load_P_out <= 1'b0;  
          RNG_Gen_out <= 1'b0;
          timer_reconfig <= 1'b0;
          timer_enable <= 1'b0;
          Logout_Req <= 1'b0;
			 
	   //  if (B_GamePlay_Shaped == 1'b1)begin
		//    State <= INIT;
		//	 end 
			 
          if (Passed == 1'b1) begin
	    State <= RECONFIGTIMER;    
	  end
	    
	  else begin
	    State <= INIT;
	  end
        end
      
        RECONFIGTIMER: begin
	  Load_P_out <= 1'b0;
	  RNG_Gen_out <= 1'b0;
          timer_reconfig <= 1'b1;
          timer_enable <= 1'b0;
	  Logout_Req <= 1'b0;
	  State <= WAITFORGAMESTART;
	end
	/*  if (Load_P_in == 1'b1) begin
	    Logout_Req <= 1'b1;
	    State <= LOGOUTWAIT;
	  end
	
	  else begin
	    State <= WAITFORGAMESTART;
	  end
	end */

	WAITFORGAMESTART: begin
	  Load_P_out <= 1'b0;
	  RNG_Gen_out <= 1'b0;
          timer_reconfig <= 1'b0;
	  Logout_Req <= 1'b0;

          
	  if (Load_P_in == 1'b1) begin
	    Logout_Req <= 1'b1;
	    State <= LOGOUTWAIT;
	  end
	
	  else begin
	    if (B_GamePlay_Shaped == 1'b1) begin
	      timer_enable <= 1'b1;
	      State <= GAMEPLAY;
	    end
	
	    else begin
	      timer_enable <= 1'b0;
	      State <= WAITFORGAMESTART;
	    end
	  end
	end

	GAMEPLAY: begin
          Load_P_out <= Load_P_in;
	  RNG_Gen_out <= B_RNG;
	  timer_enable <= 1'b1;
	  timer_reconfig <= 1'b0;
	  Logout_Req <= 1'b0;

	  if (timeout == 1'b1) begin
	    State <= GAMEOVER;
	  end

	  else begin
	    State <= GAMEPLAY;
	  end

	end

	GAMEOVER: begin
          Load_P_out <= 1'b0;
	  RNG_Gen_out <= 1'b0;
	  timer_reconfig <= 1'b0;
	  timer_enable <= 1'b0;
          Logout_Req <= 1'b0;

	  if (Load_P_in == 1'b1) begin
	    Logout_Req <= 1'b1;
	    State <= LOGOUTWAIT;
	  end
	
	  else begin
	    if (B_GamePlay_Shaped == 1'b1) begin
	      State <= RECONFIGTIMER;
	    end
	
	    else begin
	      State <= GAMEOVER;
	    end
	  end	  
	end

        LOGOUTWAIT: begin
	  Load_P_out <= 1'b0;
	  RNG_Gen_out <= 1'b0;
	  timer_reconfig <= 1'b0;
	  timer_enable <= 1'b0;
	  Logout_Req <= 1'b0;
	  State <= INIT;
        end

        default: begin 
          Load_P_out <= 1'b0;  
          RNG_Gen_out <= 1'b0;
          timer_reconfig <= 1'b0;
          timer_enable <= 1'b0;
          Logout_Req <= 1'b0;

          if (Passed == 1'b1) begin
	    State <= RECONFIGTIMER;    
	  end
	    
	  else begin
	    State <= INIT;
	  end
        end

      endcase   
    end
  end
endmodule