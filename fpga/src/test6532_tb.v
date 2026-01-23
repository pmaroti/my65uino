`define SIM 1
`include "test6532.v"
`include "RIOT.v"


module test();

  test6532 test6532( clk, btn1, uartTx, led, led2);
  reg clk=0;
  reg btn1=0;
  wire led;
  wire uartTx;
  wire led2;

  always
    #1  clk = ~clk;

  initial begin
    #500 $finish;
  end

  initial begin
    $dumpfile("6532_test.vcd");
    $dumpvars(0, test);
  end
endmodule