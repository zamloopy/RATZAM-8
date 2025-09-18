; Double Dabble 3-digit BCD -> 8-bit binary
; Input: IN &02 (ones), &03 (tens), &04 (hundreds)
; Output: binary (0–255) stored at &30

; RAM usage:
; &10 = hundreds
; &11 = tens
; &12 = ones
; &13 = result
; &14 = loop counter
; &15 = temp for comparisons

        ; ---- Input ----
        IN  &02
        STA &12         ; ones digit
        IN  &03
        STA &11         ; tens digit
        IN  &04
        STA &10         ; hundreds digit

        LDA #00
        STA &13         ; result = 0

        LDA #08
        STA &14         ; loop counter = 8

dd_loop:
        ; Step 1: check and add-3 corrections

        ; hundreds
        LDA &10
        STA &15         ; temp copy
        LDA #05
        STA &16         ; constant 5
        LDA &15
        SUB ACC,MDR     ; compute hundreds - 5 -> store in ACC? (simulate CMP)
        JC skip_hund
        LDA &10
        ADD ACC,TMP     ; add 3 correction using TMP? (simulate ADD #3)
        STA &10
skip_hund:

        ; tens
        LDA &11
        STA &15
        LDA #05
        STA &16
        LDA &15
        SUB ACC,MDR
        JC skip_tens
        LDA &11
        ADD ACC,TMP
        STA &11
skip_tens:

        ; ones
        LDA &12
        STA &15
        LDA #05
        STA &16
        LDA &15
        SUB ACC,MDR
        JC skip_ones
        LDA &12
        ADD ACC,TMP
        STA &12
skip_ones:

        ; Step 2: shift left across digits
        ; Shift hundreds -> tens -> ones -> result
        LDA &10
        SHL
        STA &10

        LDA &11
        SHL
        STA &11

        LDA &12
        SHL
        STA &12

        LDA &13
        SHL
        STA &13

        ; Step 3: loop counter
        LDA &14
        DEC
        STA &14
        JNZ dd_loop

        ; ---- Done ----
        LDA &13
        STA &30
        HLT

