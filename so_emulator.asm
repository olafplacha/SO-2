; Author: Olaf Placha

global so_emul

section .bss

; Registers, program counter and flags.
A:  resb CORES
D:  resb CORES
X:  resb CORES
Y:  resb CORES
PC: resb CORES
C:  resb CORES
Z:  resb CORES

section .data

; For every instruction, if a specific bit is deterministic,
; which means that is encodes the instruction, not its argument,
; then this bit is identical in the mask and in the instruction.
; Otherwise the bit is equal to 0.
mov_mask:   dw 0b0000_0000_0000_0000
or_mask:    dw 0b0000_0000_0000_0010
add_mask:   dw 0b0000_0000_0000_0100
sub_mask:   dw 0b0000_0000_0000_0101
adc_mask:   dw 0b0000_0000_0000_0110
sbb_mask:   dw 0b0000_0000_0000_0111
movi_mask:  dw 0b0100_0000_0000_0000
xori_mask:  dw 0b0101_1000_0000_0000
addi_mask:  dw 0b0110_0000_0000_0000
cmpi_mask:  dw 0b0110_1000_0000_0000
rcr_mask:   dw 0b0111_0000_0000_0001
clc_mask:   dw 0b1000_0000_0000_0000
stc_mask:   dw 0b1000_0001_0000_0000
jmp_mask:   dw 0b1100_0000_0000_0000
jnc_mask:   dw 0b1100_0010_0000_0000
jc_mask:    dw 0b1100_0011_0000_0000
jnz_mask:   dw 0b1100_0100_0000_0000
jz_mask:    dw 0b1100_0101_0000_0000
brk_mask:   dw 0b1111_1111_1111_1111
xchg_mask:  dw 0b0000_0000_0000_1000

; There are a few masks, which retrieve arguments.
arg_mask_0: dw 0b0000_0000_0000_0000
arg_mask_1: dw 0b0011_1000_0000_0000
arg_mask_2: dw 0b0000_0111_0000_0000
arg_mask_3: dw 0b0000_0000_1111_1111

section .text

; Sets ZF to 1 iff the instruction can be decoded using provided masks.
; Instruction can be decoded iff:
; ~ ((( INSTR ^ ~ MASK_INSTR ) | MASK_ARG1 ) | MASK_ARG2 ) == 0
; 
; Arguments:
; di - Code to be decoded.
; si - Instruction mask.
; dx - Arg1 mask.
; cx - Arg2 mask.
;
; Return value: ZF.
;
; Modifies: rdi, rsi, ZF
mask_compare:
    not si
    xor di, si
    or di, dx
    or di, cx
    not di
    test di, di
    ret

