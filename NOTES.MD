# the goal
To make a COLOR 80x24 or 60x24 (at minimum, possibly taller) text display. By "color", I mean 16
colors foreground/background (optimally), though allowances may have to be made reducing the number
of colors.

With mode 90, a separate tile would have to exist for each character/foreground/background combo,
which is ridiculous (and results in 96 * 16 * 16 = 24576 tiles!). Mode 90 assumes arbitrary tiles,
though; we can do better with our requirements.

A few assumptions:
* I imagine we'll probably be using code tiles.
* We want to preserve the full basic ASCII range of 96 printables, so characters must be at least 7
  bits. By choosing a case for our alphabet, this goes down to 6 bits, which saves us 1920 bits
  total, or 240 B (not enough to be worth it)

# VRAM memory usage
VRAM is going to be the biggest memory hog. For reference, mode 9's submode 80 uses 80 * 28 = 2240
bytes for VRAM. We want color though. 80 * 24 = 1920.

With 8-bit characters, 4-bit foreground colors, and 4-bit background colors, this is 3840 B, which
leaves only 256 B and is 93.75% of RAM! This obviously isn't viable.

We want to preserve the full basic ASCII range of 96 printables, so characters must be at least 7
bits. This leaves two choices:
* eliminate more redundancy
* reduce the color profile
* have fewer characters (60 wide instead of 80)

## eliminating redundancy
### ramtiles
We could accomplish this with ramtiles; each byte in VRAM is an index into a table of
color/character combinations. This means that we can only have 256 color/character combinations
on-screen at any time, though, and with a full character set, this could be quite limiting. It also
may not actually save much memory; we'd need to at least maintain a table of current color/character
combos, and for usability should probably have some way of tracking usage/frees so unused characters
get overwritten in the table instead of used ones.

With 8-bit color and 7-bit characters, this would use at least (80 * 24 * 8 + 15 * 256)/8 = 2400 B
(1696 free, 58.59% used).

## reducing the color profile
### reducing available colors
Foreground colors would probably be used much more than background colors, and I'm willing to reduce
the number of colors to 8. But I got a better idea:

### a color table
We could have the color bits be an index into a palette of foreground/background combos. This would
maintain the flexibility to trade off more foreground colors for more different
foreground/background combinations as the application requires. I could probably be happy with as
few as 16 combos: the basic white/red/green/yellow/blue/purple/cyan on black, plus 9 others of my
own choosing.

So, with 4-bit color indices and 7-bit characters, each VRAM cell is 11 bits. 80 * 24 * 11 / 8 =
2640 B (64.45% used, 1456 B free). This is workable!

## takeaway

I'm thinking it might be best to limit it to 60 characters wide, then have full 8-bit characters and
4-bit color indices into a table (or 7-bit ASCII and 5-bit color table); 60 * 24 * 12 / 8 = 2160 B
(52.73%) VRAM usage is totally manageable, and this means we won't have to waste cycles dealing with
data unaligned to byte boundaries.

# code tile design

We have to create our own code tiles, since uze's don't load color, and chain jump from tile to tile
so we can't add intermediate code.

## chaining or jumps

We could have a similar chaining mechanism, where each tile jumps to the next, but it may be better
to consolidate the color-loading code and jump to/from tile output code? We obviously can't output
any pixels until after we've loaded our colors, so the color-loading code can't be interleaved with
the output code unless we're loading the next tile's color.

Since we're loading 12 bits, and can only load a byte at a time from RAM, there's no way to
efficiently interleave the data such that our code will be the same for each tile. We'll have to
flip-flop between two versions. We can save cycles by having two different sets of code tiles, one
for each version, but this will obviously double the program memory consumption of our tileset
(which is pretty bad); it's probably better to have the flip-flop occur in code, at the cost of
cycles.

## VRAM organization

Method 1:

	colors: [color][color][color][color]...
	text: [text][text][text][text]....
	
Method 2:

	[text][color][color][text][text][color][color][text]...

Method 1 has the advantage that each code tile is mostly the same, but there's still going to be
flip-flopping between two versions. Method 2 has the advantage that we only have to use one VRAM
pointer, so we free up one of the pointer registers for loading color profiles.

My method 1 VRAM-reading code:

	;; r4: text index
	;; r6: number of tiles left on this line to render
	;; r20: color index
	;; X: color VRAM pointer
	;; Y: text VRAM pointer

	ld	r20, X
	sbrs	r6, 0
	adiw	X, 1

	sbrc	r6, 0		; skip next instruction if r6 is even
	swap	r20
	andi	r20, 0x0F

	ld	r4, Y+

My method 2 VRAM-reading code:

		;; if r6 is even, we're on a [text][color]
		sbrs	r6, 0		; skip next instruction if r6 is odd
		rjmp	text_color
	color_text:
		ld	r20, Y+
		ld	r4, Y+
		rjmp	end
	text_color:
		ld	r4, Y+
		ld	r20, Y
		swap	r20
	end:
		andi	r20, 0x0F

Both are 9 cycles along all code paths, but method 2 leaves X open for loading color profiles. I'm
going to stick with method 2 for now.

## cycle counts

Something important to note: at 1820 cycles per scanline, then to get a 60-column 6x8 display, we
need to have a maximum of 5.05 cycles/pixel on average (or 30.3 cycles/tile, when ignoring all the
code around the tiles). This is obviously not realistic: we need to emit an HSYNC pulse somewhere,
as well as update any audio information (if we want audio), not to mention actually deal with
setting everything up for the code tiles.

If we block out 160 cycles for the HSYNC and (arbitrarily) 220 more for miscellany (totalling 380),
then we get 1440 cycles for code tiles. For a 60-wide screen, that gives us 24 cycles per code tile.
