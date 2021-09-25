; Новый проект masm32 успешно создан
; Заполнен демо программой «Здравствуй, мир!»
.386
.model flat, stdcall
option casemap :none
include includes\masm32.inc
include includes\kernel32.inc
include includes\macros\macros.asm
include includes\msvcrt.inc
includelib includes\msvcrt.lib
includelib includes\masm32.lib
includelib includes\kernel32.lib
.data
endl 		db 0dh, 0ah, 0 ;символы конца строки
s1			db 'sha vse buit',0 ;просто сообщение, прикол
pos			dd 0 
hei 		dd 0 ; высота ихображения
wid 		dd 0 ;ширины изобпвжения
;setup 		db ' .:;+=xX$&',0  ;градиент символов
setup 		db ' &$Xx=-:. ',0  ;градиент символов
file 		dd 0
fileready 	dd 0
hkoef 		dd 2
wkoef		dd 1
setupLength dd 9d
kostil		dd 0

path db 'D:\unnamed.bmp',0
mode db 'r+b',0
outpath db 'D:\unnamed.txt',0

.code


start:
	

	invoke crt_printf,offset s1 ;пишем херню

	
	
	invoke crt_fopen, offset path, offset mode ;open file, eax = pointеr
	mov esi, eax ;та херня возвращает FILE, открываем поток файла
	    
    invoke crt_fseek, esi, 0, 2 ;указатель по файлу в конец
    invoke crt_ftell, esi		;узнаем, где указатель
    mov ebx, eax 			;теперь знаем длину файла, сохраним ее в Б
    invoke crt_fseek, esi, 0, 0	; возвращаем указатель по файлу в начало
   
   invoke HeapCreate,1,0,0	;получение дескриптора кучи
   add ebx, 1024d 				;там в начале кучи какой-то муссор, нужно с запасом. Т.е. к длине файла, что гаъодится в Б добавляем херни 
   invoke HeapAlloc,eax,1,ebx	;непосредственно получаем место под наше дерьмо!
	mov edx, offset file
	mov [edx], eax			;file теперь ссылается на кучу

;не дают мне работать. Черти

    invoke crt_fread, eax, 1d, ebx, esi ; read file
    invoke crt_ferror, esi	;зачем-то чекаем на наличие ошибок
	invoke crt_fclose, esi	;закрываем поток файла
    
    mov edx, file ;дублируем ссылку на начала файла (в памяти в едх)
    
	mov ebx, edx	;еще дублируем в ебх
    add ebx, [edx+10]	;в бмп файле, смещение самой картинки от начала файла сненено на 10 байт от начала фалйа
						;по этому к адрессу начала файла добавляем то, что находится на адресс фалйа+10
	mov eax, offset pos
	mov [eax], ebx
	; поместили позицию начала изображения в pos
	
	;mov pos, ebx - а почему я так не сделал? Ладно, трогать не буду. Тяжело писать код с перерывом в пол года
    
    
    mov ebx, [edx+18] ;по аналогии со смещением картинки, ширина на 18
    mov eax, offset wid
	mov [eax], ebx
    ; поместили ширину в вид  
    mov ebx, [edx+22] ;высота на 22
    mov eax, offset hei
	mov [eax], ebx
       ;поместили высоту в хеи
      
	  call to1byte ;процедура группирует 3 байта в 1. Т.е. из трех цветных каналов, делает 1 серый
					
      call toAcii ;а теперь все эти серые конвертим в аски соответсвие

				;осталось записать
	invoke crt_fopen, offset outpath, offset mode 
	mov edi, eax
	;теперь переписываем запись. БРУУУХ
	;хорошо бы вынести сжатие в отденый процес, а запись сразу по строчкам. Ибо
	;каждый символ в обвертке write, и это все в цикле. Кароче оптимизации труба
	;но мы тут ведь только ради изи блоксхемы))0))0
	
	;invoke crt_fwrite, edi, 1d, 1d, kostil
	;invoke crt_fflush, kostil
	;invoke crt_fclose, kostil
	mov ebp, esp
	sub esp, 24d
	mov eax, hei
	dec eax
	mov [ebp-4], dword ptr 0 ; -4 == i
	mov [ebp-8], eax ; -8 == hei
	mov eax, wid
	;dec eax
	mov [ebp-0ch], dword ptr 0 ; -0ch == j
	mov [ebp-10h], eax ; -10h == wid
	mov esi, fileready
	
	; addr = i*wid+j + fileready (esi)
	; addr = -4 mul -10h add -0ch add esi
	;if i % hkoef != 0 -> i++
	;if j % wkoef != 0 -> j++
	; le go
	
	
	loopwi:
	
	mov [ebp-0ch], dword ptr 0						; j = 0
	loopwj:
	
	
	
	
	mov eax, [ebp-0ch]
	mov ebx, wkoef
	cdq 
	div ebx
	test edx, edx
	
	jnz nokj
	
	xor edx, edx
	mov eax, [ebp-4]
	mul dword ptr [ebp -10h]
	add eax, [ebp-0ch]
	add eax, esi
	invoke crt_fwrite, eax, 1d, 1d, edi
	
	
	nokj:
	inc dword ptr [ebp-0ch] 	;j++
	mov eax, [ebp-0ch]		
	cmp eax, [ebp-10h]			;j-wid
	jl loopwj					; j < wid -> omt
	
	invoke crt_fwrite, offset endl, 1d, 1d, edi 	;cout << endl
	
	omti:
	mov eax, [ebp-4]
	mov ebx, hkoef
	cdq 
	div ebx
	test edx, edx
	jz oki
	
	inc dword ptr [ebp-4]
	jmp omti
	
	
	oki:
	
	
	
	inc dword ptr [ebp-4]
	mov eax, [ebp-4]
	cmp eax, [ebp-8]
	jl loopwi
	
	
	
