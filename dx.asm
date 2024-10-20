.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc
includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "DX-BALL",0

;coordonate fereastra
area_width EQU 610 ; latime - x
area_height EQU 480 ; lungime - y
marime dd 0
counter_g dd 0
poz dd 0
pozLat dd 0
i dd 0
area DD 0
counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

;coodronate obstacole
button_x equ 10
button_y equ 20
button_size equ 25

;coordonate minge
button_sizem dd 10
button_xm dd 277
button_ym dd 428

;coordonate paleta
button_sizep dd 40
button_xp dd 260
button_yp equ 450

;cordonate ciocnire verticala
button_xmin dd 5
button_xmax dd 590
button_ymax dd 472
button_ymin dd 5
dr dd 0
stg dd 0
;COORDONATE DREPTUNGHIURI ALBASTRE
vx dd 10,90,180,270,360,450,540, 10,90,180,270,360,450,540,10,90,180,270,360,450,540, 90,180,270,360,450
vx_final dd 60, 140, 230, 320, 410, 500, 590, 60, 140, 230, 320, 410, 500, 590,60,140, 230, 320,410,500,590, 140,230,320,410,500
vy dd 20,20,20,20,20,20,20,60,60,60,60,60,60,60,100,100,100,100,100,100,100, 140,140,140,140,140
vy_final dd 45,45,45,45,45,45,45,85,85,85,85,85,85,85,125,125,125,125,125,125,125,165,165,165,165,165
cont dd 1,1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; COLORARE DREPTUNGHIURI, UMPLERE CU LINII ORIZONTALE
colorare macro  button_x, button_y, button_size,color
local bucla_linie,umplere,afar
	
	mov edx,button_size
	shr edx,1
	mov edi,button_y
	
	;CALCUL MARIME
	mov eax, button_y
	add eax, button_size
	sub eax,edx
	mov marime,eax

	umplere:
	cmp edi, marime
	je afar
	mov eax, edi;eax=y
	mov ebx, area_width
	mul ebx; eax=y*area*width
	add eax, button_x; eax=y*area_width+x
	shl eax,2; eax=(y*area_width+x)*4
	add eax,area;pointer la area
	mov ecx,button_size
	bucla_linie:
	mov dword ptr[eax], color
	add eax,4
	loop bucla_linie
	inc edi
	jmp umplere
	afar:
endm

;COLORARE MINGE - DIMENSIUNE PATRATEL
colorare_minge macro  button_x, button_y, button_size,color
local bucla_linie,umplere,afar
	
	;CALCUL MARIME
	mov edx,button_size
	shr edx,1
	mov edi,button_y
	mov eax, button_y
	add eax, button_size
	mov marime,eax
	
	umplere:
	cmp edi, marime
	ja afar
	mov eax, edi;eax=y
	mov ebx, area_width
	mul ebx; eax=y*area*width
	add eax, button_x; eax=y*area_width+x
	shl eax,2; eax=(y*area_width+x)*4
	add eax,area;pointer la area
	mov ecx,button_size
	bucla_linie:
	mov dword ptr[eax], color
	add eax,4
	loop bucla_linie
	inc edi
	jmp umplere
	afar:
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]; primul argument
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0
	push area
	call memset; initializare cu pixeli albi
	add esp, 12
	jmp afisare
	
evt_click:

;CLICK PE BUTON STANGA
butonStanga:
	pusha
	colorare  button_xp, button_yp, button_sizep, 0 ; colorare cu negru = stergere
	popa
	 
	;INCADRARE CLICK MOUSE IN DREPTUNGHI VERDE - STANGA
	 
	mov eax, [ebp+arg2]
	cmp eax,  button_x-10
	jl button_stanga
	cmp eax,  button_x-10+2*button_size
	jg button_stanga
	
	mov eax,[ebp+arg3]
	cmp eax, 19*button_y
	jl button_stanga
	cmp eax, 19*button_y+2*button_size
	jg button_stanga
	;MODIFIC X-PALETA
	cmp button_xp, 0
	je afisare_paleta
	sub button_xp, 20
;S-A DAT CLICK => MISCAM PALETA SPRE STANGA
button_stanga:
	colorare  button_xp, button_yp, button_sizep,0FF0000h
	;REDESENEZ SI BUTONUL IN CAZ CA TRECE MINGEA PESTE EL
	colorare   button_x-10, 19*button_y, 2*button_size,0008000H
	colorare  55*button_x+9, 19*button_y, 2*button_size,0008000H
	
