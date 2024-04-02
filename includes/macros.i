WAITBLITTER MACRO
  tst.w   (a6)     ;For A1000 / A2000-A
wait_blit\@
  btst    #DMAB_BLTDONE-8,(a6)
  bne.s   wait_blit\@
  ENDM

MULUF MACRO
; \0 ... Size W/L
; \1 ... 16/32-Bit factor
; \2 ... Product
; \3 ... Scratch register
  IFEQ (\1)-40     
    move.\0  \2,\3 ;32x + 8x = 40x
    lsl.\0   #5,\2
    lsl.\0   #3,\3
    add.\0   \3,\2
  ENDC
  ENDM
