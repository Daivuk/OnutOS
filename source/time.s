.globl time_getTime
time_getTime:
	ldr r0,=0x3F003000
	ldrd r0,r1,[r0,#4]
	mov pc,lr

.globl time_wait
time_wait:
	delay .req r2
	mov delay,r0
	push {lr}
	
	bl time_getTime
	startTime .req r3
	mov startTime,r0

	loop$:
		bl time_getTime
		elapsed .req r1
		sub elapsed,r0,startTime
		cmp elapsed,delay
		.unreq elapsed
		bls loop$

	.unreq delay
	.unreq startTime

	pop {pc}
