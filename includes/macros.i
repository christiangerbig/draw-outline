WAITBLIT	MACRO
	tst.w	(a6)			;For OCS A1000/A2000-A blitter bug
waitblit_loop\@
	btst	#DMAB_BLTDONE-8,(a6)
	bne.s	waitblit_loop\@
		ENDM


MULUF		MACRO
; \0 ... Size W/L
; \1 ... 16/32-Bit factor
; \2 ... Product
; \3 ... Scratch register

; ** Multiply by 40 bytes **
	IFEQ (\1)-40
		move.\0  \2,\3		;32*x+8*x = 40*x
		lsl.\0   #5,\2
		lsl.\0   #3,\3
		add.\0   \3,\2
	ENDC
		ENDM
