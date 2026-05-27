

module digitTimer(reconfig, BorrowDN, NoBorrowUp, clk, reset, Digit, BorrowUp, NoBorrowDN);
  input reconfig, BorrowDN, NoBorrowUp, clk, reset;
  output [3:0] Digit;
  output BorrowUp, NoBorrowDN;
  
  reg [3:0] Digit;
  reg BorrowUp, NoBorrowDN;
 
  always @(posedge clk) begin
    if (reset == 1'b0) begin  
      Digit <= 4'd0;
      BorrowUp <= 1'b0;
      NoBorrowDN <= 1'b1; 
    end  
    
    else begin 
      BorrowUp <= 1'b0;

      if (reconfig == 1'b0) begin

        if (BorrowDN == 1'b1) begin
          
	  if (Digit == 4'd1) begin
          
	    if (NoBorrowUp == 1'b0) begin          
	      Digit <= 4'd9;
	      BorrowUp <= 1'b1;
	      NoBorrowDN <= 1'b0; 
	    end // NoBorrowUp
            
 
	    else begin
	      BorrowUp <= 1'b0;
	      Digit <= 4'd0;
	      NoBorrowDN <= 1'b1;
	    end // NoBorrowUp else

	  end // Digit

	  else begin  
	  Digit <= Digit - 1;
	  NoBorrowDN <= 1'b0;
	 // BorrowUp <= 1'b0;
         // NoBorrowDN <= 1'b0;
	  end // Digit else
	
	end // BorrowDN

	else begin
	  if (Digit == 4'd0) begin
            NoBorrowDN <= 1'b1;
	  end

	  else begin
	    NoBorrowDN <= 1'b0;
	  end
	  
	end // BorrowDN else
      
      end // reconfig
      
      else begin
	Digit <= 4'd9;
	BorrowUp <= 1'b0;
	NoBorrowDN <= 1'b0;
        
      end // reconfig else 
  
         
    end // reset else
  end // always


/*  always @(posedge clk) begin
    
    if (reset == 1'b0) begin  
      Digit <= 4'd0;
      BorrowUp <= 1'b0;
      NoBorrowDN <= 1'b1; 
    end  
    
    else begin
      BorrowUp <= 1'b0;

      if (reconfig == 1'b1) begin
	Digit <= 4'd9;
	NoBorrowDN <= 1'b0; // not zero
      end

      else begin

	if (BorrowDN == 1'b1) begin
	  
	  if (Digit == 4'd0) begin
	    
	    if (NoBorrowUp == 1'b0) begin
	      Digit <= 4'd9;
	      BorrowUp <= 1'b1;
	      NoBorrowDN <= 1'b0;
	    end

	    else begin
	      Digit <= 4'd0;
	      NoBorrowDN <= 1'b1;
	    end
	  
	  end
        end

	else begin
	  Digit <= Digit - 1;

	  if (Digit == 4'd1) begin
	    NoBorrowDN <= 1'b1;
	  end

	  else begin
	    NoBorrowDN <= 1'b0;
	  end
	end
      end
    end
  end
*/
endmodule
