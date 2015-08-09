.section .data
MEM_USAGE_TEXT: .asciz "Memory usage    "
MEM_KERNEL_TEXT: .asciz "Kernel    "
MEM_GPU_TEXT: .asciz "GPU    "
MEM_USER_TEXT: .asciz "User"
.align 2
MEM_KERNEL_COLOR: .int 0xFF24CBB4
MEM_GPU_COLOR: .int 0xFFFE5642
MEM_USER_COLOR: .int 0xFFF58754

.section .text
.globl mem_drawMemUsage
mem_drawMemUsage:
    push {r4-r8,lr}

    x1 .req r5
    y1 .req r6
    x2 .req r7
    y2 .req r8

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
    bl screen_println

    ldr r0,=MEM_KERNEL_COLOR
    ldr r4,[r0]
    mov r0,#0                   // x1
    bl getRAMToScreen
    mov x1,r0
    ldr r0,=endMarker           // x2
    bl getRAMToScreen
    mov x2,r0
    bl screen_getTextCursorY    // y1
    mov y1,r0
    add y2,y1,#62               // y2
    mov r0,x1
    mov r1,y1
    mov r2,x2
    mov r3,y2
    bl screen_drawRect

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
    bl screen_getTextCursorY    // y1
    mov y1,r0
    add y2,y1,#62               // y2
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

    pop {r4-r8,pc}

getRAMToScreen:
    push {lr}

    mov r3,r0
    lsr r3,#10

    bl screen_getWidth
    sub r1,r0,#4

    // 1 gig
    mov r2,#1
    lsl r2,#20

    mul r0,r3,r1
    udiv r0,r2
    add r0,#2

    pop {pc}
