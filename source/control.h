#pragma once

#include "object.h"

#define sizeof_Control 0x28
// Members
#define Control_x 0x04 // 4 bytes
#define Control_y 0x08 // 4 bytes
#define Control_width 0x0C // 4 bytes
#define Control_height 0x10 // 4 bytes
#define Control_pChildren 0x14 // 4 bytes
#define Control_pPrev 0x18 // 4 bytes
#define Control_pNext 0x1C // 4 bytes
// Callbacks
#define Control_OnClick 0x20 // 4 bytes
#define Control_OnPaint 0x24 // 4 bytes
