module fpga_6502 (
    input clk,
    input btn1,
    output uartTx,
    input uartRx,
    output led
);

localparam SYS_FREQ = 27000000;  // 27 MHz


reg [7:0] reset_cntr = 0;

reg             reset = 1;      // Active high reset, starts high with reset
reg             clk_1Mhz = 0;   // 1 MHz clock signal
wire    [15:0]  AB;             // Address bus 16 bit wide
wire     [7:0]  DI;     // Data input bus 8 bit wide
wire    [7:0]   DO;             // Data output bus 8 bit wide
reg           IRQ = 1'd0;       // Interrupt Request, active high
reg           NMI = 1'd0;       // Non-Maskable Interrupt, active high
reg           RDY = 1'd1;       // Ready signal, must be high for normal operation
wire          SYNC;             // Sync signal from CPU
wire          WE;               // Write Enable signal from CPU, active high
reg     [7:0] riot_PAin = 8'd0; // Port A input of RIOT
wire    [7:0] riot_PAout;       // Port A output of RIOT
reg     [7:0] riot_PBin = 8'd0; // Port B input of RIOT
wire    [7:0] riot_PBout;       // Port B output of RIOT
wire          r_wn;             // Read/Write signal, active high for read
wire          reset_n;          // Active low reset
wire          riot_irq_n;       // Active low IRQ from RIOT
wire          riot_select_n;    // Active low select for RIOT
wire          rom_select;       // Select signal for ROM
wire [7:0]    rom_out;
wire [7:0]    riot_out;
reg [15:0]    addr_reg;         // Registered address bus

cpu_65c02 cpu(
    .clk (clk_1Mhz),
    .reset (reset),
    .DI (DI),
    .IRQ (IRQ), 
    .NMI (NMI),
    .RDY (RDY),
    .AB (AB),
    .DO (DO),
    .SYNC (SYNC),
    .WE (WE)
);

RIOT riot(
        .A(AB[6:0]), 
        .Din(DO),
        .Dout(riot_out),
        .CS(1'b1),
        .CS_n(riot_select_n),
        .R_W_n(r_wn),
        .RS_n(AB[7]),
        .RES_n(reset_n),
        .IRQ_n(riot_irq_n),
        .CLK(clk_1Mhz),
        .PAin(riot_PAin), .PAout(riot_PAout),
        .PBin({riot_PBin[7], btn1, riot_PBin[5], uartRx, riot_PBin[3:0]}), .PBout({led, riot_PBout[6], uartTx, riot_PBout[4:0]})
);

rom rom(
    .clk(clk_1Mhz),
    .ad(AB[10:0]),
    .dout(rom_out),
    .oce(1'b1),
    .ce(rom_select)
);


assign r_wn = ~WE;
assign reset_n = ~reset;

`ifndef SIM
// Generate 1 MHz clock from 27 MHz input
reg [4:0] clk_div = 0;
always @(posedge clk) begin
    if (clk_div == 13) begin
        clk_div <= 0;
        clk_1Mhz <= ~clk_1Mhz;
    end else begin
        clk_div <= clk_div + 1;
    end
end
`else
// In simulation, use the input clock directly as 1 MHz clock
always @(posedge clk) begin
    clk_1Mhz <= ~clk_1Mhz;
end
`endif  

// Reset must be high for at least 1 cycle.
always @(posedge clk_1Mhz) begin
    if (reset_cntr != 8'h02)
        reset_cntr <= reset_cntr + 1;
    else
        reset <= 0;
end


always @(posedge clk_1Mhz) begin
    addr_reg <= AB;
end

assign riot_select_n = AB[12:10] == 3'b000 ? 1'b0 : 1'b1;  // 0x0000 - 0x03FF
assign rom_select = AB[12];     // 0x1000 - 0xFFFF

assign DI = (addr_reg[12]) ? rom_out : riot_out;


endmodule
