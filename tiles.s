#include "common.def.h"
	
	.section .text

	.global	begin_code_tile_row

;;; ========================================
;;; Expects:
;;;   r25: tile row counter (0-7)
;;;   r24: tile Y index
begin_code_tile_row:
	;; ---------------------------------------- initial register values
	ldi	r16, FONT_TILE_WIDTH
	mov	r5, r16
	ldi	r16, SCREEN_TILES_H ; only go through this many tiles before returning
	mov	r6, r16

	;; pm converts from byte addresses to word addresses (divides by 2)
	ldi	r22, lo8(pm(m96_rows))
	ldi	r23, hi8(pm(m96_rows))

	;; Set VRAM pointer to correct value (TODO optimize)
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

	mul	r4, r5
	add	r0, r22
	adc	r1, r23
	movw	r30, r0
	
	dec	r6
	ijmp
