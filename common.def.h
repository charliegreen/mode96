;;; -*- mode: asm -*-

#pragma once

#include "videoMode.def.h"

;;; ---------------------------------------- constants
#define R_FONTL r4
#define R_FONTH r5
#define R_ROWSL r6
#define R_ROWSH r7

#define R_EIGHT r8
#define R_ROW_WIDTH r9

;;; ---------------------------------------- "globals"
#define R_SCANLINE_COUNTER r20
#define R_TILE_Y r21
#define R_TILE_R r22

;;; R_TILES_LEFT is number of tiles left to OUTPUT, not left to LOAD
#define R_TILES_LEFT r23

;;; ---------------------------------------- just for use in code tiles
#define R_FG r19
#define R_BG r18

;;; text and color indices read from VRAM
#define R_TXTI r10
#define R_CLRI r25

.macro TILE_ROW n,p0,p1,p2,p3,p4,p5
_tilerow_\n:
	out	VIDEO_PORT, \p0

	;; ---------------------------------------- reading VRAM
	
	;; if R_TILES_LEFT is *odd*, we're loading a [text][color] VRAM section next
	sbrc	R_TILES_LEFT, 0	; skip next instruction if number of tiles left is even
	rjmp	1f

	;; color, then text
	ld	R_CLRI, Y+
	ld	R_TXTI, Y+
	out	VIDEO_PORT, \p1
	rjmp	2f
1:
	;; text, then color
	ld	R_TXTI, Y+
	out	VIDEO_PORT, \p1
	ld	R_CLRI, Y
	swap	R_CLRI
2:
	andi	R_CLRI, 0x0F

	;; ---------------------------------------- loading colors
	lsl	R_CLRI		; multiply by 2 to get index into color palette

	;; we only have 32 bytes of colors, so the index will never affect XH
	ldi	XL, lo8(m96_palette) ; X is now base address of color palette

	out	VIDEO_PORT, \p2

	add	XL, R_CLRI

	;; ---------------------------------------- loading next tile
	;; *(R_FONT + 8*R_TXTI + R_TILE_R) == what code tile to jump to
	movw	ZL, R_FONTL
	add	ZL, R_TILE_R
	mul	R_TXTI, R_EIGHT
	out	VIDEO_PORT, \p3
	add	ZL, r0
	adc	ZH, r1
	lpm	R_TXTI, Z

	out	VIDEO_PORT, \p4

	;; load next code tile word address into Z for ijmp
	mul	R_TXTI, R_ROW_WIDTH
	add	r0, R_ROWSL
	adc	r1, R_ROWSH
	movw	r30, r0

	dec	R_TILES_LEFT	; we can move this up here because out and ld don't modify SREG

	out	VIDEO_PORT, \p5
	
	;; ---------------------------------------- load next tile's colors
	ld	R_FG, X+
	ld	R_BG, X

	;; if --r6 == 0, return; otherwise, jump to next tile
	breq	.+2		; skip ijmp
	ijmp
	ret
.endm
