.6502

; this program is a simple monitor program that support the following commands:
; B - blink the LED once for 1second
; AXXXX - set address, where XXXX is 4 hex digits
; ? - display current address
; D - dump 16 bytes from the current address, and increment address by 16
; PXX - put byte XX at current address, increment address by 1
; G - start execution on the current address
; R - set address to 0x0000
; T - toggle debug flag
; it uses the 6532 timer to generate delays for serial output

#define RIOT_BASE 0x80
#define DRA      RIOT_BASE + 0x00 ;DRA ('A' side data register)
#define DDRA     RIOT_BASE + 0x01 ;DDRA ('A' side data direction register)
#define DRB      RIOT_BASE + 0x02 ;DRB ('B' side data register)
#define DDRB     RIOT_BASE + 0x03 ;DDRB('B' side data direction register)
#define READTDI  RIOT_BASE + 0x04 ;Read timer (disable interrupt)

#define WEDGC    RIOT_BASE + $04 ;Write edge-detect control (negative edge-detect,disable interrupt)
#define RRIFR    RIOT_BASE + $05 ;Read interrupt flag register (bit 7 = timer, bit 6 PA7 edge-detect) Clear PA7 flag
#define A7PEDI   RIOT_BASE + $05 ;Write edge-detect control (positive edge-detect,disable interrupt)
#define A7NEEI   RIOT_BASE + $06 ;Write edge-detect control (negative edge-detect, enable interrupt)
#define A7PEEI   RIOT_BASE + $07 ;Write edge-detect control (positive edge-detect enable interrupt)

#define READTEI  RIOT_BASE + $0C ;Read timer (enable interrupt)
#define WTD1DI   RIOT_BASE + $14 ;Write timer (divide by 1, disable interrupt)
#define WTD8DI   RIOT_BASE + $15 ;Write timer (divide by 8, disable interrupt)
#define WTD64DI  RIOT_BASE + $16 ;Write timer (divide by 64, disable interrupt)
#define WTD1KDI  RIOT_BASE + $17 ;Write timer (divide by 1024, disable interrupt)

#define WTD1EI   RIOT_BASE + $1C ;Write timer (divide by 1, enable interrupt)
#define WTD8EI   RIOT_BASE + $1D ;Write timer (divide by 8, enable interrupt)
#define WTD64EI  RIOT_BASE + $1E ;Write timer (divide by 64, enable interrupt)
#define WTD1KEI  RIOT_BASE + $1F ;Write timer (divide by 1024, enable interrupt)


#define BAUD_DELAY 21   ; Approx delay for 4800 baud at 1MHz clock, divided by 8 timer
#define HALF_DELAY 10   ; 0.5 bit delay for sampling in middle of bit period

#define jsr_opcode 0x10
#define addr_low 0x11
#define addr_high 0x12
#define receive_byte 0x13
#define old_addr_low 0x14
#define old_addr_high 0x15
#define debug_flag 0x16
#define temp_addr_low 0x17
#define temp_addr_high 0x18

#define txbyte 0x20
#define rxbyte 0x21
#define cntr1 0x22


.org 0x1000
start:
    cld                 ; clear decimal mode
    sei                 ; disable interrupts

    ldx #$7f            ; Load X register with 127 (stack starts from top of memory)
    txs                 ; Transfer X to stack pointer    

    lda #0b0110_0000    ; Initialize DRB with bit 6 set to 1, rest to 0, DRB5 is TX idle high
    sta DRB

    lda #0b1010_0000    ; Set B register direction: bit 4 is input RX, bit 5 is output TX, bit 6 is input button, bit 7 is output LED, 
    ;      lbtr_xxxx    l=led, b=button, t=tx, r=rx, x=unused
    sta DDRB

    lda #0x20           ; opcode for JSR
    sta jsr_opcode

    jsr send_done      ; send initial prompt


