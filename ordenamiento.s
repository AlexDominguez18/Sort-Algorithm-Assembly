;variables y constantes

section .data  
;Constantes
LF equ 10
NULL    equ 0
;Entrada consola
STDIN   equ 0
STDOUT  equ 1
STDERR  equ 2
EXIT_SUCCESS equ 0
;Modos de archivo
SYS_read    equ 0
SYS_write   equ 1
SYS_open    equ 2
SYS_close   equ 3
SYS_exit    equ 60
SYS_creat   equ 85
;Banderas de archivos
O_CREAT     equ 0x40
O_TRUNC     equ 0x200
O_APPEND    equ 0x400
O_RDONLY    equ 000000q
O_WRONLY    equ 000001q
O_RDWR      equ 000002q
S_IRUSR     equ 00400q
S_IWUSR     equ 00200q
S_IXUSR     equ 00100q

;Definicion de variables
decena              dw 10
nombreArchivo       db "numeros.txt", NULL
archivoResultados   db "resultados.txt", NULL
msjErrorAbrir       db "Error abriendo el archivo.", LF, NULL
msjErrorLeer        db "Error leyendo el archivo.", LF, NULL
msjErrorEsc         db "Error escribiendo el archivo", LF, NULL
descArchivo         dq 0
descResultados      dq 0

contNumero      db 0
numeroTemp      db 0
numeroActual    db 0,0,0
charActual      db 0
arraySize       db 10
residuo         db 0
separador       db 10

;Reserva de memoria
section .bss 
numerosLeidos   resb  12

;codigo
section .text 
global main

main:
    ;El protocolo de la pila
    push rbp
    mov rbp, rsp
    ;Limpiando registros
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx

abrirArchivo:
    ;Apertura en modo lectura del archivo numeros.txt
    mov rax, SYS_open
    mov rdi, nombreArchivo
    mov rsi, O_RDONLY
    syscall 
    ;Validando apertura del archivo
    cmp rax, 0
    jl errorAlAbrir
    ;Recuperacion del descriptor de archivo
    mov qword[descArchivo], rax

crearArchivo:
    ;Creacion del archivo resultados.txt
    mov rax, SYS_creat 
    mov rdi, archivoResultados
    mov rsi, S_IRUSR | S_IWUSR
    syscall 
    ;Validando apertura del archivo
    cmp rax, 0
    jl errorAlAbrir
    ;Recuperacion del descriptor del archivo
    mov qword[descResultados], rax
    ;Almacenando los indices de los arreglos correspondientes
    lea rsi, [rel numeroActual]
    lea rdi,[rel numerosLeidos]

leerCharArchivo:
    push rsi ;Guardar valor del indice de numeroActual
    push rdi ;Guardar valor del indice de numerosLeidos
    
    ;Lectura del archivo
    mov rax, SYS_read
    mov rdi, qword[descArchivo]
    mov rsi, charActual
    mov rdx, 1
    syscall
    
    pop rdi ;Recuperar el valor del indice de numeroActual
    pop rsi ;Recuperar el valor del indice de numerosLeidos
    
    ;Validando lectura del archivo
    cmp rax, 0
    jl errorAlLeer

    jmp checarNumero

checarNumero:
    mov al, byte [charActual]
    ;Validando que el caracter leido no sea ':'
    cmp al, 0x3A
    je convertirNumero
    ;Validando que el caracter leido no sea un salto de linea
    cmp al, LF
    je convertirNumero
    ;Guardar en el el arreglo de 'numeroActual'
    mov byte [rel rsi], al
    inc rsi ;Incrementamos el indice del arreglo de 'numeroActual'
    jmp leerCharArchivo
    
convertirNumero:
    dec rsi
    ;Validamos si el numeor leido se trata de una unidad o decena
    cmp byte [rel contNumero], 1
    je mulDecena
    inc byte [rel contNumero]
    xor al, al
    ;Guardar el valor de numeroActual
    mov al, byte [rsi] 
    sub al, 0x30  ;Obtener valor numerico
    ;Validando si solo se lee un numero de un digito
    cmp rsi, numeroActual
    je esUnDigito
    add byte [rel numeroTemp], al ;Guardamos el valor numerico
    jmp convertirNumero
    esUnDigito:
    mov byte [rdi], al
    inc rdi
    ;Reseteo de indice y contadores
    mov byte [rel numeroTemp], NULL
    mov byte [rel contNumero], NULL
    lea rsi, [rel numeroActual]
    jmp leerCharArchivo

mulDecena:
    xor al, al
    mov al, byte [rsi] ;Obtenemos el valor del arreglo en el indice
    sub al, 0x30       ;Obtenermos el valor numerico
    xor rbx, rbx
    mov bl, byte [decena]
    mul bl                          ;Multiplicamos por 10 para obtener el valor de la decena
    add al, byte [rel numeroTemp]   ;Sumamos el valor de la decena con el de la unidad
    mov byte [rdi], al              ;Guardamos el valor final en el arreglo 'numerosLeidos'
    inc rdi                         ;Incrementamos el indice del arreglo 'numeroActual'
    ;Reseteo de indice y contadores
    mov byte [rel numeroTemp], NULL
    mov byte [rel contNumero], NULL
    lea rsi, [rel numeroActual]
    ;Validacion para dejar de leer
    cmp byte [charActual], LF
    je ordenamiento
    jmp leerCharArchivo

