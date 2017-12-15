#include "common.def.h"
	
	.section .text

	.global	begin_code_tile_row

begin_code_tile_row:
	;; ---------------------------------------- initial register values
	ldi	R_TILES_LEFT, SCREEN_TILES_H ; only go through this many tiles before returning

	;; Set VRAM pointer to correct value (TODO optimize)
	ldi	YL, lo8(vram)
	ldi	YH, hi8(vram)
	ldi	r16, SCREEN_TILES_H*3/2
	mul	R_TILE_Y, r16
	add	YL, r0
	adc	YH, r1
	
	ldi	XH, hi8(m96_palette)

	;; ---------------------------------------- load first tile's colors
	ld	R_TXTI, Y+
	ld	R_CLRI, Y
	swap	R_CLRI
	andi	R_CLRI, 0x0F

	lsl	R_CLRI
	ldi	XL, lo8(m96_palette)
	add	XL, R_CLRI

	ld	R_FG, X+
	ld	R_BG, X

	;; ---------------------------------------- load first tile's address and jump
	movw	ZL, R_FONTL
	add	ZL, R_TILE_R
	mul	R_TXTI, R_EIGHT
	add	ZL, r0
	adc	ZH, r1
	ld	R_TXTI, Z		; lpm?

	mul	R_TXTI, R_ROW_WIDTH
	add	r0, R_ROWSL
	adc	r1, R_ROWSH
	movw	r30, r0
	
	dec	R_TILES_LEFT
	ijmp
