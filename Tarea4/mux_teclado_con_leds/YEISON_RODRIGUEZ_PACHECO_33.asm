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
STORAGE         DS 1

#include registers.inc


          

        



;*******************************************************************************
;                       DECLARACION VECTORES INTERRUPCION
;*******************************************************************************
        ORG $3e70
        dw RTI_ISR
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---




;*******************************************************************************
;                              PROGRAMA PRINCIPAL
;*******************************************************************************

        ORG $2000
        LDS #$3000
;INICIALIZACION DE HARDWARE:
        ; subrutina mux_teclado
        MOVB #$01,PUCR
        MOVB #$F0, DDRA
        ; subrutina RTI_ISR
        movb #$23,RTICTL        ; n = 3 M = 2
        bset CRGINT,#$80        ; activa rti
        CLI                     ; LO MUEVO DE AQUI TAL VEZ!
;LEDS
;borrar below
                movb #$ff,DDRB
                bset DDRJ,$02
                bclr PTJ,$02
                movb #$0f, DDRP
                movb #$0f, PTP
                bset DDRJ,$02
                LDX #TECLAS

;borrar  above
;INICIALIZACION DE VARIABLES:
        MOVB #$FF,TECLA
        MOVB #$FF,TECLA_IN
        CLR CONT_REB
        CLR BANDERAS
        CLR CONT_TCL
;PROGRAMA PRINCIPAL
M_loop: BRSET BANDERAS,$04,M_loop
        JSR TAREA_TECLADO
        BRA M_loop
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---


;*******************************************************************************
;                             SUBRUTINA TAREA_TECLADO
;*******************************************************************************
TAREA_TECLADO:
        TST CONT_REB
        BNE FIN_TAREA_TECLADO
        JSR MUX_TECLADO
        LDAA #$FF
        CMPA TECLA
        BEQ TECLA_LISTA_TT
        BRSET BANDERAS,$02,TECLA_LEIDA_TT
        MOVB TECLA, TECLA_IN
        BSET BANDERAS,$02       ; TECLA LEIDA = 1
        MOVB #10, CONT_REB
        RTS
TECLA_LEIDA_TT:
        LDAA TECLA
        CMPA TECLA_IN
        BEQ PONER_BANDERA_TCL_LISTA
        MOVB #$FF,TECLA
        MOVB #$FF,TECLA_IN
        BCLR BANDERAS,$01       ; TECLA LISTA = 0
        BCLR BANDERAS,$02       ; TECLA LEIDA = 0
        RTS
PONER_BANDERA_TCL_LISTA:
        BSET BANDERAS,$01       ; TECLA LISTA = 1
        RTS
TECLA_LISTA_TT:
        BRSET BANDERAS,$01,FORM_ARR_TT ; TECLA LISTA = 1?
        RTS
FORM_ARR_TT:
        BCLR BANDERAS,$01       ; TECLA LISTA = 0
        BCLR BANDERAS,$02       ; TECLA LEIDA = 0
        JSR FORMAR_ARRAY
FIN_TAREA_TECLADO:
        RTS

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---


;*******************************************************************************
;                                SUBRUTINA FORMAR_ARRAY
;*******************************************************************************
FORMAR_ARRAY:
        movb TECLA_IN,PORTB
        RTS

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---

;*******************************************************************************
;                                INTERRUPCION RTI_ISR     PROBADA
;*******************************************************************************
RTI_ISR:        BSET CRGFLG,#$80
                TST CONT_REB      ; Si contador de rebotes es 0, no hace nada
                BEQ FIN_RTI_ISR
                DEC CONT_REB      ; decrementando contador de rebotes
FIN_RTI_ISR:
                RTI

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---







;*******************************************************************************
;                                SUBRUTINA MUX_TECLADO        PROBADA
;*******************************************************************************
;Descripcion: Esta subrutina se encarga de leer una tecla del teclado de la
; Dragon 12. Utiliza como variable PATRON que es un contador que cuando es mayor
; a 4 (las filas del teclado) se termina la subrutina porque no se leyo ninguna
; tecla. En caso de que se lea una tecla se retorna en la variable TECLA. Si
; no existia una tecla se retorna un $FF en TECLA.

MUX_TECLADO:
        BSET PUCR,$01
        MOVB #$0F,DDRA
        MOVB #$FF,TECLA
        MOVB #1, PATRON               ; Inicializacion de variables
        LDAA #$FE
Loop_filas:
        LDAB PATRON                                ; Si ya se leyeron las 4 filas, termina
        CMPB #4
        BHI FIN_MUX_TECLADO
        STAA PORTA                                 ; Poniendo en las filas el valor de prueba  (EX,DX,BX,7X)
        LDAB #3
        BRCLR PORTA,$10,Tecla_encontrada           ; Verificando si alguna columna esta en 0
        DECB
        BRCLR PORTA,$20,Tecla_encontrada
        DECB
        BRCLR PORTA,$40,Tecla_encontrada
        INC PATRON                                 ; Aumentando para siguiente iteracion
        LSLA
        INCA                                       ; Desplazando para obtener el siguiente valor en la parte alta del pin A (EX,DX,BX,7X)
        BRA Loop_filas
Tecla_encontrada:                                 ; Analizando cual tecla es Mediante la ecuacion: PATRON*3 - (3-Columna)
        LDAA PATRON
                             ; Esta ecuacion da el indice en el areglo TECLAS
        PSHB                                      ; Guardando para utilizar posteriormente
        LDAB #3
        MUL
        TFR B,A
        PULB
	LDAB #2                                     ; Restaurando de pila
        SBA
        ;LDX #TECLAS                              ; Guardando la tecla en TECLAs
        MOVB A,X,TECLA
        
FIN_MUX_TECLADO:                                 ; Retornando
        RTS

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---
