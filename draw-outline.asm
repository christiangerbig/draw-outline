; ** Change relative includes path to an absolute path if it doesn't work **
	INCLUDE "includes/macros.i"

; ** Blitter line drawing registers **
DMACONR				EQU $0002
BLTCON0				EQU $0040
BLTAFWM				EQU $0044
BLTCPT				EQU $0048
BLTAPTL				EQU $0052
BLTDPT				EQU $0054
BLTSIZE				EQU $0058
BLTCMOD				EQU $0060
BLTBMOD				EQU $0062
BLTDMOD				EQU $0066
BLTBDAT				EQU $0072

; ** Blitter DMA **
DMAB_BLTDONE			EQU 14

; ** Blitter channels **
BC0F_DEST			EQU $0100										; ** Blitter channels **
BC0F_SRCC			EQU $0200
BC0F_SRCA			EQU $0800

; ** Blitter minterms **
ABNC				EQU $40											; ** Minterms **
NABC				EQU $08
NANBC				EQU $02

; ** Blitter line octants **
BLTCON1F_SIGN			EQU $0040
BLTCON1F_SUD			EQU $0010
BLTCON1F_AUL			EQU $0004
BLTCON1F_SING			EQU $0002
BLTCON1F_LINE			EQU $0001

; ** Line drawing mode **
bltcon0_bits			EQU BC0F_SRCA+BC0F_SRCC+BC0F_DEST+NANBC+NABC+ABNC
bltcon1_bits			EQU BLTCON1F_LINE+BLTCON1F_SING

; ** Playfield/Bitplane dimensions **
pf_x_size			EQU 320
pf_y_size			EQU 256
pf_depth			EQU 2
pf_plane_width			EQU pf_x_size/8
pf_plane_y_multiplier		EQU pf_plane_width*pf_depth


; ** Parameters **
; d0.l ... P1(x)
; d1.l ... P1(y)
; d2.l ... P2(x)
; d3.l ... P2(y)
; d7.w ... Colour number 1..3
; a2.l ... Pointer to interleaved bitplanes
; a6.l ... CUSTOM+DMACONR
draw_outline
	cmp.w	d1,d3
	beq	dol_no_line		;y1 = y2 ?
	bgt.s	dol_delta_y_positive	;y1 < y2 ?
	exg	d0,d2			;Swap x1 with x2 if y1 > y2
	exg	d1,d3			;Swap Y1 with Y2 if y1 > y2
dol_delta_y_positive
	addq.w	#1,d1			;For blunt edges
	moveq	#BLTCON1F_SUD,d5	;Octant #8
	sub.w	d0,d2			;dx = x2-x1
	bpl.s	dol_delta_x_positive	;dx = positive ?
	addq.w	#BLTCON1F_AUL,d5	;Octant #5
	neg.w	d2			;Toggle sign bit
dol_delta_x_positive
	sub.w	d1,d3			;dy = y2-y1
	ror.l	#4,d0			;Shift-Bits -> bits 12-15
	MULUF.W pf_plane_y_multiplier/2,d1,d4 ;Get y offset
	add.w	d0,d1			;x + y offset
	add.l	d1,d1			;Get correct x/y offset in bitplanes
	cmp.w	d2,d3
	ble.s	dol_delta_positive	;dx <= dy ?
	sub.w	#BLTCON1F_SUD,d5	;Clear octant SUD bit
	exg	d2,d3			;Swap dx with dy if dx > dy
	add.w	d5,d5			;Octant #6,7
dol_delta_positive
	add.w	d3,d3			;dy*4
	add.w	d3,d3
	move.w	d5,d0			;Save octant
	move.w	d3,d4			;Save 4*dy
	swap	d4			;Hi-word: 4*dy
	add.w	d2,d2			;dx*2
	move.w	d3,d4			;4*dy
	sub.w	d2,d3			;(4*dy)-(2*dx)
	bpl.s	dol_no_sign_bit
	or.w	#BLTCON1F_SIGN,d0	;Set sign bit if (4*dy) < (2*dx)
dol_no_sign_bit
	add.w	d2,d2			;2*(2*dx) = 4*dx
	sub.w	d2,d4			;Lo-word: (4*dy)-(4*dx)
	addq.w	#1*4,d2			;(4*dx)+(1*4)
	lsl.w	#4,d2			;((4*dx)+(1*4))*16 = length of line
	addq.w	#2,d2			;Width = 1 word
	add.l	a2,d1
	add.l	#(bltcon0_bits<<16)+(bltcon1_bits),d0
	btst	#0,d7			;Bitplane 1 ?
	beq.s	dol_check_second_bitplane
	WAITBLIT
	move.l	d0,BLTCON0-DMACONR(a6)	;Hi-word: BLTCON0, Lo-word: BLTCON1
	move.w	d3,BLTAPTL-DMACONR(a6)	;(4*dy)-(2*dx)
	move.l	d1,BLTCPT-DMACONR(a6)	;Source bitplanes address
	move.l	d1,BLTDPT-DMACONR(a6)	;Destination bitplanes address
	move.l	d4,BLTBMOD-DMACONR(a6)	;Hi-word: 4*dy, Lo-word: (4*dy)-(4*dx)
	move.w	d2,BLTSIZE-DMACONR(a6)	;Start blitter operation
dol_check_second_bitplane
	btst	#1,d7			;Bitplane 2 ?
	beq.s	dol_no_line
	moveq	#pf_plane_width,d5
	add.l	d5,d1			;Next interleaved bitplane
	WAITBLIT
	move.l	d0,BLTCON0-DMACONR(a6)	;Hi-word: BLTCON0, Lo-word: BLTCON1
	move.w	d3,BLTAPTL-DMACONR(a6)	;(4*dy)-(2*dx)
	move.l	d1,BLTCPT-DMACONR(a6)	;Source bitplanes address
	move.l	d1,BLTDPT-DMACONR(a6)	;Destination bitplanes address
	move.l	d4,BLTBMOD-DMACONR(a6)	;Hi-word: 4*dy, Lo-word: (4*dy)-(4*dx)
	move.w	d2,BLTSIZE-DMACONR(a6)	;Start blitter operation
dol_no_line
	rts

	CNOP 0,4
dol_init
	WAITBLIT
	move.l	#$ffff8000,BLTBDAT-DMACONR(a6) ;Hi-word: line texture, Lo-word: start line texture with MSB
	moveq	#-1,d0
	move.l	d0,BLTAFWM-DMACONR(a6)	;No Mask
	moveq	#pf_plane_width*pf_depth,d0 ;Interleaved bitplane moduli
	move.w	d0,BLTCMOD-DMACONR(a6)
	move.w	d0,BLTDMOD-DMACONR(a6)
	rts

	END
