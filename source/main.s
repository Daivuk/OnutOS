.section .init
.globl _start
_start:
	b main

.section .text
main:
	// Setup the stack
	mov sp,#0x8000

	// Init the general purpose input output controller
	bl gpio_init

	// Show that the kernel as launched by turning the LED on
	bl gpio_turnLEDOn

	// Initialize our frame buffer
	bl screen_init

	// Clear screen with background color
	ldr r1,=screen_varBackColor
	ldr r0,[r1]
	bl screen_clear

	// Draw OS + version
	ldr r0,=HELLO_WORLD_TEXT
	ldr r2,=screen_varForeColor
	ldr r1,[r2]
	bl screen_print

    // Draw entry point address
    ldr r0,=ENTRY_POINT_ADDR_TEXT
    bl screen_print
    ldr r0,=main
    bl screen_printAddr
    ldr r0,=NEW_LINE_TEXT
    bl screen_print
    ldr r0,=KERNEL_SIZE_TEXT
    bl screen_print
    ldr r0,=endMarker
    bl screen_printAddr
    ldr r0,=NEW_LINE_TEXT
    bl screen_print

	// Print some screen info
	bl screen_printInfo

    //--- Draw memory usage
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
    bl screen_print

    ldr r0,=MEM_KERNEL_COLOR
    ldr r4,[r0]
    ldr r0,=endMarker
    bl getRAMToScreen
    mov r6,r0
    mov r0,#0
    bl getRAMToScreen
    mov r5,r0
    mov r2,r6
    add r2,#1
    bl screen_getTextCursorY
    mov r1,r0
    add r1,#2
    mov r3,r1
    add r3,#62
    mov r0,r5
    bl screen_drawRect

    ldr r0,=MEM_GPU_COLOR
    ldr r4,[r0]
    bl screen_getFrameBuffer
    bl getRAMToScreen
    mov r6,r0
    bl screen_getFrameBuffer
    mov r5,r0
    bl screen_getSize
    add r0,r5
    bl getRAMToScreen
    mov r5,r0
    mov r2,r5
    add r2,#1
    bl screen_getTextCursorY
    mov r1,r0
    add r1,#2
    mov r3,r1
    add r3,#62
    mov r0,r6
    bl screen_drawRect

    // Top line
    ldr r0,=screen_varForeColor
    ldr r4,[r0]
    bl screen_getTextCursorY
    mov r2,r0
    bl screen_getWidth
    mov r1,r2
    mov r2,r0
    mov r3,r1
    add r3,#2
    mov r0,#0
    bl screen_drawRect

    // Bottom line
    bl screen_getTextCursorY
    mov r2,r0
    bl screen_getWidth
    mov r1,r2
    add r1,#64
    mov r2,r0
    mov r3,r1
    add r3,#2
    mov r0,#0
    bl screen_drawRect

    // Left line
    bl screen_getTextCursorY
    mov r1,r0
    mov r3,r1
    add r3,#64
    mov r0,#0
    mov r2,#2
    bl screen_drawRect

    // Right line
    bl screen_getTextCursorY
    mov r2,r0
    bl screen_getWidth
    mov r1,r2
    mov r3,r1
    add r3,#64
    mov r2,r0
    sub r0,#2
    bl screen_drawRect

    bl screen_getTextCursorY
    add r0,#64
    bl screen_setTextCursorY

	// Main loop
	loop$:
		b loop$

getRAMToScreen:
    push {lr}

    mov r3,r0
    lsr r3,#10

    bl screen_getWidth
    mov r1,r0
    sub r1,#4

    // 1 gig
    mov r2,#1
    lsl r2,#20

    mul r0,r3,r1
    udiv r0,r2
    add r0,#2

    pop {pc}
		
.section .data
HELLO_WORLD_TEXT: .ascii "Oak Nut OS 1.0\n\0"
ENTRY_POINT_ADDR_TEXT: .ascii "Entry Point at \0"
KERNEL_SIZE_TEXT: .ascii "Kernel size \0"
NEW_LINE_TEXT: .ascii "\n\0"
MEM_USAGE_TEXT: .ascii "Memory usage    \0"
MEM_KERNEL_TEXT: .ascii "Kernel    \0"
MEM_GPU_TEXT: .ascii "GPU    \0"
MEM_USER_TEXT: .ascii "User\n\0"
.align 2
MEM_KERNEL_COLOR: .int 0xFF24CBB4
MEM_GPU_COLOR: .int 0xFFFE5642
MEM_USER_COLOR: .int 0xFFF58754

.section .end
endMarker:
