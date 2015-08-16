#define USB_CORE_ADDR 0x3F980000
#define USB_HOST_ADDR 0x3F980400
#define USB_POWER_ADDR 0x3F980E00

#define ReceiveFifoSize 1024 /* 16 to 32768 */
#define NonPeriodicFifoSize 1024 /* 16 to 32768 */
#define PeriodicFifoSize 1024 /* 16 to 32768 */

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

#define HostToDevice 0
#define Out 0
#define DeviceToHost 1
#define In 1

.section .data
.align 2
UsbDevices: .space 0x5B090
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
    bl usb_attachRootHub

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

.section .data
HCD_RX_FLUSH_ALL_TEXT: .asciz "\tHCD: RXFlush(All)"
.section .text
usb_receiveFifoFlush:
    push {r4,lr}

    ldr r0,=HCD_RX_FLUSH_ALL_TEXT
    bl screen_println

    ldr r4,=USB_CORE_ADDR

    mov r0,#0b1000
    str r0,[r4,#0x10]

    recvFifoFlushLoop$:
        ldr r0,[r4,#0x10]
        and r0,#0b1000
        cmp r0,#0
        bne recvFifoFlushLoop$

    pop {r4,pc}

.section .data
HCD_UNABLE_TO_CLEAR_HALT_TEXT: .asciz "\tHCD: Unable to clear halt on channel "
.section .text
usb_clearChannels:
    push {r4-r8,lr}
    coreAddr .req r4
    EnableDmaDescriptor .req r5
    HostChannelCount .req r6
    i .req r7
    channels .req r8

    ldr coreAddr,=USB_CORE_ADDR
    ldr EnableDmaDescriptor,[coreAddr,#0x400]
    lsr EnableDmaDescriptor,#23
    and EnableDmaDescriptor,#0b1

    cmp EnableDmaDescriptor,#0b1
    beq usb_clearChannelsDone$

    ldr HostChannelCount,[coreAddr,#0x48]
    lsr HostChannelCount,#14
    and HostChannelCount,#0b1111

    add channels,coreAddr,#0x500
    mov i,HostChannelCount
    usb_clearChannelsLoop1$:        
        ldr r0,[channels]
        orr r0,#0x40000000 // Disable = true
        and r0,#0x7FFFFFFF // Enable = false
        orr r0,#0x8000 // EndPointDirection = In
        str r0,[channels]
        add channels,#0x20
        subs i,#1
        bne usb_clearChannelsLoop1$

    add channels,coreAddr,#0x500
    mov i,HostChannelCount
    usb_clearChannelsLoop2$:
        ldr r0,[channels]
        orr r0,#0xC0000000 // Enable = true, Disable = true
        orr r0,#0x8000 // EndPointDirection = In
        str r0,[channels]
        mov r2,#0x10000
        loopUntilNotEnabled$:
            subs r2,#1
            beq errorToClear$
            b continueToClearCheck$
            errorToClear$:
                ldr r0,=HCD_UNABLE_TO_CLEAR_HALT_TEXT
                bl screen_print
                sub r0,HostChannelCount,i
                bl screen_printU32ln
                b breakLoopUnable$
            continueToClearCheck$:
                ldr r0,[channels]
                and r0,#0x80000000
                cmp r0,#0x80000000
                beq loopUntilNotEnabled$
        breakLoopUnable$:
            add channels,#0x20
            subs i,#1
            bne usb_clearChannelsLoop2$

    usb_clearChannelsDone$:
        .unreq coreAddr
        .unreq EnableDmaDescriptor
        .unreq HostChannelCount
        .unreq i
        .unreq channels
        pop {r4-r8,pc}

.section .data
HCD_POWERING_UP_PORT: .asciz "\tHCD: Powering up port."
.section .text
usb_powerUpPort:
    push {r4,lr}

    ldr r4,=USB_CORE_ADDR
    ldr r0,[r4,#0x440] // Host.Port
    and r0,#0x1000 // Power bit
    cmp r0,#0
    popne {r4,pc}

    ldr r0,=HCD_POWERING_UP_PORT
    bl screen_println

    ldr r0,[r4,#0x440] // Host.Port
    orr r2,r0,#0x1000 // Power bit
    mov r0,#0x1F000
    orr r0,#0x140
    and r2,r0
    str r2,[r4,#0x440]

    pop {r4,pc}

.section .data
HCD_RESET_PORT_TEXT: .asciz "\tHCD: Reset port."
.section .text
usb_resetPort:
    push {r4,lr}

    ldr r0,=HCD_RESET_PORT_TEXT
    bl screen_println

    ldr r4,=USB_CORE_ADDR

    ldr r0,[r4,#0x440] // Host.Port
    orr r2,r0,#0x100 // Reset = true
    mov r0,#0x1F000
    orr r0,#0x140
    and r2,r0
    str r2,[r4,#0x440]
    mov r4,r2

    mov r0,#50176
    bl time_wait

    mov r0,r4
    and r2,r0,#0xFFFFFEFF // Reset = false
    mov r0,#0x1F000
    orr r0,#0x140
    and r2,r0
    str r2,[r4,#0x440]

    pop {r4,pc}

.section .data
HCD_SUCCESS_TEXT: .asciz "\tHCD: Successfully started."
.section .text
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
    bl usb_receiveFifoFlush
    bl usb_clearChannels
    bl usb_powerUpPort
    bl usb_resetPort

    ldr r0,=HCD_SUCCESS_TEXT
    ldr r2,=screen_okColor
    ldr r1,[r2]
    bl screen_println

    pop {pc}

#define MaxChildrenPerDevice 10
#define MaxInterfacesPerDevice 8
#define MaxEndpointsPerDevice 16

#define UsbDevice_Number 0x0 // 4
#define UsbDevice_Speed 0x4 // 4
    #define High    0
    #define Full    1
    #define Low     2
#define UsbDevice_Status 0x8 // 4
    #define Attached    0
    #define Powered     1
    #define Default     2
    #define Addressed   3
    #define Configured  4
#define UsbDevice_ConfigurationIndex 0xc // 1
#define UsbDevice_PortNumber 0x10 // 1
#define UsbDevice_Error 0x14 // 4
    #define NoError         0b0
    #define Stall           0b10
    #define BufferError     0b100
    #define Bable           0b1000
    #define NoAcknowledge   0b10000
    #define CrcError        0b100000
    #define BitError        0b1000000
    #define AhbError        0b10000000
    #define NotYetError     0b100000000
    #define Processing      0x80000000
// Generic device handlers
// Handler for detaching the device. The device driver should not issue further requests to the device.
#define UsbDevice_DeviceDetached 0x18 // 4
// Handler for deallocation of the device. All memory in use by the device driver should be deallocated.
#define UsbDevice_DeviceDeallocate 0x1c // 4
// Handler for checking for changes to the USB device tree. Only hubs need handle with this.
#define UsbDevice_DeviceCheckForChange 0x20 // 4
// Handler for removing a child device from this device. Only hubs need handle with this.
#define UsbDevice_DeviceChildDetached 0x24 // 4
// Handler for reseting a child device of this device. Only hubs need handle with this.
#define UsbDevice_DeviceChildReset 0x28 // 4
// Handler for reseting a child device of this device. Only hubs need handle with this.
#define UsbDevice_DeviceCheckConnection 0x2c // 4
#define UsbDevice_Descriptor 0x30
    #define UsbDevice_Descriptor_DescriptorLength 0x30 // 1
    #define UsbDevice_Descriptor_DescriptorType 0x31 // 1
        #define Device                  1
        #define Configuration           2
        #define String                  3
        #define Interface               4
        #define Endpoint                5
        #define DeviceQualifier         6
        #define OtherSpeedConfiguration 7
        #define InterfacePower          8
        #define Hid                     33
        #define HidReport               34
        #define HidPhysical             35
        #define Hub                     41
    #define UsbDevice_Descriptor_UsbVersion 0x32 // 2
    #define UsbDevice_Descriptor_Class 0x34 // 1
        #define DeviceClassInInterface      0x00
        #define DeviceClassCommunications   0x2
        #define DeviceClassHub              0x9
        #define DeviceClassDiagnostic       0xDC
        #define DeviceClassMiscellaneous    0xEF
        #define DeviceClassVendorSpecific   0xFF
    #define UsbDevice_Descriptor_SubClass 0x35 // 1
    #define UsbDevice_Descriptor_Protocol 0x36 // 1
    #define UsbDevice_Descriptor_MaxPacketSize0 0x37 // 1
    #define UsbDevice_Descriptor_VendorId 0x38 // 2
    #define UsbDevice_Descriptor_ProductId 0x3A // 2
    #define UsbDevice_Descriptor_Version 0x3C // 2
    #define UsbDevice_Descriptor_Manufacturer 0x3E // 1
    #define UsbDevice_Descriptor_Product 0x3F // 1
    #define UsbDevice_Descriptor_SerialNumber 0x40 // 1
    #define UsbDevice_Descriptor_ConfigurationCount 0x41 // 1
#define UsbDevice_Configuration 0x50
    #define UsbDevice_Configuration_DescriptorLength 0x50 // 1
    #define UsbDevice_Configuration_DescriptorType 0x51 // 1
    #define UsbDevice_Configuration_TotalLength 0x52 // 2
    #define UsbDevice_Configuration_InterfaceCount 0x54 // 1
    #define UsbDevice_Configuration_ConfigurationValue 0x55 // 1
    #define UsbDevice_Configuration_StringIndex 0x56 // 1
    #define UsbDevice_Configuration_Attributes 0x57 // 1
        #define UsbDevice_Configuration_Attributes_RemoteWakeupMask 0b100000
        #define UsbDevice_Configuration_Attributes_SelfPoweredMask 0b1000000
    #define UsbDevice_Configuration_MaximumPower 0x58 // 1
#define UsbDevice_Interfaces 0x60
#define UsbDevice_Endpoints 0xE0
#define UsbDevice_Parent 0x4E0 // 4
#define UsbDevice_FullConfiguration 0x4E4 // 4
#define UsbDevice_DriverData 0x4E8 // 4
#define UsbDevice_LastTransfer 0x4EC // 4
#define sizeof_UsbDevice 0x4F0

#define UsbInterfaceDescriptor_DescriptorLength 0x0 // 1
#define UsbInterfaceDescriptor_DescriptorType 0x1 // 81
#define UsbInterfaceDescriptor_Number 0x2 // 1
#define UsbInterfaceDescriptor_AlternateSetting 0x3 // 1
#define UsbInterfaceDescriptor_EndpointCount 0x4 // 1
#define UsbInterfaceDescriptor_Class 0x5 // 1
    #define InterfaceClassReserved              0x0
    #define InterfaceClassAudio                 0x1
    #define InterfaceClassCommunications        0x2
    #define InterfaceClassHid                   0x3
    #define InterfaceClassPhysical              0x5
    #define InterfaceClassImage                 0x6
    #define InterfaceClassPrinter               0x7
    #define InterfaceClassMassStorage           0x8
    #define InterfaceClassHub                   0x9
    #define InterfaceClassCdcData               0xa
    #define InterfaceClassSmartCard             0xb
    #define InterfaceClassContentSecurity       0xd
    #define InterfaceClassVideo                 0xe
    #define InterfaceClassPersonalHealthcare    0xf
    #define InterfaceClassAudioVideo            0x10
    #define InterfaceClassDiagnosticDevice      0xdc
    #define InterfaceClassWirelessController    0xe0
    #define InterfaceClassMiscellaneous         0xef
    #define InterfaceClassApplicationSpecific   0xfe
    #define InterfaceClassVendorSpecific        0xff
#define UsbInterfaceDescriptor_SubClass 0x6 // 1
#define UsbInterfaceDescriptor_Protocol 0x7 // 1
#define UsbInterfaceDescriptor_StringIndex 0x8 // 1

#define UsbEndpointDescriptor_DescriptorLength 0x0 // 1
#define UsbEndpointDescriptor_DescriptorType 0x1 // 1
#define UsbEndpointDescriptor_EndpointAddress 0x2 // 1
    #define UsbEndpointDescriptor_EndpointAddress_NumberMask 0b1111
    #define UsbEndpointDescriptor_EndpointAddress_DirectionMask 0b10000000
#define UsbEndpointDescriptor_Attributes 0x3
    #define UsbEndpointDescriptor_Attributes_TypeMask 0b11
    #define UsbEndpointDescriptor_Attributes_SynchronisationMask 0b1100
        #define UsbEndpointDescriptor_Attributes_Synchronisation_NoSynchronisation 0
        #define UsbEndpointDescriptor_Attributes_Synchronisation_Asynchronous   0b0100
        #define UsbEndpointDescriptor_Attributes_Synchronisation_Adaptive       0b1000
        #define UsbEndpointDescriptor_Attributes_Synchronisation_Synchrouns     0b1100
    #define UsbEndpointDescriptor_Attributes_UsageMask 0b110000
        #define UsbEndpointDescriptor_Attributes_Usage_Data                 0
        #define UsbEndpointDescriptor_Attributes_Usage_Feeback              0b010000
        #define UsbEndpointDescriptor_Attributes_Usage_ImplicitFeebackData  0b100000
#define UsbEndpointDescriptor_Packet 0x4 // 2
    #define UsbEndpointDescriptor_Packet_MaxSizeMask 0b11111111111
    #define UsbEndpointDescriptor_Packet_TransactionsMask 0b1100000000000
        #define UsbEndpointDescriptor_Packet_Transactions_None      0
        #define UsbEndpointDescriptor_Packet_Transactions_Extra1    0b0100000000000
        #define UsbEndpointDescriptor_Packet_Transactions_Extra2    0b1000000000000
#define UsbEndpointDescriptor_Interval 0x6 // 1

.section .data
USB_INIT_DEVICES_TEXT: .asciz "\tUSBD: Initializing for 127 devices."
.section .text
usb_initDevices:
    push {r4-r5,lr}

    ldr r0,=USB_INIT_DEVICES_TEXT
    bl screen_println
    
    deviceId .req r4
    pDevice .req r5
    NULL .req r0
    ldr pDevice,=UsbDevices
    mov deviceId,#0
    mov NULL,#0
    deviceIdLoop$:
        str NULL,[pDevice,#UsbDevice_Number]

        add pDevice,#sizeof_UsbDevice
        add deviceId,#1
        cmp deviceId,#0x7F
        bne deviceIdLoop$

    .unreq deviceId
    .unreq pDevice
    .unreq NULL
    pop {r4-r5,pc}

.section .data
.section .text
usb_allocDevice:
    push {r4-r5,lr}

    deviceId .req r4
    pDevice .req r5

    ldr pDevice,=UsbDevices
    mov deviceId,#1

    deviceIdLoop2$:
        ldr r0,[pDevice,#UsbDevice_Number] // Number (device ID)
        cmp r0,#0
        bne notNULL$

        // We found one. Set his ID
        str deviceId,[pDevice,#UsbDevice_Number]

        // Mark as attached
        mov r0,#Attached
        str r0,[pDevice,#UsbDevice_Status]

        // Set a couple flags to NULL
        mov r0,#NoError
        str r0,[pDevice,#UsbDevice_Error]
        mov r0,#0
        strb r0,[pDevice,#UsbDevice_PortNumber]
        str r0,[pDevice,#UsbDevice_Parent]
        str r0,[pDevice,#UsbDevice_DriverData]
        str r0,[pDevice,#UsbDevice_FullConfiguration]
        mov r0,#0xFF
        strb r0,[pDevice,#UsbDevice_ConfigurationIndex]
        mov r0,#0
        str r0,[pDevice,#UsbDevice_DeviceDeallocate]
        str r0,[pDevice,#UsbDevice_DeviceDetached]
        str r0,[pDevice,#UsbDevice_DeviceCheckConnection]
        str r0,[pDevice,#UsbDevice_DeviceCheckForChange]
        str r0,[pDevice,#UsbDevice_DeviceChildDetached]
        str r0,[pDevice,#UsbDevice_DeviceChildReset]

        // Return the device pointer
        mov r0,pDevice
        b deviceIdLoop2_done$

        notNULL$:
            add pDevice,#sizeof_UsbDevice
            add deviceId,#1
            cmp deviceId,#0x80
            bne deviceIdLoop2$

    deviceIdLoop2_done$:
        .unreq deviceId
        .unreq pDevice
        pop {r4-r5,pc}

.section .data
.section .text
usb_readDeviceDescriptor:
    push {r4-r5,lr}
    pDevice .req r4
    mov pDevice,r0

    .unreq pDevice
    pop {r4-r5,pc}

.section .data
USBD_SCANNING_TEXT: .asciz "\tUSBD: Scanning "
.section .text
usb_attachDevice:
    push {r4-r5,lr}
    pDevice .req r4
    address .req r5
    mov pDevice,r0

    // Set default text color
    ldr r2,=screen_varForeColor
	ldr r1,[r2]

    // Print id info
    ldr address,[pDevice,#UsbDevice_Number]
    ldr r0,=USBD_SCANNING_TEXT
    bl screen_print
    mov r0,address
    bl screen_printU32ln

    // Read device description
    mov r0,pDevice
    bl usb_readDeviceDescriptor

    .unreq pDevice
    .unreq address
    pop {r4-r5,pc}

.section .data
USB_SCANNING_FOR_DEVICES_TEXT: .asciz "\tUSBD: Scanning for devices."
.section .text
usb_attachRootHub:
    push {r4,lr}

    // Set default text color
    ldr r2,=screen_varForeColor
	ldr r1,[r2]

    ldr r0,=USB_SCANNING_FOR_DEVICES_TEXT
    bl screen_println

    // Init devices, put their IDs to 0 (unused)
    bl usb_initDevices

    // Allocate the root hub
    bl usb_allocDevice
    pRootHub .req r4
    mov pRootHub,r0
    mov r0,#Powered
    str r0,[pRootHub,#UsbDevice_Status]

    // Attach the root hub
    mov r0,pRootHub
    bl usb_attachDevice

    .unreq pRootHub
    pop {r4,pc}
