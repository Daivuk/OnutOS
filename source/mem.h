#pragma once

#define PROCESS_GPU 1
#define PROCESS_KERNEL 2

#define sizeof_MemBlock 0x10
    #define MemBlock_processId  0x0 // 4 bytes
    #define MemBlock_size       0x4 // 4 bytes
    #define MemBlock_pPrev      0x8 // 4 bytes
    #define MemBlock_pNext      0xC // 4 bytes

.globl mem_getTotalSize
.globl mem_init
.globl mem_drawMemUsage
.globl mem_alloc
.globl mem_free
