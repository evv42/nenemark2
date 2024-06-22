;nenemark2 misc routines and entry points
;defines here
NENETOP = $FF

NENEIO = $5000
NENEIORS = NENETOP-1

SCRPTR = NENETOP-2;modulo 32 for char pos, divide by 4 for line no.
SCRCHR = NENETOP-3
SCRADRH= NENETOP-4
SCRADRL= NENETOP-5

STRADRL= $02
STRADRH= $03

  .org $8000

nmi:
  rti

  .include "irq.asm"
  .include "i2c.asm"
  .include "neneio.asm"
  
reset:
  sei
  cld
  
  jsr pause;wait for voltages to be a bit more stable
  jsr pause
  jsr pause
  
  jsr clrmem
  
  lda #$FF
  tax
  txs
  
  lda #$03
  sta NENEIORS
  sta NENEIO
  
  jsr beep
  jsr pause
  
  jsr init_at_regs
  
  jsr init_screen
  jsr clear_screen
  outstr msg_init
  
test_lowmem:
  lda #$5A
  sta $100
  lda $900
  cmp #$5A
  beq .twokibs
  lda #'8'
  jmp .end
  .twokibs:
  lda #'2'
  .end:
  jsr char_to_screen
  outstr msg_lowmem


test_highmem:
  lda NENEIORS;set highmem page to zero
  and #$03
  sta NENEIO
  sta NENEIORS
  lda #$5A
  sta $6000
  lda $6000
  cmp #$5A
  beq .somekibs
  outchr '0'
  jmp .end
  .somekibs:
  lda $6800
  cmp #$5A
  bne .somemorekibs
  outchr '2'
  jmp .end
  .somemorekibs:
  lda NENEIORS;set highmem page to zero
  ora #$10
  sta NENEIO
  sta NENEIORS
  lda $6000
  cmp #$5A
  bne .onepage
  outchr '8'
  jmp .end
  .onepage:
  lda NENEIORS;set highmem page to zero
  and #$03
  ora #$40
  sta NENEIO
  sta NENEIORS
  lda $6000
  cmp #$5A
  bne .fullram
  outchr '3'
  outchr '2'
  jmp .end
  .fullram:
  outchr '1'
  outchr '2'
  outchr '8'
  .end:
  outstr msg_highmem
  lda NENEIORS;set highmem page to zero
  and #$03
  sta NENEIO
  sta NENEIORS

init_done:
  cli
boot_menu:
  outstr msg_menu

  .invalid:
  lda #$00
  sta ATFIN
  .waitforchar:
  jsr nenetalk_getchar
  lda ATFIN       ; Key ready?
  beq .waitforchar
  
  cmp #'n'
  beq start_nenemon
  cmp #'i'
  beq start_ipl
  jsr beep
  jmp .invalid
  
start_ipl:  
  outstr msg_ipl

  .res:
  lda #$00
  sta ATFIN
  .waitforchar:
  jsr nenetalk_getchar
  lda ATFIN       ; Key ready?
  beq .waitforchar
  
  jsr char_to_screen
  
  jmp .res
  
start_nenemon:
  outstr msg_mon
  jmp nenemon

  
  ;Messages here
msg_init:
  .ascii "nenemark2 pasocon",$0A,$00
msg_mon:
  .ascii "starting nenemon.",$0A,$00
msg_ipl:
  .ascii "starting IPL. send file !",$0A,$00
msg_menu:
  .ascii "n:nenemon i:ipl load",$0A,$00
msg_lowmem:
  .ascii "KB + ",$00
msg_highmem:
  .ascii "KB OK",$0A,$00
  
pause:
  ldx #$80
  .bigloop:
    ldy #$FF
    .smolloop:
      dey
      bne .smolloop
  dex
  bne .bigloop
  rts
  
clrmem:; clear the first 2kibs, except the stack page
  lda #$00
  ldx #$00
  .loop:
  sta $000,x
  sta $200,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne .loop
  rts
  
  .include "nenemon.asm"
  
  .org $FFFA
  .word nmi
  .word reset
  .word irq
