global decode

section .data

; For every instruction, if a specific bit is deterministic,
; which means that is encodes the instruction, not its argument,
; then this bit is equal in the mask and in the instruction.
; Otherwise the bit is equal to 0.
mov_mask:   dw 0b0000_0000_0000_0000
or_mask:    dw 0b0000_0000_0000_0010
and_mask:   dw 0b0000_0000_0000_0100
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
arg_mask_1: dw 0b0011_1000_0000_0000
arg_mask_2: dw 0b0000_0111_0000_0000
arg_mask_3: dw 0b0000_0000_1111_1111

section .text

; rsi will be used to store intermediate results.
; rdx will be used to store intermediate mask.
decode:
    xor ax, ax

    ; mov
    mov si, di
    mov dx, [rel mov_mask]
    not dx
    xor si, dx
    or si, [rel arg_mask_1]
    or si, [rel arg_mask_2]
    not si
    cmp si, 0
    je .end
    inc ax

    ; notatka: najlepiej zrobić "funkcję", która przyjmuje kod, wzorzec i 2 maski!
    ; i wykorzystuje wzór: ~ ((X ^ ~ MASK_1) | MASK_2 | MASK_3) == 0
.end:
    ret