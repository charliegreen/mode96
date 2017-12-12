#include <stdbool.h>
#include <avr/io.h>
#include <stdlib.h>
#include <avr/pgmspace.h>
#include <uzebox.h>

// #include "data/font-6x8-full.inc"
#include "_gen_/font.inc"

extern u8 vram[VRAM_SIZE];	// just for debugging

extern void do_test_setup(void);

// extern unsigned int test_get();
// extern bool buffer_test(char*buffer, bool init);

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

    do_test_setup();

    SetTile(1, 1, 0);
    
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
