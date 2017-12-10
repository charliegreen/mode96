#include "videoMode.def.h"
	
	.section .text
	.global	_tile_bg
	.global	_tile_scanline_start
	.global	_tile_scanline_end

;;; NOTE: maximum possible resolution (at least, for uzem) appears to be around 2 cycles/pixel.
;;; Observing 67 _tile_bg loops to get a perfect screen fit at 13 cycles/_tile_bg (17 cycles per
;;; loop), plus 15 cycles up front for _tile_scanline_start and 16 for _tile_scanline_end
;;; (one more because of end of loop), for a total of 67*17+15+16 = 1170 cycles per 6*69 = 414 pixels,
;;; giving us an end result of 2.826 cycles/pixel
	
;;; Each of these is 24 cycles (26 when you include the rcall to get here)

.macro	PIXEL color
	out	VIDEO_PORT, \color
	nop
	nop
	nop
.endm
	
.macro	TILE name,p0,p1,p2,p3,p4,p5
_tile_\name:

	PIXEL	\p0
	PIXEL	\p1
	PIXEL	\p2
	PIXEL	\p3
	PIXEL	\p4

	out	VIDEO_PORT, \p5
	ret
.endm

	TILE	bg, r4,r2,r2,r2,r2,r2
	TILE	scanline_start, r5,r3,r4,r3,r4,r3
	TILE	scanline_end,   r3,r4,r3,r4,r3,r5

	TILE	tile0,	r2,r2,r3,r3,r2,r2
	TILE	tile1,	r2,r3,r2,r3,r2,r3