; ACELASI LUCRU PENTRU BUTON DREAPTA
butonDreapta:
	pusha
	colorare  button_xp, button_yp, button_sizep, 0 ; colorare cu negru = stergere
	popa
	
	;testam daca s-a dat click pe butonul dreapta
	mov eax, [ebp+arg2]
	cmp eax, 55*button_x+9
	jl button_dreapta
	cmp eax, 55*button_x+9+2*button_size
	jg button_dreapta
	
	mov eax,[ebp+arg3]
	cmp eax, 19*button_y
	jl button_dreapta
	cmp eax, 19*button_y+2*button_size
	jg button_dreapta
	 
	;daca am ajuns aici inseamna ca s-a dat click pe butonul din dreapta
	cmp button_xp, 550
	ja afisare_paleta
	add button_xp, 20
	
button_dreapta:
	;REDESENEZ PALETA LA X-PALETA NOU	
	colorare  button_xp, button_yp, button_sizep,0FF0000h
	colorare  55*button_x+9, 19*button_y, 2*button_size,0008000H
	colorare   button_x-10, 19*button_y, 2*button_size,0008000H
	cmp button_xp, 0
	je afisare_paleta

	
;MISCARILE MINGII - COLIZIUNI CU PERETI
minge_miscare:
	; AM DESENAT IN EVT_TIMER MINGEA CU GALBEN
	
	; O DESENEZ CU NEGRU IN MINGE_MISCARE APOI II SCHIMB COORDONATELE
	colorare_minge  button_xm, button_ym, button_sizem, 0 
	
	start_minge:
	
	mov counter,0; LA FIECARE EVT_TIMER REDESENEAZA MINGEA LA POZITII NOI
	;COORDONATE MINGE
	mov ebx, button_xm; x-minge
	mov ecx, button_ym; y-minge
	
	;VERIFIC IN CARE POZITIE TREBUIE DESENATA MINGEA
	cmp poz,7
	je perete_dreapta_jos
	cmp ebx,button_xmin
	jne minge_jos3
	cmp poz,6
	jne minge_jos3
	mov poz,1
	jmp minge_jos
	
	minge_jos3:
	;VERIFIC COLIZIUNEA CU PALETA
	mov eax, button_yp
	sub eax, button_sizem
	sub eax,4
	cmp button_ym,eax
	je verifica
	;VERIFIC DIN CE POZITIE VINE MINGEA
	cmp poz,5
	je minge_sus2
	cmp poz,6
	je minge_jos2
	
	;se loveste de perete dreapta=> o ia spre stanga
	cmp ebx,button_xmax
	ja perete_dreapta
	cmp poz,3
	je perete_dreapta
	
	;se loveste de perete stanga => o ia spre dreapta
	cmp ebx,button_xmin 
	je perete_stanga
	cmp poz,2
	je perete_stanga
	
	;POZ0 => IN SUS SI SPRE STANGA
	cmp poz,1
	je minge_jos
	poz_0:
	mov poz,0
	minge_sus:
	cmp poz,1
	je minge_jos
	sub ebx,8
	sub ecx,8
	mov button_xm,ebx
	mov button_ym,ecx
	cmp button_ym, 4
	je poz_1
	jmp evt_timer
	
	;POZ2 => IN SUS SI SPRE DREAPTA
	poz_2:
	mov poz,5
	minge_sus2:
	cmp poz,6
	je minge_jos2
	sub ebx,8
	sub ecx,8
	mov button_xm,ebx
	mov button_ym,ecx
	cmp button_ym, 4
	je poz_3	
	jmp evt_timer
	
	;POZ3 => IN JOS SI SPRE STANGA
	poz_3:
	mov poz,6
	minge_jos2:
	sub ebx,8
	add ecx,8
	mov button_xm,ebx
	mov button_ym,ecx
	cmp button_xm,3
	je game_over
	mov poz,6
	jmp evt_timer
	
	;POZ_1 => IN JOS SI SPRE DREAPTA
	poz_1:
	mov poz,1
	minge_jos:
	cmp poz,0
	je minge_sus
	add ebx,8
	add ecx,8
	mov button_xm,ebx
	mov button_ym,ecx
	mov eax,button_ymax
	cmp button_ym,eax
	jl evt_timer
	mov poz,0 
	jmp start_minge
	
	;VERIFIC DACA S-A CIOCNIT DREAPTA
	perete_stanga:
	cmp ecx,button_ymin
	jg ok_stanga
	mov poz,1
	jmp minge_jos
	cmp ecx,button_ymax
	jne ok_stanga
	mov poz,0
	jmp start_minge
	
	;SCHIMB DIRECTIA SPRE STANGA
	ok_stanga:
	add ebx,8
	sub ecx,8 
	mov button_xm,ebx
	mov button_ym,ecx
	mov poz,2 
	jmp evt_timer
	
	;VERIFIC DACA S-A CIOCNIT STANGA
	perete_dreapta:
	cmp ecx,button_ymax
	jl ok_dreapta
	mov poz,0
	jmp start_minge
	
	;SCHIMB DIRECTIA SPRE DREAPTA
	ok_dreapta:
	cmp ebx,592
	ja intoarcere
	add ebx,8
	sub ecx,8
	mov button_xm,ebx
	mov button_ym,ecx
	mov poz,3
	jmp evt_timer
	intoarcere:
	cmp poz,1
	je poz_7
	mov poz,5
	jmp evt_timer
	
	;VERIFIC COLIZIUNE PALETA
	verifica:
	mov esi, button_xp
	mov edi, button_xp
	add edi, button_sizep
	cmp button_xm,esi
	jg e_pe_paleta
	jmp game_over
	e_pe_paleta:
	cmp button_xm,edi
	jl verificare_directii_paleta 
	jmp game_over
	
	;VERIFIC DIN CE DIRECTII VINE PE PALETA
	verificare_directii_paleta:
	cmp poz,1
	je ok_dreapta
	cmp poz,6
	je poz_0
	cmp poz,7
	je poz_0
	
	;POZ7 => IN JOS SI SPRE STANGA
	poz_7:
	mov poz,7
	perete_dreapta_jos:
	sub ebx,8
	add ecx,8
	mov button_xm,ebx
	mov button_ym,ecx
	cmp button_ym,430
	ja minge_jos3
	jmp evt_timer
	
	
