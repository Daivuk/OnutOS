#include "bitmap.h"
#include "ui.h"

#define MAX_WIDTH 1920
#define MAX_HEIGHT 1080
#define TASK_BAR_HEIGHT 40

.section .data
.align 2
FRAME_BUFFER_BITMAP: .space SIZEOF_BITMAP
DEFAULT_WALLPAPER_1080p_BITMAP:
	.int 1920
	.int 1080
	.int 32
	.int 0
WALLPAPER_BITMAP: .space SIZEOF_BITMAP
MAIN_CONTEXT: .space SIZEOF_BITMAP
TASK_BAR_BITMAP: .space SIZEOF_BITMAP

.section .data
.align 2
DEFAULT_WALLPAPER_RAW: .incbin "wallpaper.raw"
.align 2
MAIN_CONTEXT_DATA: .space MAX_WIDTH * MAX_HEIGHT * 4 // Reserve the max space for our context
.align 2
MAIN_CONTEXT_TASK_BAR_DATA: .space MAX_WIDTH * TASK_BAR_HEIGHT * 4 // Resource the space at the bottom for the darker task bar area

.section .data
.align 2
TASK_BAR_COLOR: .int 0xFF7F7F7F

.section .text
ui_init:
	push {r4-r7,lr}

	// Setup our main framebuffer bitmap
	ldr r4,=FRAME_BUFFER_BITMAP
	bl screen_getWidth
	str r0,[r4,#BITMAP_width]
	bl screen_getHeight
	str r0,[r4,#BITMAP_height]
	bl screen_getColorDepth
	str r0,[r4,#BITMAP_bbp]
	bl screen_getFrameBuffer
	str r0,[r4,#BITMAP_addr]

	// Setup our default wallpaper
	ldr r4,=DEFAULT_WALLPAPER_1080p_BITMAP
	ldr r0,=DEFAULT_WALLPAPER_RAW
	str r0,[r4,#BITMAP_addr]

	// Setup our main device context
	ldr r4,=MAIN_CONTEXT
	bl screen_getWidth
	str r0,[r4,#BITMAP_width]
	bl screen_getHeight
	str r0,[r4,#BITMAP_height]
	bl screen_getColorDepth
	str r0,[r4,#BITMAP_bbp]
	ldr r0,=MAIN_CONTEXT_DATA
	str r0,[r4,#BITMAP_addr]

	// Resize our default wallpaper to match our context
	ldr r0,=DEFAULT_WALLPAPER_1080p_BITMAP
	ldr r1,=MAIN_CONTEXT
	bl bitmap_resize

	// Create our task bar bitmap
	ldr r4,=TASK_BAR_BITMAP
	bl screen_getWidth
	str r0,[r4,#BITMAP_width]
	mov r0,#TASK_BAR_HEIGHT
	str r0,[r4,#BITMAP_height]
	mov r0,#32
	str r0,[r4,#BITMAP_bbp]
	ldr r0,=MAIN_CONTEXT_TASK_BAR_DATA
	str r0,[r4,#BITMAP_addr]

	// Blit part of the main background to the task bar
	mov r0,#0					// src x = 0
	ldr r6,=MAIN_CONTEXT		// src y = height - 40
	ldr r7,=TASK_BAR_BITMAP
	ldr r1,[r6,#BITMAP_height]
	sub r1,#TASK_BAR_HEIGHT
	mov r2,#0					// dst x
	mov r3,#0					// dst y
	ldr r4,[r6,#BITMAP_width]   // width
	mov r5,#TASK_BAR_HEIGHT		// height
	bl bitmap_blit

	// Tone it down by 50%
	ldr r0,=TASK_BAR_BITMAP
	ldr r1,=TASK_BAR_COLOR
	ldr r1,[r1]
	bl bitmap_multColor

	// Draw our context to the background
	ldr r0,=MAIN_CONTEXT
	ldr r1,=FRAME_BUFFER_BITMAP
	bl bitmap_copy

	pop {r4-r7,pc}
