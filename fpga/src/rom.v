//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9.03 (64-bit)
//Part Number: GW1NR-UV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Mon Sep  8 20:11:19 2025

module rom (dout, clk, oce, ce, ad);

output wire [7:0] dout;
input wire clk;
input wire oce;
input wire ce;
input wire [10:0] ad;

 (* RAM_STYLE = "block" *)
 reg[7:0] mem[0:2047]; // 2K x 8-bit ROM
 reg[7:0] data_out;

    always @(posedge clk) begin
        if (ce == 1'b1) begin
            data_out <= mem[ad];
        end
    end

    assign dout = (oce == 1'b1) ?  data_out : 8'b0000_0000 ;

    initial begin
		data_out = 8'h0;
		$readmemh("rom.hex", mem);
    end


endmodule //Gowin_pROM
