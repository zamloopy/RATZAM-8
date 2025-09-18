; Double Dabble 3-digit BCD -> 8-bit binary
; Input: IN &02 (BCD ones)
;        IN &03 (BCD tens)
;        IN &04 (BCD hundreds)
; Output: binary stored at &30
; RAM: &10=hundreds, &11=tens, &12=ones, &13=result, &14=loop counter

        IN  &02
        STA &12       ; ones
        IN  &03
        STA &11       ; tens
        IN  &04
        STA &10       ; hundreds

        LDA #00
        STA &13       ; result = 0
        LDA #08
        STA &14       ; 8 shift iterations

dd_loop:
        ; add-3 corrections if >=5
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

        ; shift left across digits
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

        ; decrement loop counter
        LDA &14
        DEC
        STA &14
        CMP ACC, #00
        JNZ dd_loop   ; continue until counter = 0

        ; store result
        LDA &13
        STA &30
        HLT