;Ordenamiento del arreglo capturado
ordenamiento:
    ;Limpiando registros
    xor rdx, rdx
    xor rbx, rbx
    xor rcx, rcx
    xor rax, rax
    ;Inicializando contador de 'i' en la longitud del arreglo-1
    mov dl, byte [rel arraySize]

    for_i:
        ;Inicializando contador de 'j' en la longitud del arreglo-1
        mov cl, byte [rel arraySize]
        ;Recuperando la primera posicion del arreglo de 'numerosLeidos'
        lea rsi, [rel numerosLeidos]

        for_j:
            mov al, byte [rel rsi]
            ;Comparamos si arr[i] < arr[i+1]
            cmp al, byte [rel rsi+1]
            jl esMenor
            ;Intercambiasmos el valor de arr[i] por el valor de arr[i+1] 
            mov bl, al
            mov al, byte [rel rsi+1]
            mov byte [rel rsi], al
            mov byte [rel rsi+1], bl
        esMenor:
            ;Incrementamos el indice del arreglo de 'numerosLeidos'
            inc rsi
            loop for_j
    dec rdx
    jnz for_i
    jmp escribirResultados

escribirResultados:
    ;Reseteo del contador auxiliar
    mov byte [contNumero], 0
    add byte [rel arraySize], 1 ;Incrementamos el valor en 1 para mostrar todos los numeros
    lea rsi,[rel numerosLeidos] ;Indice inicial de numerosLeidos    
    dividirNumero:
    ;Limpiando los registros
    xor rax, rax
    xor rbx, rbx
    xor rdx, rdx
    mov al, [rel rsi]           ;Almacenamos el valor del arreglo en el indice como dividendo
    mov byte [numeroTemp], al   ;Guardamos el dividendo en una variable auxiliar
    mov bl, byte [decena]       ;Almacenamos como el divisor el 10 para obtener el numero a mostrar
    div bl                      ;Guardamos el residuo en ah y el resultado al
    mov byte [residuo], ah      ;Respaldamos el residuo para la division posterior
    push rsi                    ;Guardamos en la pila el valor del indice de numerosLeidos
    ;Validacion para saber si el residuo es 0 e imprimirlo directamente
    cmp al, NULL
    je imprimirResiduo
    ;Imprimir resultado en consola
    mov byte [charActual], al
    add byte [charActual], 0x30
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, charActual
    mov rdx, 1
    syscall
    ;Escribir resultado en archivo
    mov rax, SYS_write
    mov rdi, qword[descResultados]
    mov rsi, charActual
    mov rdx, 1
    syscall
    ;Limpiamos los registros usados para imprimir y guardar el resultado
    xor rax, rax
    xor rbx, rbx
    xor rdx, rdx
    ;Division del residuo entre la decena
    mov al, byte [residuo]
    mov bl, byte [decena]
    div bl

    imprimirResiduo: 
    mov byte [charActual], ah   ;Residuo asigano al charActual
    add byte [charActual], 0x30 ;Obtenemos el valor ASCII del residuo
    ;Imprimir residuo en consola
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, charActual
    mov rdx, 1
    syscall
    ;Escrbir residuo en el archivo
    mov rax, SYS_write
    mov rdi, qword [descResultados]
    mov rsi, charActual
    mov rdx, 1
    syscall
    ;Imprimir salto linea en consola despues del numero
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, separador
    mov rdx, 1
    syscall
    ;Escribir salto de linea en el archivo despues del numero
    mov rax, SYS_write
    mov rdi, qword [descResultados]
    mov rsi, separador
    mov rdx, 1
    syscall

    pop rsi ;Recuperamos el valor del indice del arreglo 'numerosLeidos'
    inc rsi ;Incrementamos el valod del indice del arrelgo 'numerosLeidos'
    inc byte [contNumero]   ;Incrementamos el contador auxiliar
    mov al, byte [rel contNumero]
    ;Validamos si ya terminamos de recorrer el arreglo
    cmp al, byte [rel arraySize]
    jne dividirNumero

cerrarArchivos:
    ;Cerramos el archivo de los resultados
    mov rax, SYS_close
    mov rdi, qword [descResultados]
    syscall
    ;Cerramos el archivo de numeros
    mov rax, SYS_close
    mov rdi, qword [descArchivo]
    syscall 

final:
    ;El final del protocolo
    pop rbp
    mov rsp, rbp
    mov rax, 60
    mov rdi, 0
    syscall


;Mensajes para validar las interacciones con los archivos

errorAlAbrir:
    mov rdi, msjErrorAbrir
    call imprimirString
    jmp pruebaTerminada

errorAlLeer:
    mov rdi, msjErrorLeer
    call imprimirString
    jmp pruebaTerminada

errorAlEscribir:
    mov rdi, msjErrorEsc
    call    imprimirString

    jmp pruebaTerminada

pruebaTerminada:
    mov rax, SYS_exit
    mov rdi, EXIT_SUCCESS
    syscall

;Funcion para imprimir la cadena de los mensajes de error de los archivos

global imprimirString
imprimirString:
	push	rbp
	mov	rbp, rsp
	push	rbx

; Contamos los caracteres

	mov	rbx, rdi
	mov	rdx, 0
    conteoCharsLoop:
	cmp	byte [rbx], NULL
	je	conteoCharsTerminado
	inc	rdx
	inc	rbx
	jmp	conteoCharsLoop
    conteoCharsTerminado:
	cmp	rdx, 0
	je	parteTerminada

; Imprimimos la cadena

	mov	rax, SYS_write
	mov	rsi, rdi
	mov	rdi, STDOUT

	syscall

   parteTerminada:
	pop	rbx
	pop	rbp
	ret