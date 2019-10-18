;*******************************************************************************
;                                 TAREA 4
;                            TECLADO MATRICIAL
;*******************************************************************************
;
;       UNIVERSIDAD DE COSTA RICA
;       FECHA 17/10/19
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074
;       COREREO: yeisonrodriguezpacheco@gmail.com
;
;
; Descripcion:



;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS
;*******************************************************************************
; Tabla para accesar los datos del teclado.

; TECLA = FF           la subrutina  mux_teclado devuelve la tecla aqui
; TECLA INICIAL = FF   despues de leer rebotes se compara tecla inicial con tecla para saber si no era ruido y si era la misma tecla
; MAX_TCL     CONSTANTE              La cantidad de teclas que se van a leer  (longitud)
; NUM_ARRAY = Array de numeros que devuelve la subrutina tarea teclado
; CONT_REB = 0  ; es un contador de rebotes, se inicialza en 00
; TCL_LEIDA = ES UNA BANDERA, SI ES 1 LA TECLA YA SE LEYO
; TCL_LISTA   ; BANDERA PARA SABER QUE LA TECLA YA SE LEYO Y ERA VALIDA DESPUES DE LOS REBOTES
; CONT_TECLA es para contar cuantas teclas se han leido ya, y saber si se llego a MAX_TCL


; Subrutina RTI se pregunta si el contador de rebotes esta en 0, si esta en 0 retorna, sino lo decrementa en 1 y retorna

; Subrutina tarea teclado resuelve toda la lectura de las teclas, Tarea teclado devuelve a quien la llame una secuencai completa de teclas
; Es como el segundo main.
;
;

        ORG $1000
MAX_TCL:        db $03      ;Cantidad de teclas que se van a leer  (longitud)
TECLA:          ds 1
TECLA_IN:       ds 1
CONT_REB:       ds 1
CONT_TCL:       ds 1
PATRON:         ds 1
BANDERAS:       ds 1        ; X:X:X:X:X:ARRAY_OK:TLC_LEIDA:TCL_LISTA
NUM_ARRAY:      ds 6
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E

#include registers.inc

          
;*******************************************************************************
;                              PROGRAMA PRINCIPAL
;*******************************************************************************

        ORG $2000
        LDS #$3BFF
;INICIALIZACION DE HARDWARE:
        ; subrutina mux_teclado
        MOVB #$01,PUCR
        MOVB #$F0, DDRA
        ; subrutina
;INICIALIZACION DE VARIABLES:
        MOVB #$FF,TECLA
        MOVB #$FF,TECLA_IN
        CLR CONT_REB
        CLR BANDERAS
        CLR CONT_TCL

;*******************************************************************************
;                                SUBRUTINA MUX_TECLADO
;*******************************************************************************


;*******************************************************************************
;                                SUBRUTINA MUX_TECLADO
;*******************************************************************************
;Descripcion:

MUX_TECLADO:
        MOVB #$FF,TECLA
        MOVB #1, PATRON               ; Inicializacion de variables
        LDAA #$EF
Loop_filas:
        LDAB PATRON                                ; Si ya se leyeron las 4 filas, termina
        CMPB #4
        BHI FIN_MUX_TECLADO
        STAA PORTA                                 ; Poniendo en las filas el valor de prueba  (EX,DX,BX,7X)
        LDAB #3
        BRCLR PORTA,$01,Tecla_encontrada           ; Verificando si alguna columna esta en 0
        DECB
        BRCLR PORTA,$02,Tecla_encontrada
        DECB
        BRCLR PORTA,$04,Tecla_encontrada
        INC PATRON                                 ; Aumentando para siguiente iteracion
        ASLA                                       ; Desplazando para obtener el siguiente valor en la parte alta del pin A (EX,DX,BX,7X)
        BRA Loop_filas
Tecla_encontrada:                                 ; Analizando cual tecla es Mediante la ecuacion: PATRON*3 - (3-Columna)
        LDAA PATRON                               ; Esta ecuacion da el indice en el areglo TECLAS
        PSHB                                      ; Guardando para utilizar posteriormente
        LDAB #3
        MUL
        TFR B,A
        PULB                                      ; Restaurando de pila
        SBA
        LDX #TECLAS                              ; Guardando la tecla en TECLAs
        MOVB A,X,TECLA
FIN_MUX_TECLADO:                                 ; Retornando
        RTS


