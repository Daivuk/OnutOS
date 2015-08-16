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

#if !defined(EMULATOR_MODE)
	// Clear screen with background color
	ldr r1,=screen_varBackColor
	ldr r0,[r1]
	bl screen_clear

	// Draw OS + version
	ldr r0,=HELLO_WORLD_TEXT
	ldr r2,=screen_varForeColor
	ldr r1,[r2]
	bl screen_println

    // Draw entry point address
    ldr r0,=ENTRY_POINT_ADDR_TEXT
    bl screen_print
    ldr r0,=main
    bl screen_printAddrln
    ldr r0,=KERNEL_SIZE_TEXT
    bl screen_print
    ldr r0,=endMarker
    bl screen_printU32ln

	// Print some screen info
	bl screen_printInfo
	
    // Print memory info
    bl mem_drawMemUsage

    // Initialize USB devices
    bl usb_init
#endif

	// Initialize the UI engine
	bl ui_init

	// Main loop
	loop$:
		b loop$
		
.section .data
HELLO_WORLD_TEXT: .asciz "Oak Nut OS 1.0"
ENTRY_POINT_ADDR_TEXT: .asciz "Entry Point at "
KERNEL_SIZE_TEXT: .asciz "Kernel size "

.section .end
.globl endMarker
endMarker:
