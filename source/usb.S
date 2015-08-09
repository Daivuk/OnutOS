#define USB_CORE_ADDR 0x3F980000
#define USB_HOST_ADDR 0x3F980400
#define USB_POWER_ADDR 0x3F980E00

#define Ulpi 2
#define Dedicated 1

.section .data
.align 2
DEVICE_DESC_USB_TEXT: .asciz "USB:"
HCD_HARDWARE_TEXT1: .asciz "\tHCD: Hardware: "
HCD_HARDWARE_TEXT2: .asciz " (BCM"
HCD_HARDWARE_TEXT3: .asciz ")"
POWERING_USB_ON_TEXT: .asciz "\tPowering USB on "
POWERING_USB_OK: .asciz      "[Success]"
POWERING_USB_FAIL: .asciz    "[Failed]"
HCD_HARDWARE_CONFIG_TEXT: .asciz "\tHCD: Hardware configuration: "
HCD_HOST_CONFIG_TEXT: .asciz "\tHCD: Host configuration: "
HCD_DISABLING_IRQS_TEXT: .asciz "\tHCD: Disabling interrupts."
HCD_LOAD_COMPLETE_TEXT: .asciz "\tHCD: Load completed."

.section .text
.globl usb_init
usb_init:
    push {lr}
    
    bl usb_initHCD
    bl usb_powerOn

    ldr r0,=HCD_LOAD_COMPLETE_TEXT
    ldr r2,=screen_varForeColor
	ldr r1,[r2]
    bl screen_println

    bl usb_hcdStart

    pop {pc}

usb_powerOn:
    push {r4,lr}

    ldr r0,=POWERING_USB_ON_TEXT	
    ldr r2,=screen_varForeColor
	ldr r1,[r2]
    bl screen_print

    mov r0,#0x80
    mov r1,#0
    bl mailbox_write

    mov r0,#0
    bl mailbox_read

    cmp r0,#0x80
    ldreq r0,=POWERING_USB_OK
    ldreq r2,=screen_okColor
    ldrne r0,=POWERING_USB_FAIL
    ldrne r2,=screen_failColor
	ldr r1,[r2]
    bl screen_println

    pop {r4,pc}

dec2hex:
    cmp r0,#9
    addhi r0,#7
    add r0,#'0'
    mov pc,lr

