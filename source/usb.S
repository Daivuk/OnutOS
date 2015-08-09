#define USB_CORE_ADDR 0x3F980000
#define USB_HOST_ADDR 0x3F980400
#define USB_POWER_ADDR 0x3F980E00

#define ReceiveFifoSize 20480 /* 16 to 32768 */
#define NonPeriodicFifoSize 20480 /* 16 to 32768 */
#define PeriodicFifoSize 20480 /* 16 to 32768 */

#define Ulpi 2
#define Dedicated 1
#define HNP_SRP_CAPABLE 0
#define SRP_ONLY_CAPABLE 1
#define NO_HNP_SRP_CAPABLE 2
#define SRP_CAPABLE_DEVICE 3
#define NO_SRP_CAPABLE_DEVICE 4
#define SRP_CAPABLE_HOST 5
#define NO_SRP_CAPABLE_HOST 6

#define Clock30_60MHz 0
#define Clock48MHz 1
#define Clock6MHz 2

#define FlushNonPeriodic 0
#define FlushPeriodic1 1
#define FlushPeriodic2 2
#define FlushPeriodic3 3
#define FlushPeriodic4 4
#define FlushPeriodic5 5
#define FlushPeriodic6 6
#define FlushPeriodic7 7
#define FlushPeriodic8 8
#define FlushPeriodic9 9
#define FlushPeriodic10 10
#define FlushPeriodic11 11
#define FlushPeriodic12 12
#define FlushPeriodic13 13
#define FlushPeriodic14 14
#define FlushPeriodic15 15
#define FlushAll 16

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
    bl usb_startHost

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
HCD_HNP_SRP_CONFIG_TEXT: .asciz "\tHCD: HNP/SRP configuration: HNP, SRP."
HCD_SRP_CONFIG_TEXT: .asciz "\tHCD: HNP/SRP configuration: SRP."
HCD_HNP_SRP_CONFIG_NONE_TEXT: .asciz "\tHCD: HNP/SRP configuration: none."
HCD_INTERFACE_UTMI_PLUS_TEXT: .asciz "\tHCD: Interface: UTMI+."
HCD_CORE_STARTED: .asciz "\tHCD: Core started."

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
    ldr r0,=HCD_INTERFACE_UTMI_PLUS_TEXT
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

