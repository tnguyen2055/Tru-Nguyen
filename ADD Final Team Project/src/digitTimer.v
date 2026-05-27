/*
Course: ECE 6370 Advanced Digital Design
Author: Zaki Mir 
PeopleSoft ID: 1675819
Porject: digitTimer
Project Discription: 
This module implements an FPGA-based count down system. 
the module will be counting down from 9 to 0. insted 
of resetting to 0 it would wrap back to 0.  
*/

module digitTimer(rst, enable, reconfig, borrowDwn, noBorrowUp, borrowUp, noBorrowDwn, count); 
	input rst, enable, reconfig, borrowDwn, noBorrowUp;
	output reg borrowUp, noBorrowDwn;
	output reg [3:0] count; 
	
	parameter nine = 4'b1001, eight = 4'b1000, seven = 4'b0111, six = 4'b0110, five = 4'b0101, 
			  four = 4'b0100, three = 4'b0011, two = 4'b0010, 	one = 4'b0001, zero = 4'b0000; 
	
	always @(posedge borrowDwn or negedge rst or posedge reconfig) begin
		if(rst == 1'b0) begin
			count <= zero;
			borrowUp <= 1'b0;
			noBorrowDwn <= 1'b0;
		end 
		else begin
			if (reconfig == 1'b1) begin
				count <= nine;
				borrowUp <= 1'b0; 
				noBorrowDwn <= 1'b0;
			end 
			else if (enable == 1'b1) begin
				case(count) 
					nine: begin
						count <= eight;
						borrowUp <= 1'b0;
					end
					eight: begin
						count <= seven; 
					end
					seven: begin
						count <= six; 
					end
					six: begin
						count <= five; 
					end
					five: begin
						count <= four;
					end
					four: begin
						count <= three; 
					end
					three: begin
						count <= two;
					end
					two: begin
						count <= one; 
					end
					one: begin
						count <= zero;
						noBorrowDwn <= 1'b1;
					end
					zero: begin
						// request to borrow 
						
						if(noBorrowUp == 0) begin
							count <= nine; 
							borrowUp <= 1'b1;
							
						end else begin
							borrowUp <= 1'b0;
							
						end	
					end
					default: begin
						count <= count;
						borrowUp <= 1'b0;					
						
					end
				endcase
			end 
			else begin
				borrowUp <= 1'b0; 
				noBorrowDwn <= 1'b0;
				count <= zero;
			end
		end
	end

endmodule

