;**************************************************************************************************************
;                                                   TAREA 7:                                                  *
;                                   RELOJ DESPERTADOR USANDO I2C y Modulo RTC                                 *
;**************************************************************************************************************
;           FECHA: 5 NOVIEMBRE 2019                                                                           *
;           AUTOR: Pablo Vargas                                                                               *
;           CARNE: B57564                                                                                     *
;           CURSO: Microprocesadores.                                                                         *
;           PROFESOR: Geovanny Delgado.                                                                       *
;                                                                                                             *
; DESCRIPCION: Este programa se trata de un reloj despertador el cual hace uso de un reloj a tiempo real      *
;              el cual utiliza un protocolo de comunicaciones IIC en concreto el RTC DS1307.                  *
;              para establecer la alarma se utiliza el boton PH0 de la Dragon 12 y para desactivarla          *
;               se utiliza el boton PH1.                                                                       *
;..............................................................................................................
;..............................................................................................................
;                   DECLARACION DE LAS ESTRUCTURAS DE DATOS                                                   .
;..............................................................................................................
                ORG $1000
CONT_RTC:       ds 1
Banderas:       ds 1      ;BANDERAS = ALARM_OF : X : X : RTC_RW : RS : Read_Enable_Flag : X : X
BRILLO:         ds 1
CONT_DIG:       ds 1
CONT_TICKS:     ds 1
DT:             ds 1
BCD1:           ds 1
BCD2:           ds 1              ; Valores en 7 segmentos para cada display
DISP1:          ds 1
DISP2:          ds 1
DISP3:          ds 1
DISP4:          ds 1
LEDS:           ds 1
SEGMENT:        db $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
CONT_7SEG:      ds 2
Cont_Delay:     ds 1
D2mS:           db 100            ; Constantes de tiempo para la subrutina DELAY
D260uS:         db 13
D60uS:          db 3
Clear_LCD:      db $01
ADD_L1:         db $80            ; Posiciona la panatalla en la linea 1
ADD_L2:         db $C0            ; Posiciona la panatalla en la linea 2
IniDsp:         db $04,$28,$28,$06,$0C
                db $FF
Index_RTC:      ds 1
DIR_WR:         db $D0
DIR_RD:         db $D1
DIR_SEG:        db $00
ALARMA:         dw $3109

                ORG $1030
T_Write_RTC:    db $55,$30,$09,$03,$04,$12
                ORG $1040
T_Read_RTC:     ds 6


                ORG $1050
MEN_L1:         FCC "     RELOJ      "
                db $FF
MEN_L2:         FCC "DESPERTADOR 623"
                db $FF


;.................................................................................
;                      DECLARACION DEL VECTOR DE INTERRUPCIONES                  .
;.................................................................................
                                                                                 ;
                ORG $3E4C       ;KEY_WAKE_UP_PH                                  ;
                dw PTH_ISR                                                       ;
;--------------------------------------------------------------------------------;
                ORG $3E66       ;OC4                                             ;
                dw OC4_ISR                                                       ;
;--------------------------------------------------------------------------------;
                ORG $3E64       ;OC5                                             ;
                dw OC5_ISR                                                       ;
;--------------------------------------------------------------------------------;
                ORG $3E70       ;RTI                                             ;
                dw RTI_ISR                                                       ;
;--------------------------------------------------------------------------------;
                ORG $3e40       ;I2C                                             ;
                dw I2C_ISR                                                       ;
                                                                                 ;
;-----------------------Etiquetas con Registros----------------------------------;
;--------------------------------------------------------------------------------;
#include registers.inc                                                           ;
;................................................................................;
;................................................................................;
;                             PROGRAMA PRINCIPAL                                 ;
;................................................................................;
                                                                                 ;
                ORG $2000                                                        ;
                lds #$3bff          ; Se define la pila                          ;
                                                                                 ;
;________________________________________________________________________________;
; CONFIGURACION DE HARWARE:                                                      ;
;________________________________________________________________________________;

;//////////////////////////////////////// RTC ///////////////////////////////////

                movb #$75,RTICTL           ; M = 7 n = 5 configura un tiempo de 50ms para la RTI
                bset CRGINT,#$80           ; Se habilitan las interrupciones RTI

;////////////////////////////////////// Puerto H ///////////////////////////////////////

                bset PIEH,$0F              ; Habilita la interrupcion PH0-PH3 y Mod_Sel

