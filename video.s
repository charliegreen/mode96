;;; video mode: 80x24 text-only display
;;; 
;;; Type: 		tile-based
;;; Cycles/Pixel:	?? TODO
;;; Tile Size:		6x8
;;; Resolution:		480x192 (80x24 tiles)
;;; 
;;; Each scanline must total 1820 cycles, so at 480 pixels wide that's 3.79 cycles/pixel. There are
;;; 524 scanlines total.
;;;
;;; Note: for 60 chars wide, 60*6 = 360 pixels = 5.05 cycles/pixel
	
#include "videoMode.def.h"
	
	.global vram		;just for debugging

	.global m96_palette
	
	;; .global VideoModeVsync
	
	.global ClearVram
	.global SetFont
	.global SetTileTable
	.global InitializeVideoMode
	.global DisplayLogo
	
;;; ================================================================================ globals
	.section .bss
vram:		.space VRAM_SIZE
m96_palette:	.space 32	; type is ColorCombo[16]

font_lo:	.space 1
font_hi:	.space 1

;;; ================================================================================ core code
	.section .text
	
;;; register allocation:
;;; r2: foreground color
;;; r3: background color
;;; Y: VRAM address
	
sub_video_mode96:
	;; do setup
	
	WAIT	r19, 1347	; waste a scanline to align with next hsync
sub_video_mode96_entry:
	ldi	YL, lo8(vram)
	ldi	YH, hi8(vram)

	;; our tile test pattern: colors:
	;; 2: grey:  0b01010010
	;; 3: blue:  0b11000000: 0xc0
	;; 4: green: 0b00010000: 0x10
	;; 5: red:   0b00000010: 0x02

	ldi	r16, 0b01010010
	mov	r2, r16
	ldi	r16, 0xc0
	mov	r3, r16
	ldi	r16, 0x10
	mov	r4, r16
	ldi	r16, 0x02
	mov	r5, r16

	clr	r6

	ldi	r21, FONT_TILE_SIZE
	ldi	r23, FONT_TILE_WIDTH
	
	;; r10 is our scanline counter; fill it with the number of scanlines to draw
	;; ldi	r16, 524	; number of scanlines to draw
	ldi	r16, SCREEN_TILES_V * TILE_HEIGHT
	mov	r10, r16

render_scanline:
	;; generate hsync pulse
	rcall	hsync_pulse	;145

	;; number of tiles to draw per scanline (r11 is our horizontal counter)
	ldi	r16, 2		;37
	mov	r11, r16
	
	WAIT	r19, HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES + CENTER_ADJUSTMENT

	;; WAIT	r19, 200

	rcall	function
	
	rcall	_tile_scanline_start
	
0:
	rcall	_tile_bg
	
	dec	r11
	brne	0b

	rcall	_tile_scanline_end
	
	;; out	VIDEO_PORT, r6	;output a 0
	out	VIDEO_PORT, r2 	; output a background pixel so that we can distinguish between uzem background and our background

	;; 1160 + 1 + 145 + 1 + 1 = 1408
	;; 1820 - 1408 - 2 = 410
	;; WAIT	410
	WAIT	r19, 51 - CENTER_ADJUSTMENT
	
	;; if we've just drawn the last scanline, be done
	dec	r10
	breq	frame_end
	
	rjmp	render_scanline	;2

frame_end:
	rcall	hsync_pulse

	;; set vsync flag & flip field
	lds ZL,sync_flags
	ldi r20,SYNC_FLAG_FIELD
	ori ZL,SYNC_FLAG_VSYNC
	eor ZL,r20
	sts sync_flags,ZL

	;; clear any pending timer int
	ldi ZL,(1<<OCF1A)
	sts _SFR_MEM_ADDR(TIFR1),ZL
	
	ret			; returning from call to sub_video_mode96

VideoModeVsync:
	;; TODO
	ret

;;; ================================================================================ C functions
ClearVram:
	ldi	r30, lo8(VRAM_SIZE)
	ldi	r31, hi8(VRAM_SIZE)

	ldi	XL, lo8(vram)
	ldi	XH, hi8(vram)

0:
	st	X+, r1
	sbiw	r30, 1
	brne	0b

	clr	r1

	ret

SetTileTable:
	sts	font_lo, r24
	sts	font_hi, r25
	ret
	
InitializeVideoMode:
DisplayLogo:
SetFont:
	ret
