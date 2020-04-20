Problem description given at http://golf.so.pwni.ng/upload

```
Upload a 64-bit ELF shared object of size at most 1024 bytes. It should spawn a shell (execute execve("/bin/sh", ["/bin/sh"], ...)) when used like

LD_PRELOAD=<upload> /bin/true
```

So we need to construct a shared library which should spawn a execve shell when loaded in /bin/true
So I started by a construct a minimal c fill with a empty definition of a glibc function that we will override

```
➜  golf.so> gcc -fPIC -c custom.c          
➜  golf.so> gcc -shared -o custom.so custom.o          
➜  golf.so> ls -la
total 32
-rw-r--r-- 1 xyz xyz    37 Apr 18 10:04 custom.c
-rw-r--r-- 1 xyz xyz  1240 Apr 20 10:30 custom.o
-rwxr-xr-x 1 xyz xyz 15584 Apr 20 10:30 custom.so
```

It became clear early that gcc will not make anything smaller that 10KB even with additional optimization flags.
So we started out writing a elf by hand

Taking the elfl spec reference from `https://uclibc.org/docs/elf-64-gen.pdf`
Started by constructing a very basic elf executable which executes execve shell

```
use64
org 0x400000
 
ehdr:           ; Elf64_Ehdr
  db 0x7f, "ELF", 2, 1, 1, 0 ; e_ident
  times 8 db 0
  dw  2         ; e_type
  dw  0x3e      ; e_machine
  dd  1         ; e_version
  dq  _start    ; e_entry
  dq  phdr - $$ ; e_phoff
  dq  0         ; e_shoff
  dd  0         ; e_flags
  dw  ehdrsize  ; e_ehsize
  dw  phdrsize  ; e_phentsize
  dw  1         ; e_phnum
  dw  0         ; e_shentsize
  dw  0         ; e_shnum
  dw  0         ; e_shstrndx
 ehdrsize  =  $ - ehdr
 
phdr:           ; Elf64_Phdr
  dd  1         ; p_type
  dd  5         ; p_flags
  dq  0         ; p_offset
  dq  $$        ; p_vaddr
  dq  $$        ; p_paddr
  dq  filesize  ; p_filesz
  dq  filesize  ; p_memsz
  dq  0x1000    ; p_align

phdrsize  =  $ - phdr

main:
_start:
    push rax
    push rdx
    push rsi
    push rbx
    xor rax,rax
    xor rdx, rdx
    xor rsi, rsi
    mov rbx,'/bin/sh'
    push rbx
    push rsp
    pop rdi
    mov al, 59
    syscall
    pop rbx
    pop rbx
    pop rsi
    pop rdx
    pop rax
    ret

filesize  = $ - $$
```

Straight out of this blog `https://blog.stalkr.net/2014/10/tiny-elf-3264-with-nasm.html`
When assembled with `fasm small.asm ./small` we get a shell in only 156 bytes. Yay !

So now the plan was to write a shared lib by hand which will override a glibc function
For a shared library you need two program headers, one defining a LOADable segment and another a DYNAMIC segment.
Then you need to construct section headers, one SYMTAB section containing our overwriting symbol, a STRTAB containing the strings, a text section for our actual payload,and DYNSYM section.

