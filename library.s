;;; C-Callable functions for mode 96

#include "common.def.h"

;;; TODO: add all the usual Print functions, but that take color options
	
	.global ClearVram
	.global SetTile
	.global GetTile
	.global SetTileColor
	.global GetTileColor
	.global SetTileBoth

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
;;; get_tile_addr_text
;;; A helper function, not intended for use outside this library
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; Returns:
;;; Z: set to the address of the text of tile X,Y
get_tile_addr_text:
	ldi	ZL, lo8(vram)
	ldi	ZH, hi8(vram)

	;; add width of screen in bytes * Y pos
	ldi	r18, SCREEN_TILES_H*3/2 ; SCREEN_TILES_H must be even
	mul	r22, r18
	add	ZL, r0
	adc	ZH, r1
	
	;; get byte index from X value. index = X/2*3 + (2 if x is odd else 0)
	;;
	;; Note: these Python 3 expressions are equivalent:
	;;   (x//2)*3 + (2 if x%2 else 0)
	;;   x//2 + x + (1 if x%2 else 0)
	mov	r18, r24
	lsr	r18
	add	r18, r24

	sbrc	r24, 0		; skip if even
	inc	r18

	clr	r19
	add	ZL, r18
	adc	ZH, r19

	clr	r1
	ret

;;; ========================================
;;; get_tile_addr_color
;;; A helper function, not intended for use outside this library
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; Returns:
;;; Z: set to the address of the color of tile X,Y
get_tile_addr_color:
	ldi	ZL, lo8(vram)
	ldi	ZH, hi8(vram)

	;; add width of screen in bytes * Y pos
	ldi	r18, SCREEN_TILES_H*3/2 ; SCREEN_TILES_H must be even
	mul	r22, r18
	add	ZL, r0
	adc	ZH, r1

	;; get byte index from X value
	mov	r18, r24
	lsr	r18
	add	r18, r24

	sbrs	r24, 0		; skip if odd
	inc	r18

	clr	r19
	add	ZL, r18
	adc	ZH, r19

	clr	r1
	ret

;;; ========================================
;;; SetTile/SetFont
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; r20: tile number (8-bit)
SetTile:
SetFont:
	rcall	get_tile_addr_text
	st	Z, r20
	ret

;;; ========================================
;;; GetTile
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; Returns:
;;; r24: tile number (8-bit)
GetTile:
	rcall	get_tile_addr_text
	ld	r24, Z
	ret

;;; ========================================
;;; SetTileColor
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; r20: color palette index (4-bit)
SetTileColor:
	rcall	get_tile_addr_color
	ld	r18, Z
	sbrs	r24, 0		; skip if X pos is odd
	swap	r18

	andi	r18, 0xF0	; wipe current color
	or	r18, r20	; add new color

	sbrs	r24, 0		; skip if X pos is odd
	swap	r18

	st	Z, r18		; write back new color
	ret

;;; ========================================
;;; GetTileColor
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; Returns:
;;; r24: color palette index (4-bit)
GetTileColor:
	rcall	get_tile_addr_color
	ld	r18, Z
	sbrs	r24, 0		; skip if X pos is odd
	swap	r18

	andi	r18, 0x0F	; only return this tile's color
	movw	r24, r18
	ret

;;; ========================================
;;; SetTileBoth
;;; r24: X pos (8-bit)
;;; r22: Y pos (8-bit)
;;; r20: tile number (8-bit)
;;; r18: color palette index (4-bit)
SetTileBoth:
	push	r18
	rcall	SetTile
	pop	r20
	rcall	SetTileColor
	ret

;;; ================================================================================
;;; Miscellaneous callback functions or functions that aren't applicable to this mode
VideoModeVsync:
SetTileTable:	
InitializeVideoMode:
DisplayLogo:
	ret
