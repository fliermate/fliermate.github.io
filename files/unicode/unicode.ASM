PREFIX1 equ 0xF0
PREFIX2 equ 0x9D
PREFIX3A equ 0x91
PREFIX3B equ 0x92

format PE console
entry start

include 'win32a.inc'

section '.data' data readable writable

_openerr  db 'Error opening file - input.txt',13,10,0
_openlen  = $ - _openerr
_readerr  db 'Error reading file - input.txt',13,10,0
_readlen  = $ - _readerr
_createerr db 'Error creating file - output.txt',13,10,0
_createlen  = $ - _createerr
_writeerr db 'Error writing file - output.txt',13,10,0
_writelen  = $ - _writeerr
_dummy    dd ?
_infile   db 'input.txt',0
_outfile  db 'output.txt',0
_buffer   rb 16
_len      dd ?
_inhandle dd ?
_outhandle dd ?
_stdout   dd ?
_count    dd ?
_short    rb 1

section '.code' code readable executable

start:
        invoke  CreateFile, _infile, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
        mov     dword [_inhandle], eax
        cmp     eax, INVALID_HANDLE_VALUE
        je      .OpenError
        invoke  CreateFile, _outfile, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
        mov     dword [_outhandle], eax
        cmp     eax, INVALID_HANDLE_VALUE
        je      .CreateError
        invoke  GetStdHandle, STD_OUTPUT_HANDLE
        mov     dword [_stdout],eax

.redo:
        invoke  ReadFile, dword [_inhandle], _buffer, 16, _len, 0
        test    eax, eax
        jz      .ReadError
        mov     ecx, dword [_len]
        test    ecx, ecx
        jz      .close
        mov     [_count], ecx

        xor     ecx, ecx
      
.repeat1:
        push    ecx
        mov     dl, byte [_buffer + ecx]
        cmp     dl, 'Y'
        jb      .check1
        cmp     dl, 'Z'
        ja      .check2
        push    edx
        mov     [_short], PREFIX1
        call    PrintChar
        mov     [_short], PREFIX2
        call    PrintChar
        mov     [_short], PREFIX3B
        call    PrintChar
        pop     edx
        add     dl, 39
        mov     [_short], dl
        call    PrintChar
        jmp     .next

.check1:
        cmp     dl, 'A'
        jb      .nocheck
        push    edx
        mov     [_short], PREFIX1
        call    PrintChar
        mov     [_short], PREFIX2
        call    PrintChar
        mov     [_short], PREFIX3A
        call    PrintChar
        pop     edx
        add     dl, 103
        mov     [_short], dl
        call    PrintChar
        jmp     .next

.check2:
        cmp     dl, 'a'
        jae     .check3
        jmp     .nocheck

.check3:
        cmp     dl, 'z'
        ja      .nocheck
        push    edx
        mov     [_short], PREFIX1
        call    PrintChar
        mov     [_short], PREFIX2
        call    PrintChar
        mov     [_short], PREFIX3B
        call    PrintChar
        pop     edx
        add     dl,33
        mov     [_short], dl
        call    PrintChar
        jmp     .next

.nocheck:
        mov     [_short],dl
        call    PrintChar

.next:
        pop     ecx
        inc     ecx
        cmp     ecx, [_count]
        jb      .repeat1
        jmp     .redo

.close:
        invoke  CloseHandle, [_inhandle]
        invoke  CloseHandle, [_outhandle]
        jmp     .done

.OpenError:
        lea     edx, [_openerr]
        mov     ecx, _openlen
        jmp     .error

.CreateError:
        lea     edx, [_createerr]
        mov     ecx, _createlen
        jmp     .error

.ReadError:
        lea     edx, [_readerr]
        mov     ecx, _readlen
        jmp     .error

.WriteError:
        lea     edx, [_writeerr]
        mov     ecx, _writelen
        jmp     .error

.error:
        invoke  GetStdHandle, STD_OUTPUT_HANDLE
        invoke  WriteConsole, eax, edx, ecx, _dummy, 0

.done:
        invoke  ExitProcess,0

PrintChar:
        mov     edx, 1
        lea     esi, [_short]
        call    Print
        ret
Print:
        invoke  WriteFile, dword [_outhandle], esi, edx, _dummy, 0
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
        ExitProcess,'ExitProcess'
