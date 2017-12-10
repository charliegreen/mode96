#include "videoMode.def.h"
	
	.section .text
	.global	_tile_bg
	.global	_tile_scanline_start
	.global	_tile_scanline_end

_tile_bg:
	out	VIDEO_PORT, r2
	nop
	nop
	nop

	out	VIDEO_PORT, r2
	nop
	nop
	
	out	VIDEO_PORT, r2
	nop
	nop
	
	out	VIDEO_PORT, r2
	nop
	nop
	
	out	VIDEO_PORT, r2
	nop
	nop
	
	out	VIDEO_PORT, r2
	ret

_tile_scanline_start:
 	out	VIDEO_PORT, r5
	nop
	nop
	nop
	
	out	VIDEO_PORT, r3
	nop
	nop

	out	VIDEO_PORT, r4
	nop
	nop

	out	VIDEO_PORT, r3
	nop
	nop
	
	out	VIDEO_PORT, r4
	nop
	nop

	out	VIDEO_PORT, r3
	ret

_tile_scanline_end:
 	out	VIDEO_PORT, r3
	nop
	nop
	nop
	
	out	VIDEO_PORT, r4
	nop
	nop

	out	VIDEO_PORT, r3
	nop
	nop

	out	VIDEO_PORT, r4
	nop
	nop
	
	out	VIDEO_PORT, r3
	nop
	nop

	out	VIDEO_PORT, r5
	ret	