exit


toAcii proc
		push ebp
		mov ebp, esp
		pushad
	
	aaa
	
	mov eax,  hei
	mov ebx,  wid
	mul ebx
			;TODO test for edx
	mov ecx, eax
	
	xor edi, edi
	mov edi, fileready
	
	foropa:
	mov eax, setupLength	;в еаикс длина градиента
	xor ebx, ebx 			;очищаем ебикс
	mov bl, [edi]		;помещаем байт цвета

	mul ebx				; умножаем наш хер на длину градиента
	mov ebx, 255d			
	div ebx				;делим на макс значение и получаем номер символа
						;он в еах
	cmp edx, 123d
	jl notPulsOneOfTwo	;кароч если остаток меньше половины
	inc eax				;то скипаем +1
	notPulsOneOfTwo:	;а если нет - то апаем. Кароче так надо
						;округление в общем
	
	mov ebx, offset setup	;помещаем в ебикс адресс на наш градиент
	add ebx, eax			;сдвигаем на нужный символ
	
	mov bl, [ebx]			;записываем наш символ
	mov [edi], bl		;записываем символ туда, где был пиксель
	inc edi					;смещаемся на 1 байт вперед
	dec ecx					;уменьшаем счетчик
	jnz foropa
		
	popad
	pop ebp
	ret 0
toAcii endp


to1byte proc
push ebp
		mov ebp, esp
		
		
		

	
	
	mov ecx, hei
	
	xor edx, edx
	mov eax, wid
	mov ebx, 4
	div ebx
	push edx		;ebp-4 == nehvatka
	
	
	
	
	
	
	
	mov ebx, hei
	xor edx, edx
	mov eax, wid
	mul ebx
	mov ebx, eax
	; now in ebx image pixel size
	
	 invoke HeapCreate,1,0,0	;получение дескриптора кучи
	 add ebx, 1024d 				;там в начале кучи какой-то муссор, нужно с запасом. Т.е. к длине файла, что гаъодится в Б добавляем херни 
     invoke HeapAlloc,eax,1,ebx	;непосредственно получаем место под наше дерьмо!
     mov fileready, eax
     mov edi, eax
     
;нам нужен нормальный цикл. Я устал 7-й раз эту часть переписывать	
	push pos 			;ebp-8 == start image data
						
    push dword ptr 0     ;ebp-12 == j
    mov eax, wid
    shl eax, 1
    add eax, wid
    push eax 			;ebp-16 == wid*3
    mov ecx, hei
    dec ecx				;ecx == hei-1
    
    
    
    ;for(int i=hei-1; i>0; --i){
    ;	for(int j=0; j<wid*3; j+=3){
    ;		   to[index]=from[i*(wid*3+nehvatka)+j] + =//=(+1) + =//=(+2)
	;		   to[index++]/=3;
	;  }
	;}
	
	;edi == index
	
	lupI:
		;и так. Починили смещение и вертикальную ориентацию. Только теперь чет цвета по трубе пошли
		mov dword ptr [ebp-12], 0
		lupJ:
		xor eax, eax
		xor edx, edx
		mov eax, [ebp-16]	;wid*3
		add eax, [ebp-4]	;+nehvatka
		mul ecx				; *i
		add eax, [ebp-12]	;+j
		mov esi, eax	
		add esi, [ebp-8]
		xor eax, eax
		xor ebx, ebx
		mov al, [esi]		;first byte
		mov bl, [esi+1]	;second
		add eax, ebx
		mov bl, [esi+2]	;third
		add eax, ebx
		cdq					;eax = edx:eax
		mov ebx, 3
		div ebx				; /3
		xor edx, edx
		mov [edi], al		;to new
		inc edi				;index++
		
		add dword ptr [ebp-12], 3
		mov eax, [ebp-12]
		cmp eax, [ebp-16]
		jl lupJ
		
		
		
		loop lupI
	add esp, 16
	
	aaa
	
	pop ebp
	ret 0
      to1byte endp
      
      
  end start