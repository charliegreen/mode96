#include <stdbool.h>
#include <avr/io.h>
#include <stdlib.h>
#include <avr/pgmspace.h>
#include <uzebox.h>

// #include "data/font-6x8-full.inc"
// #include "_gen_/font.inc"

extern u8 vram[VRAM_SIZE];	// just for debugging

// colors:   B-G--R--
// grey:   0b01010010: 0x52
// blue:   0b11000000: 0xc0
// green:  0b00010000: 0x10
// red:    0b00000010: 0x02
// orange: 0b00010101: 0x15
// yellow: 0b00110110: 0x36
// cyan:   0b01010000: 0xa8
// violet: 0b10000011: 0x83

ColorCombo m96_palette[16] = {
    { 0xc0, 0x15 },		// blue on orange
    { 0x02, 0x10 }, 		// red on green
    { 0x83, 0x36 },		// violet on yellow
    { 0xa8, 0x02 },		// cyan on red
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

static void hexdump(u8 x0, u8 y0, u8*p, u8 len) {
    for (u8 i = 0; i < len; i++) {
	u8 x = 3*(i%8)+x0, y = y0+(i/8);
	PrintHexByte(x, y, *(p + i));
    }    
}

int main() {
    GetPrngNumber(GetTrueRandomSeed());
    // SetTileTable(font);
    // SetFontTilesIndex(0);
    ClearVram();

    for (u8 section = 0; section < 3; section++) {
	for (u8 row = 0; row < 8; row++)
	    for (u8 col = 0; col < 16; col++) {
		SetTileBoth(col, section+row, col + 16*row, (col+section) % 4);
	    }
    }
    // u8 line = 0;    
    // Print(0, line++, PSTR("Done"));
    while (true) {
	WaitVsync(1);
	button_update();

	if (_btn.prsd & BTN_START) {
	    hexdump(3, 3, vram, 128);
	}
    }
}
