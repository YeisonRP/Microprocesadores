;*******************************************************************************
;                                 TAREA 7                                      *
;                           RELOJ DESPERTADOR 623                              *
;*******************************************************************************
;                                                                              *
;       UNIVERSIDAD DE COSTA RICA                                              *
;       FECHA                                                          *
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074                                 *
;       COREREO: yeisonrodriguezpacheco@gmail.com                              *
;                                                                              *
;                                                                              *
; Descripcion:                                                                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS                      *
;*******************************************************************************
EOM:     EQU $FF
        ORG $1000
        
CONT_RTI:       ds 1
BANDERAS:       ds 1        ;COMANDO_DATO:X:X:X:X:X:X:RTC_RW
BRILLO:         ds 1        ; Brillo de los leds, se sube de 5 en 5. Va de 0 a 100 es la
CONT_DIG:       ds 1        ; Cuenta  El digito que se va a encenter
CONT_TICKS:     ds 1        ; Cuenta tiks del Output compare, va de 0 a 100
DT:             ds 1        ; DT = N - K duty cicle
BCD1:           ds 1        ; Digitos en BCD, los guarda la subrutina BIN_BCD
BCD2:           ds 1
DISP1:          ds 1        ; Los 4 valores de los display que se escriben en PORTB
DISP2:          ds 1
DISP3:          ds 1
DISP4:          ds 1
LEDS:           ds 1        ; LEDS a ser encendidos
SEGMENT:       dB $3f,$06,$5b,$4f,$66,$6d,$7d,$07,$7f,$6f
CONT_7SEG:      ds 2        ; Para hacer que cada 10hz se llame a BCD_7SEG
CONT_DELAY:     ds 1
D2mS:           dB 100
D260uS:         dB 13
D60uS:          dB 3
CLEAR_LCD:      ds 1
ADD_L1:         dB $80
ADD_L2:         dB $C0
iniDsp:         db $04,$28,$28,$06,%00001100 ;disp on, cursor off, no blinkin
                db EOM
; 1024 -- POR EOM
Index_RTC:      ds 1
Dir_WR:         db $D0
Dir_RD:         db $D1
Dir_Seg:        db $00
ALARMA:         dW $0409 ; mm:hh MINUTOS Y HORAS
T_Write_RTC:    db $00,$03,$09,$01,$05,$12,$19  ; 0 segundos, 03 minutos, 09 h, dia 1, date = 04, mes 12 y a;o 19
T_Read_RTC:     ds 7

; MENSAJES
Msj_reloj:    fcc "     RELOJ      "
        db EOM
Msj_despertador:    fcc " DESPERTADOR 623"
        db EOM

CONT_REB:       ds 1
CONT_TCL:       ds 1
PATRON:         ds 1
#include registers.inc




;*******************************************************************************
;                       DECLARACION VECTORES INTERRUPCION
;*******************************************************************************
        ; Vector interrupcion output compare canal 4
        ORG $3e66
        dw OC4_ISR

        ; Vector interrupcion output compare canal 5
        ORG $3e64
        dw OC5_ISR
        
        ; Vector interrupcion del real time interrupt
        ORG $3e70
        dw RTI_ISR
        
        ; Vector de interrupcion de key wakeups
        ORG $3e4c
        dw PHO_ISR

        ; Interrupcion IIC
        ORG $3e40
        dw IIC_ISR
        
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---










;*******************************************************************************
;-------------------------------------------------------------------------------
;--------------------------------------MAIN-------------------------------------
;-------------------------------------------------------------------------------
;*******************************************************************************

        ORG $2000
        LDS #$3BFF