;/////////////////////////////////////// OC4 /////////////////////////////////////////////

                bset TSCR1,$90             ; Habilita el TC
                bset TSCR2,$03             ; Define el preescalador
                bset TIOS,$10              ; Habilita la salida 4
                bset TIE,$10
                movb #$05, TCTL1
                clr  TCTL2
                ldd TCNT
                addd #60
                std TC4
                std TC5
; //////////////////////////////////  LEDS y DISPLAYS ////////////////////////////////////
                movb #$FF, DDRB
                bset DDRJ,$02              ;Habilita el pin 2 del puerto J
                bset PTJ,$02
                movb #$0f, DDRP
                movb #$0f, PTP

; //////////////////////////////////// I2C /////////////////////////////////////////////
                movb #$1F,IBFD
                movb #$C0,IBCR             ; Habilita el bus y las interrupciones

; ////////////////////////////// PANTALLA LCD //////////////////////////////////////////

                bset DDRK,$FF

;_________________________________________________________________________________
; INICIALIZACION DE VARIABLES:
;_________________________________________________________________________________

                CLI                         ; Activa interrupciones
                ;clr Cont_Reb                ; Resetea contadores y banderas
                clr Banderas
                clr CONT_RTC
                clr BRILLO
                clr CONT_DIG
                clr CONT_TICKS
                clr DT
                clr LEDS
                clr BCD1
                clr BCD2
                clr BRILLO
                clr DISP1
                clr DISP2
                clr DISP3
                clr DISP4
                movw #$0000,CONT_7SEG
                clr Cont_Delay



;---------------------------------------------------------------------------------
; Se realiza el ciclo de configuracion de la pantalla

                ldx #IniDsp
Config_Loop:    ldaa 1,x+               ; Comienza el ciclo de configuracion del LCD
                cmpa #$FF
                beq Clr_LCD
                bclr Banderas,$08       ; Se va a enviar un comando
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
                bra Config_Loop
Clr_LCD:        bclr Banderas,$08
                ldaa Clear_LCD          ; Comando para hacer clear
                jsr SEND
                movb D2mS,Cont_Delay
                jsr DELAY

MAIN:           ldx #MEN_L1
                ldy #MEN_L2
                jsr CARGAR_LCD

MAIN_LOOP:
                ldd ALARMA
                cmpa T_Read_RTC+1     ; Compara la hora actual con la alarma
                bne MAIN_LOOP
                cmpb T_Read_RTC+2
                bne MAIN_LOOP
                brset Banderas,$80,MAIN_LOOP
                bset Banderas,$80  ; No permite que siga sonando la alarma
                bset TIE,$20
                bset TIOS,$20
                bra MAIN_LOOP


;.................................................................................
;                             SUBRUTINA  Write_RTC
;.................................................................................
; Esta subrutina se encarga de recibir la cantidad de tornillos a contar y verifica
;  que la cantidad ingresada sea un valor permitido entre 12 y 96.


Write_RTC:
                ;brset IBSR,$01,ULTIMOBYTE_W

                ldaa Index_RTC
                bne ESCRITURA
                movb DIR_SEG,IBDR        ; Se posiciona en la direccion de escritura
                bra W_RET


ESCRITURA:      deca
                cmpa #6
                beq ULTIMOBYTE_W
                ldx #T_Write_RTC
                movb a,x,IBDR
                bra W_RET

ULTIMOBYTE_W:   bset Banderas,$04
                rts
                bclr IBCR,$20


W_RET           inc Index_RTC
                rts


;*******************************************************************************
;                             SUBRUTINA Read_RTC
;*******************************************************************************

;Descripcion: Esta subrutina se encarga de hacer todo el control del modo run
; Para mas informacion ver el enunciado de la tarea/


Read_RTC:
                ldaa Index_RTC
                inc Index_RTC

                cmpa #0
                beq WORD_ADD_R
                cmpa #1
                beq REP_ST
                cmpa #2
                beq LEC_DUMMY
                cmpa #9
                beq ULT_LECT
                cmpa #8
                beq No_AK
                bra Leer

WORD_ADD_R:
                movb DIR_SEG,IBDR         ;Envia la direccion de los segundos
                rts

REP_ST:         bset IBCR,$04
                movb DIR_RD,IBDR
                rts

LEC_DUMMY:      bclr IBCR,$0C
                bclr IBCR,$10
                ldab IBDR
                rts

ULT_LECT:       bclr IBCR,$28
                bset IBCR,$10
                ;bclr IBCR,$20
                clr Index_RTC
                bra Leer

