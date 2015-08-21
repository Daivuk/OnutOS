#pragma once

#define sizeof_MemBlock 0x10
    #define MemBlock_used   0x0 // 4 bytes
    #define MemBlock_size   0x4 // 4 bytes
    #define MemBlock_pPrev  0x8 // 4 bytes
    #define MemBlock_pNext  0xC // 4 bytes

.globl mem_getTotalSize
.globl mem_init
.globl mem_drawMemUsage
