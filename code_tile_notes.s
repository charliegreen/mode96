;;; ================================================================================
;;; GCONVERT
;;; ================================================================================

;;; Based on videoMode9core.s, the gconvert code tiles expect these registers:
;;;   r2  = background color
;;;   r3  = foreground color
;;;   r19:r18 = code for handling the end of a scanline
;;;   r20 = tiles left on this screen row to render
;;;   r21 = FONT_TILE_SIZE (size of an entire tile in words)
;;;   r22 = Y offset in tile row (0-7)
;;;   r23 = FONT_TILE_WIDTH (size of a tile row in words (probs r21/8 for 6x8 tiles))
;;;   r25:r24 = address of tile table plus current tile row offset
;;; 
;;; Code tiles also expect to be able to:
;;;   clobber: r16, r17, r31:r30
;;;   modify : r0, r1, r20
	
;;;   Y   = VRAM address

;;; Code tiles generate code like so:
	out	0x08, r2	;1
	ld	r17, Y+		;2? 3? 3, I think.
	out	0x08, r2	;1
	mul	r17, r21	;2
	out	0x08, r2	;1
	add	r0, r24		;1
	adc	r1, r25		;1
	out	0x08, r2	;1
	movw	r30, r18	;1
	dec	r20		;1
	out	0x08, r2	;1
	breq	.+2		;1 if false, 2 if true (on end of scanline)
	movw	r30, r0		;1
	out	0x08, r2	;1
	ijmp			;2
	;; For tiles not at the end, one tile row will take 19 cycles

;;; Which, without the 'out's, is:
	ld	r17, Y+		; load next tile index from VRAM into r17
	mul	r17, r21	; multiply by tile size
	add	r0, r24		; add to r25:r24 to get next tile address in r1:r0
	adc	r1, r25

	;; if r20 (tiles left on this tile row) is now zero:
	;;     jump to r18:r19 (end of scanline code)
	;; else:
	;;     jump to r0:r1
	movw	r30, r18

	dec	r20
	breq	.+2
	movw	r30, r0
	
	ijmp			; jumps to code at r30:r31

;;; This means that each code tile calls the next, which in turn means we have to make our own code
;;; tile implementation if we want to load colors for each new tile.

;;; ================================================================================
;;; CUSTOM
;;; ================================================================================

;;; We could have a similar chaining mechanism, where each tile jumps to the next. It may be better
;;; to consolidate the color-loading code and jump to/from tile output code.

;;; Since we're loading 12 bits, and can only load a byte at a time, there's no way to efficiently
;;; interleave the data such that our code will be the same for each tile. We'll have to flip-flop
;;; between two versions.

;;; Register expectations:
;;;   r23:r22: base address of color palette

	;; -------------------------------------------------- loading colors
	;; [text][color|garbage] version

	;; -------------------------------------------------- loading colors
	;; [garbage|color][text] version
	ld	r16, Y+
	andi	r16, 0x0F	; loaded color index into r16

	lsl	r16		; multiply by 2 to get index into color palette
	add	r0, r22		; add to color palette address
	add	r1, r23

	movw	XL, r0
	ld	r16, X+		; load foreground color into r16
	ld	r17, X		; load background color into r17

	;; -------------------------------------------------- outputting pixels

	out	0x08, r16
	out	0x08, r17
	out	0x08, r16
	out	0x08, r17
	out	0x08, r16
	out	0x08, r17
