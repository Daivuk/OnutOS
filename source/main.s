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
	ldr r0,=strHelloWorld
	ldr r2,=screen_varForeColor
	ldr r1,[r2]
	bl screen_print

	// Print some screen info
	bl screen_printInfo

	// Main loop
	loop$:
		b loop$
		
.align 2
.globl strHelloWorld
strHelloWorld: .ascii "Oak Nut OS 1.0\n\0"