;INICIALIZACION DE HARDWARE:
        ;subrutina iic:
        MOVB #$1F,IBFD  ; Este valor se encontro en la tabla al buscar el 240 en SCL divider
        ; el scl divider se calcula como 24Mhz/100kbits/s = 240
        ; Esto da un total de ciclos de 33 que se traduce a 1.375us, este valor es menor
        ; a 3.45us que es el maximo tiempo que permite la dragon, y tambien es mayor
        ; al minimo tiempo de hold del RTC que es de 0.3us

        ;BSET IBCR,$80 ; Se habilita IIC
        ;BSET IBCR,$40 ; Se habilita interrupcion IIC
        ;BSET IBSR,$02 ; Borra bandera interrup
        ; calling adress IBDR $D0 escribir,
        ; calling adress, me manda un ack, le mando la direccion de lo que deseo escribir
        ; y seguidanmente le dato que quiero escribir o los siguientes datos, porque el puntero
        ; se mueve despues de que cada dato es escrito.. Por ultimo le manda se;al de stop
        ;
        ;                BDR $D1 leer
        ;subrutina RTI_ISR:
        movb #$75,RTICTL        ; M = 7 n = 5 interrupcion cada 49.52ms
        bset CRGINT,#$80        ; activa rti

        ;subrutina PHO_ISR:
        bset PIEH,$0F           ; Activando interrupcion PH0,PH1,PH2,PH3

        ;Inicializacion de Output compare canal 4
        BSET TSCR1,$90 ; TEN = 1 , TFFCA = 1. Habilitando modulo timers y el borrado rapido
        CLR TSCR2         ; Preescalador = 1
        BSET TIE,$10    ; Habilitando interrupcion output compare canal 4
        BSET TIOS,$10   ; Pone como salida canal 4
        BSET TCTL1,$04  ; Pone a hacer toogle OC5

        
        ; Inicializacion de Puerto B y P para uso de los display de 7 seg.
        MOVB #$FF,DDRB            ; Todas salidas puerto B (segentos de display)
        MOVB #$0F,DDRP            ; 4 salidas puerto P (activan cada display)

        ;Inicializacion puerto J para usar leds
        bset DDRJ,$02             ; Salida puerto j

        ; Pantalla LED
        MOVB #$FF,DDRK  ; Puerto K como salidas
        
;INICIALIZACION DE VARIABLES:
        CLI                     ; Activando interrupciones


        CLR BANDERAS
        CLR Index_RTC
        ; DISPLAYS
        CLR Index_RTC
        CLR CONT_DIG
        CLR CONT_TICKS
        CLR BRILLO
        CLR BCD1
        CLR BCD2
        MOVW #0,CONT_7SEG

        LDD TCNT        ; Inicializa TC4  , esto va mas abajo
        ADDD #60
        STD TC4

        LDD TCNT                       ; Guardando en TC5 la siguiente interrupcion
        ADDD #10
        STD TC5
        
        jsr LCD         ; Inicializar LCD
        LDX #Msj_reloj       ; Cargando LCD
        LDY #Msj_despertador
        JSR CARGAR_LCD
; MAIN!!!



;        BSET TIOS,$20   ; Pone como salida canal 5  BORRAR
Main:
        ;movb #$98,BCD1
        ;movb #$76, BCD2
        LBRA Main                ; Retorna al main
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---









;*******************************************************************************
;                             SUBRUTINA LCD
;*******************************************************************************
;Descripcion: Esta subrutina inicializa la subrutina LCD
LCD:
        LDX #iniDsp
Loop_lcd_inic:
        LDAA 1,X+
        CMPA #EOM
        BEQ FIN_Loop_lcd_inic
        BCLR BANDERAS, $80            ; para mandar un comando
        JSR SEND
        MOVB D60uS,CONT_DELAY
        JSR DELAY
        BRA Loop_lcd_inic
FIN_Loop_lcd_inic:
        LDAA #$01              ; CLEAR DISPLAY
        BCLR BANDERAS, $80            ; para mandar un comando
        JSR SEND
        MOVB D2ms,CONT_DELAY
        JSR DELAY
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---





;*******************************************************************************
;                             SUBRUTINA SEND
;*******************************************************************************
;Descripcion: Esta subrutina envia datos o comandos a pantalla LCD, recibe como
; parametro la bandera COMANDO_DATO en 0 si es comando, 1 si es dato

SEND:
        PSHA
        andA #$F0
        LSRA
        LSRA
        STAA PORTK
        BRCLR BANDERAS,$80,SEND_comando  ; 0 COMANDO, 1 DATO
        BSET PORTK,$01
        BRA SEND_continuar
SEND_comando:
        BCLR PORTK,$01
SEND_continuar:
        BSET PORTK,$02
        MOVB D260us,CONT_DELAY
        JSR DELAY
        BCLR PORTK,$02

        PULA
        andA #$0F
        LSLA
        LSLA
        STAA PORTK
        BRCLR BANDERAS,$80,SEND_comando2  ; 0 COMANDO, 1 DATO
        BSET PORTK,$01
        BRA SEND_continuar2