evt_timer:
	
	;LA FIECARE EVT_TIMER REDESENEZ MINGEA CU GALBEN
	colorare_minge button_xm, button_ym, button_sizem, 0FFD700h
	
	;COORDONATE MINGE
	mov eax,button_xm
	mov ebx,button_ym
	
	;VERIFICARE ATINGERE MINGE DE OBSTACOLE
	mov esi,0
	spargere:
	cmp esi,26
	ja mai_departe
	cmp eax, vx[4*esi]
	jb next
	cmp eax, vx_final[4*esi]
	ja next
	cmp ebx, vy[4*esi]
	jb next
	cmp ebx, vy_final[4*esi]
	ja next
	cmp cont[4*esi],1
	je sterg
	
	next:
	inc esi
	jmp spargere
		
	mai_departe:
	inc counter
	cmp counter, 2
	je minge_miscare
	jmp final_draw
	
	;SPARGERE OBSTACOLE
	sterg:
	colorare vx[4*esi], vy[4*esi], 50, 0
	mov cont[4*esi],0
	mov poz,1
	inc counter
	cmp counter, 2
	je minge_miscare
	jmp final_draw
	
afisare:
	
	;DESENARE PATRATE ALBASTRE CU BUCLA
	;COORDONATE RETINUTE IN VECTORI
	mov esi,0
	obstacole:
	cmp esi,25
	ja am_desenat
	colorare vx[4*esi], vy[4*esi], 50 ,00000FFh
	inc esi
	jmp obstacole
	
	am_desenat:
	colorare  button_x-10, 19*button_y, 2*button_size,0008000H; BUTON STANGA
	colorare  55*button_x+9, 19*button_y, 2*button_size,0008000H; BUTON DREAPTA
	
	afisare_paleta:
	colorare  button_xp, button_yp, button_sizep,0FF0000h; PALETA
	
	jmp final_draw

game_over:

	; DACA MA AFLU IN AFARA PALETEI => GAME OVER
	make_text_macro 'G', area, 230, 280
	make_text_macro 'A', area, 240, 280
	make_text_macro 'M', area, 250, 280
	make_text_macro 'E', area, 260, 280
	make_text_macro 'O', area, 300, 280
	make_text_macro 'V', area, 310, 280
	make_text_macro 'E', area, 320, 280
	make_text_macro 'R', area, 330, 280
	jmp evt_timer

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2; inmul 4 - pe doubleword
	push eax
	call malloc;aloca memorie zona de desenat 
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	
	push offset draw;procedura principala
	push area;zona desenare
	push area_height
	push area_width;
	push offset window_title; titlu
	call BeginDrawing;
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start