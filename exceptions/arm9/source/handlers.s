@   This file is part of Luma3DS
@   Copyright (C) 2016 Aurora Wright, TuxSH
@
@   This program is free software: you can redistribute it and/or modify
@   it under the terms of the GNU General Public License as published by
@   the Free Software Foundation, either version 3 of the License, or
@   (at your option) any later version.
@
@   This program is distributed in the hope that it will be useful,
@   but WITHOUT ANY WARRANTY; without even the implied warranty of
@   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@   GNU General Public License for more details.
@
@   You should have received a copy of the GNU General Public License
@   along with this program.  If not, see <http://www.gnu.org/licenses/>.
@
@   Additional Terms 7.b of GPLv3 applies to this file: Requiring preservation of specified
@   reasonable legal notices or author attributions in that material or in the Appropriate Legal
@   Notices displayed by works containing it.

.macro GEN_HANDLER name
    .global \name
    .type   \name, %function
    \name:
        ldr sp, =#0x02000000    @ We make the (full descending) stack point to the end of ITCM for our exception handlers. 
                                @ It doesn't matter if we're overwriting stuff here, since we're going to reboot.
                                
        stmfd sp!, {r0-r7}      @ FIQ has its own r8-r14 regs
        ldr r1, =\@             @ macro expansion counter
        b _commonHandler

    .size   \name, . - \name
.endm

.text
.arm
.align 4

.global _commonHandler
.type   _commonHandler, %function
_commonHandler:
    mrs r2, spsr
    mov r6, sp
    mrs r3, cpsr
    orr r3, #0x1c0          @ disable Imprecise Aborts, IRQ and FIQ (AIF)
    ands r4, r2, #0xf       @ get the mode that triggered the exception
    moveq r4, #0xf          @ usr => sys
    bic r5, r3, #0xf
    orr r5, r4
    msr cpsr_c, r5          @ change processor mode
    stmfd r6!, {r8-lr}
    msr cpsr_cx, r3         @ restore processor mode
    mov sp, r6
    
    stmfd sp!, {r2,lr}      @ it's a bit of a mess, but we will fix that later
                            @ order of saved regs now: cpsr, pc + (2/4/8), r8-r14, r0-r7
                            
    mov r0, sp
    b mainHandler

GEN_HANDLER FIQHandler
GEN_HANDLER undefinedInstructionHandler
GEN_HANDLER prefetchAbortHandler
GEN_HANDLER dataAbortHandler