No_AK:          bset IBCR,$08
Leer:           suba #3
                ldx #T_Read_RTC
                movb IBDR,a,x
                rts


;.................................................................................
;                             SUBRUTINA BCD_7SEG
;.................................................................................
; Esta subrutina se encarga de realizar la conversion de los numeros en BCD al
; formato 7 segmentos.

BCD_7SEG:
                movb T_Read_RTC+1,BCD1
                movb T_Read_RTC+2,BCD2
                ldx #SEGMENT
                ldaa BCD1
                anda #$0f            ; Parte baja de BIN1 a DISP4
                movb a,x,DISP4
                ldaa BCD1
                anda #$f0            ; Parte alta de BIN1 a DISP3
                lsra
                lsra
                lsra
                lsra
                movb a,x,DISP3

Seguir_BCD2:    ldab BCD2
                andb #$0f            ; Parte baja de BIN2 a DISP2
                movb b,x,DISP2
                ldab BCD2
                andb #$f0            ; Parte alta de BIN2 a DISP1
                lsrb
                lsrb
                lsrb
                lsrb
                movb b,x,DISP1
                brset T_Read_RTC,$01,PUNTOS_ON

PUNTOS_OFF:     bclr DISP2,$80
                bclr DISP3,$80  ; Realiza el parpadeo de los puntos en los
                rts             ; Display que separan los minutos de las horas.

PUNTOS_ON:      bset DISP2,$80
                bset DISP3,$80
                rts


;.................................................................................
;                             SUBRUTINA DELAY
;.................................................................................
; Esta subrutina genera un retardo programable por el usuario utilizando OC4

DELAY:
Delay_Loop:     tst Cont_Delay
                beq Retornar_Delay
                bra Delay_Loop
Retornar_Delay: rts

;.................................................................................
;                             SUBRUTINA CARGAR LCD
;.................................................................................
; Esta subrutina se encarga de poner los mensajes en las lineas 1 y 2 de la
;  pantalla LCD

CARGAR_LCD:
                bclr Banderas, $08   ; Para enviar un comando
                ldaa ADD_L1            ; Se ubica en la primera linea del LCD
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
LoopM1          bset Banderas, $08    ; Para enviar un Dato
                ldaa 1,x+
                cmpa #$FF
                beq L2
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
                bra LoopM1
L2:             bclr Banderas, $08   ; Para enviar un comando
                ldaa ADD_L2          ; Se ubica en la Segunda linea del LCD
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
LoopM2:         bset Banderas, $08    ; Para enviar un Dato
                ldaa 1,y+
                cmpa #$FF
                beq RetornarLCD
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
                bra LoopM2
RetornarLCD:    rts


;.................................................................................
;                             SUBRUTINA SEND (COMMAND / DATA)
;.................................................................................
; Esta subrutina se encarga de enviar un commando o un dato a la pantalla LCD,
;  y estos se envian a travez de PORTK.2-PORTk.5

SEND:
                psha
                anda #$F0
                lsra
                lsra
                staa PORTK
                brset Banderas,$08, Dato1
Comando:        bclr PORTK,$01
                bra Enable1
Dato1:          bset PORTK,$01
Enable1:        bset PORTK,$02
                movb D260uS,Cont_Delay
                jsr DELAY
                bclr PORTK,$02
                pula
                anda #$0F
                lsla
                lsla
                staa PORTK
                brset Banderas,$08, Dato2
                bclr PORTK,$01
                bra Enable2
Dato2:          bset PORTK,$01
Enable2:        bset PORTK,$02
                movb D260uS,Cont_Delay
                jsr DELAY
                bclr PORTK,$02
                rts



;.................................................................................
;                        SUBRUTINA DE ATENCION DE INTERUPCION PH
;.................................................................................
; PH0 -> Escribe en el RTC.
; PH1 -> Desactiva la alarma.
; PH2 -> Baja el brillo.
; PH3 -> Sube el brillo.

PTH_ISR:
                brset PIFH,$01,PTHO
                brset PIFH,$02,PTH1
                brset PIFH,$04,PTH2
                brset PIFH,$08,PTH3
                rts
PTHO:
                bclr Banderas,$10         ; RTC_RW <- 0
                bset IBCR,$F0             ; Realiza el START en modo TX
                movb DIR_WR,IBDR            ; Pone la direccion del esclavo
                clr Index_RTC
                bclr Banderas,$80
                bset PIFH,$01             ; Desactivando interrupcion
                rti
