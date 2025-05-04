WAITBLIT			MACRO
; Input
; Result
	tst.w	(a6)			; for Agnus in Amiga 1000/2000-A: blitter busy bit bug
waitblit_loop\@
	btst	#DMAB_BLTDONE-8,(a6)
	bne.s	waitblit_loop\@
	ENDM


MULUF				MACRO
; Input
; \0	Size [W/L]
; \1 	16/32 bit factor
; \2 	Product
; \3 	Scratch register
; Result
	IFEQ (\1)-40
		move.\0  \2,\3		; (32*x)+(8*x) = 40*x
		lsl.\0   #5,\2
		lsl.\0   #3,\3
		add.\0   \3,\2
	ENDC
	ENDM
