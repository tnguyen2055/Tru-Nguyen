

module ROM_Authentication(P_digit, B_PW_shaped, ROMdigit, Logout_Req, clk, reset, ROMAddr, LoggedIn, LoggedOut, Passed);
  input B_PW_shaped, Logout_Req, clk, reset;
  input [3:0] P_digit, ROMdigit;

  output reg LoggedIn, LoggedOut, Passed;
  output reg [4:0] ROMAddr;

  reg [3:0] P_digit_reg, ROMdigit_reg;
  reg GoodUntilNow;
  reg [1:0] Counter;
  reg [3:0] State;

  parameter BUTTONCHECK = 0, FETCHROM = 1, ROMWAIT1 = 2, ROMWAIT2 = 3; 
  parameter ROMLOAD = 4, COMPARE = 5, CHECKCOUNT = 6, VERIFY = 7, PASSED = 8;

  always @(posedge clk) begin
    if (reset == 1'b0) begin
      LoggedIn <= 1'b0;  
      LoggedOut <= 1'b1;
      Passed <= 1'b0;
      GoodUntilNow <= 1'b1;
      ROMAddr <= {3'b000, Counter};
      Counter <= 2'b00;
      State <= BUTTONCHECK;
    end

    else begin
      case(State)
	BUTTONCHECK: begin
          LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Passed <= 1'b0;
      
         
          if (B_PW_shaped == 1'b1) begin
            P_digit_reg <= P_digit;
	    State <= FETCHROM;    
	  end
	    
	  else begin
	    State <= BUTTONCHECK;
	  end
         
        end
      
        FETCHROM: begin
          LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Passed <= 1'b0;
          ROMAddr <= {3'b000, Counter};
	  State <= ROMWAIT1;  
        end    

        ROMWAIT1: begin
          LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Passed <= 1'b0;
          State <= ROMWAIT2;
        end

        ROMWAIT2: begin
          LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Passed <= 1'b0;
          State <= ROMLOAD;
        end

        ROMLOAD: begin
          LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Passed <= 1'b0;
          ROMdigit_reg <= ROMdigit;
	  State <= COMPARE;
	end

        COMPARE: begin
          LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Passed <= 1'b0;

	  if (P_digit_reg == ROMdigit_reg) begin
	    
	  end

	  else begin	  	
	    GoodUntilNow <= 1'b0; 
	  end
          State <= CHECKCOUNT;
	end  

        CHECKCOUNT: begin 
          LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Passed <= 1'b0;
         
          if (Counter == 2'b11) begin
            State <= VERIFY;
	  end

	  else begin
	    Counter <= Counter + 2'b01;
            State <= BUTTONCHECK;
	  end
         
        end

	VERIFY: begin // DIGIT1 state
          LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Passed <= 1'b0;
         
          if (GoodUntilNow == 1'b1) begin
            State <= PASSED;
	  end   

	  else begin
	    State <= BUTTONCHECK;
	    GoodUntilNow <= 1'b1;
	    Counter <= 2'b00;
          end
      
        end

        PASSED: begin 
          LoggedIn <= 1'b1;  
          LoggedOut <= 1'b0;
          Passed <= 1'b1;
          GoodUntilNow <= 1'b1;
			 
          if (Logout_Req == 1'b1) begin
            State <= BUTTONCHECK;
	    Counter <= 2'b00;
	    Passed <= 1'b0;
		 LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
	  end	   

          else begin
	    State <= PASSED;
          end
              
        end

	default: begin 
	  LoggedIn <= 1'b0;  
          LoggedOut <= 1'b1;
          Passed <= 1'b0;
          GoodUntilNow <= 1'b1;
          Counter <= 2'b00;
	  ROMAddr <= {3'b000, Counter};

          if (B_PW_shaped == 1'b1) begin
            P_digit_reg <= P_digit;
	    State <= FETCHROM;    
	  end
	    
	  else begin
	    State <= BUTTONCHECK;
	  end
         
        end

      endcase   
    
    end

  end 
endmodule
