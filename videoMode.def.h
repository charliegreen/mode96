#pragma once

#include <avr/io.h>
#include "defines.h"

#define VMODE_FUNC sub_video_mode96

// 258 is the maximum value of AUDIO_OUT_HSYNC_CYCLES, so less means cutting kernel functionality
#define HSYNC_USABLE_CYCLES 258

#define FONT_TILE_WIDTH  35	// size of a tile row in words
#define TILE_HEIGHT 8
#define TILE_WIDTH 6

#define VRAM_TILES_H 36
#ifndef VRAM_TILES_V
#define VRAM_TILES_V 28
#endif

#define SCREEN_TILES_H VRAM_TILES_H
#define SCREEN_TILES_V VRAM_TILES_V

#define VRAM_SIZE (VRAM_TILES_H*VRAM_TILES_V*12/8)
#define VRAM_PTR_TYPE u8

#ifndef FIRST_RENDER_LINE
#define FIRST_RENDER_LINE 20
#endif

#ifndef FRAME_LINES
#define FRAME_LINES (SCREEN_TILES_V*TILE_HEIGHT)
#endif