SEND_comando2:
        BCLR PORTK,$01
SEND_continuar2:
        BSET PORTK,$02
        MOVB D260us,CONT_DELAY
        JSR DELAY
        BCLR PORTK,$02
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---













;*******************************************************************************
;                             SUBRUTINA CARGAR_LCD
;*******************************************************************************
;Descripcion: Esta subrutina carga los mensajes en la LCD

CARGAR_LCD:
        LDAA ADD_L1
        BCLR BANDERAS, $80            ; para mandar un comando
        JSR SEND
        MOVB D60uS,CONT_DELAY
        JSR DELAY
CARGAR_LCD_first_loop:
        LDAA 1,X+
        CMPA #EOM
        BEQ CARGAR_LCD_first_loop_end
        BSET BANDERAS, $80            ; para mandar un dato
        JSR SEND
        MOVB D60uS,CONT_DELAY
        JSR DELAY
        BRA CARGAR_LCD_first_loop
CARGAR_LCD_first_loop_end:
        LDAA ADD_L2
        BCLR BANDERAS, $80            ; para mandar un comando
        JSR SEND
        MOVB D60uS,CONT_DELAY
        JSR DELAY
        
CARGAR_LCD_SECOND_loop:
        LDAA 1,Y+
        CMPA #EOM
        BEQ CARGAR_LCD_SECOND_loop_end
        BSET BANDERAS, $80            ; para mandar un dato
        JSR SEND
        MOVB D60uS,CONT_DELAY
        JSR DELAY
        BRA CARGAR_LCD_SECOND_loop
CARGAR_LCD_SECOND_loop_end:
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---








;*******************************************************************************
;                             SUBRUTINA DELAY
;*******************************************************************************
;Descripcion: Esta subrutina se encarga de generar delays a partir de la variable
;CONT_DELAY. Por ejemplo un valor de CONT_DELAY de 50 da una interrupcion de 1x10-3
; Debido a que cada decremento de CONT_DELAY se da cada 20us

DELAY:
        TST CONT_DELAY
        BNE DELAY
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---






;*******************************************************************************
;                             SUBRUTINA BCD_7SEG
;*******************************************************************************
;Descripcion: Esta subrutina pasa valores de BCD1 y BCD2 a DISP1,DISP2,DISP3,
; DISP4, en su respectivo codigo de 7 segmentos. Si hay ceros a la izquierda
; se envia un codigo $fx

BCD_7SEG:
        LDX #BCD1          ;Declaracion punteros iniciales
        LDY #DISP1
        LDAA #2
BCD_7SEG_main_loop:
        BEQ BCD_7SEG_FIN
        PSHA
        LDAA 0,X            ; CARGANDO NUMEROS A PROCESAR
        LDAB 0,X
        PSHX
        LDX #SEGMENT
        ANDB #$0F
        MOVB B,X,1,Y+
        LSRA                     ; Analizando segundo nibble
        LSRA
        LSRA
        LSRA
        CMPA #$0F
        BEQ BCD_7SEG_CLEAR        ; Si el numero es invalido?
        MOVB A,X,1,Y+
        BRA BCD_7SEG_CONT
BCD_7SEG_CLEAR:
        CLR 1,Y+
BCD_7SEG_CONT:
        PULX                         ; Preparando para el sig ciclo
        PULA
        INX
        DECA
        BRA BCD_7SEG_main_loop
BCD_7SEG_FIN:
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---

















;*******************************************************************************
;-------------------------------------------------------------------------------
;-------------------------------INTERRUPCIONES----------------------------------
;-------------------------------------------------------------------------------
;*******************************************************************************




;*******************************************************************************
;                                INTERRUPCION RTI_ISR
;*******************************************************************************
;Descripcion: Esta interrupcion se encarga de decrementar la variable CONT_REB en 1
; cada 1 ms aproximadamente, si CONT_REB es cero la subrutina no hace nada.

                loc
RTI_ISR:        bset CRGFLG, $80
                tst CONT_REB
                beq checkREAD
                dec CONT_REB
