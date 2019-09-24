;*******************************************************************************
;                               TAREA 2: EJERCICIO 2
;                          PROGRAMA XOR ENTRE DOS TABLAS
;*******************************************************************************
;
;       UNIVERSIDAD DE COSTA RICA
;       FECHA 19/09/19
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074
;       COREREO: yeisonrodriguezpacheco@gmail.com
;
; Descripcion: Este es un programa que se encarga leer dos tablas, una de mascaras
; guardada en la direccion MASCARAS (se debe leer de manera ascendente) y otra
; de datos almacenada en la direccion DATOS (se lee de maneda descendente). El
; programa calcula la XOR entre la primer mascara y el ultimo dato, luego entre
; la segunda mascara y el penultimo dato, asi sucesivamente. La tabla de mascaras
; termina con el dato $FE y la de datos con el dato $FF. La cantidad de datos de
; las tablas debe ser menor a 1000. Ambas tablas pueden tener distintos tamanos
; Los datos y mascaras son de 1 byte.
; Los resultados de las XOR que den negativos se deben almacenar en la direccion
; NEGAT.
;
; Algunos resultados de XOR utiles para revision del programa:
; 12 XOR 23 = 31
; 00 XOR 47 = 47
; 12 XOR 9a = 88
; f3 XOR 4d = be
; 12 XOR ef = fd
; 34 XOR 23 = 17
; f2 xor 12 = e0
; e3 xor 45 = a6

        ORG $1050
DATOS:     db $45,$12,$34,$12,$f3,$12,$00,$23,$ff

        ORG $1150
MASCARAS:  db $12,$47,$9a,$4d,$ef,$23,$f2,$e3,$f2,$f8,$fc,$fe

        ORG $1300
NEGAT:     ds 100

        ORG $1500
DIR_GUARDADO    ds 2
CONTADOR_DATOS  ds 2
        
        ORG $2000
        LDY #DATOS
        LDD #0
        CLR CONTADOR_DATOS
Contando:
        LDAA 1,Y+
        CMPA #$FF
        BEQ Continuar
        ADDB #1
        BCC Contando     	; Sigue contando si no se levanta el carry
        INC CONTADOR_DATOS 	; incrementa parte alta del contador porque hubo carry
        BRA Contando
Continuar:
        LDY #CONTADOR_DATOS 	; Guardando parte baja del tamano de la tabla DATOS en memoria
        STAB 1,Y
        LDX #MASCARAS 		; X siempre tendra el puntero a datos de mascaras
        LDY #NEGAT    		; Copiando en DIR_GUARDADO de guardado el valor de NEGAT
        STY DIR_GUARDADO
Main_loop:
        LDY #DATOS           	; Cargando valores a utilizar
        LDD CONTADOR_DATOS
        BEQ FIN             	; Ya se opero en toda la tabla de DATOS
        DEY                	; Cargando en A el valor del dato de DATOS
        LDAA D,Y
        LDAB #$FE          	; Verificacion si se llego al final de la tabla de mascaras
        CMPB 0,X
        BEQ FIN            	; Si se llego al final de la tabla de mascaras se acaba el programa
        EORA 0,X             	; Calculo de la XOR, se guarda en A
        INX                	; Se incrementa el puntero de mascaras para en el siguiente ciclo leer la sig
        BMI Guardar        	; Si el resultado de la XOR es negativo, se procede a guardarlo
        BRA Dec_contador      	; Se repite el ciclo
Guardar:
        LDY DIR_GUARDADO   	; Guardando el dato y haciendo DIR_GUARDADO += 1
        STAA 1,Y+
        STY DIR_GUARDADO
Dec_contador:
        LDD CONTADOR_DATOS      ; Decrementando el contador de datos
        SUBD #1                 ; Preguntar a GD
        STD CONTADOR_DATOS
        BRA Main_loop           ; Se repite el ciclo
FIN:
        BRA FIN