#include "object.h"

.section .text
object_addRef:
	ldr r1,[r0]
	add r1,#1
	str r1,[r0]
	mov pc,lr

.section .text
object_release:
	ldr r1,[r0]
	sub r1,#1
	str r1,[r0]
	cmp r1,#0
	bleq mem_free
	mov pc,lr
