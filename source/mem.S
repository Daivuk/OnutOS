#include "mem.h"

.section .data
MEM_USAGE_TEXT: .asciz "Memory usage    "
MEM_KERNEL_TEXT: .asciz "Kernel    "
MEM_GPU_TEXT: .asciz "GPU    "
MEM_USER_TEXT: .asciz "User"
.align 2
MEM_KERNEL_COLOR: .int 0xFF24CBB4
MEM_GPU_COLOR: .int 0xFFFE5642
MEM_USER_COLOR: .int 0xFFF58754
MEM_USER_COLOR_UNUSED: .int 0xFF80462B

pFirstBlock: .int 0

.section .text
mem_getTotalSize:
#if defined(EMULATOR_MODE)
	// 256 mb
    mov r0,#1
    lsl r0,#28
#else
    // 1 gig
    mov r0,#1
    lsl r0,#30
#endif
	mov pc,lr

.section .text
mem_drawMemUsage:
    push {r4-r9,lr}

    x1 .req r5
    y1 .req r6
    x2 .req r7
    y2 .req r8
    pBlock .req r9

    // Text header
    ldr r0,=MEM_USAGE_TEXT
    bl screen_print
    ldr r0,=MEM_KERNEL_COLOR
    ldr r1,[r0]
    ldr r0,=MEM_KERNEL_TEXT
    bl screen_print
    ldr r0,=MEM_GPU_COLOR
    ldr r1,[r0]
    ldr r0,=MEM_GPU_TEXT
    bl screen_print
    ldr r0,=MEM_USER_COLOR
    ldr r1,[r0]
    ldr r0,=MEM_USER_TEXT
    bl screen_println

	// Calculate y1,y2 only once
    bl screen_getTextCursorY    // y1
    mov y1,r0
    add y2,y1,#62               // y2

	// Kernel
    ldr r0,=MEM_KERNEL_COLOR
    ldr r4,[r0]
    mov r0,#0                   // x1
    bl getRAMToScreen
    mov x1,r0
    ldr r0,=endMarker           // x2
    bl getRAMToScreen
    mov x2,r0
    mov r0,x1
    mov r1,y1
    mov r2,x2
    mov r3,y2
    bl screen_drawRect

	// Framebuffer
    ldr r0,=MEM_GPU_COLOR
    ldr r4,[r0]
    bl screen_getFrameBuffer    // x1
    bl getRAMToScreen
    mov x1,r0
    bl screen_getFrameBuffer    // x2
    mov x2,r0
    bl screen_getSize
    add r0,x2
    bl getRAMToScreen
    mov x2,r0
    mov r0,x1
    mov r1,y1
    mov r2,x2
    mov r3,y2
    bl screen_drawRect

	// User memory
	ldr pBlock,=pFirstBlock
	ldr pBlock,[pBlock]
	foreachBlock$:
		cmp pBlock,#0
		beq foreachBlock_done$

		ldr r0,[pBlock,#MemBlock_used]
		cmp r0,#0
		ldrne r0,=MEM_USER_COLOR
		ldreq r0,=MEM_USER_COLOR_UNUSED
		ldr r4,[r0]

		mov r0,pBlock
		bl getRAMToScreen
		mov x1,r0

		ldr r0,[pBlock,#MemBlock_size]
		add r0,pBlock
		add r0,#sizeof_MemBlock
		bl getRAMToScreen
		mov x2,r0

		mov r0,x1
		mov r1,y1
		mov r2,x2
		mov r3,y2
		bl screen_drawRect

		ldr pBlock,[pBlock,#MemBlock_pNext]
		b foreachBlock$
	foreachBlock_done$:

    // Top line
    ldr r0,=screen_varForeColor
    ldr r4,[r0]
    mov x1,#0                   // x1
    bl screen_getWidth          // x2
    mov x2,r0
    bl screen_getTextCursorY    // y1
    mov y1,r0
    add y2,y1,#2                // y2   
    mov r0,x1
    mov r1,y1
    mov r2,x2
    mov r3,y2
    bl screen_drawRect

    // Bottom line
    bl screen_getTextCursorY    // y1
    mov y1,r0
    add y1,#62
    add y2,y1,#2                // y2
    mov x1,#0                   // x1
    bl screen_getWidth          // x2
    mov x2,r0
    mov r0,x1
    mov r1,y1
    mov r2,x2
    mov r3,y2
    bl screen_drawRect

    // Left line
    mov x1,#0                   // x1
    mov x2,#2                   // x2
    bl screen_getTextCursorY    // y1
    mov y1,r0
    add y2,y1,#62               // y2
    mov r0,x1
    mov r1,y1
    mov r2,x2
    mov r3,y2
    bl screen_drawRect

    // Right line
    bl screen_getWidth
    mov x2,r0                   // x2
    sub x2,#1
    sub x1,x2,#2                // x1
    bl screen_getTextCursorY    // y1
    mov y1,r0
    mov y2,y1                   // y2
    add y2,#62
    mov r0,x1
    mov r1,y1
    mov r2,x2
    mov r3,y2
    bl screen_drawRect

	.unreq pBlock
    .unreq x1
    .unreq y1
    .unreq x2
    .unreq y2

    // Reset text cursor to new line
    bl screen_getTextCursorY
    add r0,#64
    bl screen_setTextCursorY
    mov r0,#0
    bl screen_setTextCursorX

    pop {r4-r9,pc}

getRAMToScreen:
    push {lr}

    mov r3,r0
    lsr r3,#10

    bl screen_getWidth
    sub r1,r0,#4

	bl mem_getTotalSize
	lsr r0,#10
	mov r2,r0

    mul r0,r3,r1
    udiv r0,r2
    add r0,#2

    pop {pc}

.section .text
mem_init:
	push {r4-r6,lr}
	frameBufferAddr .req r5
	pBlock .req r4
	pPrevBlock .req r6

	bl screen_getFrameBuffer
	mov frameBufferAddr,r0

	ldr pBlock,=endMarker // This is where the heap starts
	tst pBlock,#0x3 // Make sure we are 4 bytes aligned
	andne pBlock,#0xFFFFFFFC
	addne pBlock,#4

	// Save our block address in our variable
	ldr r0,=pFirstBlock
	str pBlock,[r0]

	// Setup the first block
	mov r0,#0
	str r0,[pBlock,#MemBlock_used] // false
	sub r0,frameBufferAddr,pBlock
	sub r0,#sizeof_MemBlock
	str r0,[pBlock,#MemBlock_size] // space between kernel and framebuffer in bytes
	mov r0,#0
	str r0,[pBlock,#MemBlock_pPrev] // nullptr
	bl screen_getSize
	add r0,frameBufferAddr
	//	mov r0,#0
	str r0,[pBlock,#MemBlock_pNext] // Should already be aligned properly

	// Setup the second block, the one after the framebuffer
	mov pPrevBlock,pBlock
	mov pBlock,r0
	mov r0,#0
	str r0,[pBlock,#MemBlock_used] // false
	bl mem_getTotalSize
	sub r0,pBlock
	sub r0,#sizeof_MemBlock
	str r0,[pBlock,#MemBlock_size] // Remaining size after the block
	str pPrevBlock,[pBlock,#MemBlock_pPrev]
	mov r0,#0
	str r0,[pBlock,#MemBlock_pNext] // nullptr, last block
	
	.unreq pPrevBlock
	.unreq pBlock
	.unreq frameBufferAddr
	pop {r4-r6,pc}
