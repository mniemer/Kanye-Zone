; #########################################################################
;
;   game.asm - Assembly file for EECS205 Assignment 4/5
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
include game.inc
include keys.inc

include \masm32\include\windows.inc 
include \masm32\include\winmm.inc 
includelib \masm32\lib\winmm.lib  

include \masm32\include\masm32.inc 
includelib \masm32\lib\masm32.lib

include \masm32\include\user32.inc 
includelib \masm32\lib\user32.lib

	
.DATA

    ;; If you need to, you can place global variables here

    SndPath BYTE "Dont_Let_Me_Get_In_My_Zone.wav", 0    ;; sound path

    zoneStr BYTE "zone", 0                                              ;; strings
    gameoverStr BYTE "He's definitely in his zone. Game Over.", 0
    blockedStr BYTE "Blocked! +10", 0
    minuslifeStr BYTE "Minus 1 life! -100", 0

    zoneRect EECS205RECT <?, ?, ?, ?>
    zoneSprite EECS205SPRITE <01400000h, 0c80000h, OFFSET zone, OFFSET zoneRect, ?, ?>
    
    playerSprite EECS205SPRITE <?, ?, ?, ?, ?, ?>
    playerRect EECS205RECT <?, ?, ?, ?>

    kanyeSprite EECS205SPRITE <?, ?, ?, ?, ?, ?>
    kanyeRect EECS205RECT <?, ?, ?, ?>

    enemySpriteArr EECS205SPRITE 7 DUP(<?, ?, ?, ?, ?, 0>)
    enemyRectArr EECS205RECT 10 DUP(<?, ?, ?, ?>)

    game_over DWORD 0
    game_over_angle DWORD 0
    
    enemies_blocked DWORD 0
    active_enemies DWORD 1
    max_enemies DWORD 7

    enemy_speed FXPT 00010000h
    enemy_speed_inc FXPT 00001000h

    score DWORD 0
    fmtStr BYTE "Score: %d", 0
    outStr BYTE 256 DUP(0)

    paused DWORD 0
    pauseStr BYTE "Paused. Press P to resume.", 0

    lives DWORD 5
    plus_one_life DWORD 0
    fmtStr2 BYTE "Lives: %d", 0
    outStr2 BYTE 256 DUP(0)
    
.CODE

GameInit PROC USES ebx esi

    invoke DrawStarField
    invoke BasicBlit, OFFSET zone, 320, 200

    invoke UpdateRect, OFFSET zoneSprite
	
    mov esi, OFFSET playerSprite                        ;; set initial positions
    mov (EECS205SPRITE PTR [esi]).fxptXCenter, 02260000h
    mov (EECS205SPRITE PTR [esi]).fxptYCenter, 015e0000h
    mov (EECS205SPRITE PTR [esi]).ptrBitmap, OFFSET player
    mov (EECS205SPRITE PTR [esi]).ptrRect, OFFSET playerRect
    invoke UpdateRect, esi

    mov esi, OFFSET enemySpriteArr           
    mov edi, OFFSET enemyRectArr
    mov (EECS205SPRITE PTR [esi]).fxptXCenter, 00640000h
    mov (EECS205SPRITE PTR [esi]).fxptYCenter, 00640000h
    mov (EECS205SPRITE PTR [esi]).ptrBitmap, OFFSET kanye_head
    mov (EECS205SPRITE PTR [esi]).ptrRect, edi
    mov (EECS205SPRITE PTR [esi]).active, 1
    mov ebx, enemy_speed
    mov (EECS205SPRITE PTR [esi]).speed, ebx
    invoke UpdateRect, esi

    rdtsc                   ;; random number generator stuff
    invoke nseed, eax

    invoke PlaySound, offset SndPath, 0, SND_FILENAME OR SND_ASYNC OR SND_LOOP  ;;sound

	ret         ;; Do not delete this line!!!
GameInit ENDP


