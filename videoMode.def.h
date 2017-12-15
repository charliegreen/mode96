#pragma once

#include <avr/io.h>
#include "defines.h"

// #define VMODE_ASM_SOURCE "video.s"
// #define VMODE_C_PROTOTYPES "video.h"
#define VMODE_FUNC sub_video_mode96

#define HSYNC_USABLE_CYCLES 264	// maximum free cycles usable by the hsync and audio (from videoMode1)

#define FONT_TILE_WIDTH  37//29   // size of a tile row in words (FONT_TILE_SIZE/8 for 6x8 tiles) (TODO)
#define FONT_TILE_SIZE  (FONT_TILE_WIDTH*TILE_HEIGHT) // size of an entire tile in words

#define TILE_HEIGHT 8
#define TILE_WIDTH 6

// #define VRAM_TILES_H 40
#define VRAM_TILES_H 32
#ifndef VRAM_TILES_V
#define VRAM_TILES_V 28
#endif

#define SCREEN_TILES_H VRAM_TILES_H
#define SCREEN_TILES_V VRAM_TILES_V

#define VRAM_SIZE (VRAM_TILES_H*VRAM_TILES_V*12/8)
// #define VRAM_ADDR_SIZE 1	// in bytes
#define VRAM_PTR_TYPE u8
// #define SPRITES_ENABLED 0

#ifndef FIRST_RENDER_LINE
#define FIRST_RENDER_LINE 20
#endif

#ifndef FRAME_LINES
#define FRAME_LINES (SCREEN_TILES_V*TILE_HEIGHT)
#endif
