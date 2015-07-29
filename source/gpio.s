.globl gpio_init
gpio_init:
	ldr r0,=0x3F200010
	mov r1,#7
	lsl r1,#21
	mvn r2,r1
	and r3,r2,r0
	mov r1,#1
	lsl r1,#21
	orr r1,r3
	str r1,[r0,#0]
	mov pc,lr

.globl gpio_turnLEDOn
gpio_turnLEDOn:
	mov r1,#1
	lsl r1,#15
	ldr r0,=0x3F200020
	str r1,[r0,#0]
	mov pc,lr
	
.globl gpio_turnLEDOff
gpio_turnLEDOff:
	mov r1,#1
	lsl r1,#15
	ldr r0,=0x3F20002C
	str r1,[r0,#0]
	mov pc,lr