GamePlay PROC USES ebx ecx esi edi

    invoke BlackStarField       ;; start by clearing screen and drawing star field
    invoke DrawStarField

    cmp paused, 1           ;; check if paused, if so skip everything and draw paused screen
    jne NOT_PAUSED
    cmp KeyPress, VK_P      ;; check for unpause (P)
    je UNPAUSE
    invoke DrawStr, OFFSET pauseStr, 200, 300, 0ffh
    jmp SKIP_ALL

UNPAUSE:                    ;; unpause and then execute rest of body
    mov paused, 0
    jmp P_NOT_PRESSED

NOT_PAUSED:                 ;; check for pause (P)
    cmp KeyPress, VK_P
    jne P_NOT_PRESSED
    mov paused, 1
    jmp SKIP_ALL

P_NOT_PRESSED:

    cmp game_over, 0            ;; check for game over, if so skip everything and put on
    je PLAY                     ;; game over screen
    add game_over_angle, 0a000h
    invoke RotateBlit, OFFSET kanye_head, 230, 280, game_over_angle
    invoke RotateBlit, OFFSET jayz_head, 310, 280, game_over_angle
    invoke DrawStr, OFFSET gameoverStr, 150, 225, 0ffh
    invoke DrawStr, OFFSET outStr, 215, 235, 0ffh
    jmp SKIP_ALL

PLAY:
    inc score
    
    invoke BasicBlit, OFFSET zone, 320, 200     ;; start by drawing the zone, score and lives
    invoke DrawStr, OFFSET zoneStr, 305, 195, 0ffh
    push score
    push OFFSET fmtStr
    push OFFSET outStr
    invoke wsprintf
    add esp, 12
    invoke DrawStr, OFFSET outStr, 290, 205, 0ffh
    push lives
    push OFFSET fmtStr2
    push OFFSET outStr2
    invoke wsprintf
    add esp, 12
    invoke DrawStr, OFFSET outStr2, 290, 215, 0ffh


    mov esi, OFFSET playerSprite                ;; update and draw the player sprite
    invoke UpdatePlayerPos, esi
    invoke UpdateRect, esi
    mov ebx, (EECS205SPRITE PTR [esi]).fxptXCenter
    mov ecx, (EECS205SPRITE PTR [esi]).fxptYCenter
    sar ebx, 16
    sar ecx, 16
    mov edx, (EECS205SPRITE PTR [esi]).ptrBitmap
    invoke BasicBlit, edx, ebx, ecx

    mov esi, OFFSET enemySpriteArr
    mov ecx, 0
    jmp COND

LOOP_BODY:                      ;; loop through kanye sprites, draw them if they're active
    mov eax, TYPE enemySpriteArr
    imul ecx
    mov edi, esi
    add edi, eax
    mov ebx, (EECS205SPRITE PTR [edi]).active
    cmp ebx, 0
    jne ACTIVE
    invoke ActivateEnemy, edi, ecx  ;; if not active, activate them

ACTIVE:
    invoke UpdateEnemyPos, edi      ;; update position and rectangles, and then draw
    invoke UpdateRect, edi
    mov eax, (EECS205SPRITE PTR [edi]).fxptXCenter
    mov ebx, (EECS205SPRITE PTR [edi]).fxptYCenter
    sar eax, 16
    sar ebx, 16
    mov edx, (EECS205SPRITE PTR [edi]).ptrBitmap
    invoke BasicBlit, edx, eax, ebx

    ;; check for intersects with the zone, decrement life and score appropriately
    ;; or game over if out of lives

    invoke CheckIntersectRect, OFFSET zoneRect, (EECS205SPRITE PTR [edi]).ptrRect
    cmp eax, 0
    je NO_ZONE_HIT
    sub lives, 1
    sub score, 100
    mov eax, (EECS205SPRITE PTR [edi]).fxptXCenter
    mov ebx, (EECS205SPRITE PTR [edi]).fxptYCenter
    sar eax, 16
    sar ebx, 16
    invoke DrawStr, OFFSET minuslifeStr, eax, ebx, 0ffh
    mov (EECS205SPRITE PTR [edi]).active, 0
    cmp lives, 0
    jg NO_ZONE_HIT
    mov game_over, 1
    jmp SKIP_ALL