checkREAD:      tst CONT_RTI        ;Se verifica que el contador llegue a 0 es decir 1 s
                beq initREAD
                dec CONT_RTI
                bra return`
initREAD:       movb #20,CONT_RTI   ;Reset contador
                ;INICIO de comunicaciones en LECTURA
                bset BANDERAS,$01 ; MODOLectura
                movb Dir_WR,IBDR                ;Mando la direccion de escritura para resetear el puntero de memoria DS1307
                ;movb #$F0,IBCR                 ;IBEN 1, IBIE 1 MS 1(START), TX 1 txak 0(Para calling address no importa),RSTA 0
                bset IBCR,$30
                movb #$00,Index_RTC             ;Index en 0

return`         rti
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                                INTERRUPCION PHO_ISR
;*******************************************************************************
;Descripcion: Esta interrupcion se divide en 4 subrunitas:
; PTH0: Borra CUENTA
; PTH1: Borra ACUMUL
; PTH2: Decrementa el brillo de los display de 7 segmentos
; PTH3: Incrementa el brillo de los display de 7 segmentos

                 loc
PHO_ISR:        brset PIFH,$01,PH0_ISR
                brset PIFH,$02,PH1_ISR
                brset PIFH,$04,PH2_ISR
                brset PIFH,$08,PH3_ISR

;       subrutina PH1
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
PH0_ISR:        bset PIFH, $01
                tst CONT_REB
                bne returnPH
                brset BANDERAS,$01,returnPH     ;Si ya se configuro la hora no se vuelve a hacer
                movb #2,CONT_REB
                ;INICIO de comunicaciones en escritura
                bclr BANDERAS,$80 ;MODOEscritura
                movb Dir_WR,IBDR               ;Se envia direccion de escritura
                movb #$F0,IBCR                 ;IBEN 1, IBIE 1 MS 1(START), TX 1 txak 0(Para calling address no importa),RSTA 0
                bset BANDERAS,$08
                ;bset IBCR,$30
                clr Index_RTC             ;Index en 0
                bra returnPH

;       subrutina PH1
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
PH1_ISR:        bset PIFH, $02
                tst CONT_REB
                bne returnPH
                movb #2,CONT_REB
                movb #$10, TIOS
                movb #$10, TIE      ;Se deshabilitan las interrupciones de OC5
returnPH:       rti
;       subrutina PH2
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
PH2_ISR:        bset PIFH, $04
                ldaa BRILLO
                beq returnPH
                suba #5
                staa BRILLO
                bra returnPH
;       subrutina PH3
;################################################################################################################################################
;Descripcion:


;Paso de parametros:
;Entrada:
;Salida:
;################################################################################################################################################
PH3_ISR:        bset PIFH, $08
                ldaa BRILLO
                cmpa #100
                beq returnPH
                adda #5
                staa BRILLO
                bra returnPH



;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                                INTERRUPCION OC4_ISR
;*******************************************************************************
;Descripcion: Esta interrupcion realiza toda la logica para que funcionen los,
; 4 displa de 7 segmentos y los leds a la vez. Para informacion mas detallada
; ver el enunciado de la tarea
OC4_ISR:
        LDX #DISP1
        LDAA #100                 ;Verificando si el contador de tics ya
        CMPA CONT_TICKS            ; llego a 125.
        BEQ OC4_ISR_tic_maximo
        INC CONT_TICKS             ; Iincrementando contador de tics
        BRA OC4_ISR_continuar1
OC4_ISR_tic_maximo:               ; Se debe cambiar de display
        CLR CONT_TICKS
        INC CONT_DIG
        LDAB CONT_DIG
        CMPB #5                   ; Si contador de digito se sale del rango se resetea
        BNE Continuar
        clr CONT_DIG
Continuar:
        LDAB CONT_DIG             ; Si el digito son los leds, se encienden
        CMPB #4
        BEQ encender_led
        MOVB B,X,PORTB                ; Mandando datos al display
        BSET PTJ,$02                  ; apagando leds
        BRA continuar2
encender_led:                        ; encendiendo leds
        MOVB LEDS,PORTB
        BCLR PTJ,$02                 ;encendiendo leds
continuar2:
        LDAA #$F7                 ; Calculando cual display se debe encender
        LDAB CONT_DIG
OC4_ISR_loop_1:
        BEQ OC4_ISR_fin_loop1
        LSRA                      ; Se desplaza el 0 para ver cual display se enciende
        DECB
        BRA OC4_ISR_loop_1
OC4_ISR_fin_loop1:
        STAA PTP                  ; Guardando resultado obtenido
