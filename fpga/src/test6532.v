module test6532 (
    input clk,
    input btn1,
    output uartTx,
    output led,
    output led2
);

reg             reset = 1;      // Active high reset, starts high with reset
wire            reset_n;        // Active low reset


reg     [32:0]  clk_div = 0;       // Clock divider counter
reg     [7:0]  state = 8'd0;

wire    [7:0]   riot_dout;
reg     [7:0]   DO;             // Data output bus 8 bit wide

reg     [7:0]   riot_PAin = 8'd0; // Port A input of RIOT
wire    [7:0]   riot_PAout;       // Port A output of RIOT
reg     [7:0]   riot_PBin = 8'd0; // Port B input of RIOT
wire    [7:0]   riot_PBout;       // Port B output of RIOT
reg             r_wn;             // Read/Write signal, active high for read
wire            riot_irq_n;       // Active low IRQ from RIOT
//reg             riot_select_n;    // Active low select for RIOT
reg   [15:0]    addr_reg;         // Registered address bus
reg   led2_reg = 0;

RIOT riot(
        .A(addr_reg[6:0]), 
        .Din(DO),
        .Dout(riot_dout),
        .CS(1'b1),
        .CS_n(addr_reg[12]),
        .R_W_n(r_wn),
        .RS_n(addr_reg[7]),
        .RES_n(reset_n),
        .IRQ_n(riot_irq_n),
        .CLK(clk_divided),
        .PAin(riot_PAin), .PAout(riot_PAout),
        .PBin({riot_PBin[7], btn1,riot_PBin[5:0]}), .PBout({led, riot_PBout[6:0]})
);

assign reset_n = ~reset;
assign led2 = led2_reg;
//assign riot_select_n = addr_reg[12];  // 0x0000 - 0x0FFF


`ifdef SIM
    wire clk_divided;
    assign clk_divided = clk; // For simulation use the input clock directly
`else
    reg             clk_divided = 0;   // divided clock signal
    // Generate 27 MHz / 13_500_000 = 1 Hz clock from 27 MHz input
    always @(posedge clk) begin
        if (clk_div == 13_500_000) begin
            clk_div <= 0;
            clk_divided <= ~clk_divided;
        end else begin
            clk_div <= clk_div + 1;
        end
    end
`endif

// Reset must be high for at least 1 cycle.
always @(posedge clk_divided)
    reset <= 1'b0;


always @(posedge clk_divided) begin
    if (reset) begin
        state <= 8'd0;
        addr_reg <= 16'h0000;
        r_wn <= 1'b1; // Read
        DO <= 8'd0;
    end else begin
        case (state)
            8'd0: begin
                addr_reg <= 16'h0083; // RIOT DDR B
                DO <= 8'b1000_0000; // Set PB7 as output
                r_wn <= 1'b0;         // Write
                state <= 8'd1;
                led2_reg <= 0;
            end
            8'd1: begin
                addr_reg <= 16'h0082; // RIOT Port B
                r_wn <= 1'b0;         // Write
                DO <= 8'b1000_0000; // Set PB7 high
                state <= 8'd2;
                led2_reg <= ~led2_reg;
            end
            8'd2: begin
                addr_reg <= 16'h0082; // RIOT Port B
                r_wn <= 1'b0;         // Write
                DO <= 8'b0000_0000; // Set PB7 low
                state <= 8'd1; // Loop back to state 1
                led2_reg <= ~led2_reg;
            end
            default: state <= 8'd0;
        endcase
    end
end

endmodule
