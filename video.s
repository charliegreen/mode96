;;; ================================================================================
;;; Video Mode 96: text-only display with arbitrary color palettes
;;; 
;;; Type: 		tile-based
;;; Cycles/Pixel:	?? TODO
;;; Tile Size:		6x8
;;; Resolution:		?? TODO
;;; 
;;; Each scanline must total 1820 cycles. There are 524 scanlines total.
	
#include "common.def.h"
	
	.global vram		; just global for debugging
	.global m96_palette
	
	.section .bss
vram:		.space VRAM_SIZE

	.section .text

;;; Register usage:
;;;    r2: a background color, for debugging
;;;   r10: scanline counter (number of scanlines to draw)
;;;   r17:r16: miscellaneous scratch
;;;   r24: our tile Y index
;;;   r25: our tile row counter (0-7)

sub_video_mode96:
	;; ---------------------------------------- do all mode setup here
	;; ldi	YL, lo8(vram)
	;; ldi	YH, hi8(vram)
	nop
	nop
	
	ldi	r16, SCREEN_TILES_V * TILE_HEIGHT
	mov	r10, r16

	ldi	r16, 0x52
	mov	r2, r16		; hold a background color

	clr	r24
	clr	r25

	WAIT	r16, 1343	; waste a scanline to align with next hsync

render_scanline:
	;; ---------------------------------------- render the scanline

	;; At the `cbi` inside hsync_pulse (first instruction), TCNT1L (0x84) should be 0x68;
	;; `rcall` and `lds` both take 2 cycles, so r8 should be 0x64
	lds	r8, TCNT1L
	lds	r9, TCNT1H
	rcall	hsync_pulse	;156 cycles (154 inside hsync_pulse)
	
	WAIT	r16, HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES + CENTER_ADJUSTMENT - 9

	;; do our code tile setup
	rcall	begin_code_tile_row

	;; output a debugging background pixel so that we can distinguish between uzem background
	;; and our background (TODO?)
	out	VIDEO_PORT, r2

	WAIT	r16, 51 - CENTER_ADJUSTMENT

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
	;; -------------------- continue to next line or end of frame, synced to 1820 cycle boundary
	WAIT	r16, 0x9b
	
	;; if we've just drawn the last scanline, be done
	dec	r10
	breq	frame_end
	
	rjmp	render_scanline

frame_end:
	;; ---------------------------------------- do end of frame processing and return
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