usb_setupHNPSRPConfig:
    push {r4-r6,lr}
    coreAddr .req r4
    usb .req r5
    OperatingMode .req r6

    ldr coreAddr,=USB_CORE_ADDR
    ldr usb,[coreAddr,#0xC] // usb struct
    ldr OperatingMode,[coreAddr,#0x48]
    and OperatingMode,#0b111

    cmp OperatingMode,#HNP_SRP_CAPABLE
    beq setHNP_SRP$
    cmp OperatingMode,#SRP_ONLY_CAPABLE
    beq setSRP$
    cmp OperatingMode,#SRP_CAPABLE_DEVICE
    beq setSRP$
    cmp OperatingMode,#SRP_CAPABLE_HOST
    beq setSRP$

    // None
    ldr r0,=HCD_HNP_SRP_CONFIG_NONE_TEXT
    bl screen_println
    and usb,#0xFFFFFCFF
    b usb_setupHNPSRPConfigDone$

    setHNP_SRP$:
        ldr r0,=HCD_HNP_SRP_CONFIG_TEXT
        bl screen_println
        orr usb,#0x300
        b usb_setupHNPSRPConfigDone$

    setSRP$:
        ldr r0,=HCD_SRP_CONFIG_TEXT
        bl screen_println
        orr usb,#0x100
        and usb,#0xFFFFFDFF
        b usb_setupHNPSRPConfigDone$

    usb_setupHNPSRPConfigDone$:
        str usb,[coreAddr,#0xC]
        .unreq coreAddr
        .unreq usb
        .unreq OperatingMode
        pop {r4-r6,pc}

usb_hcdStart:
    push {lr}
    
    // Set default text color
    ldr r2,=screen_varForeColor
	ldr r1,[r2]

    bl usb_startCore
    bl usb_hcdReset
    bl usb_phyInit
    bl usb_toggleULPIFSLSConfig
    bl usb_enableDMAConfig
    bl usb_setupHNPSRPConfig

    ldr r0,=HCD_CORE_STARTED
    bl screen_println

    pop {pc}

.section .data
HCD_STARTING_HOST_TEXT: .asciz "\tHCD: Starting host."
HCD_HOST_CLOCK_48_TEXT: .asciz "\tHCD: Host clock: 48Mhz."
HCD_HOST_CLOCK_30_60_TEXT: .asciz "\tHCD: Host clock: 30-60Mhz."
HCD_DMA_DESC_ENABLED_TEXT: .asciz "\tHCD: DMA descriptor: enabled."
HCD_DMA_DESC_DISABLED_TEXT: .asciz "\tHCD: DMA descriptor: disabled."

.section .text
usb_clearPower:
    ldr r0,=USB_POWER_ADDR
    mov r2,#0
    str r2,[r0]
    mov pc,lr

usb_setClockRate:
    push {r4-r10,lr}
    coreAddr .req r4
    hardware2 .req r5
    usb .req r6
    HighSpeedPhysical .req r7
    FullSpeedPhysical .req r8
    UlpiFsls .req r9
    HostConfig .req r10

    ldr coreAddr,=USB_CORE_ADDR
    ldr usb,[coreAddr,#0xC]
    ldr hardware2,[coreAddr,#0x48]
    ldr HostConfig,[coreAddr,#0x400]
    mov HighSpeedPhysical,hardware2
    lsr HighSpeedPhysical,#6
    and HighSpeedPhysical,#0b11
    mov FullSpeedPhysical,hardware2
    lsr FullSpeedPhysical,#8
    and FullSpeedPhysical,#0b11
    mov UlpiFsls,usb
    lsr FullSpeedPhysical,#17
    and UlpiFsls,#0b1

    and HostConfig,#0xFFFFFFFC

    cmp HighSpeedPhysical,#Ulpi
    bne clock30_60$
    cmp FullSpeedPhysical,#Dedicated
    bne clock30_60$
    cmp UlpiFsls,#1
    bne clock30_60$

    ldr r0,=HCD_HOST_CLOCK_48_TEXT
    bl screen_println
    orr HostConfig,#Clock48MHz
    b usb_setClockRateDone$

    clock30_60$:
        ldr r0,=HCD_HOST_CLOCK_30_60_TEXT
        bl screen_println
        orr HostConfig,#Clock30_60MHz

    usb_setClockRateDone$:
        str HostConfig,[coreAddr,#0x400]
        .unreq coreAddr
        .unreq hardware2
        .unreq usb
        .unreq HighSpeedPhysical
        .unreq FullSpeedPhysical
        .unreq UlpiFsls
        .unreq HostConfig
        pop {r4-r10,pc}

usb_setFslsOnly:
    ldr r0,=USB_CORE_ADDR
    ldr r2,[r0,#0x400]
    orr r2,#0b100
    str r2,[r0,#0x400]
    mov pc,lr

usb_dmaDescriptorState:
    push {lr}

    ldr r0,=USB_CORE_ADDR

    // Host.Config.EnableDmaDescriptor
    ldr r2,[r0,#0x400]
    lsr r2,#23
    and r2,#0b1

    // Core.Hardware.DmaDescription
    ldr r3,[r0,#0x50]
    lsr r3,#30
    and r3,#0b1

    cmp r2,r3
    bne dmaDescDisabled$

    // Vendor ID
    ldr r2,[r0,#0x40]
    mov r3,#0xFF0
    orr r3,#0xF
    and r2,r3
    mov r0,#0x900
    orr r0,#0xA
    cmp r2,r0
    blo dmaDescDisabled$

    ldr r0,=HCD_DMA_DESC_ENABLED_TEXT
    bl screen_println
    pop {pc}

    dmaDescDisabled$:
        ldr r0,=HCD_DMA_DESC_DISABLED_TEXT
        bl screen_println
        pop {pc}

.section .data
HCD_FIFO_CONFIG_TEXT1: .asciz "\tHCD: FIFO configuration: Total="
HCD_FIFO_CONFIG_TEXT2: .asciz " Rx="
HCD_FIFO_CONFIG_TEXT3: .asciz " NPTx="
HCD_FIFO_CONFIG_TEXT4: .asciz " PTx="
HCD_FIFO_CONFIG_TEXT5: .asciz "."

.section .text
usb_printFifo:
    push {lr}

    ldr r0,=HCD_FIFO_CONFIG_TEXT1
    bl screen_print
    mov r0,#ReceiveFifoSize
    add r0,#NonPeriodicFifoSize
    add r0,#PeriodicFifoSize
    bl screen_printAddr
    ldr r0,=HCD_FIFO_CONFIG_TEXT2
    bl screen_print
    add r0,#ReceiveFifoSize
    bl screen_printAddr
    ldr r0,=HCD_FIFO_CONFIG_TEXT3
    bl screen_print
    add r0,#NonPeriodicFifoSize
    bl screen_printAddr
    ldr r0,=HCD_FIFO_CONFIG_TEXT4
    bl screen_print
    add r0,#PeriodicFifoSize
    bl screen_printAddr
    ldr r0,=HCD_FIFO_CONFIG_TEXT5
    bl screen_println

    pop {pc}

usb_setupFifo:
    push {r4,lr}

    bl usb_printFifo

    ldr r4,=USB_CORE_ADDR

    mov r0,#ReceiveFifoSize
    str r0,[r4,#0x24] // Core.Receive.Size

    mov r0,#NonPeriodicFifoSize
    lsl r0,#16
    orr r0,#ReceiveFifoSize
    str r0,[r4,#0x28] // Core.NonPeriodicFifo.Size

    mov r0,#PeriodicFifoSize
    lsl r0,#16
    orr r0,#ReceiveFifoSize
    add r0,#NonPeriodicFifoSize
    str r0,[r4,#0x100] // Core.NonPeriodicFifo.Size

    pop {r4,pc}

.section .data
HCD_SET_HNP_ENABLED_TEXT: .asciz "\tHCD: Set HNP: enabled."

.section .text
usb_enableHNP:
    push {r4,lr}

    ldr r0,=HCD_SET_HNP_ENABLED_TEXT
    bl screen_println

    ldr r4,=USB_CORE_ADDR
    ldr r0,[r4,#0x0]
    orr r0,#0x400
    str r0,[r4,#0x0]

    pop {r4,pc}

.section .data
HCD_TXFLUSH_ALL_TEXT: .asciz "\tHCD: TXFlush(All)"
HCD_TXFLUSH_NP_TEXT: .asciz "\tHCD: TXFlush(NP)"
HCD_TXFLUSH_P_TEXT1: .asciz "\tHCD: TXFlush(P"
HCD_TXFLUSH_P_TEXT2: .asciz ")"

.section .text
usb_transmitFifoFlush:
    push {r4-r5,lr}

    mov r4,r0

    cmp r4,#FlushAll
    beq transmitFifoFlushAll$
    cmp r4,#FlushNonPeriodic
    beq transmitFifoFlushNonPeriodic$

    ldr r0,=HCD_TXFLUSH_P_TEXT1
    bl screen_print
    mov r0,r4
    bl screen_printU32
    ldr r0,=HCD_TXFLUSH_P_TEXT2
    bl screen_println
    b transmitFifoFlushLogDone$

    transmitFifoFlushAll$:
        ldr r0,=HCD_TXFLUSH_ALL_TEXT
        bl screen_println
        b transmitFifoFlushLogDone$

    transmitFifoFlushNonPeriodic$:
        ldr r0,=HCD_TXFLUSH_NP_TEXT
        bl screen_println
        b transmitFifoFlushLogDone$

    transmitFifoFlushLogDone$:
        ldr r5,=USB_CORE_ADDR
        mov r0,r4
        lsl r0,#6
        orr r0,#0b100000
        str r0,[r5,#0x10]

        comfirmTransmitLoop$:
            ldr r0,[r5,#0x10]
            and r0,#0b100000
            cmp r0,#1
            beq comfirmTransmitLoop$

        pop {r4-r5,pc}

usb_startHost:
    push {lr}
    
    // Set default text color
    ldr r2,=screen_varForeColor
	ldr r1,[r2]

    ldr r0,=HCD_STARTING_HOST_TEXT
    bl screen_println

    bl usb_clearPower
    bl usb_setClockRate
    bl usb_setFslsOnly
    bl usb_dmaDescriptorState
    bl usb_setupFifo
    bl usb_enableHNP
    mov r0,#FlushAll
    bl usb_transmitFifoFlush

    pop {pc}
