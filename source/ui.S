#define SIZEOF_BITMAP 16
	#define BITMAP_width	0x0
	#define BITMAP_height	0x4
	#define BITMAP_bbp		0x8
	#define BITMAP_addr		0xC

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
.globl ui_bitmapCopy
// Do a plain copy from a bitmap to another one.
// Destination bitmap must be of same dimensions are source
// r0 = Source bitmap
// r1 = Destination bitmap
ui_bitmapCopy:
	push {r4-r6,lr}
	srcBitmap .req r4
	dstBitmap .req r5
	size .req r6
	mov srcBitmap,r0
	mov dstBitmap,r1
	
	// Make sure they are exactly of same dimensions and bit depth
	ldr r0,[srcBitmap,#BITMAP_height]
	ldr r1,[dstBitmap,#BITMAP_height]
	cmp r0,r1
	bne ui_bitmapCopy_done$
	ldr r0,[srcBitmap,#BITMAP_bbp]
	ldr r1,[dstBitmap,#BITMAP_bbp]
	cmp r0,r1
	bne ui_bitmapCopy_done$
	ldr r0,[srcBitmap,#BITMAP_width]
	ldr r1,[dstBitmap,#BITMAP_width]
	cmp r0,r1
	bne ui_bitmapCopy_done$
	
	// Memcopy the shit out of them
	ldr r1,[dstBitmap,#BITMAP_height]
	mul size,r0,r1
	ldr srcBitmap,[srcBitmap,#BITMAP_addr]
	ldr dstBitmap,[dstBitmap,#BITMAP_addr]
	ui_bitmapCopy_loop$:
		ldr r0,[srcBitmap],#4
		str r0,[dstBitmap],#4
		subs size,#1
		bne ui_bitmapCopy_loop$

	ui_bitmapCopy_done$:
		.unreq srcBitmap
		.unreq dstBitmap
		.unreq size
		pop {r4-r6,pc}

.section .text
.globl ui_bitmapResize
// Resize source bitmap to fit into destination bitmap.
// Both bitmap must match the same bit depth
// r0 = Source bitmap
// r1 = Destination bitmap
ui_bitmapResize:
	push {r4-r10,lr}
	srcBitmap .req r4
	dstBitmap .req r5
	size .req r6
	srcWidth .req r7
	srcHeight .req r8
	dstWidth .req r9
	dstHeight .req r10
	x .req r11
	y .req r12
	mov srcBitmap,r0
	mov dstBitmap,r1

	// Make sure they are not of invalid size, like 0.
	ldr srcWidth,[srcBitmap,#BITMAP_width]
	cmp srcWidth,#0
	beq ui_bitmapResize_done$
	ldr srcHeight,[srcBitmap,#BITMAP_height]
	cmp srcHeight,#0
	beq ui_bitmapResize_done$
	ldr dstWidth,[dstBitmap,#BITMAP_width]
	cmp dstWidth,#0
	beq ui_bitmapResize_done$
	ldr dstHeight,[dstBitmap,#BITMAP_height]
	cmp dstHeight,#0
	beq ui_bitmapResize_done$
	ldr r0,[srcBitmap,#BITMAP_bbp]
	ldr r1,[dstBitmap,#BITMAP_bbp]
	cmp r0,r1
	bne ui_bitmapResize_done$

	// Loop destination x,y and point sample (for now) src
	ldr srcBitmap,[srcBitmap,#BITMAP_addr]
	ldr dstBitmap,[dstBitmap,#BITMAP_addr]
	mov y,#0
	ui_bitmapResize_loopY$:
		mov x,#0
		ui_bitmapResize_loopX$:
			mul r0,x,srcWidth
			udiv r0,dstWidth
			mul r1,y,srcHeight
			udiv r1,dstHeight
			mul r1,srcWidth
			add r0,r1
			lsl r0,#2
			add r0,srcBitmap
			ldr r0,[r0]
			str r0,[dstBitmap],#4

			add x,#1
			cmp x,dstWidth
			blo ui_bitmapResize_loopX$
		add y,#1
		cmp y,dstHeight
		blo ui_bitmapResize_loopY$

	ui_bitmapResize_done$:
		.unreq srcBitmap
		.unreq dstBitmap
		.unreq size
		.unreq srcWidth
		.unreq srcHeight
		.unreq dstWidth
		.unreq dstHeight
		.unreq x
		.unreq y
		pop {r4-r10,pc}

.section .text
.globl ui_blitFullBitmap
ui_blitFullBitmap:
	push {r4-r7,lr}
	mov r7,r3
	mov r6,r2
	mov r3,r1
	mov r2,r0
	mov r0,#0
	mov r1,#0
	ldr r4,[r6,#BITMAP_width]
	ldr r5,[r6,#BITMAP_height]
	bl ui_blitBitmap
	pop {r4-r7,pc}

// Blit a rectangle from a source bitmap to destination bitmap
// r0 = source X
// r1 = source Y
// r2 = destination X
// r3 = destination Y
// r4 = width
// r5 = height
// r6 = source bitmap
// r7 = destination bitmap
.section .text
.globl ui_blitBitmap
ui_blitBitmap:
	push {r4-r10,lr}
	srcX .req r0
	srcY .req r1
	dstX .req r2
	dstY .req r3
	width .req r4
	height .req r5
	x .req r8
	srcBitmap .req r6
	dstBitmap .req r7
	srcYAdvance .req r9
	dstYAdvance .req r10

	ldr srcYAdvance,[srcBitmap,#BITMAP_width]
	sub srcYAdvance,width
	lsl srcYAdvance,#2

	ldr dstYAdvance,[dstBitmap,#BITMAP_width]
	sub dstYAdvance,width
	lsl dstYAdvance,#2

	ldr r8,[srcBitmap,#BITMAP_width]
	mul srcY,r8
	add srcX,srcY
	lsl srcX,#2
	ldr srcBitmap,[srcBitmap,#BITMAP_addr]
	add srcBitmap,srcX

	ldr r8,[dstBitmap,#BITMAP_width]
	mul dstY,r8
	add dstX,dstY
	lsl dstX,#2
	ldr dstBitmap,[dstBitmap,#BITMAP_addr]
	add dstBitmap,dstX

	ui_blit_loopY$:
		mov x,width
		ui_blit_loopX$:
			ldr r0,[srcBitmap],#4
			str r0,[dstBitmap],#4

			subs x,#1
			bne ui_blit_loopX$

		add srcBitmap,srcYAdvance
		add dstBitmap,dstYAdvance
		subs height,#1
		bne ui_blit_loopY$

	ui_blit_done$:
		.unreq srcX
		.unreq srcY
		.unreq dstX
		.unreq dstY
		.unreq width
		.unreq height
		.unreq x
		.unreq srcBitmap
		.unreq dstBitmap
		.unreq srcYAdvance
		.unreq dstYAdvance
		pop {r4-r10,pc}

// r0 = bitmap
// r1 = color
.section .text
.globl ui_bitmapMultColor
ui_bitmapMultColor:
	push {r4-r9,lr}
	ir .req r4
	ig .req r5
	ib .req r6
	nr .req r7
	ng .req r8
	nb .req r9
	bitmap .req r0
	size .req r2

	ldr size,[bitmap,#BITMAP_width]
	ldr r3,[bitmap,#BITMAP_width]
	mul size,r3

	ldr bitmap,[bitmap,#BITMAP_addr]

	// Decompose our in color
	mov ir,r1
	mov ig,r1
	mov ib,r1
	lsr ir,#16
	lsr ig,#8
	and ir,#0xFF
	and ig,#0xFF
	and ib,#0xFF

	ui_bitmapMultColor_loop$:
		ldr r3,[bitmap]

		// Decompose
		mov nr,r3
		mov ng,r3
		mov nb,r3
		lsr nr,#16
		lsr ng,#8
		and nr,#0xFF
		and ng,#0xFF
		and nb,#0xFF

		// Mult
		mul nr,ir
		lsr nr,#8
		mul ng,ig
		lsr ng,#8
		mul nb,ib
		lsr nb,#8

		// Recompose
		and r3,#0xFF000000
		lsl nr,#16
		lsl ng,#8
		orr r3,nr
		orr r3,ng
		orr r3,nb

		str r3,[bitmap],#4

		subs size,#1
		bne ui_bitmapMultColor_loop$

	.unreq ir
	.unreq ig
	.unreq ib
	.unreq nr
	.unreq ng
	.unreq nb
	.unreq size
	.unreq bitmap
	pop {r4-r9,pc}

.section .text
.globl ui_init
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
	bl ui_bitmapResize

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
	bl ui_blitBitmap

	// Tone it down by 50%
	ldr r0,=TASK_BAR_BITMAP
	ldr r1,=TASK_BAR_COLOR
	ldr r1,[r1]
	bl ui_bitmapMultColor

	// Draw our context to the background
	ldr r0,=MAIN_CONTEXT
	ldr r1,=FRAME_BUFFER_BITMAP
	bl ui_bitmapCopy

	// Test draw task bar
	mov r0,#0
	ldr r3,=FRAME_BUFFER_BITMAP
	ldr r1,[r3,#BITMAP_height]
	sub r1,#TASK_BAR_HEIGHT
	ldr r2,=TASK_BAR_BITMAP
	bl ui_blitFullBitmap

	pop {r4-r7,pc}
