.6502

; this program is a simple serial receiver that blinks an LED when a byte is received
; it uses the 6532 timer to time the bits and reads from a serial input line

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

#define cntr1 0x21
#define rxbyte 0x21
#define textpointer 0x13

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

lp1:
    lda DRB
    and #0b0001_0000     ; Mask to check RX line (bit 4)
    bne lp1              ; If RX line is high, keep checking
    ; Start bit detected (line went low)
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
    
    ; Byte received, blink the LED
    lda #0b1000_0000     ; Load A with bitmask to toggle LED (bit 7)
    eor DRB             ; Toggle bit 7 (LED)
    sta DRB             ; Store back to DRB
    
    lda #10           ; number of 100ms delays to keep LED on: 1 second
    jsr delay_nx100ms

    lda #0b1000_0000     ; Load A with bitmask to toggle LED (bit 7)
    eor DRB             ; Toggle bit 7 (LED)
    sta DRB             ; Store back to DRB

    jmp lp1             ; Go back to checking for next byte

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