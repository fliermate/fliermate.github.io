; HEXDUMP.ASM
; Copyright (C) 2021 Boo Khan Ming
;
; MIT license apply
;
format ELF64 executable 3

segment readable executable

entry $

      pop     r8
      pop     rsi	;APP_NAME
      pop     rsi	;1st command-line argument
      mov     rdi,rsi
      cmp     rdi,0
      je      _err   
      ;lea     rdi,[fn]
      xor     rsi,rsi   ;O_RDONLY
      mov     rax,2     ; sys_create
      syscall
      cmp     rax,-1
      je      _err
      mov     dword [fd],eax

_redo:
      mov     rdx,16
      lea     rsi,[buffer]      
      mov     edi,dword [fd]
      xor     rax,rax  ; sys_read
      syscall
      cmp     rax,0
      je      _close
      mov     [count],eax

      mov     edx,[offset]
      mov     ecx,8
      call    ConvertHex
      call    PrintOffset
      call    PrintLongSpace      
      mov     rcx,0
      
_repeat1:      
      xor     rdx,rdx
      mov     dl,byte [buffer + rcx]

      push    rcx
      mov     rcx,2
      call    ConvertHex2
      call    PrintHex
      call    PrintShortSpace
      pop     rcx
      inc     rcx 
      cmp     ecx,[count]
      jb      _repeat1
      cmp     ecx,16
      jb      _pad1    
      jmp     _skip1
_pad1:
      mov     ebx,16
      sub     ebx,ecx
_pad3:
      call    PrintShortSpace
      call    PrintShortSpace
      call    PrintShortSpace
      dec     ebx
      jnz     _pad3   
                    
_skip1:      
      call    PrintLongSpace
      mov     rcx,0
      
_repeat2:      
      xor     rdx,rdx
      mov     dl,byte [buffer + rcx]
      push    rcx
      cmp     dl,32
      jb      _dot
      cmp     dl,127
      jae     _dot
      mov     [dummy],dl
      call    PrintChar
      jmp     _skip2
 
 _dot:
      mov     [dummy],'.'
      call    PrintChar
 _skip2:        
      pop     rcx
      inc     rcx 
      cmp     ecx,[count]
      jb      _repeat2
      cmp     ecx,16
      jb      _pad2    
      jmp     _skip3
_pad2:
      mov     ebx,16
      sub     ebx,ecx
_pad4:      
      call    PrintShortSpace
      call    PrintShortSpace
      dec     ebx
      jnz     _pad4
            
_skip3:
      call    PrintLine      
      add     [offset],16
      jmp     _redo
            
_close:
      mov     edi,dword [fd]
      mov     rax,3    ; sys_close
      syscall

_err:
      mov     rdi,rax
      mov     rax,60   ; sys_exit
      syscall

PrintLongSpace:
      mov     rdx,len1
      lea     rsi,[space1]
      call    Print
      ret
PrintShortSpace:
      mov     rdx,len2
      lea     rsi,[space2]
      call    Print
      ret
PrintLine:
      mov     rdx,1
      mov     [dummy],10
      lea     rsi,[dummy]
      call    Print
      ret
PrintOffset:
      mov     rdx,8
      lea     rsi,[hexnum]
      call    Print
      ret      
PrintHex:
      mov     rdx,2
      lea     rsi,[hexval]
      call    Print
      ret    
PrintChar:      
      mov     rdx,1
      lea     rsi,[dummy]
      call    Print
      ret
Print:      
      ;mov     rdx,rax
      ;lea     rsi,[buffer]
      mov     rdi,1    ; STDOUT
      mov     rax,1    ; sys_write
      syscall      
      ret
            
ConvertHex:                                     ;-) Nice code snippet by Tomasz Grysztar (flat assembler)
      ;mov      ecx,8
      xor      ebx,ebx
_loop1:
      rol      edx,4
      mov      eax,edx
      and      eax,1111b
      mov      al,[digits+eax]
      mov      [ebx+hexnum],al
      inc      ebx
      dec      ecx
      jnz      _loop1     
      ret 
      
ConvertHex2:                                     ;-) Nice code snippet by Tomasz Grysztar (flat assembler)
      ;mov      ecx,8
      xor      ebx,ebx
_loop2:
      rol      dl,4
      mov      al,dl
      and      eax,1111b
      mov      al,[digits+eax]
      mov      [ebx+hexval],al
      inc      ebx
      dec      ecx
      jnz      _loop2     
      ret       
 
segment readable writeable

buffer rb      16
fd     dd      ?
count  dd      ?
offset dd      0
;fn     db      'cpubrand.asm',0
hexnum rb      8
hexval rb      2
digits db      '0123456789ABCDEF' 
space1 db      32,32
len1   = $ - space1
space2 db      32
len2   = $ - space2
dummy  db      ?
