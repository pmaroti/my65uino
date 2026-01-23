module test6850 (
    input clk,
    input btn1,
    output uartTx,
    output led,
    output led2
);

reg             reset = 1;      // Active high reset, starts high with reset
wire            reset_n;        // Active low reset
reg      [7:0]  byte_to_send = 8'h41; // ASCII 'A'


reg     [32:0]  clk_div = 0;       // Clock divider counter
reg     [7:0]   state = 8'd0;

reg     [32:0]  loop_counter = 0; // Loop counter for delays

wire    [7:0]   DI;             // Data input bus 8 bit wide
reg     [7:0]   DO;             // Data output bus 8 bit wide
reg             cs = 1'b0;  

reg             r_wn;             // Read/Write signal, active high for read
reg   [15:0]    addr_reg;         // Registered address bus

reg   led2_reg = 0;


reg   serial_clk = 0; // 
reg  [7:0] serial_clk_div = 0; //

acia_6850 acia_6850(
    .clk(clk),  // System clock can be high frequency
    .reset(reset),
    .cs(cs), // Use registered chip select
    .e_clk(clk_divided), // Enable clock for ACIA, divided down from system clock CPU clock
    .rw_n(r_wn),
    .rs(addr_reg[0]), // Register select from LSB of address
    .data_in(DO),
    .data_out(DI), // Data output from ACIA
    .data_en(), // Not used in this test
    .txclk(serial_clk), // Use same serial clock for transmit clock
    .rxclk(serial_clk), // Use same serial clock for receive clock
    .rxdata(1'b1), // Tie RX data high
    .cts_n(1'b0), // Clear to send always active which means we can always send
    .dcd_n(1'b0), // Data set ready always active which means we are always connected
    .irq_n(), // Not used in this test  
    .txdata(uartTx),
    .rts_n() // Not used in this test
);

assign reset_n = ~reset;
assign led2 = led2_reg;

`ifdef SIM
    reg             clk_divided = 0;   // divided clock signal
    // Generate 27 MHz / 351 = 76800 kHz clock from 27 MHz input
    // Which 4800 baud rate with divide by 16 setting
    always @(posedge clk) begin
        if (clk_div == 2) begin
            clk_div <= 0;
            clk_divided <= ~clk_divided;
        end else begin
            clk_div <= clk_div + 1;
        end
    end
`else
    reg clk_divided = 0;   // divided CPU clock 
    // Generate 27 MHz / 26 = 1MHz clock from 27 MHz input
    always @(posedge clk) begin
        if (clk_div == 13) begin
            clk_div <= 0;
            clk_divided <= ~clk_divided;
        end else begin
            clk_div <= clk_div + 1;
        end
    end
`endif

// Reset must be high for at least 1 CPU clock cycle.
always @(posedge clk_divided)
    reset <= 1'b0;


always @(posedge clk) begin

    if (serial_clk_div == 8'd175) begin // 27 MHz / 350 = 77142 Hz clock for serial clk which is approx 16 * 4800
        serial_clk_div <= 0;
        serial_clk <= ~serial_clk;
    end else begin
        serial_clk_div <= serial_clk_div + 1;
    end
end


always @(posedge clk_divided) begin
    if (reset) begin
        state <= 8'd0;
        cs <= 1'b0; // Chip select inactive
    end else begin
        case (state)
            8'd0: begin
                // Initialize ACIA 6850 Control Register
                addr_reg <= 16'h0000; // Control/Status Register
                DO <= 8'b0_00_101_11 ;  // Reset command:
                    // bit 7: 0 = No receive interrupt
                    // bit 6-5: 00 = RTS low, transmitting interrupts disabled
                    // bit 4-2: 101 = 8 bits, no parity, 1 stop bit
                    // bit 1-0: 00 = reset condition
                r_wn <= 1'b0;         // Write
                cs <= 1'b1;         // Chip select active
                state <= 8'd1;
                led2_reg <= 0;
                loop_counter <= 0;
            end
            8'd1: begin
                // Set Baud Rate to clk divided by 1.
                addr_reg <= 16'h0000; // Control/Status Register
                `ifndef SIM
                    DO <= 8'b0_00_101_01 ;  // Set command:
                        // bit 7: 0 = No receive interrupt
                        // bit 6-5: 00 = ??
                        // bit 4-2: 101 = 8 bits, no parity, 1 stop bit
                        // bit 1-0: 00 = clk divided by 1
                `else
                    DO <= 8'b0_00_101_00 ;  // For simulation use:
                        // bit 7: 0 = No receive interrupt
                        // bit 6-5: 00 = ??
                        // bit 4-2: 101 = 8 bits, no parity, 1 stop bit
                        // bit 1-0: 00 = clk divided by 16
                `endif  
                r_wn <= 1'b0;         // Write
                cs <= 1'b1;         // Chip select active
                state <= 8'd2;
                led2_reg <= 1;
            end
            8'd2: begin
                // Check Status Register, wait for Transmit Data Register Empty
                addr_reg <= 16'h0000; // Control/Status Register
                r_wn <= 1'b1;         // Read
                cs <= 1'b1;         // Chip select inactive
                if (DI[1] == 1'b1) begin
                    state <= 8'd3;  // Transmit Data Register: byte transferred
                end
            end
            8'd3: begin
                // Send a test character
                addr_reg <= 16'h0001; // Transmit Data Register
                DO <= byte_to_send;         // ASCII 'A'
                r_wn <= 1'b0;         // Write
                state <= 8'd4;  // Wait before sending next character
                cs <= 1'b1;         // Chip select active
                byte_to_send <= byte_to_send + 1; // Next character
            end
            8'd4: begin
                // wait some time before sending next character
                addr_reg <= 16'h0000;
                DO <= 8'b0;         // No operation
                r_wn <= 1'b1;         // Read
                cs <= 1'b0;         // Chip select inactive
                `ifndef SIM
                    if (loop_counter < 500_000) begin     // Wait some time
                `else
                    if (loop_counter < 2) begin           // Shorter wait for simulation
                `endif
                    loop_counter <= loop_counter + 1;
                end else begin
                    loop_counter <= 0;
                    state <= 8'd2; // Go back to check status and send next character later
                end
            end
            default: state <= 8'd0;
        endcase
    end
end

endmodule
