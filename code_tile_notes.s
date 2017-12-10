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

;;; See [[NOTES.MD#code tile design]].
	
;;; Register expectations:
;;;   XH: hi8(m96_palette) (base address of color palette)
;;; Register usage:
;;;   r4: text index
;;;   r5: FONT_TILE_SIZE
;;;   r6: tile index (counter used to determine when we return)
;;;   r17:r16: scratch
;;;   r19:r18: foreground/background colors
;;;   r20: color index
;;;   r23:r22: address of tile table plus current tile row offset
	
	;; -------------------------------------------------- reading VRAM for [text][color|garbage]
	ld	r4, Y+		; load text index
	
	ld	r20, Y+		; load color index
	swap	r20
	andi	r20, 0x0F
	
	;; -------------------------------------------------- reading VRAM for [garbage|color][text]
	ld	r20, Y+		; load color index
	andi	r20, 0x0F

	ld	r4, Y+		; load text index

	;; -------------------------------------------------- the above two sections interleaved

	;; cycle count:
	;; without skip (r6 even):
	;;   sbrs:1
	;;   rjmp:2
	;;   ld, ld, swap: 5
	;;   andi: 1
	;;   ..total = 9
	;; with skip:
	;;   sbrs:2
	;;   ld, ld: 4
	;;   rjmp: 2
	;;   andi: 1
	;;   ..total = 9
	
	;; if r6 is even, we're on a [text][color]
	sbrs	r6, 0		; skip next instruction if r6 is odd
	rjmp	text_color
color_text:
	ld	r20, Y+
	ld	r4, Y+
	rjmp	end
text_color:
	ld	r4, Y+
	ld	r20, Y+
	swap	r20
end:
	andi	r20, 0x0F
	
	;; -------------------------------------------------- loading colors
	lsl	r20		; multiply by 2 to get index into color palette

	;; we only have 32 bytes of colors, so the index will never affect XH
	ldi	XL, lo8(m96_palette) ; X is now base address of color palette
	add	XL, r20		     ; X is now address of our color pair
	
	ld	r19, X+		; load foreground color into r19
	ld	r18, X		; load background color into r18

	;; ---- 7 cycles
	
	;; -------------------------------------------------- loading next code tile
	mul	r4, r5
	add	r0, r22
	adc	r1, r23

	movw	r30, r0		; copy r1:r0 into r31:r30 (Z)

	;; we can shave off the above 5 cycles with a jump table (in program memory, so we use Z),
	;; potentially saving cycles on text|color/color|text versions, but doubling tile PGMEM
	;; consumption

	;; if --r6 == 0, return; otherwise, jump to next tile
	dec	r6
	breq	.+2		; skip ijmp
	ijmp
	ret

	;; ---- 9 cycles for ijmp, 12 cycles for ret
	
	;; -------------------------------------------------- outputting pixels

	out	0x08, r18
	out	0x08, r19
	out	0x08, r18
	out	0x08, r19
	out	0x08, r18
	out	0x08, r19
