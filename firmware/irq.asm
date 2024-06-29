;nenemark2 interrupt (AT keyboard clock) routine, and local keyboard routines

ATIOR = NENEIO
ATREG = NENETOP-6
ATCNT = NENETOP-7
ATFIN = NENETOP-8
ATNYA = NENETOP-9

init_at_regs:
  lda #$76
  sta ATCNT
  rts

irq:;keyboard clock is on irq pin
  ;irq entry takes 6 cycles (more or less)
  pha ;3
  
  lda ATIOR ;3 (signal is thus obtained in 12c)
  inc ATCNT ;5
  bmi .end;2 (3 if taken)
  ror ;2
  ror ATREG ;5
  pla ;4
  rti ;6 (done in 36c)
  .end:
  lda ATCNT;3
  cmp #$81;2
  bne .pass ;3
  lda #$76; code past here is not time-constrained
  sta ATCNT
  
  lda ATNYA
  cmp #$1
  bne .notafternopress
  dec ATNYA
  jmp .pass
  
  .notafternopress:
  txa ;save x
  pha
  
  ldx ATREG
  cpx #$F0
  bne .press
  inc ATNYA
  jmp .nopress
  .press:
  lda min_scancodes,x
  sta ATFIN; we have a char !
  
  .nopress:
  pla ;restore x
  tax
  .pass:
  
  pla ;4
  rti ;6 (done in 38c)
  
min_scancodes:
  ;      0123456789ABCDEF
  .byte "??????????????`?" ; 0
  .byte "?????q1???zsaw2?" ; 1
  .byte "?cxde43?? vftr5?" ; 2
  .byte "?nbhgy6???mju78?" ; 3
  .byte "?,kio09??./l;p-?" ; 4
  .byte "??'?[=????"
  .byte $0A;(enter)
  .byte            "]?\??" ; 5
  .byte "??????"
  .byte $7F;(backspace)
  .byte        "?????????" ; 6
  .byte "????????????????" ; 7
  .byte "????????????????" ; 8
