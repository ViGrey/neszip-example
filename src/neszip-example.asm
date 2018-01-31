;; Copyright (C) 2018, Vi Grey
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED. IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;; SUCH DAMAGE.

;;;;;;;;;;
;;
;; iNES Header
;;
;;;;;;;;;;

;;INES header setup
  .db "NES", $1A
  .db $01
  .db $01
  .db $00
  .db $00
  .db 0, 0, 0, 0, 0, 0, 0, 0 ;pad header to 16 bytes

;;;;;;;;;;
;;
;; Variables
;;
;;;;;;;;;;

;;Initialize Variables (Automatic)
  enum $10
addr dsb 2
drawAllowed dsb 1
  ende

  .base $c000


;;;;;;;;;;
;;
;; Reset Management
;;
;;;;;;;;;;

;; Run upon power on or reset
RESET:
  sei          ; disable IRQs
  cld          ; disable decimal mode, meant to make decimal arithmetic "easier"
  ldx #$40
  stx $4017    ; disable APU frame IRQ
  ldx #$FF
  txs          ; Set up stack
  inx          ; X overflows back to 0
  jsr DisableNMI
  jsr Blank
  stx $4010    ; disable DMC IRQs
  ldx #$00 ;reset x back to 0
  ldy #$00 ;reset y back to 0


;;;;;;;;;;
;;
;; Vblank Waits
;;
;;;;;;;;;;

;; First vblank wait to make sure PPU is ready
vwait1:
  lda $2002 ;wait
  bpl vwait1

;; Second vblank wait, PPU is ready after this
vwait2:
  lda $2002 ;wait
  bpl vwait2


;;;;;;;;;;
;;
;; Memory Clearing Management
;;
;;;;;;;;;;

;; Initialize memory and APU
Initialize:
  ldx #$00
InitializeLoop:
  ; reset all values of $0000 - $01FF and $0300 - $07FF back to 0
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  lda #$fe
  sta $0200, x    ;move all sprites off screen
  inx
  bne InitializeLoop ;repeat until x rolls back to 0
InitializeDone:
  ldx #$01
  stx drawAllowed
  lda #$00 ;reset A value
  ldx #$00 ;reset X value
  ldy #$00 ;reset Y value


;;;;;;;;;;
;;
;; Palette/Background Initialization
;;
;;;;;;;;;;

;; Load initial palette data and background
  jsr LoadPalettes
  jsr LoadMainScreen
  jsr EnableNMI


;;;;;;;;;;
;;
;; Infinite Loop
;;
;;;;;;;;;;

Forever:
  jmp Forever


;;;;;;;;;;
;;
;; Game Main Loop
;;
;;;;;;;;;;

;; Game Main Loop
MAINLOOP: ;non-maskable interrupt (draw screen)
  ; Load graphics into PPU from the memory
  lda #$00
  sta $2003 ;set low byte (00) of the ram address
  lda #$02
  sta $4014 ;set high byte (02) of the ram address, start transfer
  jsr Draw
  ; Update game
  jsr Update
  jsr ResetScroll
MAINLOOPDone:
  rti ;return from interrupt


;;;;;;;;;;
;;
;; Draw Blank and Update
;;
;;;;;;;;;;

;set up and enable NMI
EnableNMI:
  lda #%10001000
  sta $2000
  rts

;set up the PPU
Draw:
  lda #%00011110
  sta $2001
  rts

DisableNMI:
  lda #$00
  sta $2000
  rts

Blank:
  lda #$00
  sta $2001    ; disable rendering
  rts

;update logic states
Update:
  rts


;;;;;;;;;;
;;
;; Palette Management
;;
;;;;;;;;;;

;; Load palette data
LoadPalettes:
  lda $2002 ;read PPU to reset write toggle
  lda #$3f
  sta $2006
  lda #$00 ;point $2006 to the nametable (0x3F00)
  sta $2006
  ldx #$00 ;set to start of palette
LoadPalettesLoop:
  lda PaletteData, x ;loads a 32 byte palette
  sta $2007
  inx
  cpx #$20
  bne LoadPalettesLoop
  rts


;;;;;;;;;;
;;
;; Background Management
;;
;;;;;;;;;;

;; Reset sprite values
ClearSprites:
  lda #$fe
  sta $0200, x    ;move all sprites off screen
  inx
  bne ClearSprites ;repeat until x rolls back to 0
  rts

LoadMainScreen:
  jsr ClearSprites
  jsr Blank
  ;get high and low byte of lobby screen nametable file
  lda #<(MainNametable)
  sta addr
  lda #>(MainNametable)
  sta (addr + 1)
  ;set to start of title screen nametable
  lda #$20
  sta $2006
  lda #$00  ;point $2006 to the nametable (0x2000)
  sta $2006
  ;set counter of 4 for x, y will iterate 256 times per x counter
  ldx #$04
  ldy #$00
LoadMainScreenLoop: ;loop through and load nam file into PPU
  lda (addr), y
  sta $2007
  iny
  bne LoadMainScreenLoop ;loop if y is not 0
  inc (addr + 1)
  dex ;decrement x by 1 to indicate one set of y iterations is finished
  bne LoadMainScreenLoop ;loop if x is not 0
LoadMainScreenDone:
  jsr ResetScroll
  rts

ResetScroll:
  lda #$00
  sta $2005
  sta $2005 ;Reset scroll by passing #$0000 to $2005
  rts


;;;;;;;;;;
;;
;; Values And Files
;;
;;;;;;;;;;

MainNametable:
  .incbin "graphics/main.nam" ;nametable data, must be 1024 bytes long

PaletteData:
  .incbin "graphics/palette.pal" ;palette data, must be 36 bytes long

  .org  $fffa

nescallback:
  .dw   MAINLOOP ;(NMI_Routine)
  .dw   RESET ;(Reset_Routine)
  .dw   0 ;(IRQ_Routine)

  .base $0000
  .incbin "graphics/tileset.chr" ;must be 8192 bytes long

