;nenemark2 i2c bitbanging
;for details on how i2c works, the NXP PCF8574 datasheet is quite good
;nenemark2 i2c circuit is designed to set 0 on a line when the corresponding bit is set

;some defines
SDA = (1 << 1)
SCL = (1 << 0)
NSDA = $FF ^ SDA
NSCL = $FF ^ SCL

;macros
  .macro tick_clock
  eor #SCL
  sta NENEIO
  ora #SCL
  sta NENEIO
  .endmacro

  .macro send_zero
  lda NENEIORS;get saved state, don't need to save it as it will be reset to this
  
  tick_clock
  .endmacro

  .macro send_one
  lda NENEIORS;get saved state, don't need to save it as it will be reset to this

  eor #SDA;set sda high
  sta NENEIO
  tick_clock
  ora #SDA;set sda low
  sta NENEIO
  .endmacro
  
;functions
i2cStart:; sets sda then scl low
  pha
  lda NENEIORS
  ora #SDA
  sta NENEIO
  ora #SCL
  sta NENEIO
  sta NENEIORS
  pla
  rts


i2cStop:; sets scl then sda high
  pha
  lda NENEIORS
  and #NSCL
  sta NENEIO
  and #NSDA
  sta NENEIO
  sta NENEIORS
  pla
  rts

i2cWrite:; data in a, sets x to zero. sda and scl should be low, returns 0 on ACK and 1 on NACK (that is, the line state)
  ldx #$09
  pha
  .loop:
    pla
    dex
    beq .get_ack
    rol
    pha
    bcc .zero
  
  .one:
    send_one
    jmp .loop
  .zero:
    send_zero
    jmp .loop
  .get_ack:
    jsr get_bit
    rts


i2cRead:; reads a byte from the i2c bus into a, sets x to 0. sda and scl should be low
  ldx #$09
  lda #$00
  pha
  .loop:
    dex
    beq .end
    jsr get_bit
    ror ;put bit in carry
    pla
    rol ;shift and put carry in bit 0
    pha
    jmp .loop
  .end:
    pla
    rts

get_bit:; reads a bit on the i2c bus into a
  lda NENEIORS;get saved state, don't need to save it as it will be reset to this
  eor #SDA;set sda then scl high
  sta NENEIO
  eor #SCL
  sta NENEIO
  
  lda NENEIO;get bit
  and #SDA
  beq .zero
  .one:
    lda #$01
  .zero:
    pha
    lda NENEIORS;set scl then sda low
    ora #SCL
    sta NENEIO
    ora #SDA
    sta NENEIO
    pla
    rts

i2cAck:;sda and scl should be low
  pha
  send_zero
  pla
  rts
  
i2cNack:;sda and scl should be low
  pha
  send_one  
  pla
  rts
