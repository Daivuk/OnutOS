// Write to the mail box
// r0 = value
// r1 = channel
.globl mailbox_write
mailbox_write:
	// Validate
	tst r0,#0b1111
	movne pc,lr
	cmp r1,#15
	movhi pc,lr

	value .req r0
	channel .req r1
	mailbox .req r2
	status .req r3

	ldr mailbox,=0x3F00B880

	// wait for the status to be 0
	wait$:
		ldr status,[mailbox,#0x18]
		tst status,#0x80000000
		bne wait$

	add value,channel
	str value,[mailbox,#0x20]

	.unreq value
	.unreq channel
	.unreq mailbox
	.unreq status

	mov pc,lr // return

// Read from the mail box
// r0 = channel
// return r0 as read mail
.globl mailbox_read
mailbox_read:
	cmp r0,#15
	movhi pc,lr

	channel .req r0
	mailbox .req r1
	mail .req r3

	ldr mailbox,=0x3F00B880
	
	rightMail$:
		// Wait for write status to be ready
		wait2$:
			status .req r2
			ldr status,[mailbox,#0x18]
			tst status,#0x40000000
			.unreq status
			bne wait2$
		
		// Load the next message
		ldr mail,[mailbox,#0]

		// make sure we are in the right channel
		isInChannel .req r2
		and isInChannel,mail,#0b1111
		teq isInChannel,channel
		.unreq isInChannel
		bne rightMail$

	.unreq channel
	.unreq mailbox

	and r0,mail,#0xfffffff0

	.unreq mail

	mov pc,lr // return
