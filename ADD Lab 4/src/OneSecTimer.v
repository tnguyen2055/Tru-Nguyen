// ECE 6370
// Author: Tru Nguyen
// Module name: OneSecTimer
// Function: the top-level timing module that generates a 1-second timeout signal by cascading three smaller timers. 
// It uses a 1 ms timer, then counts those pulses to form 100 ms, and finally counts again to produce a 1-second pulse.

module OneSecTimer(enable, clk, reset, OneSecTimeOut);
  input enable, clk, reset;
  output OneSecTimeOut;
  wire OneMsTimeOut, HundredMsTimeOut;

  OneMsLFSR OneMsLFSR_top (enable, clk, reset, OneMsTimeOut);
  
  countTo100 count_To_100(OneMsTimeOut, clk, reset, HundredMsTimeOut);

  countTo10 count_To_10(HundredMsTimeOut, clk, reset, OneSecTimeOut);
  


endmodule
