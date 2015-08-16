.section .data

.align 2
.globl screen_varBackColor
screen_varBackColor: .int 0xFF381423
.globl screen_varForeColor
screen_varForeColor: .int 0xFFF09EC2
.globl screen_okColor
screen_okColor: .int 0xFF00FF00
.globl screen_failColor
screen_failColor: .int 0xFFFF0000

screen_textCursorX:	.int 0
screen_textCursorY:	.int 0

screen_tabSize: .int 4

.align 4
font:
	.incbin "font.bin"

.align 4
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

.section .text
.globl screen_getFrameBuffer
screen_getFrameBuffer:
    ldr r1,=screen_varFrameBufferInfo
    ldr r0,[r1,#32]
    sub r0,#0xC0000000
    mov pc,lr

.globl screen_getWidth
screen_getWidth:
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#8]
    mov pc,lr

.globl screen_getHeight
screen_getHeight:
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#12]
    mov pc,lr

.globl screen_getColorDepth
screen_getColorDepth:
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#20]
    mov pc,lr

.globl screen_getPitch
screen_getPitch:
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#16]
    mov pc,lr

.globl screen_getSize
screen_getSize:
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#36]
    mov pc,lr

.globl screen_getTextCursorX
screen_getTextCursorX:
    ldr r2,=screen_textCursorX
    ldr r0,[r2]
    mov pc,lr

.globl screen_getTextCursorY
screen_getTextCursorY:
    ldr r2,=screen_textCursorY
    ldr r0,[r2]
    mov pc,lr

.globl screen_setTextCursorX
screen_setTextCursorX:
    ldr r2,=screen_textCursorX
    str r0,[r2]
    mov pc,lr

.globl screen_setTextCursorY
screen_setTextCursorY:
    ldr r2,=screen_textCursorY
    str r0,[r2]
    mov pc,lr

.globl screen_getTabSize
screen_getTabSize:
    ldr r2,=screen_tabSize
    ldr r0,[r2]
    mov pc,lr

.globl screen_setTabSize
screen_setTabSize:
    ldr r2,=screen_tabSize
    str r0,[r2]
    mov pc,lr

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

// r0 = ARGB color
.globl screen_clear
screen_clear:
	colour .req r0
	frameBuffer .req r1
	size .req r2

	ldr r3,=screen_varFrameBufferInfo

	// Calculate size
	ldr size,[r3,#36] // Height

	// Get frame buffer address
	ldr frameBuffer,[r3,#32]
	sub frameBuffer,#0xC0000000

	// Fill the screen (memset)
	drawPixel$:
		str colour,[frameBuffer],#4
		subs size,#4
		bne drawPixel$

	.unreq colour
	.unreq frameBuffer
	.unreq size

	mov pc,lr

// Draw a character. Will move the cursor for us
// r0 = character id
// r1 = Fore color
.globl screen_printChar
screen_printChar:
	and r0,#0x7F

	push {r4-r8,lr}
    
    // Special characters
	cmp r0,#'\n'
	beq newLine$
    cmp r0,#'\t'
    beq doTab$

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

	pop {r4-r8,pc}
    
	newLine$:
        mov r0,#0
        bl screen_setTextCursorX
        bl screen_getTextCursorY
		add r0,#16
        bl screen_setTextCursorY
		pop {r4-r8,pc}

    doTab$:
        bl screen_getTabSize
        mov r4,r0
        lsl r4,#5
		bl screen_getTextCursorX
        udiv r0,r4
        mul r0,r4
        add r0,r4
        bl screen_setTextCursorX
		pop {r4-r8,pc}

// r0 = null terminated string address
// r1 = Fore color
.globl screen_println
screen_println:
    push {lr}
    bl screen_print
    mov r0,#'\n'
    bl screen_printChar
    pop {pc}
.globl screen_print
screen_print:
	push {r4,lr}
	mov r4,r0
	loopChars$:
		ldrb r0,[r4],#1
        cmp r0,#0
		beq endPrint$

		bl screen_printChar
		b loopChars$

	endPrint$:
		pop {r4,pc}

// Print an unsigned int in decimal
// r0 = Number
// r1 = Fore color
.globl screen_printU32ln
screen_printU32ln:
    push {lr}
    bl screen_printU32
    mov r0,#'\n'
    bl screen_printChar
    pop {pc}
.globl screen_printU32
screen_printU32:
    cmp r0,#0
    addeq r0,#'0'
    beq screen_printChar

    push {r4-r6,lr}

    num .req r0
	modulo .req r3
    ten .req r4
    invNum .req r5
	count .req r6

    mov ten,#10
    mov invNum,#0
	mov count,#0

    decInv$:
		// Move on if our number is 0
        cmp num,#0
        beq devPrint$ 

		// calculate modulo
		udiv modulo,num,ten
		mul modulo,ten
		sub modulo,num,modulo

		// Append the number at the end
		mul invNum,ten
		add invNum,modulo

		// Div,Inc,Loop back
        udiv num,ten
		add count,#1
        b decInv$

    devPrint$:
		// Check if we are done the count
        cmp count,#0
        popeq {r4-r6,pc}

		// Calculate modulo
		udiv modulo,invNum,ten
		mul modulo,ten
		sub modulo,invNum,modulo

		// Print the modulo number
		mov r0,modulo
		add r0,#'0'
		bl screen_printChar

		// Div, dec, loop back
        udiv invNum,ten
		sub count,#1
        b devPrint$

    .unreq invNum
    .unreq num
    .unreq ten
	.unreq modulo
	.unreq count

dec2hex:
    cmp r0,#9
    addhi r0,#7
    add r0,#'0'
    mov pc,lr

// Print an hexadecimal address
// r0 = Address
// r1 = Fore color
.globl screen_printAddrln
screen_printAddrln:
    push {lr}
    bl screen_printAddr
    mov r0,#'\n'
    bl screen_printChar
    pop {pc}
.globl screen_printAddr
screen_printAddr:
    push {r4,lr}
    mov r4,r0
    mov r0,#'0'
    bl screen_printChar
    mov r0,#'x'
    bl screen_printChar

    mov r0,r4
    mov r2,#8
    bl screen_printHex

    pop {r4,pc}

// r0 = number
// r1 = fore color
// r2 = count
.globl screen_printHexln
screen_printHexln:
    push {lr}
    bl screen_printHex
    mov r0,#'\n'
    bl screen_printChar
    pop {pc}
.globl screen_printHex
screen_printHex:
    push {r4-r6,lr}

    num .req r4
    i .req r5

    mov num,r0
    mov i,r2
    lsl i,#2
    screen_printHex_loop$:
        sub i,#4

        mov r0,num
        lsr r0,i
        and r0,#0xF
        bl dec2hex
        bl screen_printChar
        
        cmp i,#0
        bne screen_printHex_loop$

    .unreq num
    .unreq i

    pop {r4-r6,pc}

.section .data
.align 2
FRAME_BUFFER_TEXT: .asciz    "Frame buffer:"
PHYSICAL_WIDTH_TEXT: .asciz  "    Physical Width  = "
PHYSICAL_HEIGHT_TEXT: .asciz "    Physical Height = "
VIRTUAL_WIDTH_TEXT: .asciz   "Virtual Width   = "
VIRTUAL_HEIGHT_TEXT: .asciz  "Virtual Height  = "
PITCH_TEXT: .asciz           "Pitch       = "
COLOR_DEPTH_TEXT: .asciz     "Color Depth = "
POINTER_TEXT: .asciz         "Address = "
SIZE_TEXT: .asciz            "Size    = "
COMMA_TEXT: .ascii ", "

.section .text
.globl screen_printInfo
screen_printInfo:
	push {lr}

    // Set text color
    ldr r2,=screen_varForeColor
    ldr r1,[r2]

    ldr r0,=FRAME_BUFFER_TEXT
    bl screen_println

    // Line 1
    ldr r0,=PHYSICAL_WIDTH_TEXT
    bl screen_print
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#0]
    bl screen_printU32

	ldr r2,=screen_textCursorX
	mov r0,#1024
	str r0,[r2] // Move X cursor to 32 characters
    ldr r0,=VIRTUAL_WIDTH_TEXT
    bl screen_print
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#8]
    bl screen_printU32

	ldr r2,=screen_textCursorX
	mov r0,#1920
	str r0,[r2] // Move X cursor
    ldr r0,=PITCH_TEXT
    bl screen_print
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#16]
    bl screen_printU32

	ldr r2,=screen_textCursorX
	mov r0,#2688
	str r0,[r2] // Move X cursor
    ldr r0,=POINTER_TEXT
    bl screen_print
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#32]
    sub r0,#0xC0000000
    bl screen_printAddrln

    // Line 2
    ldr r0,=PHYSICAL_HEIGHT_TEXT
    bl screen_print
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#4]
    bl screen_printU32

	ldr r2,=screen_textCursorX
	mov r0,#1024
	str r0,[r2] // Move X cursor to 32 characters
    ldr r0,=VIRTUAL_HEIGHT_TEXT
    bl screen_print
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#12]
    bl screen_printU32

	ldr r2,=screen_textCursorX
	mov r0,#1920
	str r0,[r2] // Move X cursor
    ldr r0,=COLOR_DEPTH_TEXT
    bl screen_print
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#20]
    bl screen_printU32

	ldr r2,=screen_textCursorX
	mov r0,#2688
	str r0,[r2] // Move X cursor
    ldr r0,=SIZE_TEXT
    bl screen_print
    ldr r2,=screen_varFrameBufferInfo
    ldr r0,[r2,#36]
    bl screen_printU32ln

	pop {pc}

// Draw a rectangle on the screen
// r0 = x1
// r1 = y1
// r2 = x2
// r3 = y2
// r4 = color
.globl screen_drawRect
screen_drawRect:
    yAdvance .req r3
    frameBuffer .req r4
    x1 .req r5
    y1 .req r6
    x2 .req r7
    y2 .req r8
    colour .req r9

    push {r4-r9,lr}

    mov x1,r0
    mov y1,r1
    mov x2,r2
    mov y2,r3
    mov colour,r4

    // Reordering min/max
    cmp x1,x2
    movgt r0,x1
    movgt x1,x2
    movgt x2,r0
    addeq x2,#1
    cmp y1,y2
    movgt r0,y1
    movgt y1,y2
    movgt y2,r0
    addeq y2,#1

    // Do some clamping to screen
    cmp x1,#0
    movlt x1,#0
    cmp y1,#0
    movlt y1,#0
    cmp x2,#0
    movlt x2,#0
    cmp y2,#0
    movlt y2,#0
    bl screen_getWidth
    sub r0,#1
    cmp x1,r0
    movgt x1,r0
    cmp x2,r0
    movgt x2,r0
    bl screen_getHeight
    sub r0,#1
    cmp y1,r0
    movgt y1,r0
    cmp y2,r0
    movgt y2,r0

    bl screen_getFrameBuffer
    mov frameBuffer,r0
    bl screen_getPitch
    mul r0,y1
    add frameBuffer,r0
    mov r0,x1
    lsl r0,#2
    add frameBuffer,r0

    mov yAdvance,x1
    bl screen_getWidth
    sub r0,x2
    add yAdvance,r0
    lsl yAdvance,#2

    loopY$:
        mov r0,x1
        loopX$:
            str colour,[frameBuffer],#4
            add r0,#1
            cmp r0,x2
            blo loopX$
        add frameBuffer,yAdvance
        add y1,#1
        cmp y1,y2
        blo loopY$

    .unreq x1
    .unreq y1
    .unreq x2
    .unreq y2
    .unreq colour
    .unreq frameBuffer
    .unreq yAdvance

    pop {r4-r9,pc}
