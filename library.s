;;; C-Callable functions for mode 96

#include "videoMode.def.h"
	
	.global ClearVram
	.global SetTile
	.global GetTile

	.global SetFont
	.global SetTileTable
	.global InitializeVideoMode
	.global DisplayLogo
	.global VideoModeVsync

	.section .text

;;; ========================================
;;; ClearVram
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

;;; ========================================
;;; get_byte_address_of_tile
;;; A helper function, not intended for use outside this library
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; Returns:
;;; Z: set to the text of tile X,Y
get_byte_address_of_tile:
	ldi	ZL, lo8(vram)
	ldi	ZH, hi8(vram)

	;; add width of screen in bytes * Y pos
	;; ldi	r18, SCREEN_TILES_H*3/2 ; SCREEN_TILES_H must be even
	ldi	r18, 8*3/2
	mul	r22, r18
	add	ZL, r0
	add	ZH, r1
	
	;; get byte index from X value. index = X/2*3 + (2 if x is odd else 0)
	;;
	;; Note: these Python 3 expressions are equivalent:
	;;   (x//2)*3 + (2 if x%2 else 0)
	;;   x//2 + x + (1 if x%2 else 0)
	mov	r18, r24
	lsr	r18
	add	r18, r24

	sbrc	r18, 0		; skip if even
	inc	r18

	clr	r19
	add	ZL, r18
	adc	ZH, r19
	ret
	
;;; ========================================
;;; SetTile
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; r20: tile number (8-bit)
SetTile:
	rcall	get_byte_address_of_tile
	st	Z, r20
	ret

;;; ========================================
;;; GetTile
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; Returns:
;;; r24: tile number (8-bit)
GetTile:
	rcall	get_byte_address_of_tile
	ld	r24, Z
	ret

;;; ================================================================================
;;; Miscellaneous callback functions or functions that aren't applicable to this mode
VideoModeVsync:
SetTileTable:	
InitializeVideoMode:
DisplayLogo:
SetFont:
	ret
