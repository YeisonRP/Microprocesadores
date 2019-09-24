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
;
        ORG $1000
L:               ds 1
CANT4:           ds 1
AUX:             ds 1
AUX2:            ds 1

        ORG $1100
DATOS:              ds 255

        ORG $1200
DIV4:               ds 255

        ORG $1300
        LDX #DATOS      ;Inicializando punteros que no se van a cambiar NUNCA
        LDY #DIV4
        CLRB            ; B = 0
        CLR CANT4       ; Borrando lo que tenga CATN4
Main_Loop:
        LDAA B,X        ; Cargando el numero del array a analizar
        STAA AUX        ; Guarda el numero en una variable auxiliar, liego se decidira si se guarda o no
        BPL Revi_mult   ; Si el numero es positivo, continua
        COMA            ; Calculando omplemento base 2 del numero negativo
        INCA
Revi_mult:
        STAA AUX2       ; Guardando el numero en una variable auxiliar para hacer BRCLR
        BRCLR AUX2,%00000011,Guardar_numero
        BRA Aumentar_contador
Guardar_numero:
        LDAA CANT4      ; Para hacer direccionamiento indexado con acumulador
        INC CANT4       ; Cantidad de numeros encontrados + 1
        MOVB AUX, A,Y   ; Guardando el numero en el arreglo DIV4
Aumentar_contador:
        INCB
        CMPB L
        BNE Main_Loop
FIN:
        BRA FIN

