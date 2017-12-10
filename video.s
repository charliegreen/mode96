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

;;; -------------------------------------------------- data to initialize VRAM/palette with
;;; (we can't just do this up there because .bss is zeroed)
_test_vram:
	;; simulated VRAM; starts as [text][color]
	.byte	0		; char 0, color 0
	.byte	0x01
	.byte	0		; char 0, color 1
	.byte	1		; char 1, color 0
	.byte	0x01
	.byte	1		; char 1, color 1
	.space	VRAM_SIZE-6

_test_m96_palette:
	.byte	0xc0		; blue on grey
	.byte	0x52

	.byte	0x02		; red on green
	.byte	0x10

	.space	28

;;; -------------------------------------------------- initialize VRAM/palette

	.global do_test_setup
;;; C-callable, should be called once before any video rendering
do_test_setup:
	;; ---------------------------------------- copy vram
	ldi	ZL, lo8(_test_vram)
	ldi	ZH, hi8(_test_vram)
	ldi	XL, lo8(vram)
	ldi	XH, hi8(vram)
	ldi	r18, 20		; amount of data to copy into VRAM

0:
	lpm	r19, Z+
	st	X+, r19
	dec	r18
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
	
;;; register allocation:
;;; r2: foreground color
;;; r3: background color
;;; Y: VRAM address
	
sub_video_mode96:
	;; do setup

	WAIT	r19, 1347	; waste a scanline to align with next hsync
	
sub_video_mode96_entry:

	lds	r8, TCNT1L

	ldi	YL, lo8(vram)
	ldi	YH, hi8(vram)

	;; our tile test pattern: colors:
	;; 2: grey:  0b01010010: 0x52
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

	ldi	r21, FONT_TILE_SIZE
	ldi	r23, FONT_TILE_WIDTH
	
	;; r10 is our scanline counter; fill it with the number of scanlines to draw
	;; ldi	r16, 524	; number of scanlines to draw
	ldi	r16, SCREEN_TILES_V * TILE_HEIGHT
	mov	r10, r16

render_scanline:
	;; generate hsync pulse
	
	;; At the `cbi` inside hsync_pulse (first instruction), TCNT1L (0x84) should be 0x68;
	;; `rcall` and `lds` both take 2 cycles, so r8 should be 0x64 (I think..)
	lds	r8, TCNT1L
	rcall	hsync_pulse	;145

	;; number of tiles to draw per scanline (r11 is our horizontal counter)
	;; ldi	r16, 43
	ldi	r16, 44
	mov	r11, r16
	
	WAIT	r19, HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES + CENTER_ADJUSTMENT
	WAIT	r19, 17		; adjustment for centering in uzem

	rcall	_tile_scanline_start
	
0:
	rcall	_tile_bg
	dec	r11
	brne	0b

	rcall	_tile_scanline_end

	;; output a background pixel so that we can distinguish between uzem background and our background
	out	VIDEO_PORT, r2

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
