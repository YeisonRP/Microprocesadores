;*******************************************************************************
;                               TAREA 2: EJERCICIO 3
;                          PROGRAMA ORDENAR MENOR A MAYOR
;*******************************************************************************
;
;       UNIVERSIDAD DE COSTA RICA
;       FECHA 19/09/19
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074
;       COREREO: yeisonrodriguezpacheco@gmail.com
;
; Descripcion: Este programa se encarga de guardar numeros con signo de 1 byte
; que sean divisibles por 4 en la direccion DIV4. Los datos se leen de la
; direccion DATOS y su longitud se encuentra en la variable L de 1 byte. Se debe
; almacenar en la variable CANT4 la cantidad de numeros divisibles por 4 encon-
; trados. Los punteros indices X y Y solo se pueden modificar al inicio del
; programa
;
;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS
;*******************************************************************************
        ORG $1000
L:               ds 1     ; Variable tipo byte. Es el tamano del arreglo

CANT4:           ds 1     ; Variable tipo bye. Se almacena en esta variable la
                          ; cantidad de numero divisibles por 4 encontrados
                          
AUX:             ds 1     ; Variable tipo byte que almacena el dato que se puede
                          ; o no guardar, dependiendo si es mult de 4.

        ORG $1100
DATOS:              ds 254 ; Array que contiene los datos de 1 byte con signo a
                           ; analizar

        ORG $1200
DIV4:               ds 254 ; Array que contiene los numeros divisibles por 4,
                           ; tambien de 1 byte

;*******************************************************************************
;                              PROGRAMA PRINCIPAL
;*******************************************************************************
        ORG $1300
        LDX #DATOS      ;Inicializando punteros que no se van a cambiar NUNCA
        LDY #DIV4
        CLR CANT4       ; Borrando lo que tenga CATN4
        CLRB            ; B = 0
        TST L           ; Si la longitud es 0, termina el programa
        BEQ FIN
Main_Loop:
        LDAA B,X        ; Cargando el numero del array a analizar
        STAA AUX        ; Guarda el numero en una variable auxiliar
        BRCLR AUX,%00000011,Guardar_numero ;Viendo si los dos bits LSB son 0
        BRA Aumentar_contador              ; Si no son 0, se continua.
Guardar_numero:
        LDAA CANT4      ; Para hacer direccionamiento indexado con acumulador
        INC CANT4       ; Cantidad de numeros encontrados + 1
        MOVB AUX, A,Y   ; Guardando el numero en el arreglo DIV4
Aumentar_contador:      ; Aumenta contador y verifica si ya se analizo todo.
        INCB
        CMPB L
        BNE Main_Loop
FIN:
        BRA FIN
