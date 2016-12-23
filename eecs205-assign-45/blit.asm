; #########################################################################
;
;   blit.asm - Assembly file for EECS205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include blit.inc

.DATA

	;; If you need to, you can place global variables here
	
.CODE


BasicBlit PROC USES ebx ecx edx esi edi ptrBitmap:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD
    LOCAL xFirst:DWORD, yFirst:DWORD, xLast:DWORD, yLast:DWORD

    mov esi, ptrBitmap
    mov eax, (EECS205BITMAP PTR [esi]).dwWidth
    mov ebx, (EECS205BITMAP PTR [esi]).dwHeight

    sar eax, 1
    sar ebx, 1

    mov ecx, xcenter
    mov edx, ycenter

    add ecx, eax
    add edx, ebx

    mov xLast, ecx  ;; Get last point
    mov yLast, edx

    mov ecx, xcenter
    mov edx, ycenter

    sub ecx, eax
    sub edx, ebx

    mov xFirst, ecx ;; Get first point
    mov yFirst, edx
    
    mov edi, (EECS205BITMAP PTR [esi]).lpBytes

    mov ebx, xFirst ;; Put first point into counters (x in ebx, y in ecx)
    mov ecx, yFirst

    jmp OUTER_LOOP_COND_1

OUTER_LOOP_BODY_1:
    mov ebx, xFirst
    jmp INNER_LOOP_COND_1

INNER_LOOP_BODY_1:
    mov eax, (EECS205BITMAP PTR [esi]).dwWidth          ;; Get index of color in lpBytes
    sub ecx, yFirst
    imul ecx
    sub ebx, xFirst
    add eax, ebx
    xor edx, edx
    mov dl, BYTE PTR [edi + eax]
    add ebx, xFirst
    add ecx, yFirst

    xor eax, eax
    mov al, (EECS205BITMAP PTR [esi]).bTransparent
    cmp edx, eax                                        ;; Skip transparent color
    je SKIP_1
    
    invoke Plot, ebx, ecx, edx                          ;; Plot the pixel

SKIP_1:
    inc ebx

INNER_LOOP_COND_1:
    cmp ebx, xLast
    jl INNER_LOOP_BODY_1
    inc ecx

OUTER_LOOP_COND_1:
    cmp ecx, yLast
    jl OUTER_LOOP_BODY_1

	ret    	;;  Do not delete this line!
BasicBlit ENDP

	

RotateBlit PROC USES ebx ecx edx esi edi lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT
    LOCAL cosa:FXPT, sina:FXPT, shiftX:DWORD, shiftY:DWORD, dstWidth:DWORD, dstHeight:DWORD, srcX:DWORD, srcY:DWORD
	
    invoke FixedCos, angle          ;; Calculate cos and sin of angle
    mov cosa, eax
    invoke FixedSin, angle
    mov sina, eax

    mov esi, lpBmp

    mov eax, (EECS205BITMAP PTR [esi]).dwWidth  ;; Set shiftX
    sal eax, 16
    imul cosa
    sar edx, 1         ;; FXPT to DWORD (16), also divide by 2 (1)
    mov ebx, edx

    mov eax, (EECS205BITMAP PTR [esi]).dwHeight
    sal eax, 16
    imul sina
    sar edx, 1         ;; FXPT to DWORD, (16) also divide by 2 (1)
    mov ecx, edx

    sub ebx, ecx
    mov shiftX, ebx

    mov eax, (EECS205BITMAP PTR [esi]).dwHeight ;; Set shiftY
    sal eax, 16
    imul cosa
    sar edx, 1         ;; FXPT to DWORD (16), also divide by 2 (1)
    mov ebx, edx

    mov eax, (EECS205BITMAP PTR [esi]).dwWidth
    sal eax, 16
    imul sina
    sar edx, 1         ;; FXPT to DWORD (16), also divide by 2 (1)
    mov ecx, edx

    add ebx, ecx
    mov shiftY, ebx

    mov eax, (EECS205BITMAP PTR [esi]).dwWidth      ;; Set dstWidth and dstHeight
    mov ebx, (EECS205BITMAP PTR [esi]).dwHeight
    add eax, ebx
    mov dstWidth, eax
    mov dstHeight, eax

    mov edi, (EECS205BITMAP PTR [esi]).lpBytes

    mov ebx, dstWidth       ;; ebx = dstX
    neg ebx
    
    jmp OUTER_LOOP_COND_2
    
