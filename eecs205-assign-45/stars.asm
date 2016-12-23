; #########################################################################
;
;   stars.asm - Assembly file for EECS205 Assignment 1
;   Matthew Niemer (min168)
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include stars.inc

.DATA

	;; If you need to, you can place global variables here

.CODE

DrawStarField proc USES ecx edx

	;; Place your code here

invoke DrawStar, 100, 100
invoke DrawStar, 25, 431
invoke DrawStar, 458, 231
invoke DrawStar, 477, 163
invoke DrawStar, 575, 394
invoke DrawStar, 405, 239
invoke DrawStar, 541, 470
invoke DrawStar, 83, 144
invoke DrawStar, 507, 411
invoke DrawStar, 245, 94
invoke DrawStar, 40, 259
invoke DrawStar, 356, 936
invoke DrawStar, 92, 86
invoke DrawStar, 163, 336
invoke DrawStar, 594, 76
invoke DrawStar, 350, 394
invoke DrawStar, 293, 205
invoke DrawStar, 394, 39
invoke DrawStar, 451, 432
invoke DrawStar, 141, 130
invoke DrawStar, 218, 445
invoke DrawStar, 487, 211
invoke DrawStar, 362, 321
invoke DrawStar, 599, 252

	ret  			; Careful! Don't remove this line
DrawStarField endp


AXP	PROC USES ecx edx a:FXPT, x:FXPT, p:FXPT

	;; Place your code here
mov eax, a  ;; eax gets a
mov ecx, x  ;; ecx gets x
imul ecx    ;; multiply them together

shr eax, 16 ;; get lower half of eax
shl edx, 16 ;; get upper half of edx
or eax, edx ;; concatenate them, result in eax

add eax, p  ;; add p to eax
	
	ret  			; Careful! Don't remove this line	
AXP	endp

	

END
