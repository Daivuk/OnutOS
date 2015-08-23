#pragma once

// Initialize UI sub system
.globl ui_init

// r0 = X position
// r1 = Y position
// r2 = type
.globl ui_drawCursor

// Build an Oak Nut icon
// r0 = destination bitmap
// r1 = icon color
// r2 = icons image bitmap
.globl ui_buildIcon

// Repaint the control and all of it's children recursively
// r0 = control address
.globl ui_paint
