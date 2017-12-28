#ifndef VIDEO_MODE_96_H
#define VIDEO_MODE_96_H

typedef struct {
    u8 fg;
    u8 bg;
} ColorCombo;

extern ColorCombo m96_palette[16];

extern void SetTileColor(u8 x, u8 y, u8 index);
extern u8 GetTileColor(u8 x, u8 y);
extern void SetTileBoth(u8 x, u8 y, u8 tile, u8 index);

extern void FillColor(u8 x, u8 y, u8 length, u8 index);

void PrintColor(int x,int y,const char *string,int color);
void PrintRamColor(int x,int y,char *string,int color);
void PrintBinaryByteColor(char x,char y,unsigned char byte,int color);
void PrintHexByteColor(char x,char y,unsigned char byte,int color);
void PrintHexIntColor(char x,char y,int byte,int color);
void PrintHexLongColor(char x,char y, uint32_t value,int color);
void PrintLongColor(int x,int y, unsigned long val,int color);
void PrintByteColor(int x,int y, unsigned char val,bool zeropad,int color);
void PrintCharColor(int x,int y,char c,int color);
void PrintIntColor(int x,int y, unsigned int,bool zeropad,int color);

#endif
