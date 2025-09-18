; ====================================================
; RATZAM-8 Test Program: Array manipulation + Stack
; ====================================================

; Define an array of 8 bytes
@myarray #08       ; Array 'myarray' of length 8
; Initialize array with some values
LDA #01
STA myarray[0]
LDA #03
STA myarray[1]
LDA #05
STA myarray[2]
LDA #07
STA myarray[3]
LDA #09
STA myarray[4]
LDA #0B
STA myarray[5]
LDA #0D
STA myarray[6]
LDA #0F
STA myarray[7]

; ----------------------
; Loop through array and sum values
; ----------------------
LDA #00            ; Clear accumulator
PSH ACC            ; Save initial accumulator on stack
LDT             ; Clear TMP (using LD_TMP optional instruction)
loop_start:
    ; Load next value from array
    LDA myarray[0]    ; Access index 0 for now
    ADD ACC, TMP       ; Add TMP (currently 0)
    PSH ACC            ; Save result on stack
    INC_MEM myarray[0] ; Increment index 0 (simulate pointer) 
    CMP ACC, #40       ; Compare with 0x40
    JLT loop_start     ; Repeat until sum >= 0x40
POP ACC             ; Restore last sum from stack

; ----------------------
; Output result
; ----------------------
OUT &01             ; Output accumulator to port 1

; Halt program
HLT
