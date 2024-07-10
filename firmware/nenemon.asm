;nenemark2 monitor

NENEMON_ZP_BASE = $10
NENEMON_PTRAL = NENEMON_ZP_BASE + 0; pointer a, used by l
NENEMON_PTRBL = NENEMON_ZP_BASE + 1; pointer b, used by h
NENEMON_PTRTL = NENEMON_ZP_BASE + 2; temp pointer
NENEMON_PTRAH = NENEMON_ZP_BASE + 3; a high
NENEMON_PTRBH = NENEMON_ZP_BASE + 4; b high
NENEMON_PTRTH = NENEMON_ZP_BASE + 5; t high
NENEMON_PTRSAV= NENEMON_ZP_BASE + 6
NENEMON_REG   = NENEMON_ZP_BASE + 7; whether h has been issued
NENEMON_BUFFER = $0200

NENEMON_INPUT = ATFIN    ;input register
NENEMON_OUTPUT = char_to_screen ;output function (A = char)

  .org $9000; for easily determining size

nenemon:

  
  nm_start:
  ldy #$00               ;will use y as buffer pointer
  lda #$0A  
  jsr NENEMON_OUTPUT     ;output LF
  lda #'R'  
  jsr NENEMON_OUTPUT     ;output 'R'
  nm_newinput:
  lda #$00
  sta NENEMON_INPUT
  
  nm_waitforchar:
  jsr nenetalk_getchar   ;for serial input
  lda NENEMON_INPUT      ;expecting non-zero if a char is ready
  beq nm_waitforchar
  
  nm_handlechar:
  
  cmp #$7F               ;DEL?
  bne nm_notesc          ;skip if not
  
  nm_rubout:
  dey                    ;go back in buffer
  jsr NENEMON_OUTPUT     ;go back in screen
  lda #$20
  jsr NENEMON_OUTPUT     ;clear out char
  lda #$7F
  bmi nm_out             ;go back once again
  
  nm_notesc:
  sta NENEMON_BUFFER,y   ;store in buffer
  iny
  nm_out:
  jsr NENEMON_OUTPUT     ;output char
  
  cmp #$0A               ;LF ?
  bne nm_newinput        ;wait for annother char if not
  
  nm_processbuffer:
  sty NENEMON_PTRSAV
  ldy #$00
  
  nm_parse:; process buffer to only contain 0-F or commands with bit 7 set
  lda NENEMON_BUFFER,y
  eor #$30               ;flip bits so that 0-9 would appear as such
  cmp #$0A
  bcc .done              ;done if digit
  adc #$88               ;add 89 (carry set) so that A-F are 0xFA-FF
  cmp #$FA
  bcs .unset_high_nibble
  adc #$20               ;add 20 (carry clear) so that a-f are 0xFA-FF
  cmp #$FA
  bcs .unset_high_nibble
  adc #$F0               ;add F0 (carry clear) so that g-v are 0xF0-FF
  cmp #$F0
  bcs .command
  lda #$FF               ;map invalid stuff to 0xFF
  bne .done              ;zero cleared by lda
  .command:
    and #$8F
    bmi .done            ;negative flag is set
  .unset_high_nibble:
    and #$0F
  .done:
    sta NENEMON_BUFFER,y
    iny
    cpy NENEMON_PTRSAV
    bne nm_parse
  
  ldy #$00
  sty NENEMON_REG
  sty NENEMON_PTRTL
  sty NENEMON_PTRTH
  clv                  ;(maybe useless)for using bvc instead of jmp in the rest of the function
  nm_process:
  lda NENEMON_BUFFER,y
  bmi .command
  .digit:
    asl
    asl
    asl
    asl
    ldx #$04
  .shiftintoreg:
    asl
    rol NENEMON_PTRTL
    rol NENEMON_PTRTH
    dex
    bne .shiftintoreg
    bvc .done
  .command:
    and #$0F
    tax
    beq .run;'g'
    dex
    beq .regb;'h'
    dex
    beq .inc;'i'
    dex
    ;beq nm_display;'j'
    dex
    ;beq nm_display;'k'
    dex
    beq .rega;'l'
    dex
    beq .write;'m'
    bvc .done
  .run:
    jmp (NENEMON_PTRTL)
  .inc:
    inc NENEMON_PTRAL
    bne .incend
    inc NENEMON_PTRAH
    .incend:
    bvc .done
  .rega:
    ldx #$00
    bvc .movereg
  .regb:
    ldx #$01
    stx NENEMON_REG;upper boundary set
  .movereg:
    lda NENEMON_PTRTL
    sta NENEMON_PTRAL,x
    lda NENEMON_PTRTH
    sta NENEMON_PTRAH,x
    bvc .clean
  .write:
    lda NENEMON_PTRTL
    ldx #$00
    sta (NENEMON_PTRAL,x)
  .clean:  
    lda #$00
    sta NENEMON_PTRTH
    sta NENEMON_PTRTL
  .done:
    iny
    cpy NENEMON_PTRSAV
    bne nm_process
  
  nm_display:
    lda NENEMON_PTRAH
    sta NENEMON_PTRTH
    lda NENEMON_PTRAL
    sta NENEMON_PTRTL
    
    jsr nm_print_addr
    
    ldx #$00
  nm_print_data:
    lda (NENEMON_PTRTL,x)
    jsr nm_print_byte
    lda #' '
    jsr NENEMON_OUTPUT
    lda NENEMON_REG
    beq .end
    .incptr:
      inc NENEMON_PTRTL
      bne .cmpptr
      inc NENEMON_PTRTH
    .cmpptr:
      lda NENEMON_PTRTL
      cmp NENEMON_PTRBL
      lda NENEMON_PTRTH
      sbc NENEMON_PTRBH
      bcs .end
    .wrapcheck:
      lda NENEMON_PTRTL
      and #$07
      bne nm_print_data
      jsr nm_wrap
      jmp nm_print_data
    .end:
      jmp nm_start
      
;out of loop routines
  nm_wrap:
    lda #$0A
    jsr NENEMON_OUTPUT
  nm_print_addr:
    lda NENEMON_PTRTH
    jsr nm_print_byte
    lda NENEMON_PTRTL
    jsr nm_print_byte
    lda #' '
    jsr NENEMON_OUTPUT
    rts
  nm_print_byte:
    pha                  ;save lower nibble
    lsr                  ;put higher nibble to lower's place
    lsr
    lsr
    lsr
    jsr .print_hexdig    ;print higher
    pla                  ;print lower
    and #$0F
    .print_hexdig:
      ora #'0'
      cmp #':'
      bcc .print
      adc #$26           ;to get to 'a'-'f'
      .print:
        jsr NENEMON_OUTPUT
        rts