; Decodes instruction code in the following way:
; - MOV  - 0
; - OR   - 1
; - ADD  - 2
; - SUB  - 3
; - ADC  - 4
; - SBB  - 5
; - XCHG - 6
; - MOVI - 7
; - XORI - 8
; - ADDI - 9
; - CMPI - 10
; - CLC  - 11
; - STC  - 12
; - BRK  - 13
; - JMP  - 14
; - JNC  - 15
; - JC   - 16
; - JNZ  - 17
; - JZ   - 18
; - RCR  - 19
; - other, non-decodable instruction - 20 
;
; Arguments:
; di - Instruction code to be decoded.
;
; Return value: ax.
;
; Modifies: rdi, rsi, rdx, rcx, rax, ZF.
decode:
    xor eax, eax

    ; MOV, OR, ADD, SUB, ADC, SBB, XCHG share argument flags.
    mov dx, [rel arg_mask_1]
    mov cx, [rel arg_mask_2]

    ; Try decoding as MOV.
    mov si, [rel mov_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as OR.
    inc ax
    mov si, [rel or_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as ADD.
    inc ax
    mov si, [rel add_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as SUB.
    inc ax
    mov si, [rel sub_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as ADC.
    inc ax
    mov si, [rel adc_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as SBB.
    inc ax
    mov si, [rel sbb_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as XCHG.
    inc ax
    mov si, [rel xchg_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; MOVI, XORI, ADDI, CMPI share argument flags.
    mov dx, [rel arg_mask_2]
    mov cx, [rel arg_mask_3]

    ; Try decoding as MOVI.
    inc ax
    mov si, [rel movi_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as XORI.
    inc ax
    mov si, [rel xori_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as ADDI.
    inc ax
    mov si, [rel addi_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as CMPI.
    inc ax
    mov si, [rel cmpi_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; CLC, STC, BRK share argument flags.
    mov dx, [rel arg_mask_0]
    mov cx, [rel arg_mask_0]

    ; Try decoding as CLC.
    inc ax
    mov si, [rel clc_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as STC.
    inc ax
    mov si, [rel stc_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as BRK.
    inc ax
    mov si, [rel brk_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; JMP, JNC, JC, JNZ, JZ share argument flags.
    mov dx, [rel arg_mask_3]
    mov cx, [rel arg_mask_0]

    ; Try decoding as JMP.
    inc ax
    mov si, [rel jmp_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as JNC.
    inc ax
    mov si, [rel jnc_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as JC.
    inc ax
    mov si, [rel jc_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as JNZ.
    inc ax
    mov si, [rel jnz_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; Try decoding as JZ.
    inc ax
    mov si, [rel jz_mask]
    push di
    call mask_compare
    pop di
    jz .end

    ; RCR doesn't share argument flags with other instructions.
    mov dx, [rel arg_mask_2]
    mov cx, [rel arg_mask_0]

    ; Try decoding as RCR.
    inc ax
    mov si, [rel rcr_mask]
    push di
    call mask_compare
    pop di
    jz .end

    inc ax
    
.end:
    ret

; Serializes the state of a specified core.
;
; Arguments:
; rdi - Index of core.
;
; Return value: rax.
;
; Modifies: rdi, rsi, rax.
serialize_state:
    xor eax, eax

    ; Load Z flag.
    lea rsi, [rel Z]
    mov al, [rsi + rdi]

    ; Load C flag.
    shl rax, 8
    lea rsi, [rel C]
    mov al, [rsi + rdi]

    ; Unused.
    shl rax, 8

    ; Load program counter.
    shl rax, 8
    lea rsi, [rel PC]
    mov al, [rsi + rdi]

    ; Load Y.
    shl rax, 8
    lea rsi, [rel Y]
    mov al, [rsi + rdi]

    ; Load X.
    shl rax, 8
    lea rsi, [rel X]
    mov al, [rsi + rdi]

    ; Load D register.
    shl rax, 8
    lea rsi, [rel D]
    mov al, [rsi + rdi]

    ; Load A register.
    shl rax, 8
    lea rsi, [rel A]
    mov al, [rsi + rdi]

    ret 

; Loads argument based on the given value.
;
; Arguments:
; dil - Code of the argument to load.
;
; Return value: al.
;
; Modifies: rdi, rax.
load_arg:
    cmp dil, 0
    je .load_A
    cmp dil, 1
    je .load_D
    cmp dil, 2
    je .load_X
    cmp dil, 3
    je .load_Y
    cmp dil, 4
    je .load_mem_X
    cmp dil, 5
    je .load_mem_Y
    cmp dil, 6
    je .load_mem_X_D
    jmp .load_mem_Y_D
.load_A:
    lea rax, [rel A]
    mov al, [rax + rcx]
    ret
.load_D:
    lea rax, [rel D]
    mov al, [rax + rcx]
    ret
.load_X:
    lea rax, [rel X]
    mov al, [rax + rcx]
    ret
.load_Y:
    lea rax, [rel Y]
    mov al, [rax + rcx]
    ret
.load_mem_X:
    lea rax, [rel X]
    mov al, [rax + rcx]
    and rax, 0xff
    mov al, [rsi + rax]
    ret
.load_mem_Y:
    lea rax, [rel Y]
    mov al, [rax + rcx]
    and rax, 0xff
    mov al, [rsi + rax]
    ret
.load_mem_X_D:
    push r13
    lea rax, [rel X]
    mov al, [rax + rcx]
    lea r13, [rel D]
    mov r13b, [r13 + rcx]
    add al, r13b
    and rax, 0xff
    mov al, [rsi + rax]
    pop r13
    ret
.load_mem_Y_D:
    push r13
    lea rax, [rel Y]
    mov al, [rax + rcx]
    lea r13, [rel D]
    mov r13b, [r13 + rcx]
    add al, r13b
    and rax, 0xff
    mov al, [rsi + rax]
    pop r13
    ret

; Stores the second argument in a memory that is
; specified by the first argument.
;
; Arguments:
; dil - Code of the target memory. 
; sil - Value to store.
; rdx - Pointer to memory.
;
; Modifies: none.
store_arg:
    push r8
    cmp dil, 0
    je .store_A
    cmp dil, 1
    je .store_D
    cmp dil, 2
    je .store_X
    cmp dil, 3
    je .store_Y
    cmp dil, 4
    je .store_mem_X
    cmp dil, 5
    je .store_mem_Y
    cmp dil, 6
    je .store_mem_X_D
    jmp .store_mem_Y_D
.store_A:
    lea r8, [rel A]
    jmp .store_reg
.store_D:
    lea r8, [rel D]
    jmp .store_reg
.store_X:
    lea r8, [rel X]
    jmp .store_reg
.store_Y:
    lea r8, [rel Y]
    jmp .store_reg
.store_reg:
    mov byte [r8 + rcx], sil
    pop r8
    ret
.store_mem_X:
    lea r8, [rel X]
    mov r8b, [r8 + rcx]
    jmp .store_mem
.store_mem_Y:
    lea r8, [rel Y]
    mov r8b, [r8 + rcx]
    jmp .store_mem
.store_mem_X_D:
    push r9
    lea r9, [rel D]
    mov r9b, [r9 + rcx]
    lea r8, [rel X]
    mov r8b, [r8 + rcx]
    add r8b, r9b
    pop r9
    jmp .store_mem
.store_mem_Y_D:
    push r9
    lea r9, [rel D]
    mov r9b, [r9 + rcx]
    lea r8, [rel Y]
    mov r8b, [r8 + rcx]
    add r8b, r9b
    pop r9
    jmp .store_mem
.store_mem:
    ; At this point r8b stores target memory location. 
    and r8, 0xff
    mov byte [rdx + r8], sil
    pop r8
    ret

; Emulates SO processor.
;
; Arguments:
; rdi - Pointer to instructions.
; rsi - Pointer to data.
; rdx - Number of instructions to emulate.
; rcx - Index of core to emulate.
so_emul:
    push r12
    push r13
    push r14
    push r15
.next_iteration:
    ; Check if finished.
    cmp rdx, 0
    je .end

    ; Decrement the number of instructions left.
    dec rdx

    ; Load the value of the program counter.
    lea r8, [rel PC]
    ; r8 stores the address of the program counter.
    add r8, rcx
    ; r9w stores the value of the program counter.
    xor r9, r9
    mov r9b, [r8]
    ; r12w stores the next instruction.
    mov r12w, [rdi + r9 * 2]
    ; Increment the program counter.
    inc r9b
    mov [r8], r9b

    ; Decode the instruction.
    push rdi
    push rsi
    push rdx
    push rcx

    ; Move the instruction to the appropriate register.
    mov di, r12w
    call decode

    pop rcx
    pop rdx
    pop rsi
    pop rdi

    ; Put arg1 into r13b.
    xor r13, r13
    mov r13w, r12w
    and r13w, [rel arg_mask_2]
    shr r13w, 8

    ; Put arg2 into r14b.
    xor r14, r14
    mov r14w, r12w
    and r14w, [rel arg_mask_1]
    shr r14w, 11

    ; Put imm8 into r15b.
    xor r15, r15
    mov r15w, r12w
    and r15w, [rel arg_mask_3]

    ; Now ax stores the index of instruction to be executed.
    cmp ax, 0
    je .mov_instr
    cmp ax, 1
    je .or_instr
    cmp ax, 2
    je .add_instr
    cmp ax, 3
    je .sub_instr
    cmp ax, 4
    je .adc_instr
    cmp ax, 5
    je .sbb_instr
    cmp ax, 6
    je .xchg_instr
    cmp ax, 7
    je .movi_instr
    cmp ax, 8
    je .xori_instr
    cmp ax, 9
    je .addi_instr
    cmp ax, 10
    je .cmpi_instr
    cmp ax, 11
    je .clc_instr
    cmp ax, 12
    je .stc_instr
    cmp ax, 13
    je .brk_instr
    cmp ax, 14
    je .jmp_instr
    cmp ax, 15
    je .jnc_instr
    cmp ax, 16
    je .jc_instr
    cmp ax, 17
    je .jnz_instr
    cmp ax, 18
    je .jz_instr
    cmp ax, 19
    je .rcr_instr
    ; Non-decodable instruction, skip.
    jmp .next_iteration

; ----------
 
.mov_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg2 into r12b.
    xor rdi, rdi
    mov dil, r14b
    call load_arg
    mov r12b, al

    ; Store the value of arg2 into appropriate place.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r12b
    call store_arg

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.or_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg1 into r15b.
    xor rdi, rdi
    mov dil, r13b
    call load_arg
    mov r15b, al

    ; Put the value of arg2 into r12b.
    xor rdi, rdi
    mov dil, r14b
    call load_arg
    mov r12b, al

    ; OR arg1 and arg2 values and put into r15b.
    or r15b, r12b

    ; Set zero flag.
    lea r12, [rel Z]
    cmp r15b, 0
    je .or_set_flag_1
    jmp .or_set_flag_0
.or_set_flag_0:
    mov byte [r12 + rcx], 0
    jmp .or_continue
.or_set_flag_1:
    mov byte [r12 + rcx], 1
    jmp .or_continue

.or_continue:

    ; Store the value of r15b into appropriate place.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r15b
    call store_arg

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.add_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg1 into r15b.
    xor rdi, rdi
    mov dil, r13b
    call load_arg
    mov r15b, al

    ; Put the value of arg2 into r12b.
    xor rdi, rdi
    mov dil, r14b
    call load_arg
    mov r12b, al

    ; Add arg1 and arg2 values and put into r15b.
    add r15b, r12b

    ; Set zero flag.
    lea r12, [rel Z]
    cmp r15b, 0
    je .add_set_flag_1
    jmp .add_set_flag_0
.add_set_flag_0:
    mov byte [r12 + rcx], 0
    jmp .add_continue
.add_set_flag_1:
    mov byte [r12 + rcx], 1
    jmp .add_continue

.add_continue:

    ; Store the value of r15b into appropriate place.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r15b
    call store_arg

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.sub_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg1 into r15b.
    xor rdi, rdi
    mov dil, r13b
    call load_arg
    mov r15b, al

    ; Put the value of arg2 into r12b.
    xor rdi, rdi
    mov dil, r14b
    call load_arg
    mov r12b, al

    ; Subtract arg2 from arg1 put the result into r15b.
    sub r15b, r12b

    ; Set zero flag.
    lea r12, [rel Z]
    cmp r15b, 0
    je .sub_set_flag_1
    jmp .sub_set_flag_0
.sub_set_flag_0:
    mov byte [r12 + rcx], 0
    jmp .sub_continue
.sub_set_flag_1:
    mov byte [r12 + rcx], 1
    jmp .sub_continue

.sub_continue:

    ; Store the value of r15b into appropriate place.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r15b
    call store_arg

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.adc_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Clear all bits of r15. Then put the value of arg1 into r15b.
    xor rdi, rdi
    mov dil, r13b
    call load_arg
    xor r15, r15
    mov r15b, al

    ; Put the value of arg2 into r12b.
    xor rdi, rdi
    mov dil, r14b
    call load_arg
    xor r12, r12
    mov r12b, al

    ; Add arg1 and arg2 values and put into r15.
    add r15, r12

    ; Add carry flag to r15.
    lea r12, [rel C]
    xor r14, r14
    mov r14b, [r12 + rcx]
    add r15, r14

    ; Set carry flag.
    xor r12, r12
    mov r12, r15
    shr r12, 8
    lea r14, [rel C]
    cmp r12, 1
    je .adc_set_cflag_1
    jmp .adc_set_cflag_0
.adc_set_cflag_0:
    mov byte [r14 + rcx], 0
    jmp .adc_c_continue
.adc_set_cflag_1:
    mov byte [r14 + rcx], 1
    jmp .adc_c_continue
.adc_c_continue:

    ; Set zero flag.
    lea r12, [rel Z]
    cmp r15b, 0
    je .adc_set_zflag_1
    jmp .adc_set_zflag_0
.adc_set_zflag_0:
    mov byte [r12 + rcx], 0
    jmp .adc_z_continue
.adc_set_zflag_1:
    mov byte [r12 + rcx], 1
    jmp .adc_z_continue

.adc_z_continue:

    ; Store the value of r15b into appropriate place.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r15b
    call store_arg

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.sbb_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg1 into r15b.
    xor rdi, rdi
    mov dil, r13b
    call load_arg
    xor r15, r15
    mov r15b, al

    ; Put the value of arg2 into r12b.
    xor rdi, rdi
    mov dil, r14b
    call load_arg
    xor r12, r12
    mov r12b, al

    ; Add carry flag to r12.
    push r15
    lea r14, [rel C]
    xor r15, r15
    mov r15b, [r14 + rcx]
    add r12, r15
    pop r15

    ; Now r12 stores arg2 + carry value.

    ; Subtract arg2 from arg1 put the result into r15.
    sub r15, r12

    ; Set carry flag.
    xor r12, r12
    mov r12, r15
    shr r12, 63
    lea r14, [rel C]
    cmp r12, 1
    je .sbb_set_cflag_1
    jmp .sbb_set_cflag_0
.sbb_set_cflag_0:
    mov byte [r14 + rcx], 0
    jmp .sbb_c_continue
.sbb_set_cflag_1:
    mov byte [r14 + rcx], 1
    jmp .sbb_c_continue
.sbb_c_continue:

    ; Set zero flag.
    lea r12, [rel Z]
    cmp r15b, 0
    je .sbb_set_zflag_1
    jmp .sbb_set_zflag_0
.sbb_set_zflag_0:
    mov byte [r12 + rcx], 0
    jmp .sbb_z_continue
.sbb_set_zflag_1:
    mov byte [r12 + rcx], 1
    jmp .sbb_z_continue

.sbb_z_continue:

    ; Store the value of r15b into appropriate place.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r15b
    call store_arg

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.xchg_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg2 into r12b.
    xor rdi, rdi
    mov dil, r14b
    call load_arg
    xor r12, r12
    mov r12b, al

    ; Get the address of the arg1 in memory. r13b stores the code of the address.
    push r8
    cmp r13b, 0
    je .xchg_A0
    cmp r13b, 1
    je .xchg_D0
    cmp r13b, 2
    je .xchg_X0
    cmp r13b, 3
    je .xchg_Y0
    cmp r13b, 4
    je .xchg_mem_X0
    cmp r13b, 5
    je .xchg_mem_Y0
    cmp r13b, 6
    je .xchg_mem_X_D0
    jmp .xchg_mem_Y_D0
.xchg_A0:
    lea r8, [rel A]
    jmp .xchg_reg0
.xchg_D0:
    lea r8, [rel D]
    jmp .xchg_reg0
.xchg_X0:
    lea r8, [rel X]
    jmp .xchg_reg0
.xchg_Y0:
    lea r8, [rel Y]
    jmp .xchg_reg0
.xchg_reg0:
    add r8, rcx
    jmp .xchg_end0
.xchg_mem_X0:
    lea r8, [rel X]
    mov r8b, [r8 + rcx]
    and r8, 0xff
    add r8, rsi
    jmp .xchg_end0
.xchg_mem_Y0:
    lea r8, [rel Y]
    mov r8b, [r8 + rcx]
    and r8, 0xff
    add r8, rsi
    jmp .xchg_end0
.xchg_mem_X_D0:
    push r9
    lea r9, [rel D]
    mov r9b, [r9 + rcx]
    lea r8, [rel X]
    mov r8b, [r8 + rcx]
    add r8b, r9b
    pop r9
    and r8, 0xff
    add r8, rsi
    jmp .xchg_end0
.xchg_mem_Y_D0:
    push r9
    lea r9, [rel D]
    mov r9b, [r9 + rcx]
    lea r8, [rel Y]
    mov r8b, [r8 + rcx]
    add r8b, r9b
    pop r9
    and r8, 0xff
    add r8, rsi
    jmp .xchg_end0
.xchg_end0:
    ; At this point r8 stores arg1 memory location.

    ; Get the address of the arg2 in memory. r14b stores the code of the address.
    push r9
    push r8
    cmp r14b, 0
    je .xchg_A1
    cmp r14b, 1
    je .xchg_D1
    cmp r14b, 2
    je .xchg_X1
    cmp r14b, 3
    je .xchg_Y1
    cmp r14b, 4
    je .xchg_mem_X1
    cmp r14b, 5
    je .xchg_mem_Y1
    cmp r14b, 6
    je .xchg_mem_X_D1
    jmp .xchg_mem_Y_D1
.xchg_A1:
    lea r8, [rel A]
    jmp .xchg_reg1
.xchg_D1:
    lea r8, [rel D]
    jmp .xchg_reg1
.xchg_X1:
    lea r8, [rel X]
    jmp .xchg_reg1
.xchg_Y1:
    lea r8, [rel Y]
    jmp .xchg_reg1
.xchg_reg1:
    add r8, rcx
    jmp .xchg_end1
.xchg_mem_X1:
    lea r8, [rel X]
    mov r8b, [r8 + rcx]
    and r8, 0xff
    add r8, rsi
    jmp .xchg_end1
.xchg_mem_Y1:
    lea r8, [rel Y]
    mov r8b, [r8 + rcx]
    and r8, 0xff
    add r8, rsi
    jmp .xchg_end1
.xchg_mem_X_D1:
    push r9
    lea r9, [rel D]
    mov r9b, [r9 + rcx]
    lea r8, [rel X]
    mov r8b, [r8 + rcx]
    add r8b, r9b
    pop r9
    and r8, 0xff
    add r8, rsi
    jmp .xchg_end1
.xchg_mem_Y_D1:
    push r9
    lea r9, [rel D]
    mov r9b, [r9 + rcx]
    lea r8, [rel Y]
    mov r8b, [r8 + rcx]
    add r8b, r9b
    pop r9
    and r8, 0xff
    add r8, rsi
    jmp .xchg_end1
.xchg_end1:
    mov r9, r8
    pop r8
    ; At this point r9 stores arg2 memory location.

    ; Atomically xchg arg1 and arg2.
    lock xchg byte [r8], r12b

    ; Now r12b contains exchanged value. Store it in arg2.
    mov [r9], r12b

    pop r9
    pop r8
    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.movi_instr:
    push rdi
    push rsi
    push rdx

    ; Store the value of imm8 into appropriate place.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r15b
    call store_arg

    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.xori_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg1 into r14b.
    xor rdi, rdi
    mov dil, r13b
    call load_arg
    mov r14b, al

    ; XOR arg1 and imm8 values and put into r14b.
    xor r14b, r15b

    ; Set zero flag.
    lea r12, [rel Z]
    cmp r14b, 0
    je .xori_set_flag_1
    jmp .xori_set_flag_0
.xori_set_flag_0:
    mov byte [r12 + rcx], 0
    jmp .xori_continue
.xori_set_flag_1:
    mov byte [r12 + rcx], 1
    jmp .xori_continue

.xori_continue:

    ; Store the value of r14b into appropriate place.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r14b
    call store_arg

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.addi_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg1 into r14b.
    xor rdi, rdi
    mov dil, r13b
    call load_arg
    mov r14b, al

    ; Add arg1 and imm8 values and put into r14b.
    add r14b, r15b

    ; Set zero flag.
    lea r12, [rel Z]
    cmp r14b, 0
    je .addi_set_flag_1
    jmp .addi_set_flag_0
.addi_set_flag_0:
    mov byte [r12 + rcx], 0
    jmp .addi_continue
.addi_set_flag_1:
    mov byte [r12 + rcx], 1
    jmp .addi_continue

.addi_continue:

    ; Store the value of r14b into appropriate place.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r14b
    call store_arg

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.cmpi_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg1 into r14b.
    xor rdi, rdi
    mov dil, r13b
    call load_arg
    xor r14, r14
    mov r14b, al

    ; Add arg1 and imm8 values and put into r14.
    sub r14, r15

    ; Set carry flag.
    xor r12, r12
    mov r12, r14
    shr r12, 63
    lea r15, [rel C]
    cmp r12, 1
    je .cmpi_set_cflag_1
    jmp .cmpi_set_cflag_0
.cmpi_set_cflag_0:
    mov byte [r15 + rcx], 0
    jmp .cmpi_c_continue
.cmpi_set_cflag_1:
    mov byte [r15 + rcx], 1
    jmp .cmpi_c_continue
.cmpi_c_continue:

    ; Set zero flag.
    lea r12, [rel Z]
    cmp r14b, 0
    je .cmpi_set_zflag_1
    jmp .cmpi_set_zflag_0
.cmpi_set_zflag_0:
    mov byte [r12 + rcx], 0
    jmp .cmpi_z_continue
.cmpi_set_zflag_1:
    mov byte [r12 + rcx], 1
    jmp .cmpi_z_continue

.cmpi_z_continue:

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.clc_instr:
    lea r12, [rel C]
    mov byte [r12 + rcx], 0

    jmp .next_iteration

; ----------

.stc_instr:
    lea r12, [rel C]
    mov byte [r12 + rcx], 1

    jmp .next_iteration

; ----------

.brk_instr:
    jmp .end

; ----------

.jmp_instr:
    ; Increment the program counter by imm8 stored in r15b.
    lea r13, [rel PC]
    ; Load the program counter into r12b.
    mov r12b, [r13 + rcx]
    add r12b, r15b
    mov [r13 + rcx], r12b

    jmp .next_iteration

; ----------

.jnc_instr:
    ; Load the carry flag into r12b.
    lea r12, [rel C]
    mov r12b, [r12 + rcx]

    ; Check if the carry flag is equal to 0.
    cmp r12b, 0
    jne .next_iteration

    ; Increment the program counter by imm8 stored in r15b.
    lea r13, [rel PC]
    ; Load the program counter into r12b.
    mov r12b, [r13 + rcx]
    add r12b, r15b
    mov [r13 + rcx], r12b

    jmp .next_iteration

; ----------

.jc_instr:
    ; Load the carry flag into r12b.
    lea r12, [rel C]
    mov r12b, [r12 + rcx]

    ; Check if the carry flag is equal to 0.
    cmp r12b, 0
    je .next_iteration

    ; Increment the program counter by imm8 stored in r15b.
    lea r13, [rel PC]
    ; Load the program counter into r12b.
    mov r12b, [r13 + rcx]
    add r12b, r15b
    mov [r13 + rcx], r12b

    jmp .next_iteration

; ----------

.jnz_instr:
    ; Load the zero flag into r12b.
    lea r12, [rel Z]
    mov r12b, [r12 + rcx]

    ; Check if the zero flag is equal to 0.
    cmp r12b, 0
    jne .next_iteration

    ; Increment the program counter by imm8 stored in r15b.
    lea r13, [rel PC]
    ; Load the program counter into r12b.
    mov r12b, [r13 + rcx]
    add r12b, r15b
    mov [r13 + rcx], r12b

    jmp .next_iteration

; ----------
    
.jz_instr:
    ; Load the zero flag into r12b.
    lea r12, [rel Z]
    mov r12b, [r12 + rcx]

    ; Check if the zero flag is equal to 0.
    cmp r12b, 0
    je .next_iteration

    ; Increment the program counter by imm8 stored in r15b.
    lea r13, [rel PC]
    ; Load the program counter into r12b.
    mov r12b, [r13 + rcx]
    add r12b, r15b
    mov [r13 + rcx], r12b

    jmp .next_iteration

; ----------

.rcr_instr:
    push rdi
    push rsi
    push rdx
    push rax

    ; Put the value of arg1 into r15b.
    xor rdi, rdi
    mov dil, r13b
    call load_arg
    mov r15b, al

    ; Remember the least significant bit of arg1 in r14b.
    mov r14b, r15b
    and r14b, 1

    ; Right shift arg1, and set the most significant bit equal to carry flag.
    shr r15b, 1
    ; Load the carry flag into r12b.
    lea r12, [rel C]
    mov r12b, [r12 + rcx]
    shl r12b, 7
    or r15b, r12b

    ; Set carry flag equal to arg1 least significant bit.
    lea r12, [rel C]
    mov byte [r12 + rcx], r14b

    ; Store the new value of arg1.
    mov rdx, rsi
    mov dil, r13b
    mov sil, r15b
    call store_arg

    pop rax
    pop rdx
    pop rsi
    pop rdi
    jmp .next_iteration

; ----------

.end:
    ; Move index of the core into appropriate register.
    mov rdi, rcx
    call serialize_state

    pop r15
    pop r14
    pop r13
    pop r12
    ret