;--------------------------------------------------------------------------------------------
; this is the main loop that waits for commands and executes them
;--------------------------------------------------------------------------------------------
main_loop:
    jsr receivebyte_blocking     ; wait for a byte to be received

    cmp #10             ; 'LF' character ignored
    beq main_loop
    cmp #13             ; 'CR' character ignored
    beq main_loop

    cmp #0x41           ; 'A' command to set address
    beq set_address_cmd

    cmp #0x42           ; 'B' command to blink LED
    beq blink_led_cmd

    cmp #0x3F           ; '?' command to display current address
    beq display_address_cmd

    cmp #0x44           ; 'D' command to dump 16 bytes from current address
    beq dump_memory_cmd

    cmp #0x50           ; 'P' command to put byte at current address
    beq put_byte_cmd

    cmp #0x47           ; 'G' command to go execute from current address
    beq go_execute_cmd

    cmp #0x52           ; 'R' command to reset address to 0x0000
    beq reset_address_cmd

    cmp #0x54           ; 'T' command to toggle debug flag
    beq toggle_debug_flag_cmd

    ; Unknown command, send ! prompt
    lda #0x21           ; send '!' character to indicate unknown command
    jsr sendbyte
    jsr send_crln

    jmp main_loop


toggle_debug_flag_cmd:
    lda #0x01
    eor debug_flag
    sta debug_flag

    jsr send_done
    jmp main_loop

;--------------------------------------------------------------------------------------------
; this is the set address command handler, expects 4 hex digits and sets addr_high and addr_low
;--------------------------------------------------------------------------------------------    
set_address_cmd:
    jsr receive_hex_byte
    sta addr_high

    jsr receive_hex_byte
    sta addr_low

    jsr send_done
    jmp main_loop

;--------------------------------------------------------------------------------------------
; this is the reset address command handler, sets address to 0x0000
;--------------------------------------------------------------------------------------------
reset_address_cmd:
    lda addr_low
    sta old_addr_low
    lda addr_high
    sta old_addr_high

    lda #0x00
    sta addr_high
    sta addr_low

    jsr send_done
    jmp main_loop

;--------------------------------------------------------------------------------------------
; this is the blink LED command handler, blinks the LED once for 1 second
;--------------------------------------------------------------------------------------------
blink_led_cmd:
    jsr blink_led

    jsr send_done
    jmp main_loop

;--------------------------------------------------------------------------------------------
; this is the display address command handler, displays current address
;--------------------------------------------------------------------------------------------  
display_address_cmd:
    lda addr_high
    jsr send_hex_byte
    
    lda addr_low
    jsr send_hex_byte

    jsr send_crln
    jmp main_loop

;--------------------------------------------------------------------------------------------
; this is the dump memory command handler, dumps 16 bytes from current address
;--------------------------------------------------------------------------------------------  
dump_memory_cmd:
    jsr do_dump
    jmp main_loop

;--------------------------------------------------------------------------------------------
; this is the put byte command handler, expects 2 hex digits and puts byte at current address
;--------------------------------------------------------------------------------------------      
put_byte_cmd:
    jsr receive_hex_byte
    ldy #0x00
    sta (addr_low),Y

    inc addr_low
    bne no_high_inc2
    inc addr_high
no_high_inc2:

    jsr send_done
    jmp main_loop

;--------------------------------------------------------------------------------------------
; this is the execute command handler, calls to address as subroutine to start execution
;--------------------------------------------------------------------------------------------  
go_execute_cmd:
    jmp $0010       ; jump to address 0x0010 to start execution
                    ; address $10 contains the JSR opcode
                    ; address $11 contains the low byte of the address to call to
                    ; address $12 contains the high byte of the address to call to
    jsr send_done
    jmp main_loop

do_dump:
    lda #16
    sta cntr1
dump_loop:
    ldy #0x00
    lda (addr_low),Y
    jsr send_hex_byte

    inc addr_low
    bne no_high_inc
    inc addr_high
no_high_inc:

    dec cntr1
    beq dump_done

    lda #0x20
    jsr sendbyte
    jmp dump_loop
dump_done:
    jsr send_crln
    rts    