NO_ZONE_HIT:                ;; check for kanye/player intersects, deactivate kanyes if they get hit
    mov edx, OFFSET playerSprite
    mov ebx, (EECS205SPRITE PTR [edx]).ptrRect
    invoke CheckIntersectRect, ebx, (EECS205SPRITE PTR [edi]).ptrRect
    cmp eax, 0
    je NO_PLAYER_HIT
    
    mov eax, (EECS205SPRITE PTR [edi]).fxptXCenter
    mov ebx, (EECS205SPRITE PTR [edi]).fxptYCenter
    sar eax, 16
    sar ebx, 16
    invoke DrawStr, OFFSET blockedStr, eax, ebx, 0ffh
    mov (EECS205SPRITE PTR [edi]).active, 0

    inc enemies_blocked         ;; increment enemies blocked by 1, score by 10
    inc plus_one_life
    cmp plus_one_life, 20
    jle DONT_ADD_LIFE
    inc lives
    add score, 50
    mov plus_one_life, 0
DONT_ADD_LIFE:
    add score, 10               ;; every five enemies blocked you get another enemy and speed increases
    mov eax, enemies_blocked
    cmp eax, 5
    jle SKIP_INCREMENTS
    mov eax, active_enemies
    cmp eax, max_enemies
    jge SKIP_ENEMY_INC
    inc active_enemies

SKIP_ENEMY_INC:
    invoke AXP, enemy_speed_inc, 00010000h, 00000500h
    mov enemy_speed_inc, eax
    mov enemies_blocked, 0

SKIP_INCREMENTS:

NO_PLAYER_HIT:
    inc ecx  


COND:                   ;; only loop through/draw number of active enemies
    cmp ecx, active_enemies
    jl LOOP_BODY



SKIP_ALL:

     	ret         ;; Do not delete this line!!!
GamePlay ENDP

UpdatePlayerPos PROC USES esi edi ebx ptrSprite:PTR EECS205SPRITE
;;updates the player position with the mouse
    mov esi, OFFSET MouseStatus
    mov edi, ptrSprite

    cmp MouseStatus.buttons, MK_LBUTTON ;; if left mouse button is pressed,
    jne SKIPTHIS                           ;; put horiz/vert position into ballX/ballY
    mov eax, (MouseInfo PTR [esi]).horiz
    mov ebx, (MouseInfo PTR [esi]).vert

    sal eax, 16
    sal ebx, 16

    mov (EECS205SPRITE PTR [edi]).fxptXCenter, eax
    mov (EECS205SPRITE PTR [edi]).fxptYCenter, ebx

SKIPTHIS:
    ret    
UpdatePlayerPos ENDP

UpdateEnemyPos PROC USES esi ebx ecx edx edi ptrSprite:PTR EECS205SPRITE
    LOCAL dwX:DWORD, dwY:DWORD, neg_speed:FXPT
;;updates the enemy position, they all try to go to the zone
;;also the speed increases over time
    mov esi, ptrSprite
    mov ebx, (EECS205SPRITE PTR [esi]).fxptXCenter
    mov ecx, (EECS205SPRITE PTR [esi]).fxptYCenter
    mov edx, (EECS205SPRITE PTR [esi]).speed

    mov edi, enemy_speed_inc
    invoke AXP, edx, 00010000h, edi
    mov edx, eax

    neg eax
    mov neg_speed, eax

    mov dwX, ebx
    sar dwX, 16
    mov dwY, ecx
    sar dwY, 16
    
    cmp dwX, 300
    jle RIGHTSIDE
    invoke AXP, ebx, 00010000h, neg_speed
    mov ebx, eax
    jmp VERT
    
