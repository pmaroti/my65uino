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


#define BAUD_DELAY 21   ; Approx delay for 4800 baud at 1MHz clock, divided by 8 timer
; Calculated as: 1,000,000 / 4800 / 8 = 26, but needs tuning as processing takes time too approx 40 cycles per bit
; so actual delay is about 21: to be tested and adjusted as needed

#define txbyte 0x12
#define textpointer 0x13

.org 0x1000
start:
    cld
    sei

    ldx #$7f            ; Load X register with 127 (stack starts from top of memory)
    txs                 ; Transfer X to stack pointer        

    lda #0b0110_0000    ; Initialize DRB with bit 6 set to 1, rest to 0
    sta DRB

    lda #0b1010_0000    ; Set B register direction: bit 5 is output TX, bit 6 is input button, bit 7 is output LED
    sta DDRB

loop:
; Send text over serial
    lda #<text          ; low byte of text address
    sta textpointer     ; store in textpointer
    lda #>text          ; high byte of text address
    sta textpointer+1   ; store in textpointer+1
    jsr sendtext        ; send the text

; Blink LED
    lda #0b10000000     ; Load A with bitmask to toggle LED (bit 7)
    eor DRB             ; Toggle bit 7 (LED)
    sta DRB             ; Store back to DRB

; wait long approx 262ms
    lda #0xff
    sta WTD1KDI         ; start long delay in 6532 timer, disable interrupt, divide by 1024
waitlong:
    lda READTDI
    bne waitlong
    jmp loop

sendtext:               ; uses registers A, X, Y
    ldy #0              ; Y = 0 index into text
nextchar:
    lda (textpointer),y ; load byte from text
    beq done_sending    ; if zero byte, it is a termination character, done sending
    sta txbyte          ; store byte to send
    jsr sendbyte        ; send the byte
    iny                 ; increment Y to point to next character
    jmp nextchar        ; repeat for next character

sendbyte:               ; uses registers X, A
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

sendbit:                ; uses register A only
    bcs send1
    lda #0b1101_1111
    and DRB
    jmp storebit
send1:
    lda #0b0010_0000
    ora DRB
storebit:
    sta DRB
    lda #BAUD_DELAY
    sta WTD8DI
waitbit0:
    lda READTDI
    bne waitbit0
    rts


.org 0x1e00
text:
    .asciiz "Hello, 65uino World!\r\n"
  
.org 0x1ffa
    dw start
    dw start
    dw start