.section .data
MEM_USAGE_TEXT: .ascii "Memory usage    \0"
MEM_KERNEL_TEXT: .ascii "Kernel    \0"
MEM_GPU_TEXT: .ascii "GPU    \0"
MEM_USER_TEXT: .ascii "User\n\0"
.align 2
MEM_KERNEL_COLOR: .int 0xFF24CBB4
MEM_GPU_COLOR: .int 0xFFFE5642
MEM_USER_COLOR: .int 0xFFF58754

.section .text
.globl mem_drawMemUsage
mem_drawMemUsage:
    push {r4-r6,lr}

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
    add r3,#66
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

    // Reset text cursor to new line
    bl screen_getTextCursorY
    add r0,#64
    bl screen_setTextCursorY
    mov r0,#0
    bl screen_setTextCursorX

    pop {r4-r6,pc}

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
