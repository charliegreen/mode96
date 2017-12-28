#include <stdbool.h>
#include <avr/io.h>
#include <stdlib.h>
#include <avr/pgmspace.h>
#include <uzebox.h>

/* EXAMPLES
 * 0: just for miscellaneous debugging code
 * 1: show ASCII with 12 different palettes
 * 2: show color values
 * 3: scramble VRAM
 * 4: fake terminal output (TODO, NYI)
 */
#define EXAMPLE 1

ColorCombo m96_palette[16] = {
    { 0xc0, 0x15 },		// blue on orange
    { 0x02, 0x10 }, 		// red on green
    { 0x83, 0x36 },		// violet on yellow
    { 0xa8, 0x02 },		// cyan on red

    { 0xe3, 0x42 },
    { 0x2f, 0x23 },
    { 0x55, 0x49 },
    { 0x61, 0xd3 },

    { 0xc2, 0xd7 },
    { 0xa7, 0xfd },
    { 0x39, 0x05 },
    { 0xff, 0x00 },
};

typedef struct {
    u16 prev;			// Previous buttons that were held
    u16 down;			// Buttons that are held right now
    u16 prsd;			// Buttons that were pressed this frame
    u16 rlsd;			// Buttons that were released this frame
} ButtonData;
ButtonData _btn = {0, 0, 0, 0};

void button_update() {
    _btn.down = ReadJoypad(0);
    _btn.prsd = _btn.down & (_btn.down ^ _btn.prev);
    _btn.rlsd = _btn.prev & (_btn.down ^ _btn.prev);
    _btn.prev = _btn.down;
}

static void palette_randomize() {
    for (u8 i = 0; i < 16; i++) {
	m96_palette[i].fg = GetPrngNumber(0);
	m96_palette[i].bg = GetPrngNumber(0);
    }
}

#if EXAMPLE == 2
static void palette_display() {
    static u8 X = 3, Y = 4;

    Print(X, Y-1, PSTR(" N: FG BG"));
    for (u8 i = 0; i < 16; i++) {
	PrintByte(X+1, Y+i, i, false);
	PrintChar(X+2, Y+i, ':');

	PrintHexByte(X+4, Y+i, m96_palette[i].fg);
	PrintHexByte(X+7, Y+i, m96_palette[i].bg);
	for (u8 j = 0; j < 9; j++)
	    SetTileColor(X+j, Y+i, i);
    }
}

#elif EXAMPLE == 3
static void scramble_screen() {
    for (u8 row = 0; row < SCREEN_TILES_V; row++) {
	for (u8 col = 0; col < SCREEN_TILES_H; col++) {
	    SetTile(col, row, GetPrngNumber(0) % 96);
	    SetTileColor(col, row, GetPrngNumber(0) % 16);
	}
    }
}
#endif

int main() {
    GetPrngNumber(GetTrueRandomSeed());
    ClearVram();

#if EXAMPLE == 0
    SetTile(0, 0, '0'-32);
    SetTile(SCREEN_TILES_H-1, 0, '1'-32);
    SetTile(SCREEN_TILES_H-1, SCREEN_TILES_V-1, '2'-32);
    SetTile(0, SCREEN_TILES_V-1, '3'-32);

    Print(4, 0, PSTR("foo bar baz"));

    while (true)
	WaitVsync(1);

#elif EXAMPLE == 1
    for (u8 section = 0; section < 12; section++) {
    	for (u8 row = 0; row < 8; row++) {
    	    for (u8 col = 0; col < 12; col++) {
		u8 rowoff = 8 *(section % 4);
		u8 coloff = 12*(section / 4);
		if (row+rowoff > SCREEN_TILES_V-1)
		    continue;
    		SetTileBoth(col+coloff, row+rowoff, col + 12*row, section);
    	    }
    	}
    }

    while (true) {
	WaitVsync(1);
	button_update();
	if (_btn.prsd)
	    palette_randomize();
    }

#elif EXAMPLE == 2
    palette_display();

    while (true) {
	WaitVsync(1);
	button_update();

	if (_btn.prsd) {
	    palette_randomize();
	    palette_display();
	}
    }

#elif EXAMPLE == 3
    palette_randomize();
    scramble_screen();

    while (true) {
	WaitVsync(1);
	button_update();

	if (_btn.prsd) {
	    palette_randomize();
	    scramble_screen();
	}
    }

#else
#error Unknown example
#endif
}
