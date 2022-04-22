global decode
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
    and r13w, arg_mask_2
    shr r13w, 8

    ; Put arg2 into r14b.
    xor r14, r14
    mov r14w, r12w
    and r14w, arg_mask_1
    shr r14w, 11

    ; Put imm8 into r15b.
    xor r15, r15
    mov r15w, r12w
    and r15w, arg_mask_3

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
    
.mov_instr:
    ; na podstawie r13b i r14b wykonać move...
    jmp .next_iteration

.or_instr:
    jmp .next_iteration

.add_instr:
    jmp .next_iteration

.sub_instr:
    jmp .next_iteration

.adc_instr:
    jmp .next_iteration

.sbb_instr:
    jmp .next_iteration

.xchg_instr:
    jmp .next_iteration

.movi_instr:
    jmp .next_iteration

.xori_instr:
    jmp .next_iteration

.addi_instr:
    jmp .next_iteration

.cmpi_instr:
    jmp .next_iteration

.clc_instr:
    jmp .next_iteration

.stc_instr:
    jmp .next_iteration

.brk_instr:
    jmp .end

.jmp_instr:
    jmp .next_iteration

.jnc_instr:
    jmp .next_iteration

.jc_instr:
    jmp .next_iteration

.jnz_instr:
    jmp .next_iteration
    
.jz_instr:
    jmp .next_iteration

.rcr_instr:
    jmp .next_iteration


.end:
    ; Move index of the core into appropriate register.
    mov rdi, rcx
    call serialize_state

    pop r15
    pop r14
    pop r13
    pop r12
    ret

; lea rdi, [rel D]
; mov byte [rdi + rcx], 69

; lea rdi, [rel PC]
; mov byte [rdi + rcx], 3