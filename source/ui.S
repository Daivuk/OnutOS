#include "bitmap.h"
#include "ui.h"
#include "mem.h"
#include "process.h"

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
m_cursorBitmap:
	.int 12
	.int 19
	.int 32
	.int 0
m_cursorPos: .space 8
m_startIconBitmap:
	.int 32
	.int 32
	.int 32
	.int 0
m_iconMaskBitmap:
	.int 32
	.int 32
	.int 32
	.int 0
m_iconShadowBitmap:
	.int 32
	.int 32
	.int 32
	.int 0
m_iconHighlightBitmap:
	.int 32
	.int 32
	.int 32
	.int 0
m_startIconImageBitmap:
	.int 32
	.int 32
	.int 32
	.int 0

.section .data
.align 2
DEFAULT_WALLPAPER_RAW: .incbin "wallpaper.raw"
CURSOR_RAW: .incbin "cursor.raw"
ICON_MASK_RAW: .incbin "iconMask.raw"
ICON_SHADOW_RAW: .incbin "iconShadow.raw"
ICON_HIGHLIGHT_RAW: .incbin "iconHighlight.raw"
ICON_START_RAW: .incbin "iconStart.raw"

.section .data
.align 2
TASK_BAR_COLOR: .int 0xFF7F7F7F
START_ICON_COLOR: .int 0xFF8E335B

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
	bl screen_getSize
	mov r1,#PROCESS_KERNEL // Allocate memory for our bitmap
	bl mem_alloc
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

	bl screen_getWidth // Allocate memory for our bitmap
	mov r1,#TASK_BAR_HEIGHT
	mul r0,r1
	lsl r0,#PROCESS_KERNEL
	mov r1,#1
	bl mem_alloc
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

	// Load the cursors
	ldr r0,=m_cursorBitmap
	ldr r1,=CURSOR_RAW
	str r1,[r0,#BITMAP_addr]

	// Initialize cursor position to 0,0
	ldr r1,=m_cursorPos
	mov r0,#0
	str r0,[r1,#0]
	str r0,[r1,#4]

	// Initialize system icons bitmaps
	ldr r0,=m_iconMaskBitmap
	ldr r1,=ICON_MASK_RAW
	str r1,[r0,#BITMAP_addr]
	ldr r0,=m_iconShadowBitmap
	ldr r1,=ICON_SHADOW_RAW
	str r1,[r0,#BITMAP_addr]
	ldr r0,=m_iconHighlightBitmap
	ldr r1,=ICON_HIGHLIGHT_RAW
	str r1,[r0,#BITMAP_addr]
	ldr r0,=m_startIconImageBitmap
	ldr r1,=ICON_START_RAW
	str r1,[r0,#BITMAP_addr]

	// The start menu icon
	ldr r0,=m_startIconBitmap
	ldr r1,=START_ICON_COLOR
	ldr r1,[r1]
	ldr r2,=m_startIconImageBitmap
	bl ui_buildIcon

	// Draw the icon for test
	mov r0,#0
	mov r1,#0
	ldr r2,=m_startIconBitmap
	ldr r3,=MAIN_CONTEXT
	bl bitmap_blitFullAlpha

	// Draw our context to the background
	ldr r0,=MAIN_CONTEXT
	ldr r1,=FRAME_BUFFER_BITMAP
	bl bitmap_copy

	pop {r4-r7,pc}

.section .text
ui_drawCursor:
	push {r4-r9,lr}
	x .req r8
	y .req r9
	mov x,r0
	mov y,r1

	// Make sure we moved. If the position
	// is the same, ignore redraw
	ldr r2,=m_cursorPos;
	ldr r2,[r2,#0]
	cmp r0,r2
	bne ui_drawCursor_draw$
	ldr r2,=m_cursorPos;
	ldr r2,[r2,#4]
	cmp r1,r2
	beq ui_drawCursor_done$

	ui_drawCursor_draw$:
		// Erase the cursor area
		ldr r1,=m_cursorPos;
		ldr r0,[r1,#0]
		ldr r1,[r1,#4]
		mov r2,r0
		mov r3,r1
		ldr r5,=m_cursorBitmap
		ldr r4,[r5,#BITMAP_width]
		ldr r5,[r5,#BITMAP_height]
		ldr r6,=MAIN_CONTEXT
		ldr r7,=FRAME_BUFFER_BITMAP
		bl bitmap_blit

		// Draw the cursor on the area
		mov r0,x
		mov r1,y
		ldr r2,=m_cursorBitmap
		ldr r3,=FRAME_BUFFER_BITMAP
		bl bitmap_blitFullTransparent

		// Update the cursor position to the new one
		ldr r2,=m_cursorPos;
		str x,[r2,#0]
		str y,[r2,#4]

	ui_drawCursor_done$:
		pop {r4-r9,pc}

	.unreq x
	.unreq y

// Build an Oak Nut icon
// r0 = destination bitmap
// r1 = icon color
// r2 = icons image bitmap
.section .text
ui_buildIcon:
	push {r4-r6,lr}
	dstBitmap .req r4
	color .req r5
	image .req r6
	mov dstBitmap,r0
	mov color,r1
	mov image,r2

	mov r0,#0x1000
	mov r1,#PROCESS_KERNEL
	bl mem_alloc
	str r0,[dstBitmap,#BITMAP_addr]

	// Fill with color
	mov r0,dstBitmap
	mov r1,color
	bl bitmap_fill

	// Draw the icon on top of the solid color
	mov r0,image
	mov r1,dstBitmap
	bl bitmap_copyAlpha

	// Overlay the shadow using alpha
	ldr r0,=m_iconShadowBitmap
	mov r1,dstBitmap
	bl bitmap_copyAlpha

	// Overlay the highlights
	ldr r0,=m_iconHighlightBitmap
	mov r1,dstBitmap
	bl bitmap_copyAlphaAdd

	// Mask out the rest
	ldr r0,=m_iconMaskBitmap
	mov r1,dstBitmap
	bl bitmap_mask

	.unreq dstBitmap
	.unreq color
	.unreq image
	pop {r4-r6,pc}
