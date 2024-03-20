; HEXDUMPD.ASM - DOS
; Copyright (C) 2023 Boo Khan Ming
;
; MIT license apply
;
; v0.01 - Initial release
; v0.02 - Fixed hex conversion for 32-bit integer to support offset larger than 64KB
; v0.03 - Contains patches by SeproMan (Belgium) for changing 32-bit operation/instruction to 16-bit. Thanks!

format MZ
entry main:start
stack 100h

label CMD_LENGTH byte at 80h
label CMD_STRING byte at 81h

segment main

start:
        mov     ax,text
        mov     ds,ax

        xor   cx, cx
        mov   cl, [es:CMD_LENGTH]
        lea     di, [es:CMD_STRING]
        lea     si, [_filename]
        cmp     cx, 0
        jz      err0
again:
        mov     al, [es:di]
        cmp     al, ' '
        jnz     continue
        inc     di
        jmp     again
continue:
        cmp     al, 13
        jz      skip
        mov     [si], al
        inc     si
        inc     di
        loop    again
skip:
        xor     al, al
        mov     [si],al
        inc     si
        mov     al, '$'
        mov     [si], al

        ;mov     dx, _filename
        ;mov     ah, 9
        ;int     21h

        mov     ah, 3dh
        xor     al, al
        mov     dx, _filename
        int     21h
        mov     [_handle], ax
        jc      err1

redo:
        mov     ah, 3fh
        mov     bx, [_handle]
        mov     cx, 16
        mov     dx, _buffer
        int     21h
        mov     [_len], ax
        jc      err2
        mov     cx, [_len]
        test    cx, cx
        jz      close
        mov     [_count], cx

        lea     si, [_offset]
        call    ConvertLongHex
        call    PrintOffset
        call    PrintLongSpace
        xor     cx, cx
      
repeat1:
        xor     dx, dx
        mov     si, cx
        mov     dl, byte [_buffer + si]
        push    cx
        mov     cx, 2
        call    ConvertShortHex
        call    PrintHex
        call    PrintShortSpace
        pop     cx
        inc     cx
        cmp     cx, [_count]
        jb      repeat1
        cmp     cx, 16
        jb      pad1
        jmp     skip1
pad1:
        mov     bx, 16
        sub     bx,cx
pad3:
        call    PrintShortSpace
        call    PrintShortSpace
        call    PrintShortSpace
        dec     bx
        jnz     pad3
skip1:
        call    PrintLongSpace
        xor     cx, cx
      
repeat2:
        xor     dx, dx
        mov     si, cx
        mov     dl, byte [_buffer + si]
        push    cx
        cmp     dl, 32
        jb      dot
        cmp     dl, 127
        jae     dot
        mov     [_short], dl
        call    PrintChar
        jmp     skip2
dot:
        mov     [_short], '.'
        call    PrintChar
skip2:
        pop     cx
        inc     cx
        cmp     cx, [_count]
        jb      repeat2
        cmp     cx, 16
        jb      pad2
        jmp     skip3
pad2:
        mov     bx, 16
        sub     bx, cx
pad4:
        call    PrintShortSpace
        call    PrintShortSpace
        dec     bx
        jnz     pad4
skip3:
        call    PrintLine
       add   word [_offset], 16
       adc   word [_offset + 2], 0
        jmp     redo

close:
        mov     ah, 3eh
        mov     bx, [_handle]
        int     21h
        jmp     done

err0:
        mov     dx, _msg0
        mov     ah, 9
        int     21h
        jmp     done

err1:
        mov     dx, _msg1
        mov     ah, 9
        int     21h
        mov     dx, _filename
        mov     ah, 9
        int     21h
        jmp     done

err2:
        mov     dx, _msg2
        mov     ah, 9
        int     21h
        mov     dx, _filename
        mov     ah, 9
        int     21h
        jmp     done

done:
        mov     ax, 4c00h
        int     21h

PrintLongSpace:
        mov     dx, _space1
        call    Print
        ret
PrintShortSpace:
        mov     dx, _space2
        call    Print
        ret
PrintLine:
        mov     dx, _double
        call    Print
        ret
PrintOffset:
        mov     dx, _hexnum
        call    Print
        ret
PrintHex:
        mov     dx, _hexval
        call    Print
        ret
PrintChar:      
        mov     dl, [_short]
        mov     ah, 2
        int     21h
        ret
Print:
        mov     ah, 9
        int     21h
        ret

;input: si - pointer to 32-bit integer
;output: _hexnum
ConvertLongHex:    ;-) Nice code snippet by angch (Ang Chin Han)
   lea di, [_hexnum]
   mov bx, 2
.loop3:
   mov dx, word [si+2]
   mov cx, 4   ; 4 hexgit per 16 bit word
   push si
.loop1:
   rol dx, 4
   mov si, dx
   and  si, 0000fh
   mov al,[_digits+si]
   mov [di],al
   inc di
   dec cx
   jnz .loop1
   pop si
   sub si, 2 ; Next 16 bit word
   dec bx
   jnz .loop3
   ret
      
ConvertShortHex:   ;-) Nice code snippet by Tomasz Grysztar (flat assembler)
        xor      di, di
.loop2:
        rol      dl,4
        xor      dh, dh
        mov      si,dx
        and      si,1111b
        mov      al,[_digits+si]
        mov      [di+_hexval],al
        inc      di
        dec      cx
        jnz      .loop2
        ret

segment text

_msg0     db 'Usage: HEXDUMPD <filename>',13,10,'$'
_msg1     db 'Error opening file ','$'
_msg2     db 'Error reading file ','$'
_short    db ?
_double   db 13,10,'$'
_hexnum   rb 8
          db '$'
_hexval   rb 2
          db '$'
_digits   db '0123456789ABCDEF'
_space1   db 32,32,'$'
_space2   db 32,'$'
_buffer   rb 16
_len      dw ?
_ptr      dw ?
_handle   dw ?
_count    dw ?
_offset   dd 0
_filename rb 255