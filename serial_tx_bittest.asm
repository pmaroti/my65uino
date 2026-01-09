.6502

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
#define WTD1DI   RIOT_BASE + $14 ; Write timer (divide by 1, disable interrupt)
#define WTD8DI   RIOT_BASE + $15 ;Write timer (divide by 8, disable interrupt)
#define WTD64DI  RIOT_BASE + $16 ;Write timer (divide by 64, disable interrupt)
#define WTD1KDI  RIOT_BASE + $17 ;Write timer (divide by 1024, disable interrupt)

#define WTD1EI   RIOT_BASE + $1C ;Write timer (divide by 1, enable interrupt)
#define WTD8EI   RIOT_BASE + $1D ;Write timer (divide by 8, enable interrupt)
#define WTD64EI  RIOT_BASE + $1E ;Write timer (divide by 64, enable interrupt)
#define WTD1KEI  RIOT_BASE + $1F ;Write timer (divide by 1024, enable interrupt)

; Bitmasks for setting and clearing signals in Data Register B (DRB) (as hex)


#define BAUD_DELAY 26  ; Approx delay for 9600 baud at 1MHz clock, divided by 8 timer

#define cntr1 0x10
#define cntr2 0x11

#define txbyte 0x12
#define textpointer 0x13

.org 0x1000
start:
    cld ; clear decimal mode
    sei ; disable interrupts

    ldx #$7f   ; Load X register with 127 (stack starts from top of memory)
    txs        ; Transfer X to stack pointer    

    lda #0b0111_1111  ; Initialize DRB with bit 6 set to 1, rest to 0, DRB5 is TX idle high
    sta DRB

    lda #0b1011_1111  ; Set B register direction: bit 6 is input button, bit 7 is output LED, bit 5 is output TX
    sta DDRB

loop:
    clc
    jsr sendbit ; send bit 0

    sec
    jsr sendbit ; send bit 1

    jmp loop ; repeat forever

sendbit:
    bcs send1          ; if carry set, send 1
    lda #0b1101_1111   ; sending 0, clear bit 5 (TX) 
    and DRB            ; and keep other bits unchanged using AND operation
    jmp storebit
send1:
    lda #0b0010_0000   ; sending 1, set bit 5 (TX)
    ora DRB            ; and keep other bits unchanged using OR operation    
storebit:
    sta DRB            ; output the bit to TX line 
    lda #BAUD_DELAY    ; load delay count
    sta WTD8DI         ; start delay in 6532 timer, disable interrupt, divide by 1
waitbit:
    lda READTDI        ; read timer, disable interrupt
    bne waitbit        ; wait until timer reaches 0
    rts                ; return from sendbit

.org 0x1ffa
    dw start
    dw start
    dw start