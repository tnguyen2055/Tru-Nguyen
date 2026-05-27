
// ============================================================
// Edited by Z. Mir (ZM): added NumberID_from_ID_Auth [15:0]
// input and NumberID_to_scoreRAM [15:0] output. PW_check
// latches the user-typed 16-bit ID on entry to PWPASSED
// (mirroring how PlayerID_to_scoreRAM is captured there) and
// clears it on reset/INIT.
// ============================================================
module PW_check(matchedID, Digit, B_in_shaped, PW_ROMdigit, PlayerID_from_ID_Auth, NumberID_from_ID_Auth, Logout_Req_from_GameCtrl, clk, reset, PW_ROMAddr, LoggedIn, LoggedOut, PlayerID_to_scoreRAM, NumberID_to_scoreRAM, Logout_Req_to_ID_check);
  input matchedID, B_in_shaped, Logout_Req_from_GameCtrl, clk, reset;
  input [3:0] Digit; 
  input [15:0] PW_ROMdigit;
  input [4:0] PlayerID_from_ID_Auth;
  input [15:0] NumberID_from_ID_Auth;                  // ZM: new
  
  output reg LoggedIn, LoggedOut, Logout_Req_to_ID_check;
  output reg [4:0] PW_ROMAddr;
  output reg [4:0] PlayerID_to_scoreRAM;
  output reg [15:0] NumberID_to_scoreRAM;              // ZM: new
  
  reg [15:0] EnterPW_reg; 
  reg [15:0] PW_ROMdata_reg;
  
  reg [1:0] FailCounter;
  reg [3:0] State;

  parameter INIT = 0, DIGIT1 = 1, DIGIT2 = 2, DIGIT3 = 3, DIGIT4 = 4, FETCHROM = 5, ROMWAIT1 = 6, ROMWAIT2 = 7; 
  parameter CATCHROM = 8, COMPARE = 9, PWPASSED = 10, PWSTATUS = 11, LOGOUTWAIT = 12;

  parameter HIGH = 1'b1;
  parameter LOW = 1'b0;
  
  always @(posedge clk) begin
    if (reset == LOW) begin
      LoggedIn <= LOW;
	  LoggedOut <= HIGH;
      Logout_Req_to_ID_check <= LOW;
	  PW_ROMAddr <= 5'd0;
      PlayerID_to_scoreRAM <= 3'd0;
      NumberID_to_scoreRAM <= 16'd0;       // ZM: new
	  EnterPW_reg <= 16'd0;
	  PW_ROMdata_reg <= 16'd0;
	  FailCounter <= 2'd0;
      State <= INIT;
    end

    else begin
      case(State)
		INIT: begin
		  LoggedIn <= LOW;
		  LoggedOut <= HIGH;
          Logout_Req_to_ID_check <= LOW;
		  PW_ROMAddr <= 5'd0;
		  PlayerID_to_scoreRAM <= 3'd0;
		  NumberID_to_scoreRAM <= 16'd0;     // ZM: new
		  EnterPW_reg <= 16'd0;
		  PW_ROMdata_reg <= 16'd0;
		  FailCounter <= 2'd0;
		
		  if (matchedID == HIGH) begin
		    State <= DIGIT1;
		  end
		  
		  else begin
		    State <= INIT;
		  end
		end
		
		DIGIT1: begin
          LoggedIn <= LOW;
		  LoggedOut <= HIGH;
          Logout_Req_to_ID_check <= LOW;
		  PW_ROMAddr <= 5'd0;
		  EnterPW_reg <= 16'd0;
		  PW_ROMdata_reg <= 16'd0;
		  
          if (B_in_shaped == HIGH) begin
	        EnterPW_reg[15:12] <= Digit;
            State <= DIGIT2; 
		  end
	 
	      else begin
	        State <= DIGIT1;
		  end 
	    end
         
        DIGIT2: begin
          LoggedIn <= LOW;  
		  LoggedOut <= HIGH;
          Logout_Req_to_ID_check <= LOW;
		  
          if (B_in_shaped == HIGH) begin
	        EnterPW_reg[11:8] <= Digit;
            State <= DIGIT3; 
		  end
	 
	      else begin
	        State <= DIGIT2;
		  end 
	    end
      
		DIGIT3: begin
          LoggedIn <= LOW; 
		  LoggedOut <= HIGH;
          Logout_Req_to_ID_check <= LOW;
		  
          if (B_in_shaped == HIGH) begin
	        EnterPW_reg[7:4] <= Digit;
            State <= DIGIT4; 
		  end
	 
	      else begin
	        State <= DIGIT3;
		  end 
	    end
		
		DIGIT4: begin
          LoggedIn <= LOW;  
		  LoggedOut <= HIGH;
          Logout_Req_to_ID_check <= LOW;
		  
          if (B_in_shaped == HIGH) begin
	        EnterPW_reg[3:0] <= Digit;
            State <= FETCHROM; 
		  end
	 
	      else begin
	        State <= DIGIT4;
		  end 
	    end
		
        FETCHROM: begin
          LoggedIn <= LOW;
		  LoggedOut <= HIGH;
		  Logout_Req_to_ID_check <= LOW;
		  State <= ROMWAIT1;  
        end    

        ROMWAIT1: begin
          LoggedIn <= LOW;
		  LoggedOut <= HIGH;
		  Logout_Req_to_ID_check <= LOW;
		  State <= ROMWAIT2;  
        end

        ROMWAIT2: begin
          LoggedIn <= LOW;
		  LoggedOut <= HIGH;
		  Logout_Req_to_ID_check <= LOW;
		  State <= CATCHROM;  
        end

        CATCHROM: begin
          LoggedIn <= LOW;   
		  LoggedOut <= HIGH;
		  Logout_Req_to_ID_check <= LOW;
          PW_ROMdata_reg <= PW_ROMdigit;
		  State <= COMPARE;
		end

        COMPARE: begin
          LoggedIn <= LOW;  
          LoggedOut <= HIGH;
		  
	      if (EnterPW_reg == PW_ROMdata_reg) begin
			State <= PWPASSED; 
		  end

		  else begin
		    if (FailCounter == 2'd3) begin
			  State <= LOGOUTWAIT;
			  Logout_Req_to_ID_check <= HIGH;
			end
			
			else begin
			  PW_ROMAddr <= PW_ROMAddr + 1;
			  State <= PWSTATUS; 
		    end
		  end
		end
		
        PWSTATUS: begin	  	
	      if (PW_ROMdata_reg == 16'hFFFF) begin
		    FailCounter <= FailCounter + 1;
	        State <= DIGIT1; 
		  end 
	  
          else begin
	        State <= FETCHROM; 
		  end  
		
		end

		PWPASSED: begin
		  LoggedIn <= HIGH;
		  LoggedOut <= LOW;
		  PlayerID_to_scoreRAM <= PlayerID_from_ID_Auth;
		  NumberID_to_scoreRAM <= NumberID_from_ID_Auth;   // ZM: latch user-typed ID
		  
		  if (Logout_Req_from_GameCtrl == LOW) begin
		    State <= PWPASSED;
		  end
		  
		  else begin
		    Logout_Req_to_ID_check <= HIGH;
		    State <= LOGOUTWAIT;
		  end
		end
		
		LOGOUTWAIT: begin
		  Logout_Req_to_ID_check <= LOW;
		  State <= INIT;
		end
		
		default: begin 
		  LoggedIn <= LOW;  
		  LoggedOut <= HIGH;
          Logout_Req_to_ID_check <= LOW;
		  EnterPW_reg <= 16'd0;
		  PW_ROMdata_reg <= 16'd0;
		  FailCounter <= 2'd0;
		
		  if (matchedID == HIGH) begin
		    State <= DIGIT1;
		  end
		  
		  else begin
		    State <= INIT;
		  end
	    end
              
      endcase      
    end
  end 
endmodule
