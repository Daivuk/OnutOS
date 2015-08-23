#include "bitmap.h"

.section .text
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
// Do a plain copy from a bitmap to another one, but alpha blend
// Destination bitmap must be of same dimensions are source
// r0 = Source bitmap
// r1 = Destination bitmap
bitmap_copyAlpha:
	push {r4-r12,lr}
	srcBitmap .req r4
	dstBitmap .req r5
	size .req r6
	srcR .req r7
	srcG .req r8
	srcB .req r9
	srcA .req r10
	dstR .req r2
	dstG .req r3
	dstB .req r11
	dstA .req r12
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
	
	ldr r1,[dstBitmap,#BITMAP_height]
	mul size,r0,r1
	ldr srcBitmap,[srcBitmap,#BITMAP_addr]
	ldr dstBitmap,[dstBitmap,#BITMAP_addr]
	bitmap_copyAlpha_loop$:
		// Load source and destination color
		ldr r0,[srcBitmap],#4
		ldr r1,[dstBitmap]

		// Decompose source
		and srcB,r0,#0xFF
		lsr r0,#8
		and srcG,r0,#0xFF
		lsr r0,#8
		and srcR,r0,#0xFF
		lsr srcA,r0,#8

        mul srcR,srcA
        mul srcG,srcA
        mul srcB,srcA
        rsb srcA,srcA,#0xFF

		// Decompose destination
		and dstB,r1,#0xFF
		lsr r1,#8
		and dstG,r1,#0xFF
		lsr r1,#8
		and dstR,r1,#0xFF
		lsr dstA,r1,#8

		// Do the maths
        mla dstR,dstR,srcA,srcR
		lsr dstR,#8

        mla dstG,dstG,srcA,srcG
		lsr dstG,#8

        mla dstB,dstB,srcA,srcB
		lsr dstB,#8

		// Recompose destination color
        orr r1,dstB,dstA,lsl #24
        orr r1,r1,dstR,lsl #16
        orr r1,r1,dstG,lsl #8

		// Store result
		str r1,[dstBitmap],#4
		subs size,#1
		bne bitmap_copyAlpha_loop$

	ui_copyAlpha_done$:
		.unreq srcBitmap
		.unreq dstBitmap
		.unreq size
		.unreq srcA
		.unreq srcR
		.unreq srcG
		.unreq srcB
		.unreq dstA
		.unreq dstR
		.unreq dstG
		.unreq dstB
		pop {r4-r12,pc}

.section .text
bitmap_alphaBlendPixel:
	push {r4-r7,lr}
	srcA .req r0
	srcR .req r4
	srcG .req r2
	srcB .req r3
	dstA .req r1
	dstR .req r5
	dstG .req r6
	dstB .req r7

	// Decompose source
	and srcB,r0,#0xFF
	lsr r0,#8
	and srcG,r0,#0xFF
	lsr r0,#8
	and srcR,r0,#0xFF
	lsr srcA,r0,#8

	// Decompose destination
	and dstB,r1,#0xFF
	lsr r1,#8
	and dstG,r1,#0xFF
	lsr r1,#8
	and dstR,r1,#0xFF
	lsr dstA,r1,#8

    mul srcR,srcA;
    mul srcG,srcA;
    mul srcB,srcA;
    rsb srcA,srcA,#0xFF

	// Do the maths
	mla dstR,dstR,srcA,srcR
	lsr dstR,#8

	mla dstG,dstG,srcA,srcG
	lsr dstG,#8

	mla dstB,dstB,srcA,srcB
	lsr dstB,#8

	// Recompose destination color
    orr r0,dstB,dstA,lsl #24
    orr r0,r0,dstR,lsl #16
    orr r0,r0,dstG,lsl #8

	.unreq srcR
	.unreq srcG
	.unreq srcB
	.unreq srcA
	.unreq dstR
	.unreq dstG
	.unreq dstB
	.unreq dstA

	pop {r4-r7,pc}

.section .text
// Do a plain copy from a bitmap to another one, but alpha blend additive
// Destination bitmap must be of same dimensions are source
// r0 = Source bitmap
// r1 = Destination bitmap
bitmap_copyAlphaAdd:
	push {r4-r12,lr}
	srcBitmap .req r4
	dstBitmap .req r5
	size .req r6
	srcR .req r7
	srcG .req r8
	srcB .req r9
	srcA .req r10
	dstR .req r2
	dstG .req r3
	dstB .req r11
	dstA .req r12
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
	
	ldr r1,[dstBitmap,#BITMAP_height]
	mul size,r0,r1
	ldr srcBitmap,[srcBitmap,#BITMAP_addr]
	ldr dstBitmap,[dstBitmap,#BITMAP_addr]
	bitmap_copyAlphaAdd_loop$:
		// Load source and destination color
		ldr r0,[srcBitmap],#4
		ldr r1,[dstBitmap]

		// Decompose source
		and srcB,r0,#0xFF
		lsr r0,#8
		and srcG,r0,#0xFF
		lsr r0,#8
		and srcR,r0,#0xFF
		lsr srcA,r0,#8

		// Decompose destination
		and dstB,r1,#0xFF
		lsr r1,#8
		and dstG,r1,#0xFF
		lsr r1,#8
		and dstR,r1,#0xFF
		lsr dstA,r1,#8

		// Do the maths
		mul srcR,srcA
		add dstR,dstR,srcR,lsr #8
		cmp dstR,#0xFF
		movhi dstR,#0xFF

		mul srcG,srcA
		add dstG,dstG,srcG,lsr #8
		cmp dstG,#0xFF
		movhi dstG,#0xFF

		mul srcB,srcA
		add dstB,dstB,srcB,lsr #8
		cmp dstB,#0xFF
		movhi dstB,#0xFF

		// Recompose destination color
        orr r1,dstB,dstA,lsl #24
        orr r1,r1,dstR,lsl #16
        orr r1,r1,dstG,lsl #8

		// Store result
		str r1,[dstBitmap],#4
		subs size,#1
		bne bitmap_copyAlphaAdd_loop$

	bitmap_copyAlphaAdd_done$:
		.unreq srcBitmap
		.unreq dstBitmap
		.unreq size
		.unreq srcA
		.unreq srcR
		.unreq srcG
		.unreq srcB
		.unreq dstA
		.unreq dstR
		.unreq dstG
		.unreq dstB
		pop {r4-r12,pc}

.section .text
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

.section .text
.globl bitmap_blitFullAlpha
bitmap_blitFullAlpha:
	push {r4-r7,lr}
	mov r7,r3
	mov r6,r2
	mov r3,r1
	mov r2,r0
	mov r0,#0
	mov r1,#0
	ldr r4,[r6,#BITMAP_width]
	ldr r5,[r6,#BITMAP_height]
	bl bitmap_blitAlpha
	pop {r4-r7,pc}

.section .text
bitmap_blitFullTransparent:
	push {r4-r7,lr}
	mov r7,r3
	mov r6,r2
	mov r3,r1
	mov r2,r0
	mov r0,#0
	mov r1,#0
	ldr r4,[r6,#BITMAP_width]
	ldr r5,[r6,#BITMAP_height]
	bl bitmap_blitTransparent
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
	dstWidth .req r8
	dstHeight .req r8

	// Do some validation and crop the rectangle if necessary
	ldr dstWidth,[dstBitmap,#BITMAP_width] // Make sure destination X + width < destination width
	add r9,dstX,width
	cmp r9,dstWidth
	subhi r9,dstWidth
	subhi width,r9

	ldr dstHeight,[dstBitmap,#BITMAP_height]
	add r9,dstY,height
	cmp r9,dstHeight
	subhi r9,dstHeight
	subhi height,r9

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
		.unreq dstHeight
		.unreq dstWidth
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
bitmap_blitAlpha:
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
	dstWidth .req r8
	dstHeight .req r8

	// Do some validation and crop the rectangle if necessary
	ldr dstWidth,[dstBitmap,#BITMAP_width] // Make sure destination X + width < destination width
	add r9,dstX,width
	cmp r9,dstWidth
	subhi r9,dstWidth
	subhi width,r9

	ldr dstHeight,[dstBitmap,#BITMAP_height]
	add r9,dstY,height
	cmp r9,dstHeight
	subhi r9,dstHeight
	subhi height,r9

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

	ui_blit_loopY_alpha$:
		mov x,width
		ui_blit_loopX_alpha$:
			ldr r0,[srcBitmap],#4
			ldr r1,[dstBitmap]

			bl bitmap_alphaBlendPixel

			str r0,[dstBitmap],#4
			subs x,#1
			bne ui_blit_loopX_alpha$

		add srcBitmap,srcYAdvance
		add dstBitmap,dstYAdvance
		subs height,#1
		bne ui_blit_loopY_alpha$

	ui_blit_done_alpha$:
		.unreq dstHeight
		.unreq dstWidth
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

// Blit a rectangle from a source transparent bitmap to destination bitmap
// r0 = source X
// r1 = source Y
// r2 = destination X
// r3 = destination Y
// r4 = width
// r5 = height
// r6 = source bitmap
// r7 = destination bitmap
.section .text
bitmap_blitTransparent:
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
	dstWidth .req r8
	dstHeight .req r8

	// Do some validation and crop the rectangle if necessary
	ldr dstWidth,[dstBitmap,#BITMAP_width] // Make sure destination X + width < destination width
	add r9,dstX,width
	cmp r9,dstWidth
	subhi r9,dstWidth
	subhi width,r9

	ldr dstHeight,[dstBitmap,#BITMAP_height]
	add r9,dstY,height
	cmp r9,dstHeight
	subhi r9,dstHeight
	subhi height,r9

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

	ui_blit_loopYT$:
		mov x,width
		ui_blit_loopXT$:
			ldr r0,[srcBitmap],#4
			tst r0,#0xFF000000
			strne r0,[dstBitmap],#4
			addeq dstBitmap,#4

			subs x,#1
			bne ui_blit_loopXT$

		add srcBitmap,srcYAdvance
		add dstBitmap,dstYAdvance
		subs height,#1
		bne ui_blit_loopYT$

	ui_blit_doneT$:
		.unreq dstHeight
		.unreq dstWidth
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
	ldr r3,[bitmap,#BITMAP_height]
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

// r0 = bitmap
// r1 = color
.section .text
bitmap_fill:
	bitmap .req r0
	color .req r1
	size .req r2

	ldr size,[bitmap,#BITMAP_width]
	ldr r3,[bitmap,#BITMAP_height]
	mul size,r3

	ldr bitmap,[bitmap,#BITMAP_addr]

	bitmap_fill_loop$:
		str color,[bitmap],#4
		subs size,#1
		bne bitmap_fill_loop$
		
	.unreq color
	.unreq size
	.unreq bitmap
	mov pc,lr

// r0 = bitmap
// r1 = color
.section .text
bitmap_fillAlpha:
	push {r4-r10,lr}
	bitmap .req r0
	color .req r1
	size .req r2
    tmp .req r3
    invSrcA .req r3
	srcR .req r4
	srcG .req r5
	srcB .req r6
	srcA .req r3
	dstR .req r7
	dstG .req r8
	dstB .req r9
	dstA .req r10

	ldr size,[bitmap,#BITMAP_width]
	ldr tmp,[bitmap,#BITMAP_height]
	mul size,tmp

    // Decompose source
	and srcB,color,#0xFF
	lsr color,#8
	and srcG,color,#0xFF
	lsr color,#8
	and srcR,color,#0xFF
	lsr srcA,color,#8

    mul srcR,srcA
    mul srcG,srcA
    mul srcB,srcA
    rsb invSrcA,srcA,#0xFF

	ldr bitmap,[bitmap,#BITMAP_addr]

	bitmap_fill_loopAlpha$:
		ldr color,[bitmap]

		// Decompose destination
		and dstB,color,#0xFF
		lsr color,#8
		and dstG,color,#0xFF
		lsr color,#8
		and dstR,color,#0xFF
		lsr dstA,color,#8

		// Do the maths
		mla dstR,dstR,invSrcA,srcR
		lsr dstR,#8

		mla dstG,dstG,invSrcA,srcG
		lsr dstG,#8

		mla dstB,dstB,invSrcA,srcB
		lsr dstB,#8

		// Recompose destination color
        orr color,dstB,dstA,lsl #24
        orr color,color,dstR,lsl #16
        orr color,color,dstG,lsl #8

		str color,[bitmap],#4

		subs size,#1
		bne bitmap_fill_loopAlpha$
		
	.unreq color
	.unreq size
	.unreq bitmap
	.unreq srcR
	.unreq srcG
	.unreq srcB
	.unreq srcA
	.unreq dstR
	.unreq dstG
	.unreq dstB
	.unreq dstA
    .unreq tmp
    .unreq invSrcA
    pop {r4-r10,pc}

.section .text
bitmap_mask:
	push {r4,lr}

	mask .req r0
	bitmap .req r1
	size .req r2

	ldr size,[mask,#BITMAP_width]
	ldr r3,[mask,#BITMAP_height]
	mul size,r3

	ldr mask,[mask,#BITMAP_addr]
	ldr bitmap,[bitmap,#BITMAP_addr]

	bitmap_mask_loop$:
		ldr r3,[mask],#4
		and r3,#0xFF000000
		ldr r4,[bitmap]
		and r4,#0x00FFFFFF
		orr r4,r3
		str r4,[bitmap],#4
		subs size,#1
		bne bitmap_mask_loop$

	.unreq mask
	.unreq bitmap
	.unreq size
	pop {r4,pc}
