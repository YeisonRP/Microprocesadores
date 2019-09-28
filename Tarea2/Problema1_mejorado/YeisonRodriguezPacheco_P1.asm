;*******************************************************************************
;                               TAREA 2: EJERCICIO 1
;                          PROGRAMA ORDENAR MENOR A MAYOR
;*******************************************************************************
;
;       UNIVERSIDAD DE COSTA RICA
;       FECHA 18/09/19
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074
;       COREREO: yeisonrodriguezpacheco@gmail.com
;
; Descripcion: Este es un programa que se encarga de ordenar un array de numeros
; de un byte ubicados en la direccion ORDENAR, dichos numeros son con signo y
; ademas la longitud del array es menor de 200. Los numeros se ordenan de menor
; a mayor sin tomar en cuenta los ceros. Los datos ordenados se almacenan en un
; array que comienza en la direccion ORDENADOS. La cantidad de datos a ordenar
; se almacena en la variable CANT. Las variables CLEAR y CONTADOR son de un byte
; y se utilizan para poner en 0 el numero ya analizado en una iteracion y para
; llevar la cuenta de cuando se debe detener el programa.
;
;

;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS
;*******************************************************************************
        ORG $1000
CANT:      ds 1          ; Variable tipo byte

CLEAR:     ds 1          ; Variable auxiliar tipo byte. Utilizada para guardar
                         ; una posición a borrar del arreglo ORDENAR.
                         
CONTADOR:  ds 1          ; Variable tipo byte utilizada como contador.

        ORG $1100
ORDENAR:   ds 200        ; Arreglo de numero de 1 byte a ordenar

        ORG $1200
ORDENADOS: ds 200        ; Arreglo que almacena numeros de 1 byte ordenados


;*******************************************************************************
;                              PROGRAMA PRINCIPAL
;*******************************************************************************
        ORG $1500
        
        LDX #ORDENAR
        LDY #ORDENADOS
        CLR CLEAR           ; CLEAR = 0
        LDAA CANT           ; CONTADOR '= CANT - 1
        BEQ FIN             ; Si cant es 0, termina
        DECA
        STAA CONTADOR       ; Contador = CANT -1
Main_loop:
        CLRB                ; B = 0
        LDAA CANT           ; A '= CANT - 1
        DECA
check_next_number:
        TST A,X          ; Es el numero analizado 0?
        BEQ decrementar_contador_interno
        TBEQ B, guardar_num  ; B = 0?
        CMPB A,X    ; Numero actual mayor o igual a numero en memoria?
        BGT guardar_num
        CMPB A,X         ; Numero actual igual a numero en memoria?
        BNE decrementar_contador_interno
        CLR A,X          ; Poniendo numero en memoria igual al actual en 0 para eliminarlo
        BRA decrementar_contador_interno
guardar_num:
        LDAB A,X           ; Guardando numero que es menor al anterior
        STAA CLEAR         ; Guardando posicion de borrado para borrarlo si fue el menor en esta iteracion
decrementar_contador_interno:
        TBEQ A,decrementar_contador_general ; Si ya se leyeron todos los numeros en esta iteracion
        DECA
        BRA check_next_number  ; Se lee el siguiente numero
decrementar_contador_general:
        LDAA CLEAR      ;Limpiando en ORDENAR el numero ya elegido en esta iteracion, para que no se vuelva a elegir
        CLR A,X
        STAB 1,Y+       ; Guardando el numero en ordenados
        DEC CONTADOR
        BEQ FIN
        BRA Main_loop   ; Repetir el ciclo ya que el contador general no ha llegado a 0
FIN:
        BRA FIN

