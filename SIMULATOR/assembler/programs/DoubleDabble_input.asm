; Double Dabble 3-digit BCD -> 8-bit binary
; Input: IN &02 (ones), &03 (tens), &04 (hundreds)
; Output: binary stored at &30
; RAM: &10=hundreds, &11=tens, &12=ones, &13=result, &14=loop counter

        IN &02
        STA &12        ; ones
        IN &03
        STA &11        ; tens
        IN &04
        STA &10        ; hundreds

        LDA #00
        STA &13        ; result = 0
        LDA #08
        STA &14        ; loop counter = 8

dd_loop:
        ; Add-3 corrections
        LDA &10
        CMP ACC, #05
        JLT skip_hund
        ADD ACC, #03
        STA &10
skip_hund:
        LDA &11
        CMP ACC, #05
        JLT skip_tens
        ADD ACC, #03
        STA &11
skip_tens:
        LDA &12
        CMP ACC, #05
        JLT skip_ones
        ADD ACC, #03
        STA &12
skip_ones:

        ; Shift left across digits
        LDA &10
        SHL ACC
        STA &10

        LDA &11
        SHL ACC
        STA &11

        LDA &12
        SHL ACC
        STA &12

        LDA &13
        SHL ACC
        STA &13

        ; Decrement loop counter
        LDA &14
        DEC ACC
        STA &14
        CMP ACC, #00
        JGT dd_loop    ; continue until counter != 0

        ; Store result
        LDA &13
        STA &30
        HLT

