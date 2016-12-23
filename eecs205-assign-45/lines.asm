; #########################################################################
;
;   lines.asm - Assembly file for EECS205 Assignment 2
;   Matthew Niemer (min168)
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA
;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943           	;;  PI / 2
PI =  205887	            ;;  PI 
TWO_PI	= 411774          ;;  2 * PI 
PI_INC_RECIP =  5340353       ;;  128 / PI   (use this to find the table entry for a given angle
	                        ;;              it is easier to use than divison would be)

	;; If you need to, you can place global variables here

FLIP BYTE 0    ;;set if angle is between pi and 2pi
SCREEN_HEIGHT = 480
SCREEN_WIDTH = 640
	
.CODE
	

FixedSin PROC USES ecx edx angle:FXPT

    cmp angle, 0            ;; check 0 < angle < 2pi
    jl NEGATIVE
    cmp angle, TWO_PI
    jg NOT_ZERO_TO_TWO_PI
    jmp ZERO_TO_TWO_PI

NOT_ZERO_TO_TWO_PI:         ;; mod angle by 2pi if 0 > angle or angle > 2pi
    xor edx, edx
    mov eax, angle
    mov ecx, TWO_PI
    idiv ecx
    mov angle, edx
    jmp ZERO_TO_TWO_PI

NEGATIVE:
    xor edx, edx        ;; dafuq to do here ughh
    neg angle
    mov eax, angle
    mov ecx, TWO_PI
    idiv ecx
    mov angle, edx
    add FLIP, 1
    
ZERO_TO_TWO_PI:
    cmp angle, PI           ;; check pi < angle < 2pi
    jl ZERO_TO_PI
    add FLIP, 1 ;; set if we need to flip later
    sub angle, PI           ;; shift the angle

ZERO_TO_PI:
    cmp angle, PI_HALF      ;; check 0 < angle < pi/2
    jg PI_HALF_TO_PI
    jl ZERO_TO_PI_HALF
    mov eax, 00010000h      ;; if angle = pi/2, return 1
    jmp DONE 

PI_HALF_TO_PI:              ;; shift angle if pi/2 < angle < pi
    mov ecx, PI
    sub ecx, angle
    mov angle, ecx

ZERO_TO_PI_HALF:            ;; use the table if 0 < angle < pi/2
    invoke AXP, angle, PI_INC_RECIP, 0  ;; use axp to get index
    mov ecx, eax
    shr ecx, 16             ;; only take top half of index
    xor eax, eax
    mov ax, [SINTAB + 2*ecx] ;; get value from table
    
    cmp FLIP, 1    ;; flip result if angle was between pi and 2pi
    jne DONE
    xor ecx, ecx
    sub ecx, eax
    mov eax, ecx

DONE:
    mov FLIP, 0     ;; reset this value!
    ret        	;;  Don't delete this line...you need it	
FixedSin ENDP 
	
FixedCos PROC angle:FXPT

    add angle, PI_HALF      ;; just shift angle and call FixedSin
    invoke FixedSin, angle
	ret        	;;  Don't delete this line...you need it		
FixedCos ENDP	

	
DrawLine PROC USES ebx ecx edx esi edi x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
    LOCAL i:DWORD, fixed_inc:FXPT, fixed_j:FXPT

    mov eax, x0
    mov ebx, x1
    mov ecx, y0
    mov edx, y1
    sub ebx, eax    ;; ebx = x1 - x0
    sub edx, ecx    ;; edx = y1 = y0
    invoke Abs, ebx
    mov ebx, eax    ;; ebx = Abx(x1 - x0)
    invoke Abs, edx
    mov edx, eax    ;; edx = Abs(y1 - y0)
    cmp edx, ebx
    jge OUTER_ELSE

    mov eax, x0
    mov ebx, x1
    mov ecx, y0
    mov edx, y1
    sub ebx, eax    ;; ebx = x1 - x0
    sub edx, ecx    ;; edx = y1 - y0

    mov eax, edx
    sar edx, 16
    shl eax, 16
    ;;xor edx, edx
    idiv ebx
    mov fixed_inc, eax  ;; fixed_inc = (y1 - y0)/(x1 - x0)

    mov ebx, x0     ;; ebx = x0
    mov ecx, x1     ;; ecx = x1
    cmp ebx, ecx
    jle FIRST_ELSE
    mov ebx, x1     ;; Swap
    mov ecx, x0     ;; Swap
    mov eax, y1
    shl eax, 16         ;; int to fix
    mov fixed_j, eax    ;; fixed_j = Fixed(y1)
    jmp SKIP_FIRST_ELSE

