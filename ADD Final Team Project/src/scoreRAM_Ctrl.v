
module scoreRAM_Ctrl(pulse_WRAM_from_GameCtrl, pulse_sctrl_RAM_from_GameCtrl, PlayerID_from_Auth, NumberID_from_Auth, LatestScore, data_fromRAM, clk, reset, R_W_en, RAMAddr, data_toRAM, MyBest_to_DispCnt, GlobalBest_to_DispCnt);

  input pulse_WRAM_from_GameCtrl, pulse_sctrl_RAM_from_GameCtrl, clk, reset;
  input [4:0] PlayerID_from_Auth;
  input [15:0] NumberID_from_Auth;
  input [7:0] LatestScore;
  input [23:0] data_fromRAM;
  
  output reg R_W_en; // write 0, read 1
  output reg [4:0] RAMAddr;
  output reg [23:0] data_toRAM, MyBest_to_DispCnt, GlobalBest_to_DispCnt;
  
  reg [7:0] LatestScore_reg;
  reg [23:0] RAMdata_reg;
  reg [7:0] GlobalBest_reg;
  reg [15:0] BestPlayer_reg;
  reg [7:0] MyBest_reg;
  reg [3:0] State;
  
  parameter RAMINIT = 0, WAITFORSCORE = 1, FETCHRAM = 2, RAMWAIT1 = 3, RAMWAIT2 = 4; 
  parameter CATCHRAM = 5, COMPARE = 6, WRITETORAM = 7, SCOREOUTPUT = 8;
  
  parameter HIGH = 1'b1;
  parameter LOW = 1'b0;
  
  always @(posedge clk) begin
    if (reset == LOW) begin
	  R_W_en <= HIGH;
	  RAMAddr <= 5'd0;
	  data_toRAM <= 24'd0;
	  LatestScore_reg <= 8'd0;
	  GlobalBest_reg <= 8'd0;
	  BestPlayer_reg <= 16'd0;             // ZM: was uninitialized, would power up as X
	  MyBest_reg <= 8'd0;
	  MyBest_to_DispCnt <= 24'd0;
	  GlobalBest_to_DispCnt <= 24'd0;
	  State <= RAMINIT;
	end
	
	else begin
	  case(State)
	    RAMINIT: begin
		  R_W_en <= HIGH;
		  RAMAddr <= RAMAddr + 1'b1;
		  data_toRAM <= 24'h000000;          // ZM: was 0x111111 -- pre-filled every slot with bogus "Player 0x1111 scored 17"
		  
		  if (RAMAddr == 5'd31) begin
		    R_W_en <= LOW;
		    State <= WAITFORSCORE;
		  end
		end
		
		WAITFORSCORE: begin
		  R_W_en <= LOW;
		  
		  if (pulse_WRAM_from_GameCtrl == HIGH) begin
			LatestScore_reg <= LatestScore;
			RAMAddr <= PlayerID_from_Auth;
			State <= FETCHRAM;
		  end
		  
		  else begin
		    State <= WAITFORSCORE;
		  end
		end
		
		FETCHRAM: begin
		  R_W_en <= LOW;
		  State <= RAMWAIT1;
		end
		
		RAMWAIT1: begin
		  R_W_en <= LOW;
		  State <= RAMWAIT2;
		end
		
		RAMWAIT2: begin
		  R_W_en <= LOW;
		  State <= CATCHRAM;	
		end
		
		CATCHRAM: begin
		  R_W_en <= LOW;
		  RAMdata_reg <= data_fromRAM;
		  MyBest_reg <= data_fromRAM[7:0];   // ZM: Bug 3 fix -- always refresh MyBest_reg from the current player's RAM slot. Prevents the previous player's value from leaking through when the new score doesn't beat the stored best.
		  State <= COMPARE;
		end
		
		COMPARE: begin
		  State <= WRITETORAM;
		  
		  if (RAMdata_reg [7:0] < LatestScore_reg) begin
		    MyBest_reg <= LatestScore_reg;
		    data_toRAM <= {NumberID_from_Auth, LatestScore_reg};   // ZM: was '=' (blocking), now '<=' to match the rest of the FSM
			R_W_en <= HIGH;
			RAMAddr <= PlayerID_from_Auth;
		  end
		end
		
		WRITETORAM: begin
		  R_W_en <= LOW;
	      State <= SCOREOUTPUT;
		end
		
		SCOREOUTPUT: begin
		  R_W_en <= LOW;
		  State <= WAITFORSCORE;
		  
		  // Update global best AND output snapshot in one cycle
		  if (LatestScore_reg > GlobalBest_reg) begin
			 GlobalBest_reg <= LatestScore_reg;
			 BestPlayer_reg <= NumberID_from_Auth;
			 GlobalBest_to_DispCnt <= {NumberID_from_Auth, LatestScore_reg};
		  end
		  else begin
			 GlobalBest_to_DispCnt <= {BestPlayer_reg, GlobalBest_reg};
		  end
		  
		  MyBest_to_DispCnt <= {NumberID_from_Auth, MyBest_reg};
		end
		
		default: begin
		  R_W_en <= HIGH;
		  RAMAddr <= RAMAddr + 1'b1;
		  data_toRAM <= 24'h000000;          // ZM: was 0x111111 -- match RAMINIT
		  
		  if (RAMAddr == 5'd31) begin
		    State <= WAITFORSCORE;
		  end
		end
		
	  endcase
	end
  
  end
endmodule