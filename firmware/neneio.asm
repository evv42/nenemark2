;nenemark2 screen and serial interface routines

;defines
BEEP = (1 << 2)
NBEEP = $FF ^ BEEP

;macros
  .macro outchr,char
  lda #\1
  jsr char_to_screen
  .endmacro

  .macro outstr,string
  lda #<\1
  sta STRADRL
  lda #>\1
  sta STRADRH
  jsr putstr
  .endmacro

;functions

beep:
  pha
  txa
  pha
  tya
  pha
  lda NENEIORS
  ldx #$FF
  .loop:
    eor #BEEP ;flip beep line
    sta NENEIO
    ldy #$3F
    .smolloop:
      nop
      dey
      bne .smolloop
    dex
    bne .loop
  and #NBEEP ;disable beep line
  sta NENEIORS
  pla
  tay
  pla
  tax
  pla
  rts

putstr:
  ldy #$00
  .loop:
    lda (STRADRL),y
    beq .pass
    jsr char_to_screen
    iny
    jmp .loop
  .pass:
    rts

nenetalk_getchar:
  pha
  txa
  pha
  tya
  pha
  jsr i2cStart
  lda #$01
  jsr i2cWrite
  jsr i2cRead
  cmp #$5A
  bne .nope
  jsr i2cAck
  jsr i2cRead
  sta ATFIN
  jsr i2cNack
  jsr i2cStop
  jmp .end
  .nope:
  jsr i2cNack
  jsr i2cStop
  .end:
  pla
  tay
  pla
  tax
  pla
  rts
  
init_screen:
  ldy #$00
  .loop:
    jsr i2cStart
    lda #$78
    jsr i2cWrite
    lda #$00
    jsr i2cWrite
    lda screeninit,y
    jsr i2cWrite
    jsr i2cStop
    iny
    cpy #$1E
    bne .loop
  rts
  
char_to_screen:
  sta SCRCHR
  txa
  pha
  tya
  pha
  ;send a copy to i2c address 0
  jsr i2cStart
  lda #$00
  jsr i2cWrite
  lda SCRCHR
  jsr i2cWrite
  jsr i2cStop
  ;end
  lda SCRCHR
  cmp #$0A ;LF?
  beq .linefeed
  cmp #$7F  ;DEL?
  beq .backspace
  lda #<screenfont
  sta SCRADRL
  lda #>screenfont
  sta SCRADRH
  ldx #$02
  .mul:
    lda SCRCHR
    adc SCRADRL
    sta SCRADRL
    bcc .cont
    inc SCRADRH
    clc
    .cont:
      dex
      bpl .mul
  ldy #$00
  jsr i2cStart
  lda #$78
  jsr i2cWrite
  lda #$40
  jsr i2cWrite
  .place_char:
    lda (SCRADRL),y
    jsr i2cWrite
    iny
    cpy #$03
    bne .place_char
  lda #$00
  jsr i2cWrite
  jsr i2cStop
  inc SCRPTR
  pla
  tay
  pla
  tax
  lda SCRCHR
  rts
  .linefeed:
    lda SCRPTR; go to next line
    and #$60
    adc #$20
    and #$60
    sta SCRPTR;store for future ref
    
    jsr set_scrptr
    jsr fill_line
    lda SCRPTR
    jsr set_scrptr
    
    pla
    tay
    pla
    tax
    lda SCRCHR
    rts
  .backspace:
    dec SCRPTR;go back one char
    
    jsr set_scrptr
    
    pla
    tay
    pla
    tax
    lda SCRCHR
    rts
  
set_scrptr:
  pha
  jsr i2cStart;prepare ssd1306 for reciving commands
  lda #$78
  jsr i2cWrite
  lda #$00
  jsr i2cWrite
  
  lda SCRPTR;set page (line)
  lsr
  lsr
  lsr
  lsr
  lsr ;A is now line number
  ora #$B4 ; set page start address
  jsr i2cWrite
  
  lda SCRPTR;set lower adress, (SCRPTR*4) & 15
  asl
  asl
  and #$0F
  jsr i2cWrite
  
  lda SCRPTR;set higer adress, (SCRPTR/4) & 7
  lsr
  lsr
  and #$07
  ora #$10
  jsr i2cWrite
  jsr i2cStop
  pla
  rts
  
