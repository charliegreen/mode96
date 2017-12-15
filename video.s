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
	
	.global vram		; just global for debugging
	.global m96_palette
	
	.section .bss
vram:		.space VRAM_SIZE

font_lo:	.space 1
font_hi:	.space 1

	.section .text
;;; ========================================
;;; Mode 96
;;;
;;; Register usage:
;;;   r10: scanline counter
;;;   r17:r16: miscellaneous scratch
;;;   r21: FONT_TILE_SIZE
;;;   r23: FONT_TILE_WIDTH

sub_video_mode96:
	;; do setup
	;; WAIT	r19, 1347	; waste a scanline to align with next hsync
	WAIT	r19, 1341
	
sub_video_mode96_entry:		; just a debugging symbol for gdb to break on
	ldi	YL, lo8(vram)
	ldi	YH, hi8(vram)

	;; ldi	r21, FONT_TILE_SIZE
	nop
	ldi	r23, FONT_TILE_WIDTH
	
	;; r10 is our scanline counter; fill it with the number of scanlines to draw
	ldi	r16, SCREEN_TILES_V * TILE_HEIGHT
	;; ldi	r16, 40
	mov	r10, r16

	ldi	r16, 0x52
	mov	r2, r16		; hold a background color

	clr	r24		; our tile Y index
	clr	r25		; our tile row counter (0-7)

render_scanline:
	;; generate hsync pulse
	;; At the `cbi` inside hsync_pulse (first instruction), TCNT1L (0x84) should be 0x68;
	;; `rcall` and `lds` both take 2 cycles, so r8 should be 0x64 (I think..)
	lds	r8, TCNT1L
	lds	r9, TCNT1H	;0x64, 0x2b7
	rcall	hsync_pulse	;156 cycles (154 inside hsync_pulse)
	
	WAIT	r19, HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES + CENTER_ADJUSTMENT - 9
	;; WAIT	r19, 17		; adjustment for centering in uzem

	rcall	begin_code_tile_row

	;; decrement Y (last code tile will have loaded everything for its "next" tile)
	;; sbiw	Y, 2

	;; output a background pixel so that we can distinguish between uzem background and our background
	out	VIDEO_PORT, r2
	WAIT	r19, 51 - CENTER_ADJUSTMENT

	inc	r25		; increment row counter

	;; -------------------- this is what the kids call the "end of tile row timing dance"
	sbrs	r25, 3		; if r25 has reached 8 (0b1000), skip
	rjmp 1f
0:
	clr	r25		; clear row counter
	inc	r24		; increment tile Y index
	rjmp	2f
1:
	nop
	nop
	nop
2:
	;; -------------------- sync up to 1820 cycles and continue
	WAIT	r19, 0x9b
	
	;; if we've just drawn the last scanline, be done
	dec	r10
	breq	frame_end
	
	rjmp	render_scanline

frame_end:
	nop
	lds	r8, TCNT1L
	lds	r9, TCNT1H
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
