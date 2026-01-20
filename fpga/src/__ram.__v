//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9.03 (64-bit)
//Part Number: GW1NR-UV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Mon Sep  8 20:11:19 2025

module ram (dout, clk, oce, ce, ad, we, din, data_out);

output wire [7:0] dout;
input wire clk;
input wire oce;
input wire ce;
input wire [10:0] ad;
input wire we = 0;
input wire [7:0] din;

 (* RAM_STYLE = "block" *)
 reg[7:0] mem[0:2047];
 output reg[7:0] data_out;

    always @(posedge clk) begin
        if (ce == 1'b1) begin
            if (we == 1'b1) begin
                mem[ad] <= din;
                data_out <= din;
            end
            data_out <= mem[ad];
        end
    end

    assign dout = (oce == 1'b1) ?  data_out : 8'b0000_0000 ;

endmodule //Gowin_pROM