usb_initHCD:
    push {r4-r8,lr}

    // Set default text color
    ldr r2,=screen_varForeColor
	ldr r1,[r2]

    // Title
    ldr r0,=DEVICE_DESC_USB_TEXT
    bl screen_println
    
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
    bl screen_println

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
    bl screen_printHexln

    ldr r0,=HCD_HOST_CONFIG_TEXT
    bl screen_print
    mov r0,hostConfig
    mov r2,#8
    bl screen_printHexln

    ldr r0,=HCD_DISABLING_IRQS_TEXT
    bl screen_println
    mov r0,#0
    str r0,[r4,#0x18]
    ldr r0,[r4,#0x8]
    and r0,#0xFFFFFFFE
    str r0,[r4,#0x8]

    .unreq vendorId
    .unreq userId
    .unreq hostConfig

    pop {r4-r8,pc}

.section .data
HCD_START_CORE_TEXT: .asciz "\tHCD: Start core."
HCD_MASTER_RESET_TEXT: .asciz "\tHCD: Master reset."
HCD_ONE_TIME_PHY_INIT_TEXT: .asciz "\tHCD: One time phy initialisation."
HCD_ULPI_FLLS_CONFIG_ENABLED_TEXT: .asciz "\tHCD: ULPI FSLS configuration: enabled."
HCD_ULPI_FLLS_CONFIG_DISABLED_TEXT: .asciz "\tHCD: ULPI FSLS configuration: disabled."
HCD_DMA_CONFIG_ENABLED_TEXT: .asciz "\tHCD: DMA configuration: enabled."

.section .text
usb_hcdReset:
    push {r4,lr}

    ldr r0,=HCD_MASTER_RESET_TEXT
    bl screen_println

    ldr r4,=USB_CORE_ADDR

    hcdResetLoop1$:
        ldr r0,[r4,#0x10] // Reset
        and r0,#0x80000000
        cmp r0,#0 // AhbMasterIdle == false
        beq hcdResetLoop1$

    ldr r0,[r4,#0x10] // Reset
    orr r0,#0x1 // CoreSoft = true
    str r0,[r4,#0x10]

    hcdResetLoop2$:
        ldr r0,[r4,#0x10] // Reset
        and r0,#0x80000000
        cmp r0,#0 // AhbMasterIdle == false
        beq hcdResetLoop2$

        ldr r0,[r4,#0x10] // Reset
        and r0,#0x1
        cmp r0,#1 // CoreSoft == true
        beq hcdResetLoop2$

    pop {r4,pc}

usb_phyInit:
    push {r4,lr}

    ldr r0,=HCD_ONE_TIME_PHY_INIT_TEXT
    bl screen_println

    ldr r4,=USB_CORE_ADDR

    ldr r0,[r4,#0xC] // usb struct
    orr r0,#0b10000 // ModeSelect = UTMI
    and r0,#0xFFFFFFF7 // PhyInterface = false
    str r0,[r4,#0xC]

    bl usb_hcdReset

    pop {r4,pc}

usb_toggleULPIFSLSConfig:
    push {r4-r6,lr}
    coreAddr .req r4
    usb .req r5
    hardware2 .req r6

    ldr coreAddr,=USB_CORE_ADDR
    ldr usb,[coreAddr,#0xC]
    ldr hardware2,[coreAddr,#0x48]

    // Hardware.HighSpeedPhysical == Ulpi
    mov r0,hardware2
    lsr r0,#6
    and r0,#0b11
    cmp r0,#Ulpi
    bne ULPIFSLSConfigDisabled$

    // && Hardware.FullSpeedPhysical == Dedicated
    mov r0,hardware2
    lsr r0,#8
    and r0,#0b11
    cmp r0,#Dedicated
    bne ULPIFSLSConfigDisabled$

    // Enabled
    ldr r0,=HCD_ULPI_FLLS_CONFIG_ENABLED_TEXT
    bl screen_println
    orr usb,#0xA0000
    b usb_toggleULPIFSLSConfigDone$

    ULPIFSLSConfigDisabled$:
        ldr r0,=HCD_ULPI_FLLS_CONFIG_DISABLED_TEXT
        bl screen_println
        and usb,#0xFFF5FFFF

    usb_toggleULPIFSLSConfigDone$:
        str usb,[coreAddr,#0xC]
        .unreq coreAddr
        .unreq usb
        .unreq hardware2
        pop {r4-r6,pc}

usb_startCore:
    push {r4,lr}

    ldr r0,=HCD_START_CORE_TEXT
    bl screen_println

    ldr r4,=USB_CORE_ADDR
    ldr r0,[r4,#0xC] // usb struct
    and r0,#0xFFAFFFFF // Turn bit 20 and 22 off
                       // UlpiDriveExternalVbus 
                       // TsDlinePulseEnable 
    str r0,[r4,#0xC]

    pop {r4,pc}

usb_enableDMAConfig:
    push {r4-r5,lr}
    Ahb .req r5
    
    ldr r0,=HCD_DMA_CONFIG_ENABLED_TEXT
    bl screen_println

    ldr Ahb,[r4,#0x8] // Ahb struct
    orr Ahb,#0b100000 // DmaEnable = true
    and Ahb,#0xFF7FFFFF // DmaRemainderMode = Incremental
    str Ahb,[r4,#0x8] // Ahb struct

    .unreq Ahb
    pop {r4-r5,pc}

usb_hcdStart:
    push {r4,lr}
    
    // Set default text color
    ldr r2,=screen_varForeColor
	ldr r1,[r2]

    bl usb_startCore
    bl usb_hcdReset
    bl usb_phyInit
    bl usb_toggleULPIFSLSConfig
    bl usb_enableDMAConfig

    pop {r4,pc}
