module countTo2(clk, rst, enable, timeout);
	input wire clk, rst, enable;
	output reg timeout; 
	reg [3:0] count = 4'h0;
	
	always @ (posedge clk or negedge rst) begin 
		if (rst == 0) begin 			// resting the count and time out 
			count <= 4'h0;
			timeout <= 0; 
		end 
		else begin 
			if (enable == 1) begin	// only counting if the enable is one 
				if (count >= 4'h9) begin	// looking for count to be over 1
					count <= 4'h0;
					timeout <= 1;
				end else begin				// incrase the count with clock edge if 
					count <= count + 1;
					timeout <= 0; 
				end 
			end else begin					// looking for edge case scenario 
				count <= count; 
				timeout <= 0; 
			end
		end
	end 
endmodule


