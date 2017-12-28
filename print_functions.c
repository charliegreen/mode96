#include <uzebox.h>
#include <avr/pgmspace.h>
#include <string.h>

#include "video.h"

static u8 ilen(unsigned long val) {
    u8 ret = 0;
    while (val) {
	val /= 10;
	ret++;
    }
    return ret;
}

void PrintColor(int x,int y,const char *string,int color) {
    Print(x, y, string);
    FillColor(x, y, strlen_P(string), color);
}

void PrintRamColor(int x,int y,char *string,int color) {
    PrintRam(x, y, (unsigned char*)string);
    FillColor(x, y, strlen(string), color);
}

void PrintBinaryByteColor(char x,char y,unsigned char byte,int color) {
    PrintBinaryByte(x, y, byte);
    FillColor(x, y, 8, color);
}

void PrintHexByteColor(char x,char y,unsigned char byte,int color) {
    PrintHexByte(x, y, byte);
    FillColor(x, y, 2, color);
}

void PrintHexIntColor(char x,char y,int byte,int color) {
    PrintHexInt(x, y, byte);
    FillColor(x, y, 4, color);
}

void PrintHexLongColor(char x,char y, uint32_t value,int color) {
    PrintHexLong(x, y, value);
    FillColor(x, y, 8, color);
}

void PrintLongColor(int x,int y, unsigned long val,int color) {
    PrintLong(x, y, val);
    u8 l = ilen(val);
    FillColor(x-l+1, y, l, color);
}

void PrintByteColor(int x,int y, unsigned char val,bool zeropad,int color) {
    PrintByte(x, y, val, zeropad);
    u8 l = ilen(val);
    FillColor(x-l+1, y, l, color);
}

void PrintCharColor(int x,int y,char c,int color) {
    PrintChar(x, y, c);
    SetTileColor(x, y, color);
}

void PrintIntColor(int x,int y, unsigned int i,bool zeropad,int color) {
    PrintInt(x, y, i, zeropad);
    u8 l = zeropad ? 5 : ilen(i);
    FillColor(x-l+1, y, l, color);
}