FIRST_ELSE:
    mov eax, y0
    shl eax, 16         ;; int to fix
    mov fixed_j, eax    ;; fixed_j = Fixed(y0)

SKIP_FIRST_ELSE:
    mov i, ebx
    mov esi, fixed_inc
    jmp FIRST_COND

FIRST_LOOP:
    mov eax, fixed_j
    sar eax, 16         ;; fix to int
    invoke Plot, i, eax, color
    add i, 1            ;; increment i   
    add fixed_j, esi    ;; fixed_j += fixed_inc

FIRST_COND:
    cmp i, ecx
    jle FIRST_LOOP
    jmp DONE



OUTER_ELSE:
    mov eax, y0
    mov ebx, y1
    cmp eax, ebx
    je DONE

    mov eax, x0
    mov ebx, x1
    mov ecx, y0
    mov edx, y1
    sub ebx, eax    ;; ebx = x1 - x0
    sub edx, ecx    ;; edx = y1 - y0

    mov ecx, edx
    mov eax, ebx
    mov edx, ebx
    sar edx, 16
    sal eax, 16
    ;;xor edx, edx
    idiv ecx
    mov fixed_inc, eax  ;; fixed_inc = (x1 - x0)/(y1 - y0)

    mov ebx, y0     ;; ebx = y0
    mov ecx, y1     ;; ecx = y1
    cmp ebx, ecx
    jle SEC_ELSE
    mov ebx, y1     ;; Swap
    mov ecx, y0     ;; Swap
    mov eax, x1
    sal eax, 16         ;; int to fix
    mov fixed_j, eax    ;; fixed_j = Fixed(x1)
    jmp SKIP_SEC_ELSE

SEC_ELSE:
    mov eax, x0
    sal eax, 16         ;; int to fix
    mov fixed_j, eax    ;; fixed_j = Fixed(x0)

SKIP_SEC_ELSE:
    mov i, ebx
    mov esi, fixed_inc
    jmp SEC_COND

SEC_LOOP:
    mov eax, fixed_j
    sar eax, 16         ;; fix to int
    invoke Plot, eax, i, color
    add i, 1            ;; increment i   
    add fixed_j, esi    ;; fixed_j += fixed_inc

SEC_COND:
    cmp i, ecx
    jle SEC_LOOP
    jmp DONE



    DONE:
	ret        	;;  Don't delete this line...you need it
DrawLine ENDP

Plot PROC USES esi ecx x:DWORD, y:DWORD, color:DWORD

    cmp x, SCREEN_WIDTH     ;; Don't draw if out of bounds
    jge SKIP
    cmp x, 0
    jl SKIP
    cmp y, SCREEN_HEIGHT
    jge SKIP
    cmp y, 0
    jl SKIP
    
    mov esi, ScreenBitsPtr  ;; Get the index
    mov eax, SCREEN_WIDTH
    imul y
    add eax, x
    mov ecx, color
    mov BYTE PTR [esi + eax], cl    ;; Plot the point

SKIP:
    ret
Plot ENDP

Abs PROC x:DWORD

    mov eax, x
    cmp eax, 0
    jge DONE
    neg eax
DONE:  
    ret
Abs ENDP

END
