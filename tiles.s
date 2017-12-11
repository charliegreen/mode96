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
begin_code_tile_row:
	;; ---------------------------------------- initial register values
	ldi	r16, FONT_TILE_WIDTH ; should be FONT_TILE_SIZE, but for now each tile is just one row
	mov	r5, r16
	ldi	r16, 8		; only go through this many tiles before returning
	mov	r6, r16

	.global begin_code_tile_row_bkpt
begin_code_tile_row_bkpt:	

	;; pm converts from byte addresses to word addresses (divides by 2)
	ldi	r22, lo8(pm(code_tile_table_base))
	ldi	r23, hi8(pm(code_tile_table_base))
	
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

	;; out	VIDEO_PORT, \p1

	;; color, then text
	ld	r20, Y+
	ld	r4, Y+
	rjmp	2f
1:
	;; out	VIDEO_PORT, \p1
	ld	r4, Y+
	ld	r20, Y
	swap	r20
2:
	out	VIDEO_PORT, \p1
	andi	r20, 0x0F

	;; ---------------------------------------- loading colors
	lsl	r20
	out	VIDEO_PORT, \p2

	ldi	XL, lo8(m96_palette)
	add	XL, r20

	out	VIDEO_PORT, \p3

	;; ---------------------------------------- loading next tile
	mul	r4, r5

	out	VIDEO_PORT, \p4
	add	r0, r22
	adc	r1, r23

	movw	r30, r0

	out	VIDEO_PORT, \p5
	
	;; load colors
	ld	r19, X+
	ld	r18, X
	
	dec	r6
	breq	.+2
	ijmp
	ret
.endm

code_tile_table_base:	
	TILE_ROW	0, r19,r18,r18,r18,r18,r18
	TILE_ROW	1, r19,r18,r19,r18,r19,r18
	TILE_ROW	2, r19,r19,r18,r18,r19,r19

	.rept	FONT_TILE_WIDTH*256
	nop
	.endr
error_tile:
	;; a tile that will be rendered if we ever read the wrong tile index and jump too far
	ldi	r16, 0x07	; BRIGHT RED
	out	VIDEO_PORT, r16
	
	ldi	r17, 0x38	; BRIGHT GREEN
	nop
	nop

	out	VIDEO_PORT, r17
	nop
	nop
	nop

	out	VIDEO_PORT, r16
	nop
	nop
	nop

	out	VIDEO_PORT, r17
	nop
	nop
	nop

	out	VIDEO_PORT, r16
	nop
	nop
	nop

	out	VIDEO_PORT, r17
	ret
