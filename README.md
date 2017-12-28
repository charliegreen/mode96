# mode96
A video driver for the Uzebox.

This is a codetile-based 36x28 video mode that can support up to 256 different 1bpp tiles, where
each cell on screen may be independently set to one of 16 palettes of foreground/background color
combinations. It's intended to be used for text-based graphics, but could still easily be used for
other purposes.

This mode has a fairly low ROM footprint because it compresses its tileset; it also has a moderate
maximum RAM footprint of 1544 B.

## screenshot examples

ASCII tileset (96 tiles), displayed with 12 of 16 possible different palettes:

![example 1](https://imgur.com/V9Ydd2A.png)

Scrambled VRAM, showing characters with 16 different palettes:

![example 3](https://imgur.com/MB2Hu8H.png)
