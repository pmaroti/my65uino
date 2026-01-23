`define SIM 1
`include "test6850.v"
`include "acia_6850.v"


module test();

  test6850 test6850( clk, btn1, uartTx, led, led2);
  reg clk=0;
  reg btn1=0;
  wire led;
  wire uartTx;
  wire led2;

  always
    #1  clk = ~clk;

  initial begin
    #1500 $finish;
  end

  initial begin
    $dumpfile("6850_test.vcd");
    $dumpvars(0, test);
  end
endmodule