OC4_ISR_continuar1:
        LDAA #100                 ; Calculando cuando apagar el display
        SUBA BRILLO
        STAA DT
        CMPA CONT_TICKS
        BNE OC4_ISR_continuar2
        MOVB #$FF,PTP             ; Se apaga el display
        BSET PTJ,$02              ; disable leds
OC4_ISR_continuar2:
        LDD CONT_7SEG                 ; Calculando si ya pasaron 100ms
        CPD #5000
        BEQ OC4_ISR_llamar
        ADDD #1                       ; sumando 1 a CONT_7SEG
        STD CONT_7SEG                 ; Guaradndolo
        BRA OC4_ISR_continuar3
OC4_ISR_llamar:
        MOVW #0,CONT_7SEG
        JSR BCD_7SEG
OC4_ISR_continuar3:                    ; Decrementando contador de delay si no es 0
        TST CONT_DELAY
        BEQ OC4_ISR_retornar
        DEC CONT_DELAY
OC4_ISR_retornar:
        LDD TCNT                       ; Guardando en TC4 la siguiente interrupcion
        ADDD #480
        STD TC4
        RTI
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---




;*******************************************************************************
;                                INTERRUPCION OC5_ISR
;*******************************************************************************
;Descripcion:

OC5_ISR:
        LDD TCNT                       ; Guardando en TC4 la siguiente interrupcion
        ADDD #10
        STD TC5
        RTI
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---




;*******************************************************************************
;                                INTERRUPCION IIC_ISR
;*******************************************************************************

IIC_ISR:

        BRCLR BANDERAS,$01,IIC_ISR_WRITE_RTC
        JSR READ_RTC
        BSET IBSR,$02  ;Borra bandera interrupcion
        RTI
IIC_ISR_WRITE_RTC:
        JSR WRITE_RTC
        BSET IBSR,$02  ;Borra bandera interrupcion
        RTI
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---



;*******************************************************************************
;                                SUBRUTINA WRITE_RTC
;*******************************************************************************
                loc
WRITE_RTC:      brset IBSR,$02,error_wrtc       ;No se recibe el ack
                ldaa Index_RTC
                bne next`
                movb Dir_Seg,IBDR       ;Mandar la direccion de la primera palabra es decir segundos
                bra return_wrtc
next`           deca                    ;offset de -1 porque se toma en cuenta el envio de la direccion
                ldx #T_WRITE_RTC
                movb A,X,IBDR           ;Mandar el dato correspondiente segun el index
                cmpa #5                 ;Es el ultimo dato?
                bne return_wrtc
                bclr IBCR,$20
                ;Bset IBCR,#$40 ;TXAK <- 1
return_wrtc:    inc Index_RTC
                rts
error_wrtc:     movb #$FF,LEDS                  ;Enciende todos los leds como alarma
                bra return_wrtc
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---



;*******************************************************************************
;                                SUBRUTINA READ_RTC
;*******************************************************************************
loc
READ_RTC:       ldaa Index_RTC
                bne next0`          ;Primera?
                movb Dir_Seg,IBDR       ;Se envia la direccion a leer (Segundos)
                bra return_rrtc
next0`          cmpa #1             ;Segunda?
                bne next1`
                bset IBCR,$04       ;Repeate start
                movb Dir_RD,IBDR
                bra return_rrtc
next1`          cmpa #2             ;Tercera?
                bne next2`
                bclr IBCR,$1C       ;Borra repeated start y pasa a modo rx y pone en 0 el ack por seguridad
                ldab IBDR           ;Lectura dummy
                bra return_rrtc
next2`          cmpa #9             ;Ultimo lista?
                bne next3`
                bclr IBCR,$28       ;borra el no ack (8) y manda señal de stop (2)
                bset IBCR,$10       ;pasa a modo tx
                bra return_rrtc
next3`          cmpa #8             ;Penultima?     FIXME: esto significa que no se lee el ultimo dato?
                bne next4`
                bset IBCR,$08       ;Pone un no ack
next4`          deca
                deca
                deca                ;A -3 porque se consideran las primeras 3 interrupciones en el index
                ldx #T_Read_RTC
                movb IBDR,A,X       ;Se mueve el dato a la posicion deseada

return_rrtc     inc Index_RTC
                rts

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---
        