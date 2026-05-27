

module Counter(Count, clk, reset, Count_out);
  input Count, clk, reset;
  output reg [3:0] Count_out;

  always @(posedge clk) begin
    if (reset == 1'b0) begin
      Count_out <= 4'd0;
    end

    else begin
      if (Count == 1'b1) begin
	Count_out <= Count_out+1;
      end
        
    end
  end
endmodule
