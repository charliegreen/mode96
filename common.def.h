;;; -*- mode: asm -*-

#pragma once

#include "videoMode.def.h"

;; #define R_FG r19
;; #define R_BG r18

;; #define R_FONTL r4
;; #define R_FONTH r5
;; #define R_ROWSL r6	
;; #define R_ROWSH r7

;; #define R_EIGHT r8
;; #define R_ROW_WIDTH r9

.macro TILE_ROW n,p0,p1,p2,p3,p4,p5
_tilerow_\n:
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
	ld	R_FG, X+
	ld	R_BG, X
	
	breq	.+2
	ijmp
	ret
.endm
