

// ============================================================
// Edited by Z. Mir (ZM): added NumberID_to_PW [15:0] output.
// Carries the user-typed 16-bit ID number out of ID_check so
// the PW chain can forward it to scoreRAM. Latched from
// EnterID_reg on entry to IDPASSED, cleared on logout/reset.
// Port appended at end of list to keep existing positional
// instantiations source-compatible.
// ============================================================
module ID_check(Digit, B_in_shaped, Logout_Req_from_PW, ID_ROMdata, clk, reset, matchedID, PlayerID_to_PW, ID_ROMAddr, NumberID_to_PW);
  input [3:0] Digit;
  input B_in_shaped, Logout_Req_from_PW, clk, reset;
  input [15:0] ID_ROMdata;

  output reg matchedID;
  output reg [4:0] PlayerID_to_PW, ID_ROMAddr;
  output reg [15:0] NumberID_to_PW;     // ZM: new

  parameter DIGIT1 = 0, DIGIT2 = 1, DIGIT3 = 2, DIGIT4 = 3, FETCHROM = 4, ROMWAIT1 = 5;
  parameter ROMWAIT2 = 6, CATCHROM = 7, COMPARE = 8, IDPASSED = 9, IDSTATUS = 10;
  
  reg [3:0] State;
  reg [15:0] EnterID_reg;
  reg [15:0] ID_ROMdata_reg;

  always @(posedge clk) begin
    if (reset == 1'b0) begin
      matchedID <= 1'b0;
      PlayerID_to_PW <= 5'd0;
      ID_ROMAddr <= 5'd0;
      EnterID_reg <= 16'd0;
      ID_ROMdata_reg <= 16'd0;
      NumberID_to_PW <= 16'd0;          // ZM: new
      State <= DIGIT1; end
 
    else begin
      case(State)
        DIGIT1: begin
	      matchedID <= 1'b0;
          PlayerID_to_PW <= 5'd0;
          ID_ROMAddr <= 5'd0;
          EnterID_reg <= 16'd0;
	      ID_ROMdata_reg <= 16'd0;

	      if (B_in_shaped == 1'b1) begin
	        EnterID_reg[15:12] <= Digit;
            State <= DIGIT2; end
	 
	      else begin
	        State <= DIGIT1; end 
	    end

        DIGIT2: begin
	      matchedID <= 1'b0;

	      if (B_in_shaped == 1'b1) begin
	        EnterID_reg[11:8] <= Digit;
            State <= DIGIT3; end
	 
	      else begin
	        State <= DIGIT2; end 
	    end

        DIGIT3: begin
	      matchedID <= 1'b0;

	      if (B_in_shaped == 1'b1) begin
			EnterID_reg[7:4] <= Digit;
            State <= DIGIT4; end
	 
		  else begin
			State <= DIGIT3; end 
	    end

        DIGIT4: begin
		  matchedID <= 1'b0;

		  if (B_in_shaped == 1'b1) begin
			EnterID_reg[3:0] <= Digit;
            State <= FETCHROM; end
	 
		  else begin
			State <= DIGIT4; end
		  end

        FETCHROM: begin
		  matchedID <= 1'b0;
		  State <= ROMWAIT1;
        end    

        ROMWAIT1: begin
		  matchedID <= 1'b0;
          State <= ROMWAIT2;
        end

        ROMWAIT2: begin
          matchedID <= 1'b0;
          State <= CATCHROM;
        end

        CATCHROM: begin
		  matchedID <= 1'b0;
          ID_ROMdata_reg <= ID_ROMdata;
		  State <= COMPARE;
	    end

        COMPARE: begin
          matchedID <= 1'b0;

		  if (EnterID_reg == ID_ROMdata_reg) begin
			State <= IDPASSED; end

		  else begin
			ID_ROMAddr <= ID_ROMAddr + 1;
			State <= IDSTATUS; end
		end

		IDPASSED: begin
		  PlayerID_to_PW <= ID_ROMAddr;
		  matchedID <= 1'b1;
		  NumberID_to_PW <= EnterID_reg;    // ZM: latch user-typed ID

		  if (Logout_Req_from_PW == 1'b0) begin
			State <= IDPASSED; end
		  else begin
		    matchedID <= 1'b0;
		    NumberID_to_PW <= 16'd0;        // ZM: clear on logout
			State <= DIGIT1; end
		end

		IDSTATUS: begin	  	
	      if (ID_ROMdata_reg == 16'hFFFF) begin
	        State <= DIGIT1; end 
	  
          else begin
	        State <= FETCHROM; end  
		end

		default: begin
		  matchedID <= 1'b0;
          PlayerID_to_PW <= 5'd0;
          EnterID_reg <= 16'd0;
		  ID_ROMdata_reg <= 16'd0;
		  NumberID_to_PW <= 16'd0;          // ZM: clear in default for safety

		  if (B_in_shaped == 1'b1) begin
			EnterID_reg[15:12] <= Digit;
            State <= DIGIT2; end
	 
		  else begin
			State <= DIGIT1; end 
		end
      endcase
    end
  end
endmodule
