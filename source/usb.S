#define USB_CORE_ADDR 0x3F980000
#define USB_HOST_ADDR 0x3F980400
#define USB_POWER_ADDR 0x3F980E00
#define USB_TAG_SET_POWER_STATE 0x00028001
#define USB_MAILBOX_CHANNEL 8

.section .data
.align 2
DEVICE_DESC_USB_TEXT: .asciz "USB:\n"
HCD_HARDWARE_TEXT1: .asciz "    HCD: Hardware: "
HCD_HARDWARE_TEXT2: .asciz " (BCM"
HCD_HARDWARE_TEXT3: .asciz ")\n"
POWERING_USB_ON_TEXT: .asciz "    Powering USB on "
POWERING_USB_OK: .asciz      "[Success]\n"
POWERING_USB_FAIL: .asciz    "[Failed]\n"
HCD_HARDWARE_CONFIG_TEXT: .asciz "    HCD: Hardware configuration: "
HCD_HOST_CONFIG_TEXT: .asciz "    HCD: Host configuration: "

TAB_TEXT: .asciz "\t"
ENDL_TEXT: .asciz "\n"

.align 4
usb_powerTag:
    .int 28 // Buffer size
    .int 0 // Request code
    .int USB_TAG_SET_POWER_STATE // Tag id
    .int 8 // value size
    .int 3 // Device id
    .int 3 // Value
    .int 0 // End tag

.section .text
.globl usb_init
usb_init:
    push {lr}
    
    bl usb_printDevice

    bl usb_powerOn

    pop {pc}

usb_powerOn:
    push {r4,lr}

    ldr r0,=POWERING_USB_ON_TEXT	
    ldr r2,=screen_varForeColor
	ldr r1,[r2]
    bl screen_print

    ldr r4,=usb_powerTag
    add r4,#0xC0000000
    mov r0,r4
	mov r1,#USB_MAILBOX_CHANNEL
    bl mailbox_write

    mov r0,#USB_MAILBOX_CHANNEL
    bl mailbox_read

    cmp r0,r4
    ldreq r0,=POWERING_USB_OK
    ldreq r2,=screen_okColor
    ldrne r0,=POWERING_USB_FAIL
    ldrne r2,=screen_failColor
	ldr r1,[r2]
    bl screen_print

    pop {r4,pc}

dec2hex:
    cmp r0,#9
    addhi r0,#7
    add r0,#'0'
    mov pc,lr

usb_printDevice:
    push {r4-r8,lr}

    mov r0,#32
    bl screen_setTabSize

    // Set default text color
    ldr r2,=screen_varForeColor
	ldr r1,[r2]

    // Title
    ldr r0,=DEVICE_DESC_USB_TEXT
    bl screen_print
    
    userId .req r5
    vendorId .req r6
    hostConfig .req r7

    ldr r4,=USB_CORE_ADDR
    ldr userId,[r4,#0x3c]
    ldr vendorId,[r4,#0x40]

    ldr r8,=USB_HOST_ADDR
    ldr hostConfig,[r8,#0x0]

    // USB Hardware
    ldr r0,=HCD_HARDWARE_TEXT1
    bl screen_print
    mov r0,vendorId
    lsr r0,#24
    bl screen_printChar
    mov r0,vendorId
    lsr r0,#16
    bl screen_printChar
    mov r0,vendorId
    lsr r0,#12
    and r0,#0xF
    bl dec2hex
    bl screen_printChar
    mov r0,#'.'
    bl screen_printChar
    mov r0,vendorId
    mov r2,#3
    bl screen_printHex
    ldr r0,=HCD_HARDWARE_TEXT2
    bl screen_print
    mov r0,userId
    mov r2,#5
    lsr r0,#12
    bl screen_printHex
    ldr r0,=HCD_HARDWARE_TEXT3
    bl screen_print

    ldr r0,=HCD_HARDWARE_CONFIG_TEXT
    bl screen_print
    ldr r0,[r4,#0x44]
    mov r2,#8
    bl screen_printHex
    mov r0,#' '
    bl screen_printChar
    ldr r0,[r4,#0x48]
    mov r2,#8
    bl screen_printHex
    mov r0,#' '
    bl screen_printChar
    ldr r0,[r4,#0x4C]
    mov r2,#8
    bl screen_printHex
    mov r0,#' '
    bl screen_printChar
    ldr r0,[r4,#0x50]
    mov r2,#8
    bl screen_printHex
    ldr r0,=ENDL_TEXT
    bl screen_print

    ldr r0,=HCD_HOST_CONFIG_TEXT
    bl screen_print
    mov r0,hostConfig
    mov r2,#8
    bl screen_printHex
    ldr r0,=ENDL_TEXT
    bl screen_print

    mov r0,#4
    bl screen_setTabSize

    .unreq vendorId
    .unreq userId
    .unreq hostConfig

    pop {r4-r8,pc}
