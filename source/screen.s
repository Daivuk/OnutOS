.section .data

.align 2
.globl screen_varBackColor
screen_varBackColor: .int 0xFF381423
.globl screen_varForeColor
screen_varForeColor: .int 0xFFF09EC2

screen_textCursorX:	.int 0
screen_textCursorY:	.int 0

.align 4
font:
	.incbin "font.bin"

.align 4
.globl screen_varFrameBufferInfo 
screen_varFrameBufferInfo:
	.int 1920   // 0 Physical Width
	.int 1080	// #4 Physical Height
	.int 1920	// #8 Virtual Width
	.int 1080	// #12 Virtual Height
	.int 0		// #16 GPU - Pitch
	.int 32		// #20 Bit Depth
	.int 0		// #24 X
	.int 0		// #28 Y
	.int 0		// #32 GPU - Pointer
	.int 0		// #36 GPU - Size

/*	.int 108	// size
	.int 0

	.int 0x00048003 // set_physical_display
	.int 8
	.int 8
	.int 1680
	.int 1050

	.int 0x00048004 // set_virtual_buffer
	.int 8
	.int 8
	.int 1680
	.int 1050

	.int 0x00048005 // t_set_depth
	.int 4
	.int 4
	.int 16

	.int 0x00048009 // t_set_virtual_offset
	.int 8
	.int 8
	.int 0
	.int 0

	.int 0x00040001 // t_allocate_buffer
	.int 8
	.int 8
	.int 0
	.int 0

	.int 0 // End tag*/

.section .text
.globl screen_init
screen_init:
	push {r4,lr}

	ldr r4,=screen_varFrameBufferInfo
	mov r0,r4
	add r0,#0xC0000000
	mov r1,#1
	bl mailbox_write

	mov r0,#1
	bl mailbox_read

	// If the return value is non-zero, turn off the LED in sign of error
	teq r0,#0
	blne gpio_turnLEDOff

	// If the frame buffer address is zero, turn off the LED in sign of error
	ldr r0,[r4,#32]
	sub r0,#0xC0000000
	teq r0,#0
	bleq gpio_turnLEDOff

	mov r0,r4

	pop {r4,pc}

/*
screen_init:
	push {r4,lr}

	ldr r4,=screen_varFrameBufferInfo
	mov r0,r4
	add r0,#0xC0000000

	// Write
	add r0,#8
	ldr r1,=0x3F00B8A8
	str r0,[r1]

	waitForFB$:
		ldr r2,[r4,#96]
		teq r2,#0
		beq waitForFB$

	bl gpio_turnLEDOff

	ldr r0,=screen_varFrameBufferInfo

	pop {r4,pc}
	*/

// r0 = ARGB color
.globl screen_clear
screen_clear:
	colour .req r0
	frameBuffer .req r1
	size .req r2

	ldr r3,=screen_varFrameBufferInfo

	// Calculate size
	ldr r1,[r3,#8] // Width
	ldr size,[r3,#12] // Height
	mul size,r1

	// Get frame buffer address
	ldr frameBuffer,[r3,#32]
	sub frameBuffer,#0xC0000000

	// Fill the screen (memset)
	drawPixel$:
		str colour,[frameBuffer],#4
		subs size,#1
		bne drawPixel$

	.unreq colour
	.unreq frameBuffer
	.unreq SIZE

	mov pc,lr

// Draw a character. Will move the cursor for us
// r0 = character id
// r1 = Fore color
.globl screen_printChar
screen_printChar:
	and r0,#0x7F

	push {r4,r5,r6,r7,r8,lr}

	x .req r0
	y .req r7
	charAddr .req r2
	bits .req r3
	cwidth .req r4
	cheight .req r5
	frameBuffer .req r6
	colour .req r1
	yAdvance .req r8

	// Point to the character address in the font
	ldr charAddr,=font
	add charAddr, r0,lsl #4

	ldr r5,=screen_textCursorX
	ldr x,[r5]
	ldr r5,=screen_textCursorY
	ldr y,[r5]
	ldr r3,=screen_varFrameBufferInfo

	ldr frameBuffer,[r3,#32]
	sub frameBuffer,#0xC0000000

	ldr yAdvance,[r3,#8] // Width
	lsl yAdvance,#2

	mov r5,yAdvance
	mul r5,y
	add frameBuffer,r5
	add frameBuffer,x

	sub yAdvance,#32

	mov cheight,#16

	rowLoop$:
		mov cwidth,#8
		ldrb bits,[charAddr]
		pixelLoop$:
			tst bits,#0b1
			beq continue$
			str colour,[frameBuffer]
			continue$:
				add frameBuffer,#4
				lsr bits,#1
				subs cwidth,#1
				bne pixelLoop$
			
		add frameBuffer,yAdvance
		add charAddr,#1
		subs cheight,#1
		bne rowLoop$

	add x,#32
	ldr r5,=screen_textCursorX
	str x,[r5]

	.unreq x
	.unreq y
	.unreq charAddr
	.unreq bits
	.unreq cwidth
	.unreq cheight
	.unreq frameBuffer
	.unreq colour
	.unreq yAdvance

	pop {r4,r5,r6,r7,r8,pc}

// r0 = null terminated string address
// r1 = Fore color
.globl screen_print
screen_print:
	push {r4,lr}
	mov r4,r0
	loopChars$:
		ldrb r0,[r4],#1
		tst r0,#0x7F
		beq endPrint$

		cmp r0,#'\n'
		beq newLine$

		bl screen_printChar
		b loopChars$

		newLine$:
			ldr r0,=screen_textCursorX
			mov r2,#0
			str r2,[r0]

			ldr r0,=screen_textCursorY
			ldr r2,[r0]
			add r2,#16
			str r2,[r0]

			b loopChars$

	endPrint$:
		pop {r4,pc}

.globl screen_printInfo
screen_printInfo:

	mov pc,lr
