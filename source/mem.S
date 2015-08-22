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
    add y2,y1,#32               // y2

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

	// User memory
	ldr pBlock,=pFirstBlock
	ldr pBlock,[pBlock]
	foreachBlock$:
		cmp pBlock,#0
		beq foreachBlock_done$

		ldr r0,[pBlock,#MemBlock_processId]
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
    add y1,#32
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
    add y2,y1,#32               // y2
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
    add y2,#32
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
    add r0,#34
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

	// Setup the first empty block
	mov r0,#0
	str r0,[pBlock,#MemBlock_processId] // Unused
	sub r0,frameBufferAddr,pBlock
	sub r0,#sizeof_MemBlock
	sub r0,#sizeof_MemBlock
	str r0,[pBlock,#MemBlock_size] // space between kernel and framebuffer in bytes - sizeof MemBlock
	mov r0,#0
	str r0,[pBlock,#MemBlock_pPrev] // nullptr
	mov r0,frameBufferAddr
	sub r0,#sizeof_MemBlock
	str r0,[pBlock,#MemBlock_pNext]

	// The second block is the GPU area, that we mark as used
	mov pPrevBlock,pBlock
	mov pBlock,r0
	mov r0,#PROCESS_GPU
	str r0,[pBlock,#MemBlock_processId]
	bl screen_getSize
	str r0,[pBlock,#MemBlock_size]
	add r0,pBlock
	add r0,#sizeof_MemBlock
	str r0,[pBlock,#MemBlock_pNext]
	str pBlock,[r0,#MemBlock_pPrev]
	
	// Setup the second block, the one after the framebuffer
	mov pPrevBlock,pBlock
	mov pBlock,r0
	mov r0,#0
	str r0,[pBlock,#MemBlock_processId] // Unused
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

mem_alloc:
	requestSize .req r0
	requestProcessId .req r1
	nextMinimumSize .req r1
	pNextBlock .req r1
	processId .req r2
	size .req r2
	pNewBlock .req r2
	pBlock .req r3

	ldr pBlock,=pFirstBlock
	ldr pBlock,[pBlock]

	mem_alloc_foreachBlock$:
		cmp pBlock,#0
		beq mem_alloc_foreachBlock_done$

		// Check if this block is in used
		ldr processId,[pBlock,#MemBlock_processId]
		cmp processId,#0
		bne mem_alloc_foreachBlock_continue$

		// Check if enough size
		ldr size,[pBlock,#MemBlock_size]
		cmp size,requestSize
		blo mem_alloc_foreachBlock_continue$

		// Use this block
		str requestProcessId,[pBlock,#MemBlock_processId]
		mov nextMinimumSize,#sizeof_MemBlock
		add nextMinimumSize,#1
		sub size,requestSize
		cmp size,nextMinimumSize
		blo mem_alloc_blockFound$

		// Split and create the next block
		ldr pNextBlock,[pBlock,#MemBlock_pNext]
		add pNewBlock,pBlock,#sizeof_MemBlock
		add pNewBlock,requestSize
		str pNewBlock,[pBlock,#MemBlock_pNext]
		str pNextBlock,[pNewBlock,#MemBlock_pNext]
		str pBlock,[pNewBlock,#MemBlock_pPrev]
		cmp pNextBlock,#0
		strne pNewBlock,[pNextBlock,#MemBlock_pPrev]
		mov r1,#0
		str r1,[pNewBlock,#MemBlock_processId]
		ldr r1,[pBlock,#MemBlock_size]
		sub r1,requestSize
		sub r1,#sizeof_MemBlock
		str r1,[pNewBlock,#MemBlock_size]
		str requestSize,[pBlock,#MemBlock_size]

		mem_alloc_blockFound$:
			mov r0,pBlock
			add r0,#sizeof_MemBlock
			mov pc,lr

		mem_alloc_foreachBlock_continue$:
			ldr pBlock,[pBlock,#MemBlock_pNext]
			b mem_alloc_foreachBlock$

	mem_alloc_foreachBlock_done$:
		mov r0,#0
		mov pc,lr

	.unreq pNewBlock
	.unreq requestSize
	.unreq requestProcessId
	.unreq nextMinimumSize
	.unreq pNextBlock
	.unreq pBlock
	.unreq processId
	.unreq size

mem_free:
	pBlock .req r0
	processId .req r1
	size .req r1
	pPrevBlock .req r2
	nextSize .req r2
	pNextBlock .req r3
	prevSize .req r3

	sub pBlock,#sizeof_MemBlock
	mov r1,#0
	str r1,[pBlock,#MemBlock_processId]

	// Can we merge with previous block?
	ldr pPrevBlock,[pBlock,#MemBlock_pPrev]
	cmp pPrevBlock,#0
	beq mem_free_dontMergePrev$ // pPrev is NULL
	ldr processId,[pPrevBlock,#MemBlock_processId]
	cmp processId,#0
	bne mem_free_dontMergePrev$ // pPrev is not free
	ldr prevSize,[pPrevBlock,#MemBlock_size]
	ldr size,[pBlock,#MemBlock_size]
	add size,#sizeof_MemBlock
	add prevSize,size
	str prevSize,[pPrevBlock,#MemBlock_size]
	ldr pNextBlock,[pBlock,#MemBlock_pNext]
	str pNextBlock,[pPrevBlock,#MemBlock_pNext]
	cmp pNextBlock,#1
	strne pPrevBlock,[pNextBlock,#MemBlock_pPrev]
	mov pBlock,pPrevBlock

	mem_free_dontMergePrev$:
	// Can we merge with next block?
	ldr pNextBlock,[pBlock,#MemBlock_pNext]
	cmp pNextBlock,#0
	moveq pc,lr // pNext is NULL
	ldr processId,[pNextBlock,#MemBlock_processId]
	cmp processId,#0
	movne pc,lr // pNext is not free
	ldr nextSize,[pNextBlock,#MemBlock_size]
	ldr size,[pBlock,#MemBlock_size]
	add size,#sizeof_MemBlock
	add size,nextSize
	str size,[pBlock,#MemBlock_size]
	ldr pNextBlock,[pNextBlock,#MemBlock_pNext]
	str pNextBlock,[pBlock,#MemBlock_pNext]
	cmp pNextBlock,#0
	strne pBlock,[pNextBlock,#MemBlock_pPrev]

	mov pc,lr
	.unreq pBlock
	.unreq processId
	.unreq pPrevBlock
	.unreq pNextBlock
	.unreq size
	.unreq prevSize
	.unreq nextSize