RIGHTSIDE:
    invoke AXP, ebx, 00010000h, edx
    mov ebx, eax

VERT:
    cmp dwY, 200
    jle TOPSIDE
    invoke AXP, ecx, 00010000h, neg_speed
    mov ecx, eax
    jmp DONE_W_THIS
    
TOPSIDE:
    invoke AXP, ecx, 00010000h, edx
    mov ecx, eax

DONE_W_THIS:
    mov (EECS205SPRITE PTR [esi]).fxptXCenter, ebx
    mov (EECS205SPRITE PTR [esi]).fxptYCenter, ecx
    mov (EECS205SPRITE PTR [esi]).speed, edx

    ret
UpdateEnemyPos ENDP
   


UpdateRect PROC USES ebx ecx edx edi esi ptrSprite:PTR EECS205SPRITE
    LOCAL x:DWORD, y:DWORD, HalfWidth:DWORD, HalfHeight:DWORD
;;updates the rectangles associated with each sprite to check for collisions
    mov edx, ptrSprite     
    mov ebx, (EECS205SPRITE PTR [edx]).fxptXCenter
    mov ecx, (EECS205SPRITE PTR [edx]).fxptYCenter
    mov x, ebx
    mov y, ecx

    sar x, 16
    sar y, 16

    mov edi, (EECS205SPRITE PTR [edx]).ptrBitmap
    mov esi, (EECS205SPRITE PTR [edx]).ptrRect

    mov eax, (EECS205BITMAP PTR [edi]).dwWidth
    mov ebx, (EECS205BITMAP PTR [edi]).dwHeight
    sar eax, 1
    sar ebx, 1
    mov HalfWidth, eax
    mov HalfHeight, ebx

    mov eax, x
    sub eax, HalfWidth
    mov (EECS205RECT PTR [esi]).dwLeft, eax

    mov eax, x
    add eax, HalfWidth
    mov (EECS205RECT PTR [esi]).dwRight, eax

    mov eax, y
    sub eax, HalfHeight
    mov (EECS205RECT PTR [esi]).dwTop, eax

    mov eax, y
    add eax, HalfHeight
    mov (EECS205RECT PTR [esi]).dwBottom, eax
	
    ret
UpdateRect ENDP

ActivateEnemy PROC USES esi edi ecx ptrSprite:PTR EECS205SPRITE, index:DWORD
;;initializes an enemy and a random spot (can be off the screen)
    mov esi, ptrSprite
    invoke RandX
    sal eax, 16
    mov (EECS205SPRITE PTR [esi]).fxptXCenter, eax
    invoke RandY
    sal eax, 16
    mov (EECS205SPRITE PTR [esi]).fxptYCenter, eax
    mov (EECS205SPRITE PTR [esi]).ptrBitmap, OFFSET kanye_head
    mov (EECS205SPRITE PTR [esi]).active, 1
    mov ebx, enemy_speed
    mov (EECS205SPRITE PTR [esi]).speed, ebx

    mov edi, OFFSET enemyRectArr
    mov ecx, index
    mov eax, TYPE enemyRectArr
    imul ecx
    add edi, eax
    mov (EECS205SPRITE PTR [esi]).ptrRect, edi
    
    invoke UpdateRect, esi
    ret

ActivateEnemy ENDP

RandX PROC
;;gets a random starting x position
    invoke nrandom, 2
    cmp eax, 0
    jne OTHERSIDEX
    invoke nrandom, 100
    jmp DONEX

OTHERSIDEX:
    invoke nrandom, 300
    add eax, 500

DONEX:
    ret

RandX ENDP


RandY PROC
;;gets a random starting y position
    invoke nrandom, 2
    cmp eax, 0
    jne OTHERSIDEY
    invoke nrandom, 100
    jmp DONEY

OTHERSIDEY:
    invoke nrandom, 300
    add eax, 300

DONEY:
    ret

RandY ENDP

END
