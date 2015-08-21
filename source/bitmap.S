#include "bitmap.h"

.section .text
.globl bitmap_copy
// Do a plain copy from a bitmap to another one.
// Destination bitmap must be of same dimensions are source
// r0 = Source bitmap
// r1 = Destination bitmap
bitmap_copy:
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
.globl bitmap_resize
// Resize source bitmap to fit into destination bitmap.
// Both bitmap must match the same bit depth
// r0 = Source bitmap
// r1 = Destination bitmap
bitmap_resize:
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
.globl bitmap_blitFull
bitmap_blitFull:
	push {r4-r7,lr}
	mov r7,r3
	mov r6,r2
	mov r3,r1
	mov r2,r0
	mov r0,#0
	mov r1,#0
	ldr r4,[r6,#BITMAP_width]
	ldr r5,[r6,#BITMAP_height]
	bl bitmap_blit
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
.globl bitmap_blit
bitmap_blit:
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
.globl bitmap_multColor
bitmap_multColor:
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
