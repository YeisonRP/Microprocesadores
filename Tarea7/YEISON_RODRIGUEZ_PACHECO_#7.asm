;*******************************************************************************
;                                 TAREA 7                                      *
;                           RELOJ DESPERTADOR 623                              *
;*******************************************************************************
;                                                                              *
;       UNIVERSIDAD DE COSTA RICA                                              *
;       FECHA 04/12/19                                                         *
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074                                 *
;       COREREO: yeisonrodriguezpacheco@gmail.com                              *
;                                                                              *
;                                                                              *
; Descripcion: Esta tarea consiste en un reloj que tiene una alarma. La alarma
; se programa en tiempo de ensamblado en la constante de un byte llamada ALARMA,
; dicha constante tiene como formato MM:HH minutos horas.
; Al llegar el reloj al valor de ALARMA (leyendo el RTC cada cierto tiempo), se
; activara una alarma que producira un sonido, ademas de que las luces led
; se moveran de derecha a izquiera rapidamente. Al presionar el boton ph1 la
; alarma se silencia.
; Para resetear la hora (se pone igual a la hora indicada en la variable llamad
; T_Write_RTC) se debe presionar el boton ph0. Los botones ph2 y ph3 controlan
; la intensidad del brillo de la pantalla.
; En la LCD de se mostrara el mensaje : Reloj Despertador 623.
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS                      *
;*******************************************************************************
EOM:     EQU $FF
        ORG $1000
        
CONT_RTI:       ds 1
BANDERAS:       ds 1        ;COMANDO_DATO:X:X:ALARMA_LEDS:ALARMA:X:X:RTC_RW
                               ;ALARMA_LEDS en 1 enciende los leds,
                               ;ALARMA en 0 apaga la alarma, es controlado por ph0 y ph1
                               ;RTC_RW 1 escribe 0 lee el RTC
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
ALARMA:         dW $0108 ; mm:hh MINUTOS Y HORAS
        ORG $1030
T_Write_RTC:    db $51,$00,$08,$01,$05,$12 ; 0 segundos, 03 minutos, 09 h, dia 1, date = 04, mes 12 y a;o 19
        ORG $1040
T_Read_RTC:     ds 7

; MENSAJES
Msj_reloj:    fcc "     RELOJ      "
        db EOM
Msj_despertador:    fcc " DESPERTADOR 623"
        db EOM

CONT_REB:       ds 1    ; Contador de rebotes para los botones
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
        ;*;
        CLR Index_RTC
        ; DISPLAYS
        CLR Index_RTC
        CLR CONT_DIG
        CLR CONT_TICKS
        CLR BRILLO
        CLR BCD1
        CLR BCD2
        CLR LEDS
        CLR CONT_REB
        MOVW #0,CONT_7SEG
        LDX #T_Read_RTC+1     ; Borrando parte importante del arreglo
        MOVW #$0000,0,X
        
        LDD TCNT        ; Inicializa TC4  , esto va mas abajo
        ADDD #60
        STD TC4

        ;*;
        LDD TCNT                       ; Guardando en TC5 la siguiente interrupcion
        ADDD #10
        STD TC5
        
        jsr LCD         ; Inicializar LCD
        LDX #Msj_reloj       ; Cargando LCD
        LDY #Msj_despertador
        JSR CARGAR_LCD
        
        
;*******************************************************************************
;                             MAIN
;*******************************************************************************
Main:
        LDX #T_Read_RTC+1
        LDD ALARMA
        CPD 0,X                ; Comparando la hora y minutos con alarma
        BNE esperar
        BRCLR BANDERAS,$08,esperar      ; Bit para que la alarma no vuelva a sonar
        BSET TIOS,$20           ; Para encender sonido
        BSET BANDERAS,$10       ; Para encender leds
esperar:
        bset PIEH,$0F
        LDAA #$FF
Loop:   DBNE A,Loop
        bra Main

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---









;*******************************************************************************
;                             SUBRUTINA LCD
;*******************************************************************************
;Descripcion: Esta subrutina inicializa la pantalla LCD
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
; se envia un codigo $fx. Tambien se encarga de enviar a los display 2 y 3
; encendido y apagado segun el valor de los segundos leidos del rtc

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
BCD_7SEG_FIN:                     ; Puntos de los segundos
        BRCLR T_Read_RTC,$01,BCD_7SEG_FIN_msb_0
        BSET DISP2,$80
        BSET DISP3,$80
        BRA BCD_7SEG_FIN_real
