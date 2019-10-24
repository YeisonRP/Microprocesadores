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
MEMOR:          DS 1
  ;''''''''''''''''''''''''''''''' Delay Estructuras''''''''''''''''''''''''''''''''''''''
        ORG $1040
LAZO_EXT:          ds 1
LAZO_MED:          ds 1
LAZO_INT:          ds 1

VALOR_EXT:            db 1
VALOR_MED:          db 1
VALOR_INT:          db 1

#include registers.inc

; BORRAR ABAJO
                ORG $1600
LEDS:           ds 1

 ; BORRAR ARRIBA
          
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
        
;borrar below
                movb #$ff,DDRB
                bset DDRJ,$02
                bclr PTJ,$02
                movb #$0f, DDRP
                movb #$0f, PTP
                bset DDRJ,$02
                movb #$01,LEDS
;borrar  above

alw:    JSR MUX_TECLADO        ;Prueba
        movb TECLA,PORTB
        BRA alw
        
; BORRAR ABOVE

;BORRAR BELOW
;*******************************************************************************
;                                SUBRUTINA MUX_TECLADO
;*******************************************************************************
;Descripcion:

MUX_TECLADO:
        MOVB #1, PATRON               ; Inicializacion de variables
        LDAA #$EF
Loop_filas:
        STAA PORTA
        LDAB #10
wait:   DBNE B,wait
        LDAB PATRON
        CMPB #4
        BHI FIN_MUX_TECLADO
        LDAB #3
        BRCLR PORTA,$01,Tecla_encontrada
        DECB
        BRCLR PORTA,$02,Tecla_encontrada
        DECB
        BRCLR PORTA,$04,Tecla_encontrada
        INC PATRON
        lsla
        inca
        BRA Loop_filas
Tecla_encontrada:
        LDAA PATRON
        STAB MEMOR;PSHB     ; G, GT, RD, BR   ,
        LDAB #3
        MUL
        TFR B,A
        LDAB MEMOR;PULB
        SBA
        LDX #TECLAS
        MOVB A,X,TECLA
FIN_MUX_TECLADO:
        RTS

DELAY:
        MOVB VALOR_EXT, LAZO_EXT
Loop_medio:
        MOVB VALOR_MED, LAZO_MED
Loop_corto:
        MOVB VALOR_INT, LAZO_INT
Retardo:
        DEC LAZO_INT      ;4 ciclos
        TST LAZO_INT      ;3 ciclos
        BEQ decre_lazo_medio
        BRA Retardo
decre_lazo_medio:
        DEC LAZO_MED
        TST LAZO_MED
        BEQ decre_lazo_ext
        BRA Loop_corto
decre_lazo_ext:
        DEC LAZO_EXT
        TST LAZO_EXT
        BEQ final
        BRA Loop_medio
final:
        RTS
