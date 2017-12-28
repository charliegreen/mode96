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
;;;   r17:r16: miscellaneous scratch

sub_video_mode96:
	;; ---------------------------------------- do all mode setup here
	ldi	r16, FONT_TILE_WIDTH
	mov	R_ROW_WIDTH, r16
	ldi	r16, 8
	mov	R_EIGHT, r16

	ldi	r16, lo8(m96_font)
	mov	R_FONTL, r16
	ldi	r16, hi8(m96_font)
	mov	R_FONTH, r16
	
	;; pm converts from byte addresses to word addresses (divides by 2)
	ldi	r16, lo8(pm(m96_rows))
	mov	R_ROWSL, r16
	ldi	r16, hi8(pm(m96_rows))
	mov	R_ROWSH, r16

	ldi	r16, SCREEN_TILES_V * TILE_HEIGHT
	mov	R_SCANLINE_COUNTER, r16

	ldi	r16, 0x52
	mov	r2, r16		; hold a background color

	clr	R_TILE_Y
	clr	R_TILE_R

	WAIT	r16, 1333	; waste a scanline to align with next hsync

render_scanline:
	;; ---------------------------------------- render the scanline

	;; At the `cbi` inside hsync_pulse (first instruction), TCNT1L (0x84) should be 0x68;
	;; `rcall` and `lds` both take 2 cycles, so should be 0x64
	lds	r16, TCNT1L
	lds	r17, TCNT1H
	rcall	hsync_pulse	;156 cycles (154 inside hsync_pulse)

	WAIT	r16, HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES

	;; do our code tile setup
	rcall	begin_code_tile_row

	;; output a debugging background pixel so that we can distinguish between uzem background
	;; and our background (TODO?)
	out	VIDEO_PORT, r2

	inc	R_TILE_R	; increment row counter

	;; -------------------- this is what the kids call the "end of tile row timing dance"
	sbrs	R_TILE_R, 3	; if R_TILE_R has reached 8 (0b1000), skip
	rjmp	1f
0:
	clr	R_TILE_R	; clear row counter
	inc	R_TILE_Y	; increment tile Y index
	rjmp	2f
1:
	nop
	nop
	nop
2:
	;; -------------------- continue to next line or end of frame, synced to 1820 cycle boundary
	WAIT	r16, 55
	
	;; if we've just drawn the last scanline, be done
	dec	R_SCANLINE_COUNTER
	breq	frame_end
	
	rjmp	render_scanline

frame_end:
	;; ---------------------------------------- do end of frame processing and return
	nop
	lds	r16, TCNT1L
	lds	r17, TCNT1H
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
