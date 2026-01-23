`define SIM 1
`include "fpga_6502.v"
`include "RIOT.v"
`include "ALU.v"
`include "rom.v"
`include "cpu_65c02.v"



module test();

  fpga_6502 fpga_6502( clk, btn1, uartTx, uartRx, led);
  reg clk=0;
  reg btn1=1;
  wire led;
  wire uartTx;
  wire led2;

  always
    #1  clk = ~clk;

  initial begin
    #500 $finish;
  end

  initial begin
    $dumpfile("6502_test.vcd");
    $dumpvars(0, test);
  end
endmodule