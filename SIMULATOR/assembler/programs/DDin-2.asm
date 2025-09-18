; Double Dabble: 3-digit BCD -> 8-bit binary
; Input: IN &02 (ones), IN &03 (tens), IN &04 (hundreds)
; Output: binary stored at &30

; RAM usage:
; &10 = hundreds
; &11 = tens
; &12 = ones
; &13 = result (binary)
; &14 = loop counter

        ; ---- Input BCD digits ----
        IN  &02
        STA &12         ; ones
        IN  &03
        STA &11         ; tens
        IN  &04
        STA &10         ; hundreds

        LDA #00
        STA &13         ; result = 0

        LDA #08
        STA &14         ; loop counter = 8

dd_loop:
        ; ---- Step 1: add-3 correction if >=5 ----
        ; Hundreds
        LDA &10
        SUB #05
        JC skip_hund   ; if ACC < 5, skip add-3
        ADD #03
        STA &10
skip_hund:

        ; Tens
        LDA &11
        SUB #05
        JC skip_tens
        ADD #03
        STA &11
skip_tens:

        ; Ones
        LDA &12
        SUB #05
        JC skip_ones
        ADD #03
        STA &12
skip_ones:

        ; ---- Step 2: shift left ----
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

        ; ---- Step 3: decrement loop counter ----
        LDA &14
        DEC
        STA &14
        JNZ dd_loop

        ; ---- Done ----
        LDA &13
        STA &30
        HLT

