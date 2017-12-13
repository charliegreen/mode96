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

#endif