fill_line:
  ldy #$80
  jsr i2cStart
  lda #$78
  jsr i2cWrite
  lda #$40
  jsr i2cWrite
  .loop:
    lda #$00
    jsr i2cWrite
    dey
    bne .loop
  jsr i2cStop
  rts 
  
clear_screen:
  jsr fill_line
  jsr fill_line
  jsr fill_line
  jsr fill_line
  rts

screeninit:; init code for ssd1306
  db $A8,$3F
  db $D3,$00
  db $40
  db $20,$00
  db $A1
  db $C8
  db $DA,$02
  db $81,$20
  db $D5,$80
  db $8D,$14
  db $D9,$22
  db $DB,$20
  db $22,$04,$07
  db $AF,$A4,$A6
screenreset:
  db $B4,$10,$00
  
  ;Font here
screenfont:
  db $FF,$FF,$FF;NUL
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $20,$30,$3C;LF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $20,$30,$3C;CR
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $FF,$FF,$FF
  db $00,$00,$00;space
  db $00,$5F,$00;!
  db $07,$00,$07;"
  db $3E,$14,$3E;#
  db $26,$6B,$32;$
  db $61,$1C,$43;%
  db $66,$59,$F6;&
  db $00,$03,$00;'
  db $1C,$22,$41;(
  db $41,$22,$1C;)
  db $2A,$1C,$2A;*
  db $08,$3E,$08;+
  db $00,$60,$00;,
  db $08,$08,$08;-
  db $00,$40,$00;.
  db $60,$1C,$03;/
  db $3E,$41,$3E;0
  db $00,$02,$7F;1
  db $71,$49,$46;2
  db $49,$49,$36;3
  db $0F,$78,$08;4
  db $4F,$49,$39;5
  db $3E,$49,$31;6
  db $01,$09,$7F;7
  db $36,$49,$36;8
  db $46,$49,$3E;9
  db $00,$36,$00;:
  db $00,$36,$10;;
  db $08,$14,$22;<
  db $14,$14,$14;=
  db $22,$14,$08;>
  db $02,$59,$06;?
  db $16,$71,$16;@
  db $7E,$11,$7E;A (maj)
  db $7F,$49,$36;B
  db $3E,$41,$41;C
  db $7F,$41,$3E;D
  db $7F,$49,$49;E
  db $7F,$09,$01;F
  db $3E,$41,$79;G
  db $7F,$08,$7F;H
  db $00,$7F,$00;I
  db $20,$40,$3F;J
  db $7F,$1C,$63;K
  db $7F,$40,$40;L
  db $7F,$04,$7F;M
  db $7F,$01,$7F;N
  db $7F,$41,$7F;O
  db $7F,$09,$06;P
  db $3E,$61,$7E;Q
  db $7F,$09,$76;R
  db $46,$49,$31;S
  db $01,$7F,$01;T
  db $3F,$40,$7F;U
  db $3F,$40,$3F;V
  db $7F,$10,$7F;W
  db $63,$1C,$63;X
  db $07,$78,$07;Y
  db $71,$49,$47;Z
  db $7F,$41,$41;[
  db $03,$1C,$60;\
  db $41,$41,$7F;]
  db $02,$01,$02;^
  db $80,$80,$80;_
  db $00,$01,$02;`
  db $20,$54,$78;A (min)
  db $7F,$44,$38;B
  db $38,$44,$28;C
  db $38,$44,$7F;D
  db $38,$54,$58;E
  db $08,$7E,$09;F
  db $98,$A4,$7C;G
  db $7F,$04,$78;H
  db $04,$7D,$00;I
  db $40,$80,$7D;J
  db $7F,$10,$6C;K
  db $41,$7F,$40;L
  db $7C,$18,$7C;M
  db $7C,$04,$78;N
  db $38,$44,$38;O
  db $FC,$24,$18;P
  db $18,$24,$FC;Q
  db $7C,$04,$08;R
  db $48,$54,$24;S
  db $04,$3E,$44;T
  db $3C,$40,$7C;U
  db $1C,$60,$1C;V
  db $7C,$30,$7C;W
  db $6C,$10,$6C;X
  db $9C,$A0,$7C;Y
  db $64,$54,$4C;Z
  db $08,$7F,$41;{
  db $00,$FF,$00;|
  db $41,$7F,$08;}
  db $10,$08,$10;~
  db $FF,$FF,$FF;DEL