;--------------------------------------------------------------------------------------------
; this send done command handler, sends '#' character followed by CRLF
;--------------------------------------------------------------------------------------------  
send_done:
    lda #0x23      ; send '#' character to indicate done
    jsr sendbyte

    lda debug_flag
    beq skip_debug

    lda addr_low
    sta temp_addr_low
    lda addr_high
    sta temp_addr_high
    lda #0x10
    sta addr_low
    lda #0x00
    sta addr_high
    jsr do_dump
    lda temp_addr_low
    sta addr_low
    lda temp_addr_high
    sta addr_high

skip_debug:
    jsr send_crln
    rts

;--------------------------------------------------------------------------------------------
; this send CRLF command handler, sends carriage return and line feed
;--------------------------------------------------------------------------------------------
send_crln:
    lda #0x0D        ; send carriage return
    jsr sendbyte       
    lda #0x0A        ; send line feed
    jsr sendbyte
    rts

;--------------------------------------------------------------------------------------------
; this is the receive hex byte command handler:
;     receives two ASCII hex digits and converts to binary byte
;     results stored in receive_byte, but also returned in accumulator
;--------------------------------------------------------------------------------------------
receive_hex_byte:
    jsr receivebyte_blocking         ; get high nibble
    jsr asciihex_to_bin     ; convert ASCII hex to binary
    asl
    asl
    asl
    asl
    sta receive_byte        ; store in temp location

    jsr receivebyte_blocking         ; get low nibble
    jsr asciihex_to_bin     ; convert ASCII hex to binary
    ora receive_byte        ; combine high and low nibbles
    sta receive_byte        ; store combined byte
    rts
;--------------------------------------------------------------------------------------------
; this is the send hex byte command handler:
;     converts binary byte in accumulator to two ASCII hex digits and sends them
;--------------------------------------------------------------------------------------------
send_hex_byte:
                            ; input byte in A
                            ; send high nibble
    pha                     ; save A on stack
    lsr                     ; shift right 4 bits to get high nibble in low nibble position
    lsr
    lsr
    lsr
    jsr bin_to_asciihex     ; convert to ASCII hex
    jsr sendbyte            ; send high nibble

    pla                     ; restore original byte
    and #0x0F               ; mask to get low nibble
    jsr bin_to_asciihex     ; convert to ASCII hex
    jsr sendbyte            ; send low nibble
    rts 

;--------------------------------------------------------------------------------------------
; Binary to ASCII hex character conversion
; input: A = binary value 0-15
; output: A = ASCII hex character '0'-'9', 'A'-'F
;--------------------------------------------------------------------------------------------
bin_to_asciihex:
    and #$0F          ; ensure only low nibble
    cmp #$0A
    bcc b2a_below_10
    clc
    adc #$07          ; adjust for A-F
b2a_below_10:
    adc #$30          ; convert binary to ASCII hex
    rts

;--------------------------------------------------------------------------------------------
; ASCII hex character to binary conversion
; input: A = ASCII hex character '0'-'9', 'A'-'F
; output: A = binary value 0-15
;--------------------------------------------------------------------------------------------
asciihex_to_bin:
    sec
    sbc #$30          ; convert ASCII hex to binary
    cmp #$0A
    bcc a2b_below_10
    sec
    sbc #$07          ; adjust for A-F
a2b_below_10:
    rts


;--------------------------------------------------------------------------------------------
; this is the receive byte blocking function
;     wait for start bit and then
;     receives a byte from serial RX line into rxbyte, but accumulator also returns the byte
;--------------------------------------------------------------------------------------------
receivebyte_blocking:
    lda #0x00
    sta rxbyte         ; clear rxbyte
    lda DRB
    and #0b0001_0000     ; Mask to check RX line (bit 4)
    bne receivebyte_blocking ; If RX line is high, keep checking
    ; Start bit detected (line went low), simple countinue to receive byte
;--------------------------------------------------------------------------------------------
; this is the receive byte command handler, must be called when start bit has been detected
;     receives a byte from serial RX line into rxbyte, but accumulator also returns the byte
;--------------------------------------------------------------------------------------------
receivebyte:
    ; Initial: wait half bit time to sample in middle of bits
    lda #HALF_DELAY
    sta WTD8DI           ; start half bit delay in 6532 timer, disable interrupt, divide by 8