BCD_7SEG_FIN_msb_0:
        BCLR DISP2,$80
        BCLR DISP3,$80
BCD_7SEG_FIN_real:
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
;Descripcion: Esta interrupcion se encarga de incrementar la variable CONT_RTI en 1
; cada 50 ms aproximadamente, Esta subrutina cada vez que pasa 1 segundo se
; encarga de mandar una lectura el RTC para que actualice la hora al sistema

RTI_ISR:
                BSET CRGFLG,#$80
                LDAA CONT_REB
                BEQ RTI_ISR_CONTINUAR
                DEC CONT_REB
RTI_ISR_CONTINUAR:

                LDAA CONT_RTI
                CMPA #1 ;CMPA #19
                BEQ RTI_ISR_paso_1_segundo
                INC CONT_RTI                ; Incrementando y retornando
                RTI
                
RTI_ISR_paso_1_segundo:
                CLR CONT_RTI
                LDX #T_Read_RTC         ; Guardando minutos y horas
                MOVB 1,+X,BCD1
                MOVB 1,+X,BCD2
                BSET BANDERAS,$01       ; RTC_RW = 1
                MOVB Dir_WR,IBDR        ; Direccion de escritura
                BSET IBCR,$10           ; Transmision
                BSET IBCR,$20           ; START
                RTI

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                                INTERRUPCION PHO_ISR
;*******************************************************************************
;Descripcion: Esta interrupcion se divide en 4 subrunitas:
; PTH0: Inicializa la hora del reloj
; PTH1: Detiene la alarma
; PTH2: Decrementa el brillo de los display de 7 segmentos
; PTH3: Incrementa el brillo de los display de 7 segmentos
PHO_ISR:
                LDAA CONT_REB
                BEQ PHO_ISR_continuar
                BSET PIFH,$0F
                RTI
PHO_ISR_continuar:
                MOVB #1,CONT_REB        ; No entrar de nuevo a la int en un rato
                BRSET PIFH,$01,PTHO
                BRSET PIFH,$02,PTH1
                BRSET PIFH,$04,PTH2
                BRSET PIFH,$08,PTH3
                BSET PIFH,$0F
PTHO:
        BSET PIFH,$01        ; Desactivando interrupcion
        Bset BANDERAS,$08    ; Activa la alarma
        BSET IBCR,%11010000  ; Activa modulo, interrupcion,pone a transmitir
        MOVB #$1F,IBFD       ; Del calculo de la tabla
        MOVB Dir_WR,IBDR     ; Direccion de escritura del RTC
        BCLR BANDERAS,$01    ; RTC_RW = 0
        CLR Index_RTC
        BSET IBCR,%00100000  ; START
        RTI


PTH1:
        Bclr BANDERAS,$08    ; desactiva la alarma
        BCLR TIOS,$20   ; Desactiva interrupcion de OC5
        BCLR BANDERAS,$10       ; Para encender leds
        CLR LEDS        ; Borra los leds
        BSET PIFH,$02     ; Desactivando interrupcion
        RTI


PTH2:
        LDAA BRILLO        ; sumando 5 al brillo si no es 100
        CMPA #100
        BHS PTH2_final
        ADDA #5
        STAA BRILLO
PTH2_final:
        BSET PIFH,$04     ; Desactivando interrupcion
        RTI


PTH3:
        TST BRILLO       ; restando 5 a brillo si no es 0
        BLS PTH3_fin
        LDAA BRILLO
        SUBA #5
        STAA BRILLO
PTH3_fin:
        BSET PIFH,$08     ; Desactivando interrupcion
        RTI



;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                                INTERRUPCION OC4_ISR
;*******************************************************************************
;Descripcion: Esta interrupcion realiza toda la logica para que funcionen los,
; 4 displa de 7 segmentos y los leds a la vez. Para informacion mas detallada
; ver el enunciado de la tarea. Ademas de que llama a PATRON_LEDS si la alarma
; esta activada
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
        JSR PATRON_LEDS
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
;Descripcion: Esta interrupcion hace toogle en la salida del OC5 con la finalidad
; de generar un sonido de alarma.

