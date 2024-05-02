  INCLUDE "includes/macros.i"                  ;Change to absolute path if it doesn't work

DMACONR           EQU $0002
BLTCON0           EQU $0040
BLTAFWM           EQU $0044
BLTCPT            EQU $0048
BLTAPTL           EQU $0052
BLTDPT            EQU $0054
BLTSIZE           EQU $0058
BLTCMOD           EQU $0060
BLTBMOD           EQU $0062
BLTDMOD           EQU $0066
BLTBDAT           EQU $0072

DMAB_BLTDONE      EQU 14

BC0F_DEST         EQU $0100                    ; ** Blitter channels **
BC0F_SRCC         EQU $0200
BC0F_SRCA         EQU $0800

ABNC	          EQU $40                      ; ** Minterms **
NABC	          EQU $08
NANBC	          EQU $02

BLTCON1F_SIGN     EQU $0040
BLTCON1F_SUD      EQU $0010
BLTCON1F_AUL      EQU $0004
BLTCON1F_SING     EQU $0002
BLTCON1F_LINE     EQU $0001

BLTCON0BITS       EQU BC0F_SRCA+BC0F_SRCC+BC0F_DEST+NANBC+NABC+ABNC
BLTCON1BITS       EQU BLTCON1F_LINE+BLTCON1F_SING

pf_x_size         EQU 320
pf_y_size         EQU 256
pf_depth          EQU 2
pf_bitplane_width EQU pf_x_size/8

; ** Parameters **
; d0.l ... P1(x)
; d1.l ... P1(y)
; d2.l ... P2(x)
; d3.l ... P2(y)
; d7.w ... Colour number 1..3
; a2.l ... Pointer to interleaved bitplanes
; a6.l ... CUSTOM+DMACONR
draw_outline
  cmp.w   d1,d3
  beq     dol_no_line                          ;Y1 = Y2 ?
  bgt.s   dol_delta_y_positive                 ;Y1 < Y2 ?
  exg     d0,d2                                ;Swap X1 with X2
  exg     d1,d3                                ;Swap Y1 with Y2
dol_delta_y_positive
  addq.w  #1,d1                                ;For blunt edges
  moveq   #BLTCON1F_SUD,d5                     ;Octant #8
  sub.w   d0,d2                                ;dx = x2-x1
  bpl.s   dol_delta_x_positive                 ;dx = positive ?
  addq.w  #BLTCON1F_AUL,d5                     ;Octant #5
  neg.w   d2                                   ;Trigger sign bit
dol_delta_x_positive
  sub.w   d1,d3                                ;dy = y2-y1
  ror.l   #4,d0                                ;Shift-Bits to bits 12-15
  MULUF.W (pf_bitplane_width*pf_depth)/2,d1,d4 ;Y offset in bitmap
  add.w   d0,d1                                ;x + y offset
  add.l   d1,d1                                ;Get correct x/y offset
  cmp.w   d2,d3                                ;dx <= dy ?
  ble.s   dol_delta_positive
  sub.w   #BLTCON1F_SUD,d5
  exg     d2,d3                                ;Swap dx with dy
  add.w   d5,d5                                ;Octant #6,7
dol_delta_positive
  add.w   d3,d3                                ;dy*4
  add.w   d3,d3
  move.w  d5,d0                                ;Save Octant
  move.w  d3,d4                                ;Save 4*dy
  swap    d4                                   ;Bits 16-31: 4*dy
  add.w   d2,d2                                ;dx*2
  move.w  d3,d4                                ;Bits 0-15: 4*dy
  sub.w   d2,d3                                ;(4*dy)-(2*dx)
  bpl.s   dol_no_sign_bit                      ;Positive ?
  or.w    #BLTCON1F_SIGN,d0                    ;Set sign bit
dol_no_sign_bit
  add.w   d2,d2                                ;2*(2*dx) = 4*dx
  sub.w   d2,d4                                ;Bits 0-15: (4*dy)-(4*dx)
  addq.w  #1*4,d2                              ;(4*dx)+(1*4)
  lsl.w   #4,d2                                ;((4*dx)+(1*4))*16 = length of line
  addq.w  #2,d2                                ;Width = 1 word
  add.l   a2,d1                                ;Add bitplanes address
  add.l   #(BLTCON0BITS<<16)+(BLTCON1BITS),d0  ;Set constant  BLTCON0 & BLTCON1 bits
dol_check_first_bitplane
  btst    #0,d7                                ;Bitplane 1 ?
  beq.s   dol_check_second_bitplane
  WAITBLITTER
  move.l  d0,BLTCON0-DMACONR(a6)               ;Bits 31-16: BLTCON0, Bits 15-0: BLTCON1
  move.w  d3,BLTAPTL-DMACONR(a6)               ;(4*dy)-(2*dx)
  move.l  d1,BLTCPT-DMACONR(a6)                ;Source bitplanes address
  move.l  d1,BLTDPT-DMACONR(a6)                ;Destination bitplanes address
  move.l  d4,BLTBMOD-DMACONR(a6)               ;Bits 31-16: 4*dy, Bits 15-0: 4*(dy-dx)
  move.w  d2,BLTSIZE-DMACONR(a6)               ;Start blitter
dol_check_second_bitplane
  btst    #1,d7                                ;Bitplane 2 ?
  beq.s   dol_no_line
  moveq   #pf_bitplane_width,d5
  add.l   d5,d1                                ;Next bitplane
  WAITBLITTER
  move.l  d0,BLTCON0-DMACONR(a6)               ;Bits 31-16: BLTCON0, Bits 15-0: BLTCON1
  move.w  d3,BLTAPTL-DMACONR(a6)               ;(4*dy)-(2*dx)
  move.l  d1,BLTCPT-DMACONR(a6)                ;Source bitplanes address
  move.l  d1,BLTDPT-DMACONR(a6)                ;Destination bitplanes address
  move.l  d4,BLTBMOD-DMACONR(a6)               ;Bits 31-16: 4*dy, Bits 15-0: 4*(dy-dx)
  move.w  d2,BLTSIZE-DMACONR(a6)               ;Start blitter
dol_no_line
  rts

  CNOP 0,4
dol_init
  WAITBLITTER
  move.l  #$ffff8000,BLTBDAT-DMACONR(a6)      ;Bits 31-16: line texture, Bits 0-15: start line texture with MSB
  moveq   #-1,d0
  move.l  d0,BLTAFWM-DMACONR(a6)              ;No Mask
  moveq   #pf_bitplane_width*pf_depth,d0      ;Moduli for interleaved bitmaps
  move.w  d0,BLTCMOD-DMACONR(a6)
  move.w  d0,BLTDMOD-DMACONR(a6)
  rts

  END
