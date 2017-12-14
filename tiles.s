#include "videoMode.def.h"
	
	.section .text

	.global	begin_code_tile_row
	.global begin_code_tile_row_bkpt

;;; ========================================
;;; Expects:
;;;   Y: set to beginning of current row of VRAM
;;;   r25: tile row counter (0-7)
;;;   r24: tile Y index
begin_code_tile_row:
	;; ---------------------------------------- initial register values
	ldi	r16, FONT_TILE_WIDTH
	mov	r5, r16
	ldi	r16, SCREEN_TILES_H ; only go through this many tiles before returning
	mov	r6, r16

	;; pm converts from byte addresses to word addresses (divides by 2)
	ldi	r22, lo8(pm(m96_font_table))
	ldi	r23, hi8(pm(m96_font_table))

	;; ;; add row index
	;; ldi	r16, FONT_TILE_WIDTH
	;; mul	r25, r16
	;; add	r22, r0
	;; adc	r23, r1

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

	;; ---------------------------------------- load first tile's address and jump
	ldi	ZL, lo8(m96_font)
	ldi	ZH, hi8(m96_font)
	add	ZL, r25		; tile row counter
	ldi	r16, 8
	mul	r4, r16
	add	ZL, r0
	adc	ZH, r1
	ld	r4, Z		; lpm?

begin_code_tile_row_bkpt:
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
	;; r4 is now an index into m96_font

	ldi	ZL, lo8(m96_font)
	ldi	ZH, hi8(m96_font)
	add	ZL, r25		; tile row counter
	ldi	r16, 8
	mul	r4, r16
	add	ZL, r0
	adc	ZH, r1
	ld	r4, Z

	mul	r4, r5
	add	r0, r22
	out	VIDEO_PORT, \p4
	adc	r1, r23
	movw	r30, r0

	dec	r6		; we can move this up here because out and ld don't modify SREG

	out	VIDEO_PORT, \p5
	
	;; ---------------------------------------- load colors
	ld	r19, X+
	ld	r18, X
	
	breq	.+2
	ijmp
	ret
.endm

#define F r19
#define _ r18	

;; #undef F
;; #undef _	

m96_font_table:
	TILE_ROW	00	_ _ _ _ _ _
	TILE_ROW	01	_ _ _ _ _ F
	TILE_ROW	02	_ _ _ _ F _
	TILE_ROW	03	_ _ _ _ F F
	TILE_ROW	04	_ _ _ F _ _
	TILE_ROW	05	_ _ _ F _ F
	TILE_ROW	06	_ _ _ F F _
	TILE_ROW	07	_ _ _ F F F
	TILE_ROW	08	_ _ F _ _ _
	TILE_ROW	09	_ _ F _ _ F
	TILE_ROW	0a	_ _ F _ F _
	TILE_ROW	0b	_ _ F _ F F
	TILE_ROW	0c	_ _ F F _ _
	TILE_ROW	0d	_ _ F F _ F
	TILE_ROW	0e	_ _ F F F _
	TILE_ROW	0f	_ _ F F F F

	TILE_ROW	10	_ F _ _ _ _
	TILE_ROW	11	_ F _ _ _ F
	TILE_ROW	12	_ F _ _ F _
	TILE_ROW	13	_ F _ _ F F
	TILE_ROW	14	_ F _ F _ _
	TILE_ROW	15	_ F _ F _ F
	TILE_ROW	16	_ F _ F F _
	TILE_ROW	17	_ F _ F F F
	TILE_ROW	18	_ F F _ _ _
	TILE_ROW	19	_ F F _ _ F
	TILE_ROW	1a	_ F F _ F _
	TILE_ROW	1b	_ F F _ F F
	TILE_ROW	1c	_ F F F _ _
	TILE_ROW	1d	_ F F F _ F
	TILE_ROW	1e	_ F F F F _
	TILE_ROW	1f	_ F F F F F

	TILE_ROW	20	F _ _ _ _ _
	TILE_ROW	21	F _ _ _ _ F
	TILE_ROW	22	F _ _ _ F _
	TILE_ROW	23	F _ _ _ F F
	TILE_ROW	24	F _ _ F _ _
	TILE_ROW	25	F _ _ F _ F
	TILE_ROW	26	F _ _ F F _
	TILE_ROW	27	F _ _ F F F
	TILE_ROW	28	F _ F _ _ _
	TILE_ROW	29	F _ F _ _ F
	TILE_ROW	2a	F _ F _ F _
	TILE_ROW	2b	F _ F _ F F
	TILE_ROW	2c	F _ F F _ _
	TILE_ROW	2d	F _ F F _ F
	TILE_ROW	2e	F _ F F F _
	TILE_ROW	2f	F _ F F F F
	
	TILE_ROW	30	F F _ _ _ _
	TILE_ROW	31	F F _ _ _ F
	TILE_ROW	32	F F _ _ F _
	TILE_ROW	33	F F _ _ F F
	TILE_ROW	34	F F _ F _ _
	TILE_ROW	35	F F _ F _ F
	TILE_ROW	36	F F _ F F _
	TILE_ROW	37	F F _ F F F
	TILE_ROW	38	F F F _ _ _
	TILE_ROW	39	F F F _ _ F
	TILE_ROW	3a	F F F _ F _
	TILE_ROW	3b	F F F _ F F
	TILE_ROW	3c	F F F F _ _
	TILE_ROW	3d	F F F F _ F
	TILE_ROW	3e	F F F F F _
	TILE_ROW	3f	F F F F F F