OC5_ISR:
        LDD TCNT                       ; Guardando en TC4 la siguiente interrupcion
        ADDD #10
        STD TC5
        RTI
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---




;*******************************************************************************
;                                INTERRUPCION IIC_ISR
;*******************************************************************************
; DESCRIPCION: Esta interrupcion se encarga de atender los llamados de las
; comunicaciones entre el RTC y el microprocesador.
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
; DESCRIPCION: Esta subrutina se encarga de escribir el contenido de T_Write_RTC
; en el RTC mediante varios ciclos de interrupciones.
WRITE_RTC:
        TST INDEX_RTC
        BEQ WRITE_RTC_primer_dato
        LDAA INDEX_RTC  ;Despues de enviar el word adress
        DECA    ; Por el primer ciclo en que se envia WORD_adress
        LDX #T_Write_RTC
        MOVB A,X,IBDR   ;Poniendo los datos para mandarlos al RTC
        LDAA Index_RTC
        CMPA #8
        BEQ WRITE_RTC_ult_dato
        INC INDEX_RTC
        BRA WRITE_RTC_retornar
WRITE_RTC_ult_dato:
        CLR INDEX_RTC   ; Borrando index
        BCLR IBCR,$20   ; MS/SL = 0, SE;AL DE STOP
        BRA WRITE_RTC_retornar
WRITE_RTC_primer_dato:
        MOVB Dir_Seg,IBDR  ;Direccion de los segundos
        INC INDEX_RTC
WRITE_RTC_retornar:
        BSET IBCR,$10   ; Transmitir
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---



;*******************************************************************************
;                                SUBRUTINA READ_RTC
;*******************************************************************************
; DESCRIPCION: Esta subrutina se encarga de leer lo que manda el RTC en distintas
; interrupciones y lo guarda en la variable T_Read_RTC
READ_RTC:
        LDAA Index_RTC
        INC Index_RTC
        CMPA #0
        BEQ READ_RTC_primer_dato
        CMPA #1
        BEQ READ_RTC_segundo_dato
        CMPA #2
        BEQ READ_RTC_tercer_dato
        CMPA #9
        BEQ READ_RTC_ultimo_dato
        CMPA #8
        BNE READ_RTC_no_es_penultimo_dato
        BSET IBCR,$08
READ_RTC_no_es_penultimo_dato:
        LDX #T_Read_RTC
        DECA              ; Por el desfase de los anteriores 3 ciclos
        DECA
        DECA
        MOVB IBDR,A,X    ; Guardando dato en donde debe ir
        RTS
READ_RTC_primer_dato:
        MOVB DIR_SEG,IBDR         ;Envia la direccion de los segundos
        RTS
READ_RTC_segundo_dato:
        BSET IBCR,$04             ; Reteated started
        MOVB DIR_RD,IBDR          ; Envia direccion de lectura
        RTS
READ_RTC_tercer_dato:
        BCLR IBCR,$0C             ; Borra repeated started y TXAK
        BCLR IBCR,$10             ; Pone en modo recepcion
        LDAB IBDR                 ; dummy para mandar ciclos al slave
        RTS
READ_RTC_ultimo_dato:
        BCLR IBCR,$28             ; Pone senal stop y txak en 0
        BSET IBCR,$10             ; Pone como transmisor para sig ciclo
        CLR Index_RTC             ; Borra indice por si acaso

        BRA READ_RTC_no_es_penultimo_dato ; Para mandarlo a guardar el dato


;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---
        
        
;*******************************************************************************
;                                SUBRUTINA PATRON_LEDS
;*******************************************************************************
;DESCRIPCION: Se encarga de barrer los leds de izq a derecha si la alarma esta
; activada
PATRON_LEDS:
        BRCLR BANDERAS,$10,PATRON_LEDS_TERMINAR
        LDAA LEDS
        BEQ PATRON_LEDS_RESET
        LSR LEDS
        RTS
PATRON_LEDS_RESET:
        BSET LEDS,$80
PATRON_LEDS_TERMINAR:
        RTS
 ;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---