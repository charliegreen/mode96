#include "videoMode.def.h"
	
	.section .text

	.global	begin_code_tile_row

;;; ========================================
;;; Expects:
;;;   Y: set to beginning of current row of VRAM
;;;   r25: tile row counter (0-7)
;;;   r24: tile Y index
begin_code_tile_row:
	;; ---------------------------------------- initial register values
	ldi	r16, FONT_TILE_SIZE
	mov	r5, r16
	ldi	r16, SCREEN_TILES_H ; only go through this many tiles before returning
	mov	r6, r16

	;; pm converts from byte addresses to word addresses (divides by 2)
	ldi	r22, lo8(pm(m96_font))
	ldi	r23, hi8(pm(m96_font))

	;; add row index
	ldi	r16, FONT_TILE_WIDTH
	mul	r25, r16
	add	r22, r0
	adc	r23, r1

	;; Set VRAM pointer to correct value
	ldi	YL, lo8(vram)
	ldi	YH, hi8(vram)
	
	ldi	r16, SCREEN_TILES_H*3/2
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

;; #define F r19
;; #define _ r18	
	
;; m96_font:
;; 	TILE_ROW	0_0	_ _ _ _ _ _
;; 	TILE_ROW	0_1	_ _ F F _ _
;; 	TILE_ROW	0_2	_ F F F F _
;; 	TILE_ROW	0_3	_ F F F F _
;; 	TILE_ROW	0_4	_ _ F F _ _
;; 	TILE_ROW	0_5	_ _ _ _ _ _
;; 	TILE_ROW	0_6	F _ F _ F _
;; 	TILE_ROW	0_7	_ F _ F _ F

;; 	TILE_ROW	1_0	_ _ _ _ _ _
;; 	TILE_ROW	1_1	_ F F F _ _
;; 	TILE_ROW	1_2	F _ _ _ F _
;; 	TILE_ROW	1_3	F _ _ _ F _
;; 	TILE_ROW	1_4	F F F F F _
;; 	TILE_ROW	1_5	F _ _ _ F _
;; 	TILE_ROW	1_6	F _ _ _ F _
;; 	TILE_ROW	1_7	F _ _ _ F _

;; 	TILE_ROW	2_0	_ _ _ _ _ _
;; 	TILE_ROW	2_1	F F F F _ _
;; 	TILE_ROW	2_2	F _ _ _ F _
;; 	TILE_ROW	2_3	F _ _ _ F _
;; 	TILE_ROW	2_4	F F F F _ _
;; 	TILE_ROW	2_5	F _ _ _ F _
;; 	TILE_ROW	2_6	F _ _ _ F _
;; 	TILE_ROW	2_7	F F F F _ _

;; #undef F
;; #undef _	