OUTER_LOOP_BODY_2:
    mov ecx, dstHeight      ;; ecx = dstY
    neg ecx
    jmp INNER_LOOP_COND_2

INNER_LOOP_BODY_2:
    mov eax, cosa       ;; srcX = dstX*cosa + dstY*sina
    sal ebx, 16
    imul ebx
    sar ebx, 16
    mov srcX, edx
    mov eax, sina
    sal ecx, 16
    imul ecx
    sar ecx, 16
    add srcX, edx

    mov eax, cosa       ;; srcY = dstY*cosa - dstX*sina
    sal ecx, 16
    imul ecx
    sar ecx, 16
    mov srcY, edx
    mov eax, sina
    sal ebx, 16
    imul ebx
    sar ebx, 16
    sub srcY, edx

    cmp srcX, 0         ;; if (srcX >= 0 && srcY >= 0)
    jl SKIP_2
    cmp srcY, 0
    jl SKIP_2
    mov eax, (EECS205BITMAP PTR[esi]).dwWidth   ;; && if (srcX < dwWidth)
    cmp srcX, eax
    jge SKIP_2
    mov eax, (EECS205BITMAP PTR[esi]).dwHeight  ;; && if (srcY < dwHeight)
    cmp srcY, eax
    jge SKIP_2

    mov eax, (EECS205BITMAP PTR [esi]).dwWidth          ;; Get index of color in lpBytes
    imul srcY
    add eax, srcX
    xor edx, edx
    mov dl, BYTE PTR [edi + eax]

    xor eax, eax
    mov al, (EECS205BITMAP PTR [esi]).bTransparent
    cmp edx, eax                                        ;; Skip transparent color
    je SKIP_2

    add ebx, xcenter                                    ;; shift values
    add ecx, ycenter
    sub ebx, shiftX
    sub ecx, shiftY
    
    invoke Plot, ebx, ecx, edx                          ;; Plot it

    add ebx, shiftX                                     ;; shift them back
    add ecx, shiftY
    sub ebx, xcenter
    sub ecx, ycenter
    
SKIP_2:
    inc ecx

INNER_LOOP_COND_2:
    cmp ecx, dstHeight
    jl INNER_LOOP_BODY_2
    
    inc ebx

OUTER_LOOP_COND_2:
    cmp ebx, dstWidth
    jl OUTER_LOOP_BODY_2

	ret  	;;  Do not delete this line!
	
RotateBlit ENDP


CheckIntersectRect PROC USES ebx edi esi one:PTR EECS205RECT, two:PTR EECS205RECT

    mov eax, 1
    
    mov esi, one
    mov edi, two

    mov ebx, (EECS205RECT PTR [esi]).dwRight    
    cmp ebx, (EECS205RECT PTR [edi]).dwRight    ;; Check 1.R and 2.R
    jg CHK_LEFT
    
    cmp ebx, (EECS205RECT PTR [edi]).dwLeft     ;; Check 1.R and 2.L
    jge CHK_TOP_BOTTOM                          ;; If they overlap check top and bottom
    jmp NO_INTERSECT                            ;; If they don't we good

CHK_LEFT:
    mov ebx, (EECS205RECT PTR [esi]).dwLeft    
    cmp ebx, (EECS205RECT PTR [edi]).dwRight    ;; Check 1.L and 2.R
    jle CHK_TOP_BOTTOM                          ;; If they overlap check top and bottom
    jmp NO_INTERSECT                            ;; If they don't we good

CHK_TOP_BOTTOM:
    mov ebx, (EECS205RECT PTR [esi]).dwBottom
    cmp ebx, (EECS205RECT PTR [edi]).dwBottom   ;; Check 1.B and 2.B
    jg CHK_TOP

    cmp ebx, (EECS205RECT PTR [edi]).dwTop      ;; Check 1.B and 2.T
    jge INTERSECT                               ;; If they overlap , intersect
    jmp NO_INTERSECT                            ;; If not, we good

CHK_TOP:
    mov ebx, (EECS205RECT PTR [esi]).dwTop      ;; Check 1.T and 2.B
    cmp ebx, (EECS205RECT PTR [edi]).dwBottom   ;; If they overlap, intersect
    jle INTERSECT


NO_INTERSECT:
    xor eax, eax

INTERSECT:
	ret  	;;  Do not delete this line!
	
CheckIntersectRect ENDP

END
