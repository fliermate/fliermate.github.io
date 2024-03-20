; HEXDUMPW.ASM - Win32 CUI
; Copyright (C) 2022 Boo Khan Ming
;
; MIT license apply
;
format PE console
entry start

include 'win32a.inc'

section '.data' readable writable

_message0 db 'Usage:  HEXDUMPW <filename>',13,10,0
_msglen0  = $ - _message0
_message1 db 'INVALID_HANDLE_VALUE',13,10,0
_msglen1  = $ - _message1
_message2 db 'ReadFile FALSE',13,10,0
_msglen2  = $ - _message2
_dummy    dd ?
_short    db ?
          db 0
_double   dw ?
_hexnum   rb 8
_hexval   rb 2
_digits   db '0123456789ABCDEF'
_space1   db 32,32
_len1     = $ - _space1
_space2   db 32
_len2     = $ - _space2
_filename rb MAX_PATH
_fnlen    dd ?
_buffer   rb 16
_len      dd ?
_ptr      dd ?
_handle   dd ?
_stdout   dd ?
_count    dd ?
_offset   dd 0

section '.code' code readable executable

start:
        invoke  GetCommandLine
        push    eax
        mov     edi, eax
        or      ecx, -1
        xor     eax, eax
        repnz   scasb           ; Calculate total length of command line arguments
        not     ecx
        pop     eax
        mov     dword [_fnlen], ecx
        push    eax
        mov     edi, eax
        or      ecx, -1
        mov     eax, 32
        repnz   scasb           ; Calculate length of first command line argument (APPNAME)
        not     ecx
        pop     eax
        inc     ecx
        sub     dword [_fnlen], ecx     ; Compute the length of second command line argument (_FILENAME)
        cmp     dword [_fnlen], 0
        jle     .err0
        add     eax, ecx
        mov     ecx, dword [_fnlen]
        mov     esi, eax
        lea     edx, [_filename]
        mov     edi, edx
        rep     movsb
        ;invoke  GetStdHandle, -11
        ;invoke  WriteConsole, eax, _filename, dword [_fnlen], _dummy, 0
        invoke  CreateFile, _filename, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
        mov     dword [_handle], eax
        cmp     eax, INVALID_HANDLE_VALUE
        je      .err1
        invoke  GetStdHandle, -11
        mov     dword [_stdout],eax

.redo:
        invoke  ReadFile, dword [_handle], _buffer, 16, _len, 0
        test    eax, eax
        jz      .err2
        mov     ecx, dword [_len]
        test    ecx, ecx
        jz      .close
        mov     [_count], ecx

        mov     edx, [_offset]
        mov     ecx, 8
        call    ConvertLongHex
        call    PrintOffset
        call    PrintLongSpace
        xor     ecx, ecx
      
.repeat1:
        xor     edx, edx
        mov     dl, byte [_buffer + ecx]
        push    ecx
        mov     ecx, 2
        call    ConvertShortHex
        call    PrintHex
        call    PrintShortSpace
        pop     ecx
        inc     ecx
        cmp     ecx, [_count]
        jb      .repeat1
        cmp     ecx, 16
        jb      .pad1
        jmp     .skip1
.pad1:
        mov     ebx, 16
        sub     ebx,ecx
.pad3:
        call    PrintShortSpace
        call    PrintShortSpace
        call    PrintShortSpace
        dec     ebx
        jnz     .pad3
.skip1:
        call    PrintLongSpace
        xor     ecx, ecx
      
.repeat2:
        xor     edx, edx
        mov     dl, byte [_buffer + ecx]
        push    ecx
        cmp     dl, 32
        jb      .dot
        cmp     dl, 127
        jae     .dot
        mov     [_short], dl
        call    PrintChar
        jmp     .skip2
.dot:
        mov     [_short], '.'
        call    PrintChar
.skip2:
        pop     ecx
        inc     ecx
        cmp     ecx, [_count]
        jb      .repeat2
        cmp     ecx, 16
        jb      .pad2
        jmp     .skip3
.pad2:
        mov     ebx, 16
        sub     ebx, ecx
.pad4:
        call    PrintShortSpace
        call    PrintShortSpace
        dec     ebx
        jnz     .pad4
.skip3:
        call    PrintLine
        add     [_offset], 16
        jmp     .redo

.close:
        invoke  CloseHandle, [_handle]
        jmp     .done

.err0:
        lea     edx, [_message0]
        mov     ecx, _msglen0
        jmp     .error

.err1:
        lea     edx, [_message1]
        mov     ecx, _msglen1
        jmp     .error

.err2:
        lea     edx, [_message2]
        mov     ecx, _msglen2
        jmp     .error

.error:
        invoke  GetStdHandle, -11
        invoke  WriteConsole, eax, edx, ecx, _dummy, 0

.done:
        invoke  ExitProcess,0

PrintLongSpace:
        mov     edx, _len1
        lea     esi, [_space1]
        call    Print
        ret
PrintShortSpace:
        mov     edx, _len2
        lea     esi, [_space2]
        call    Print
        ret
PrintLine:
        mov     edx, 2
        mov     [_double], 0x0A0D
        lea     esi, [_double]
        call    Print
        ret
PrintOffset:
        mov     edx, 8
        lea     esi, [_hexnum]
        call    Print
        ret
PrintHex:
        mov     edx, 2
        lea     esi, [_hexval]
        call    Print
        ret
PrintChar:      
        mov     edx, 1
        lea     esi, [_short]
        call    Print
        ret
Print:
        ;invoke  WriteConsole, dword [_stdout], esi, edx, _dummy, 0
        invoke  WriteFile, dword [_stdout], esi, edx, _dummy, 0
        ret
            
ConvertLongHex:    ;-) Nice code snippet by Tomasz Grysztar (flat assembler)
        xor      ebx,ebx
.loop1:
        rol      edx,4
        mov      eax,edx
        and      eax,1111b
        mov      al,[_digits+eax]
        mov      [ebx+_hexnum],al
        inc      ebx
        dec      ecx
        jnz      .loop1
        ret
      
ConvertShortHex:   ;-) Nice code snippet by Tomasz Grysztar (flat assembler)
        xor      ebx,ebx
.loop2:
        rol      dl,4
        mov      al,dl
        and      eax,1111b
        mov      al,[_digits+eax]
        mov      [ebx+_hexval],al
        inc      ebx
        dec      ecx
        jnz      .loop2
        ret
 
section '.idata' import readable writable

 library kernel32, 'KERNEL32.DLL'

 import kernel32,\
        GetStdHandle, 'GetStdHandle', \
        WriteConsole, 'WriteConsoleA', \
        CreateFile, 'CreateFileA', \
        ReadFile, 'ReadFile', \
        WriteFile, 'WriteFile', \
        CloseHandle, 'CloseHandle', \
        GetCommandLine, 'GetCommandLineA', \
        ExitProcess,'ExitProcess'