```
use64
org 0x0
 
ehdr:                             ; Elf64_Ehdr
    db  0x7f, "ELF", 2, 1, 1, 0   ; e_ident
        times 8 db      0
    dw  3                         ; e_type
    dw  0x3e                      ; e_machine
    dd  1                         ; e_version
    dq  _start                    ; e_entry
    dq  phdr - $$                 ; e_phoff
    dq  sectionHeaders - $$       ; e_shoff
    dd  0                         ; e_flags
    dw  ehdrsize                  ; e_ehsize
    dw  phdrsize                  ; e_phentsize
    dw  2                         ; e_phnum
    dw  64                        ; e_shentsize
    dw  6                         ; e_shnum
    dw  4                         ; e_shstrndx
    ehdrsize  = $ - ehdr
 
phdr:           ; Elf64_Phdr
    phdr_loadable:
        dd  1                     ; p_type
        dd  7                     ; p_flags
        dq  0                     ; p_offset
        dq  $$                    ; p_vaddr
        dq  $$                    ; p_paddr
        dq  filesize              ; p_filesz
        dq  filesize              ; p_memsz
        dq  0x1000                ; p_align
phdrsize  = $ - phdr
    phdr_dynamic:
        dd  2                     ; p_type
        dd  7                     ; p_flags
        dq  dynamic               ; p_offset
        dq  dynamic               ; p_vaddr
        dq  dynamic               ; p_paddr
        dq  dynamicsize           ; p_filesz
        dq  dynamicsize           ; p_memsz
        dq  0x1000                ; p_align

; org 0x1000
main:
_start:
    push rax
    push rdx
    push rsi
    push rbx
    xor rax,rax
    xor rdx, rdx
    xor rsi, rsi
    mov rbx,'/bin/sh'
    push rbx
    push rsp
    pop rdi
    mov al, 59
    syscall
    pop rbx
    pop rbx
    pop rsi
    pop rdx
    pop rax
    ret

mainsize = $ - main

sectionHeaders:
    section_dynsym:
          dd      1               ;sh_name
          dd      11              ;sh_type DYNSYM
          dq      7               ;sh_flags rx
          dq      dynsym          ;sh_addr
          dq      dynsym          ;sh_offset
          dq      dynsymsize      ;sh_size
          dd      3               ;sh_link
          dd      1               ;sh_info
          dq      1               ;sh_addralign
          dq      24              ;sh_entsize

    section_text:
          dd      19              ;sh_name
          dd      1               ;sh_type PROGBITS
          dq      7               ;sh_flags rx
          dq      main            ;sh_addr
          dq      main            ;sh_offset
          dq      mainsize        ;sh_size
          dd      3               ;sh_link
          dd      0               ;sh_info
          dq      1               ;sh_addralign
          dq      0               ;sh_entsize

    section_shstrtab:
          dd      9               ;sh_name
          dd      3               ;sh_type STRTAB
          dq      7               ;sh_flags rx
          dq      shstrtab        ;sh_addr
          dq      shstrtab        ;sh_offset
          dq      shstrtabsize    ;sh_size
          dd      0               ;sh_link
          dd      0               ;sh_info
          dq      1               ;sh_addralign
          dq      0               ;sh_entsize

    section_dynamic:
          dd      41               ;sh_name
          dd      6                ;sh_type SYMTAB
          dq      7                ;sh_flags rx
          dq      dynamic          ;sh_addr
          dq      dynamic          ;sh_offset
          dq      dynamicsize      ;sh_size
          dd      3                ;sh_link
          dd      0                ;sh_info
          dq      8h               ;sh_addralign
          dq      16               ;sh_entsize

sectionHeaderssize = $ - sectionHeaders

dynsym:
    times 24 db 0
	      dd      1                 ;st_name
	      db      18                ;st_info global function 00010000 || 00000010
	      db      0                 ;st_other
	      dw      1                 ;st_shndx
	      dq	  _start              ;st_value
	      dq      mainsize          ;st_size
dynsymsize = $ - dynsym

dynamic:
    dt_strtab:
        dq          5
        dq          shstrtab
    dt_symtab:
        dq          6
        dq          dynsym
    dt_none:
        dq          0
        dq          0
dynamicsize = $ - dynamic 


shstrtab:
    db 0
shstrtabsize = $ - shstrtab

filesize  = $ - $$
```
The final file size was already getting around 700 bytes.
We were almost done writing it by hand, but when we were building the dynamic section while reading the elf spec we came across the flag `DT_INIT`
```
DT_INIT 12 d_ptr Address of the initialization function
```
Shit, we could just point DT_INIT to our function and it will execute, no need of all this extra sections.
So the only thing we need for this 2 program headers and one dynamic section containing our DT_INIT

```
use64
org 0x0
 
ehdr:                             ; Elf64_Ehdr
    db  0x7f, "ELF", 2, 1, 1, 0   ; e_ident
        times 8 db      0
    dw  3                         ; e_type
    dw  0x3e                      ; e_machine
    dd  1                         ; e_version
    dq  _start                    ; e_entry
    dq  phdr - $$                 ; e_phoff
    dq  sectionHeaders - $$       ; e_shoff
    dd  0                         ; e_flags
    dw  ehdrsize                  ; e_ehsize
    dw  phdrsize                  ; e_phentsize
    dw  2                         ; e_phnum
    dw  64                        ; e_shentsize
    dw  6                         ; e_shnum
    dw  4                         ; e_shstrndx
    ehdrsize  = $ - ehdr
 
phdr:           ; Elf64_Phdr
    phdr_loadable:
        dd  1                     ; p_type
        dd  7                     ; p_flags
        dq  0                     ; p_offset
        dq  $$                    ; p_vaddr
        dq  $$                    ; p_paddr
        dq  filesize              ; p_filesz
        dq  filesize              ; p_memsz
        dq  0x1000                ; p_align
phdrsize  = $ - phdr
    phdr_dynamic:
        dd  2                     ; p_type
        dd  7                     ; p_flags
        dq  dynamic               ; p_offset
        dq  dynamic               ; p_vaddr
        dq  dynamic               ; p_paddr
        dq  dynamicsize           ; p_filesz
        dq  dynamicsize           ; p_memsz
        dq  0x1000                ; p_align

; org 0x1000
main:
_start:
    push rax
    push rdx
    push rsi
    push rbx
    xor rax,rax
    xor rdx, rdx
    xor rsi, rsi
    mov rbx,'/bin/sh'
    push rbx
    push rsp
    pop rdi
    mov al, 59
    syscall
    pop rbx
    pop rbx
    pop rsi
    pop rdx
    pop rax
    ret

mainsize = $ - main

sectionHeaders:
dynsym:
dynsymsize = $ - dynsym

dynamic:
    dt_strtab:
        dq          5
        dq          dynsym
    dt_symtab:
        dq          6
        dq          dynsym
    dt_init:
        dq          12
        dq          main
dynamicsize = $ - dynamic 

filesize  = $ - $$
```

Just the bare essentials, the final file was `266 bytes`. We got 1/2 flag.
For the next flag we needed under 196 bytes.

1. Trim the shellcode
2. Overlap the elf header with the program header = save 4 bytes
3. Overlap the dynamic program header with the dynamic section = save 8*6 bytes
4. Overlap few bytes of the dynamic section with the shellcode = 2 bytes

```
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
```



```
➜  golf.so> fasm smalllib.asm smalllib.so
flat assembler  version 1.73.13  (16384 kilobytes memory, x64)
2 passes, 193 bytes.
```
We got it to 193 bytes and got the 2nd flag as well. Crazy





