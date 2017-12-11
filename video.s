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

;;; -------------------------------------------------- data to initialize VRAM/palette with
;;; (we can't just do this up there because .bss is zeroed)
_test_vram:
	;; simulated VRAM; starts as [text][color]
	.macro FOO
	.byte	2		; 4 unique markers
	.byte	0x21
	.byte	1
	.byte	1
	.byte	0x10
	.byte	2

	.byte	0		; 4 EOL markers
	.byte	0x33
	.byte	0
	.byte	0
	.byte	0x33
	.byte	0
	.endm

	.rept 16
	FOO
	.endr
	
	.space	VRAM_SIZE-12*16

_test_m96_palette:
	;; colors:   B-G--R--
	;; grey:   0b01010010: 0x52
	;; blue:   0b11000000: 0xc0
	;; green:  0b00010000: 0x10
	;; red:    0b00000010: 0x02
	;; orange: 0b00010101: 0x15
	;; yellow: 0b00110110: 0x36
	;; cyan:   0b01010000: 0xa8
	;; violet: 0b10000011: 0x83

	.byte	0xc0		; blue on orange
	.byte	0x15

	.byte	0x02		; red on green
	.byte	0x10

	.byte	0x83		; violet on yellow
	.byte	0x36

	.byte	0xa8		; cyan on red
	.byte	0x02

	.space	24

;;; -------------------------------------------------- initialize VRAM/palette

	.global do_test_setup
;;; C-callable, should be called once before any video rendering
do_test_setup:
	;; ---------------------------------------- copy vram
	ldi	ZL, lo8(_test_vram)
	ldi	ZH, hi8(_test_vram)
	ldi	XL, lo8(vram)
	ldi	XH, hi8(vram)
	ldi	r24, lo8(VRAM_SIZE)
	ldi	r25, hi8(VRAM_SIZE)

0:
	lpm	r17, Z+
	st	X+, r17
	sbiw	r24, 1
	brne	0b

	;; ---------------------------------------- copy palette
	ldi	ZL, lo8(_test_m96_palette)
	ldi	ZH, hi8(_test_m96_palette)
	ldi	XL, lo8(m96_palette)
	ldi	XH, hi8(m96_palette)
	ldi	r18, 32

0:
	lpm	r19, Z+
	st	X+, r19
	dec	r18
	brne	0b
	
	ret
	
;;; -------------------------------------------------- actual code

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
	WAIT	r19, 1343
	
sub_video_mode96_entry:		; just a debugging symbol for gdb to break on
	ldi	YL, lo8(vram)
	ldi	YH, hi8(vram)

	ldi	r21, FONT_TILE_SIZE
	ldi	r23, FONT_TILE_WIDTH
	
	;; r10 is our scanline counter; fill it with the number of scanlines to draw
	ldi	r16, SCREEN_TILES_V * TILE_HEIGHT
	;; ldi	r16, 40
	mov	r10, r16

	ldi	r16, 0x52
	mov	r2, r16		; hold a background color
	
render_scanline:
	;; generate hsync pulse
	;; At the `cbi` inside hsync_pulse (first instruction), TCNT1L (0x84) should be 0x68;
	;; `rcall` and `lds` both take 2 cycles, so r8 should be 0x64 (I think..)
	lds	r8, TCNT1L
	lds	r9, TCNT1H	;0x64, 0x253
	rcall	hsync_pulse	;156 cycles (154 inside hsync_pulse)
	
	WAIT	r19, HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES + CENTER_ADJUSTMENT - 9
	;; WAIT	r19, 17		; adjustment for centering in uzem

	rcall	begin_code_tile_row

	;; decrement Y (last code tile will have loaded everything for its "next" tile)
	;; sbiw	Y, 2

	;; output a background pixel so that we can distinguish between uzem background and our background
	out	VIDEO_PORT, r2

	WAIT	r19, 51 - CENTER_ADJUSTMENT

	;; We're getting 0x64 looping to 0x253 in TCNT1, which means our scanline loop is 495 cycles long
	;; It's a scanline, it should be 1820 cycles, so wait 1325
	;; WAIT	r19, 1325

	;; WAIT	r19, 300
	
	;; if we've just drawn the last scanline, be done
	dec	r10
	breq	frame_end
	
	rjmp	render_scanline

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
