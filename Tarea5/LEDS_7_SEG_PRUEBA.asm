

        ORG $1000
MAX_TCL:        db $02      ;Cantidad de teclas que se van a leer  (longitud)
TECLA:          ds 1        ;Tecla leida en un momento t0
TECLA_IN:       ds 1        ;Tecla leida en un momento t1
CONT_REB:       ds 1        ;Contador de rebotes que espera 10ms por la subrutina RTI_ISR
CONT_TCL:       ds 1        ;Contador de teclas que han sido escritas, usada en FORMAR_ARRAY
PATRON:         ds 1        ;Contador que va hasta 5, usado por MUX_TECLADO
BANDERAS:       ds 1        ;X:X:X:MODSEL:CAMBIO_MODO:ARRAY_OK:TLC_LEIDA:TCL_LISTA
                            ; CAMBIO_MODO es para que la pantalla LCD solo se refresque una vez entre cada cambio de modo
                            ; MODSEL. 1 es para modo CPROG, 0 MODO RUN
CUENTA:         ds 1        ; Lleva la cuenta de los tornillos
ACUMUL:         ds 1        ; Contador de empaques procesados, llega a 99 y rebasa hasta 0 al sumarle mas
CPROG:          ds 1        ; Con cuanto se llena una bolsita de tornillos
VMAX:           db 25
; Cuenta maxima a la que llega TIMER_CUENTA (subrutina run)
TIMER_CUENTA:   ds 1        ; Variable utilizada para contar con RTI hasta VMAX (subrutina run)
LEDS:           ds 1        ; LEDS a ser encendidos
BRILLO:         ds 1        ; Brillo de los leds, se sube de 5 en 5. Va de 0 a 100 es la variable K
CONT_DIG:       ds 1        ; Va de 0 a 3 (solo se usan sus dos primero bits) y cuenta
                            ; El digito que se va a encenter
CONT_TICKS:     ds 1        ; Cuenta tiks del Output compare, va de 0 a 100
DT:             ds 1        ; DT = N - K duty cicle
LOW:            ds 1        ; Utilizada por la subrutina BIN_BCD
BCD1:           ds 1        ; Digitos en BCD, los guarda la subrutina BIN_BCD
BCD2:           ds 1
DISP1:          ds 1        ; Los 4 valores de los display que se escriben en PORTB
DISP2:          ds 1
DISP3:          ds 1
DISP4:          ds 1
CONT_7SEG:      ds 2        ; Para hacer que cada 10hz se llame a BCD_7SEG
CONT_DELAY:     ds 1
D2mS:           db 10   ; falta definir valor
D240uS:         db 10   ; falta definir valor
D60uS:          db 10   ; falta definir valor
CLEAR_LCD:      db 10   ; falta definir valor
ADD_L1:         db 10
ADD_L2:         db 10
BIN1:           ds 1     ; No estaban en la declaracion original
BIN2:           ds 1     ; No estaban en la declaracion original

        ORG $1030
NUM_ARRAY:      db $ff,$ff,$ff,$ff,$ff,$ff             ;Guarda los numeros ingresados en el teclado
        ORG $1040
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E ;Tabla de teclas del teclado
        ORG $1050
SEGMENT:       dB $3f,$06,$5b,$4f,$66,$6d,$7d,$07,$7f,$6f
        ORG $1060
iniDsp:         ds 10
        ORG $1070       ; mensajes

#include registers.inc




;*******************************************************************************
;                       DECLARACION VECTORES INTERRUPCION
;*******************************************************************************
        ; Vector interrupcion output compare canal 4
        ORG $3e66
        dw OC4_ISR




;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---




;*******************************************************************************
;-------------------------------------------------------------------------------
;--------------------------------------MAIN-------------------------------------
;-------------------------------------------------------------------------------
;*******************************************************************************

        ORG $2000
        LDS #$3BFF
;INICIALIZACION DE HARDWARE:
        ;subrutina mux_teclado:
        MOVB #$01,PUCR       ;Resistencias pull up
        MOVB #$F0, DDRA      ;Puerto A, parte alta salidas, parte baja entradas

        ;subrutina RTI_ISR:
        movb #$23,RTICTL        ; M = 2 n = 3
        bset CRGINT,#$80        ; activa rti

        ;subrutina PHO_ISR:
        bset PIEH,$01           ; Activando interrupcion PH0

        ;Inicializacion de Output compare canal 4.
        MOVB #$90,TSCR1 ; TEN = 1 , TFFCA = 1. Habilitando modulo timers y el borrado rapido
        MOVB #$00,TSCR2 ; Preescalador = 1
        BSET TIE,$10    ; Habilitando interrupcion output compare canal 4
        BSET TIOS,$10   ; Pone como salida canal 4
        LDD TCNT        ; Inicializa TC4  , esto va mas abajo
        ADDD #480
        STD TC4                   ; se lee puerto PTn bit 4 puerto PTn o PTIT

        ; Inicializacion de Puerto B y P para uso de los display de 7 seg.
        MOVB #$FF,DDRB            ; Todas salidas puerto B (segentos de display)
        MOVB #$0F,DDRP            ; 4 salidas puerto P (activan cada display)
        MOVB #$00, PORTB          ; Apagando sementos
        MOVB #$0F, PTP            ; Apagando los display


;INICIALIZACION DE VARIABLES:
        CLI                     ; Activando interrupciones
        MOVB #$FF,TECLA
        MOVB #$FF,TECLA_IN
        CLR CONT_REB
        CLR BANDERAS
        BSET BANDERAS,$10       ; Poniendo el sistema en modo CONFIG
        CLR CONT_TCL
        ; pantallas
        CLR CUENTA
        CLR ACUMUL
        CLR CPROG
        ; BORRAR ABAJO
        MOVB #50,BRILLO
        MOVB #$FF, DISP1
        MOVB #$FF, DISP2
        MOVB #$FF, DISP3
        MOVB #$FF, DISP4
        MOVW #0,CONT_7SEG
        MOVB #0,CONT_TICKS
        ; BORRAR ARRIBA
;PROGRAMA PRINCIPAL
        BRA *
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---





                                                                            ;*******************************************************************************
;                                INTERRUPCION OC4_ISR
;*******************************************************************************
;Descripcion:

OC4_ISR:
        INC CONT_TICKS
        BEQ CAMBIAR
        BRA CONTINUAR
CAMBIAR:
        INC CONT_DIG
        LDAA #$F7                 ; Calculando cual display se debe encender
        LDAB CONT_DIG
        ANDB #$03
OC4_ISR_loop_1:
        BEQ OC4_ISR_fin_loop1
        LSRA                      ; Se desplaza el 0 para ver cual display se enciende
        DECB
        BRA OC4_ISR_loop_1
OC4_ISR_fin_loop1:
        STAA PTP
        
CONTINUAR:
        LDX #DISP1

        MOVB #$07,PORTB                ; Mandando leds al display
        ;LDAA #$FE
       ; STAA PTP                  ; Guardando resultado obtenido
        LDD TCNT                       ; Guardando en TC4 la siguiente interrupcion
        ADDD #480
        STD TC4
        RTI
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---
