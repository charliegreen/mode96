#include "videoMode.def.h"
	
	.section .text

	.global	begin_code_tile_row

;;; NOTE: maximum possible resolution (at least, for uzem) appears to be around 2 cycles/pixel.
;;; Observing 67 _tile_bg loops to get a perfect screen fit at 13 cycles/_tile_bg (17 cycles per
;;; loop), plus 15 cycles up front for _tile_scanline_start and 16 for _tile_scanline_end
;;; (one more because of end of loop), for a total of 67*17+15+16 = 1170 cycles per 6*69 = 414 pixels,
;;; giving us an end result of 2.826 cycles/pixel

;;; ========================================
;;; Expects:
;;;   Y: set to beginning of current row of VRAM
;;;   r25: tile row counter (0-7)
;;;   r24: tile Y index
begin_code_tile_row:
	;; ---------------------------------------- initial register values
	ldi	r16, FONT_TILE_SIZE
	mov	r5, r16
	ldi	r16, 8		; only go through this many tiles before returning
	;; ldi	r16, 4
	mov	r6, r16

	.global begin_code_tile_row_bkpt
begin_code_tile_row_bkpt:

	;; pm converts from byte addresses to word addresses (divides by 2)
	ldi	r22, lo8(pm(code_tile_table_base))
	ldi	r23, hi8(pm(code_tile_table_base))

	;; add row index
	ldi	r16, FONT_TILE_WIDTH
	mul	r25, r16
	add	r22, r0
	adc	r23, r1

	;; Set VRAM pointer to correct value

	ldi	YL, lo8(vram)
	ldi	YH, hi8(vram)
	
	;; ldi	r16, SCREEN_TILES_H*3/2
	ldi	r16, 8*3/2
	mul	r24, r16
	add	YL, r0
	adc	YH, r1
	
	ldi	XH, hi8(m96_palette)

	;; ---------------------------------------- load first tile's colors
	ld	r4, Y+
	ld	r20, Y
	swap	r20
	andi	r20, 0x0F

	lsl	r20
	ldi	XL, lo8(m96_palette)
	add	XL, r20

	ld	r19, X+
	ld	r18, X

	mul	r4, r5
	add	r0, r22
	adc	r1, r23
	movw	r30, r0
	
	dec	r6
	ijmp

.macro TILE_ROW n,p0,p1,p2,p3,p4,p5
_tile_\n:
	out	VIDEO_PORT, \p0
	
	;; ---------------------------------------- read VRAM
	sbrs	r6, 0
	rjmp	1f

	;; color, then text
	ld	r20, Y+
	out	VIDEO_PORT, \p1
	ld	r4, Y+
	rjmp	2f
1:
	ld	r4, Y+
	out	VIDEO_PORT, \p1
	ld	r20, Y
	swap	r20
2:
	;; out	VIDEO_PORT, \p1
	out	VIDEO_PORT, \p2
	andi	r20, 0x0F

	;; ---------------------------------------- loading colors
	lsl	r20

	ldi	XL, lo8(m96_palette)
	add	XL, r20

	out	VIDEO_PORT, \p3

	;; ---------------------------------------- loading next tile
	mul	r4, r5

	add	r0, r22
	out	VIDEO_PORT, \p4
	adc	r1, r23

	movw	r30, r0

	dec	r6		; we can move this up here because out and ld don't modify SREG

	out	VIDEO_PORT, \p5
	
	;; load colors
	ld	r19, X+
	ld	r18, X
	
	breq	.+2
	ijmp
	ret
.endm

#define F r19
#define _ r18	
	
code_tile_table_base:
	TILE_ROW	0_0	_ _ _ _ _ _
	TILE_ROW	0_1	_ _ F F _ _
	TILE_ROW	0_2	_ F F F F _
	TILE_ROW	0_3	_ F F F F _
	TILE_ROW	0_4	_ _ F F _ _
	TILE_ROW	0_5	_ _ _ _ _ _
	TILE_ROW	0_6	F _ F _ F _
	TILE_ROW	0_7	_ F _ F _ F

	TILE_ROW	1_0	_ _ _ _ _ _
	TILE_ROW	1_1	_ F F F _ _
	TILE_ROW	1_2	F _ _ _ F _
	TILE_ROW	1_3	F _ _ _ F _
	TILE_ROW	1_4	F F F F F _
	TILE_ROW	1_5	F _ _ _ F _
	TILE_ROW	1_6	F _ _ _ F _
	TILE_ROW	1_7	F _ _ _ F _

	TILE_ROW	2_0	_ _ _ _ _ _
	TILE_ROW	2_1	F F F F _ _
	TILE_ROW	2_2	F _ _ _ F _
	TILE_ROW	2_3	F _ _ _ F _
	TILE_ROW	2_4	F F F F _ _
	TILE_ROW	2_5	F _ _ _ F _
	TILE_ROW	2_6	F _ _ _ F _
	TILE_ROW	2_7	F F F F _ _

#undef F
#undef _	
	
;; 	.rept	FONT_TILE_SIZE*0x30
;; 	nop
;; 	.endr
;; error_tile:
;; 	;; a tile that will be rendered if we ever read the wrong tile index and jump too far
;; 	ldi	r16, 0x07	; BRIGHT RED
;; 	out	VIDEO_PORT, r16
	
;; 	ldi	r17, 0x38	; BRIGHT GREEN
;; 	nop
;; 	nop

;; 	out	VIDEO_PORT, r17
;; 	nop
;; 	nop
;; 	nop

;; 	out	VIDEO_PORT, r16
;; 	nop
;; 	nop
;; 	nop

;; 	out	VIDEO_PORT, r17
;; 	nop
;; 	nop
;; 	nop

;; 	out	VIDEO_PORT, r16
;; 	nop
;; 	nop
;; 	nop

;; 	out	VIDEO_PORT, r17
;; 	ret