PTH1:
                bclr TIE,$20
                bclr TIOS,$20
                bset PIFH,$02     ; Desactivando interrupcion
                rti

PTH2:
                tst BRILLO       ; restando 5 a brillo si no es 0
                bls Brillo_Min
                dec BRILLO
                dec BRILLO
                dec BRILLO
                dec BRILLO
                dec BRILLO
Brillo_Min:
                bset PIFH,$04     ; Desactivando interrupcion
                rti

PTH3:
                ldaa BRILLO        ; sumando 5 al brillo si no es 100
                cmpa #100
                bhi Brillo_Max
                inc BRILLO
                inc BRILLO
                inc BRILLO
                inc BRILLO
                inc BRILLO
Brillo_Max:
                bset PIFH,$08     ; Desactivando interrupcion
                rti


;.................................................................................
;         SUBRUTINA DE ATENCION DE INTERRUPCIONES OUTPUT COMPARE CHANNEL 4
;.................................................................................
; Esta subrutina define un contador con uso de la interrupcion OC4.
; Decrementa Cont_Delay y carga TC4

OC4_ISR:
                tst CONT_7SEG
                bne Sigue
                movw #5000,CONT_7SEG
                jsr BCD_7SEG
Sigue:          ldaa CONT_TICKS
                cmpa #100                       ; Revisa si pasaron 100 TICKS
                blt Puente1
                movb #$00, CONT_TICKS
                inc CONT_DIG            ; si CON_TICKS = 0 pone el numero el DISP correspondiente
                ldaa CONT_DIG
                cmpa #5
                blt Puente1
                clr CONT_DIG
                bset PTJ, $02                   ; Desconecta los leds
Puente1:        ldab #$F7
                tst CONT_TICKS
                beq DISPLAYS
                ldaa #100
                suba BRILLO
                staa DT
                ldaa CONT_TICKS
                cmpa DT
                blt Puente2
                movb #$FF,PTP

Puente2:        tst Cont_Delay
                beq CargarTC4             ; Carga el OC4
                dec Cont_Delay
CargarTC4:      ldd TCNT
                addd #30
                std TC4
                inc CONT_TICKS
                dec CONT_7SEG
                rti

DISPLAYS:       ldaa CONT_DIG
                cmpa #0
                bne DIS3                   ; Hace el ciclo de refrescamiento
                movb DISP4,PORTB
                stab PTP
                lbra Puente2

DIS3:           rorb
                cmpa #1
                bne DIS2
                movb DISP3,PORTB
                stab PTP
                lbra Puente2

DIS2:           rorb
                cmpa #2
                bne DIS1
                movb DISP2,PORTB
                stab PTP
                lbra Puente2

DIS1:           rorb
                cmpa #3
                bne ENCENDER_LEDS
                movb DISP1,PORTB
                stab PTP
                lbra Puente2

ENCENDER_LEDS:  movb #$FF,PTP
                bclr PTJ,$02
                movb LEDS,PORTB
                lbra Puente2

;.................................................................................
;                        SUBRUTINA DE ATENCION DE INTERUPCION RTI
;.................................................................................
RTI_ISR:        bset CRGFLG,$80    ; Se desactiva la bandera de interrupcion RTI
                tst CONT_RTC
                beq RTC_READ        ; Esta suburutina se dedica exclusivamente a reducir el contador de rebotes y
                dec CONT_RTC
                rti

RTC_READ:       movb #20,CONT_RTC
                brclr Banderas,$04,Retornar
                bset Banderas,$10   ; RTC_RW <- 1
                movb DIR_WR,IBDR
                bset IBCR,$30       ; Realiza un START en modo TX

                clr Index_RTC               ; <- PRUEBA
Retornar:       rti

;.................................................................................
;                        SUBRUTINA DE ATENCION DE I2C_ISR
;.................................................................................
;
;
;
I2C_ISR:        bset IBSR,$20
                brset Banderas,$10, R_RTC
                jsr Write_RTC
                rti

R_RTC:          jsr Read_RTC
                rti


;.................................................................................
;         SUBRUTINA DE ATENCION DE INTERRUPCIONES OUTPUT COMPARE CHANNEL 5
;.................................................................................
; Esta subrutina define la frecuencia a la que suena buzzer de la alarma

OC5_ISR:
                ldd TCNT
                addd #75         ; <----- POR DEFINIR
                std TC5
                rti