#pragma once

#define SIZEOF_BITMAP   16
    #define BITMAP_width	0x0
    #define BITMAP_height	0x4
    #define BITMAP_bbp		0x8
    #define BITMAP_addr		0xC

// Do a plain copy from a bitmap to another one.
// Destination bitmap must be of same dimensions are source
// r0 = Source bitmap
// r1 = Destination bitmap
.globl bitmap_copy

// Resize source bitmap to fit into destination bitmap.
// Both bitmap must match the same bit depth
// r0 = Source bitmap
// r1 = Destination bitmap
.globl bitmap_resize

// Put the full source into destination
// r0 = destination X
// r1 = destination Y
// r2 = Source bitmap
// r3 = destination bitmap
.globl bitmap_blitFull

// Blit a rectangle from a source bitmap to destination bitmap
// r0 = source X
// r1 = source Y
// r2 = destination X
// r3 = destination Y
// r4 = width
// r5 = height
// r6 = source bitmap
// r7 = destination bitmap
.globl bitmap_blit

// r0 = bitmap
// r1 = color
.globl bitmap_multColor