wait_halfbit:
    nop
    lda RRIFR
    bpl wait_halfbit    ; wait until timer expires, bit 7 = 0 means not expired
    ; Now read 8 data bits, rxbyte is not cleared, we will shift all bits into it
    ldx #0x8            ; 8 bits to read
readbitsloop:
    ; Wait full bit time
    lda #BAUD_DELAY
    sta WTD8DI           ; start full bit delay in 6532 timer, disable interrupt, divide by 8
wait_fullbit:
    nop
    lda RRIFR   
    bpl wait_fullbit    ; wait until timer expires, bit 7 = 0 means not expired
    ; Sample RX line
    lda DRB
    and #0b0001_0000    ; Mask to check RX line (bit 4)
    beq store0          ; If RX line is low, store 0
    ; Store 1
    sec                 ; Set carry to store 1
    jmp storebit
store0:
    clc                 ; Clear carry to store 0
storebit:
    ror rxbyte          ; Shift right and bring in carry bit into the rxbyte
    dex
    bne readbitsloop    ; loop until all bits read
    lda rxbyte
    rts

;--------------------------------------------------------------------------------------------
; this is the send byte command handler, sends byte in accumulator out serial TX line
;--------------------------------------------------------------------------------------------
sendbyte:               ; uses registers X, A
    sta txbyte          ; store byte to send in txbyte
    clc
    jsr sendbit         ; start bit (0)
    ldx #8              ; 8 data bits to send
sendbitsloop:
    lsr txbyte          ; LSB first, this shifts bit0 into carry
    jsr sendbit         ; send the bit in carry
    dex                 ; decrement bit counter
    bne sendbitsloop    ; loop until all bits sent
    sec                 ; set carry for stop bit (1)
    jsr sendbit         ; stop bit (1)
done_sending:
    rts

;--------------------------------------------------------------------------------------------
; this is the send bit command handler, sends bit in carry out serial TX line
; this is called by sendbyte to send each bit
;--------------------------------------------------------------------------------------------
sendbit:                ; uses register A only
    bcs send1
    lda #0b1101_1111
    and DRB
    jmp setbit
send1:
    lda #0b0010_0000
    ora DRB
setbit:
    sta DRB
    lda #BAUD_DELAY
    sta WTD8DI
waitbit:
    lda READTDI
    bne waitbit
    rts    
    
;--------------------------------------------------------------------------------------------
; this is the blink LED command handler, blinks the LED once for 1 second
;--------------------------------------------------------------------------------------------
blink_led:
    ; Byte received, blink the LED
    lda #0b1000_0000     ; Load A with bitmask to toggle LED (bit 7)
    eor DRB             ; Toggle bit 7 (LED)
    sta DRB             ; Store back to DRB
    
    lda #10           ; number of 100ms delays to keep LED on: 1 second
    jsr delay_nx100ms

    lda #0b1000_0000     ; Load A with bitmask to toggle LED (bit 7)
    eor DRB             ; Toggle bit 7 (LED)
    sta DRB             ; Store back to DRB
    rts

;--------------------------------------------------------------------------------------------
; this is the delay n times 100ms command handler, n is in Accumulator
; exact delay is approx 100.352 ms per count at 1MHz clock with divide by 1024 timer
;--------------------------------------------------------------------------------------------
delay_nx100ms:          ; delay n times 100ms, n is in Accumulator
    sta cntr1
delayn_loop:
    lda #98             ; approx 100ms delay at 1MHz clock with divide by 1024 timer
                        ; 100.352 ms (98 * 1024 / 1000))
    sta WTD1KDI         ; start long delay in 6532 timer, disable interrupt, divide by 1024
wait_tmr:
    lda READTDI
    bne wait_tmr
    dec cntr1
    bne delayn_loop
    rts

.org 0x1ffa
    dw start
    dw start
    dw start