;*******************************************************************************
;                                 TAREA 5                                      *
;                         PANTALLAS MULTIPLEXADAS                              *
;*******************************************************************************
;                                                                              *
;       UNIVERSIDAD DE COSTA RICA                                              *
;       FECHA 02/11/19                                                         *
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074                                 *
;       COREREO: yeisonrodriguezpacheco@gmail.com                              *
;                                                                              *
;                                                                              *
; Descripcion: Este programa se encarga de realizar todo el control en una fa- *
; brica que hace bolsas de tornillos. El programa funciona en dos modos:
; Modo config: En este modo se ingresan datos en el teclado de la tarjeta, el
; teclado esta definido como vemos a continuacion:
;                                                                              *
;                 C0  C1  C2                                                   *
;                 PA0 PA1 PA2                                                  *
;                  |   |   |                                                   *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA4, R0 -  | 1 | 2 | 3 |                                                 *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA5, R1 -  | 4 | 5 | 6 |                                                 *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA6, R2 -  | 7 | 8 | 9 |                                                 *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA7, R3 -  | B | 0 | E |                                                 *
;                -------------                                                 *
;                                                                              *
; Al ingresar el enter se guarda la cantidad de tornillos que tendra la bolsa, *
; seguidamente si se baja el dipswitch numero 7 se pasara al modo run, que se  *
; detalla a continuacion.                                                      *
; Modo Run: El modo run es cuando se procede a contar los tornillos en la banda*
; ,se muestra la cuenta de los tornillos en los display 3 y 4,y cuando se llena*
; la bolsa se activa un rele que se encarga de dar el control al sistema que   *
; empaca la bolsa. Para llenar otra bolsa se debe pulsar el sw5.               *
;                                                                              *
; Si hay dificultades para ver los display, se debe pulsar el sw2 para subir el*
; brillo de los display, si por el contrario se desea bajar, presionar sw3.    *
;                                                                              *
; Para resetear el contador de bolsas, presionar sw4                           *
;                                                                              *
; Si se desea volver al modo config para cambiar el tamano de las bolsas, sim- *
; plemente se debe subir el dipswitch 7 nuevamente y repetir el proceso.       *
;                                                                              *
; En el modo config siempre estara encendido el led PB1, en el modo run el PB0.*
;                                                                              *
; En la pantalla LED del dispositivo se mostrara informacion relevante sobre   *
; las variables desplegadas en los display de 7 segmentes.                     *
;                                                                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS                      *
;*******************************************************************************
EOM:     EQU $FF
        ORG $1000
        ; 1000 ---- 100F
; CAMBIAR ORDEN DE BANDERAS AL FINAL
BANDERAS:       ds 1        ; Banderas del sistema
; COMANDO_DATO : CAMBIO_MODO : CALC_TICKS : ALERTA : PANT_FLAG : ARRAY_OK : TCL_LEIDA : TCL_LISTA
BANDERAS2:      ds 1
; X : X : X : X : X : X : X : X :


; CALC_TICKS:
; ALERTA: Bandera que esta en 1 cuando se debe poner el patron de LEDS de alerta
; PANT_FLAG
; ARRAY_OK: Bandera que esta en 1 cuando el array del teclado esta listo
; TCL_LEIDA: Bandera que se pone en 1 cuando se lee una tecla del teclado
; TCL_LISTA: Se pone en 1 cuando la tecla es soltada (esta lista)
; COMANDO_DATO: Esta bandera es 0 si se envia un comando, 1 si se envian datos
; CAMBIO_MODO: Se pone en 1 si hubo un cambio de modo

V_LIM:          ds 1        ; Velocidad maxima a la que puede ir el auto
MAX_TCL:        db $02      ;Cantidad de teclas que se van a leer  (longitud)
TECLA:          ds 1        ;Tecla leida en un momento t0
TECLA_IN:       ds 1        ;Tecla leida en un momento t1
CONT_REB:       ds 1        ;Contador de rebotes que espera 10ms por la subrutina RTI_ISR
CONT_TCL:       ds 1        ;Contador de teclas que han sido escritas, usada en FORMAR_ARRAY
PATRON:         ds 1        ;Contador que va hasta 5, usado por MUX_TECLADO
NUM_ARRAY:      db $ff,$ff             ;Guarda los numeros ingresados en el teclado
BRILLO:         ds 1        ; Brillo de los leds, se sube de 5 en 5. Va de 0 a 100 es la variable K
POT:            ds 1        ; Es el valor leido en el potenciometro.
TICK_EN:        ds 2
TICK_DIS:       ds 2

        ; 1011 ---- 101F
VELOC:          ds 1
TICK_VEL:       ds 1
BIN1:           ds 1
BIN2:           ds 1
BCD1:           ds 1        ; Digitos en BCD, los guarda la subrutina BIN_BCD
BCD2:           ds 1
BCD_L:          ds 1
BCD_H:          ds 1
DISP1:          ds 1        ; Los 4 valores de los display que se escriben en PORTB
DISP2:          ds 1
DISP3:          ds 1
DISP4:          ds 1
LEDS:           ds 1        ; LEDS a ser encendidos
CONT_DIG:       ds 1        ; Cuenta  El digito que se va a encenter
CONT_TICKS:     ds 1        ; Cuenta tiks del Output compare, va de 0 a 100

        ; 1020 ---- 102B
DT:             ds 1        ; DT = N - K duty cicle
CONT_7SEG:      ds 2        ; Para hacer que cada 10hz se llame a BCD_7SEG
CONT_200:       ds 2        ; Para hacer que cada 10hz se llame a BCD_7SEG
CONT_DELAY:     ds 1
D2mS:           dB 100
D260uS:         dB 13
D60uS:          dB 3
CLEAR_LCD:      ds 1
ADD_L1:         dB $80
ADD_L2:         dB $C0

        ; 102C ---- 102F por definir:
MODO_ANTERIOR   DS 1     ; Para saber si hubo cambio de modo
; xx
; xx
; xx

;BANDERAS:       ds 1        ;COMANDO_DATO:ALERTA:X:MODSEL:CAMBIO_MODO:ARRAY_OK:TLC_LEIDA:TCL_LISTA
                            ; CAMBIO_MODO es para que la pantalla LCD solo se refresque una vez entre cada cambio de modo
                            ; MODSEL. 1 es para modo CPROG, 0 MODO RUN
                            ; COMANDO_DATO: Esta bandera es 0 si se envia un comando, 1 si se envian datos

        ORG $1030
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E ;Tabla de teclas del teclado

        ORG $1040
SEGMENT:       dB $3f,$06,$5b,$4f,$66,$6d,$7d,$07,$7f,$6f,$40,$00

        ORG $1050
iniDsp:         db $04,$28,$28,$06,%00001100 ;disp on, cursor off, no blinkin
                db EOM
        ORG $1060
Msj_config_1:    fcc "  MODO CONFIG.  "
        db EOM
Msj_config_2:    fcc " VELOC. LIMITE  "
        db EOM
Msj_libre_1:    fcc "  RADAR   623   "
        db EOM
Msj_libre_2:    fcc "  MODO LIBRE    "
        db EOM
Msj_medicion_1:    fcc " MODO MEDICION  "
        db EOM
Msj_medicion_calculando_2:    fcc "  CALCULANDO... "
        db EOM
Msj_medicion_esperando_2:    fcc "  ESPERANDO...  "
        db EOM
Msj_medicion_su_vel_vel_lim_2:    fcc "SU VEL. VEL.LIM "
        db EOM

#include registers.inc




;*******************************************************************************
;                       DECLARACION VECTORES INTERRUPCION
;*******************************************************************************
        ; Vector interrupcion output compare canal 4
        ORG $3e66
        dw OC4_ISR

        ; Vector interrupcion del real time interrupt
        ORG $3e70
        dw RTI_ISR

        ; Vector de interrupcion de key wakeups
        ORG $3e4c
        dw CALCULAR

        ORG $3E52       ;ATD
        dw ATD_ISR

        ORG $3E5E       ;Timmer Overflow
        dw TCNT_ISR
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---










;*******************************************************************************
;-------------------------------------------------------------------------------
;--------------------------------------MAIN-------------------------------------
;-------------------------------------------------------------------------------
;*******************************************************************************

        ORG $2000
        LDS #$3BFF

;-_-_-_-_-_-_-_-_-_-_-_-_ INICIALIZACION DE HARDWARE: -_-_-_-_-_-_-_-_-_-_-_-_-_

;____________________________________ ATD ______________________________________

        movb #$82,ATD0CTL2      ; Activa el ATD y las interrupciones
        movb #%00110000,ATD0CTL3      ; 6 conversiones por canal
        movb #%10110111,ATD0CTL4      ; Define frecuencia en 500KHz y 4 periodos del itempo de muestreo
;_______________________________________________________________________________




;_________________________ Puerto A para teclado _______________________________

        MOVB #$01,PUCR       ;Resistencias pull up
        MOVB #$F0,DDRA      ;Puerto A, parte alta salidas, parte baja entradas
;_______________________________________________________________________________




;_____________________________________ RTI _____________________________________

        movb #$23,RTICTL        ; M = 2 n = 3
        bset CRGINT,#$80        ; activa rti
;_______________________________________________________________________________




;___________________________ OC4 y Timmer Overflow _____________________________

        BSET TSCR1,$80 ; TEN = 1 , Habilitando modulo timers
        BSET TSCR2, $03 ; Preescalador = 8
        BSET TIE,$10    ; Habilitando interrupcion output compare canal 4
        BSET TIOS,$10   ; Pone como salida canal 4
;_______________________________________________________________________________





;______________________ INICIALIZACION DE DISPLAY 7 SEG ________________________

        MOVB #$FF,DDRB            ; Todas salidas puerto B (segentos de display)
        MOVB #$0F,DDRP            ; 4 salidas puerto P (activan cada display)
;_______________________________________________________________________________





;______________________ INICIALIZACION DE J PARA LEDS __________________________

        bset DDRJ,$02             ; Salida puerto j
;_______________________________________________________________________________





;__________________ INICIALIZACION DE K PARA PANTALLA LED ______________________

        MOVB #$FF,DDRK  ; Puerto K como salidas
;_______________________________________________________________________________



;-_-_-_-_-_-_-_-_-_-_-_-_ INICIALIZACION DE VARIABLES: -_-_-_-_-_-_-_-_-_-_-_-_-


	CLI                     ; Activando interrupciones
        MOVB #$FF,TECLA
        MOVB #$FF,TECLA_IN
        CLR CONT_REB
        CLR BANDERAS
        CLR CONT_TCL
        CLR V_LIM
        CLR VELOC
        CLR CONT_DIG
        CLR CONT_TICKS
        CLR BRILLO
        CLR BIN1
        CLR BIN2
        MOVW #0,CONT_7SEG

        LDD TCNT        ; Inicializa TC4  , esto va mas abajo
        ADDD #60
        STD TC4

        BSET MODO_ANTERIOR,$01   ; Para que siempre sea diferente a los demas modos

        jsr LCD         ; Inicializar LCD
;_______________________________________________________________________________




;-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_ Main -_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-

Main:
        LDAA MODO_ANTERIOR         ; Logica para saber si se cambio de modo
        CMPA PTIH
        BEQ continuar_main
        BSET BANDERAS,$40
continuar_main:
        MOVB PTIH,MODO_ANTERIOR

        BRSET PTIH,$C0,mod_medicion ; Revisando por pulling si esta en modo Med
        clr VELOC
        BCLR PIEH,$09           ; Desactivando interrupcion PH0,PH3
        BCLR TSCR2,$80         ; Desactivando interrupcion TO
        BRCLR PTIH,$C0,mod_config ; Revisando por pulling si esta en modo CONF
        JSR LIBRE ; MODO LIBRE
        BRA Main                ; Retorna al main

mod_config:
        BRSET BANDERAS,$40,mod_config_actualizar_lcd
        BRA mod_config_no_actualizar_lcd
mod_config_actualizar_lcd:
        LDX #Msj_config_1       ; Cargando LCD
        LDY #Msj_config_2
        JSR CARGAR_LCD
        ;MOVB #$BB,BIN2          ; Cargando 0s en displays de la izq
        BSET LEDS,$01           ; Encendiendo el led correspondiente
        BCLR LEDS,$06
        BCLR BANDERAS,$40       ; Borrando bandera cambio modo
mod_config_no_actualizar_lcd:
        JSR MODO_CONFIG
        BRA Main                ; Retorna al main

mod_medicion:
        BRSET BANDERAS,$40,mod_medicion_actualizar_lcd
        BRA mod_medicion_no_actualizar_lcd
mod_medicion_actualizar_lcd:
;        LDX #Msj_medicion_1       ; Cargando LCD
;        LDY #Msj_medicion_esperando_2
;        JSR CARGAR_LCD
;        BCLR BANDERAS,$40       ;CAMBIO MODO NO SE OCUPA AQUI
        BSET LEDS,$02           ; Encendiendo el led correspondiente
        BCLR LEDS,$05
        BSET PIEH,$09           ; Activando interrupcion PH0,PH3
        BSET TSCR2, $80         ; Activando interrupcion TO
mod_medicion_no_actualizar_lcd:
        JSR MODO_MEDICION
        LBRA Main                ; Retorna al main
;_______________________________________________________________________________








;*******************************************************************************
;                             SUBRUTINA MODO_MEDICION
;*******************************************************************************

MODO_MEDICION:
        TST VELOC                    ; Si velocidad es 0, termina
        BEQ MODO_MEDICION_retornar
        JSR PANT_CTRL
        RTS
MODO_MEDICION_retornar:
        LDAA #$BB
        STAA BIN1
        STAA BIN2
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---



;*******************************************************************************
;                             SUBRUTINA PANT_CTRL
;*******************************************************************************

PANT_CTRL:
        BCLR PIEH,$09           ; Desactivando interrupcion PH0,PH3
        LDAA VELOC                  ; Verificando si VELOC es valida
        CMPA #30
        BLO PANT_CTRL_vel_no_valida
        CMPA #99
        BHI PANT_CTRL_vel_no_valida
        CMPA V_LIM              ; Verificando si es mayor a la velocidad maxima
        BLO PANT_CTRL_calcular_ticks
        BSET BANDERAS,$10  ; ALARMA <-- 1
PANT_CTRL_calcular_ticks:
        BRSET BANDERAS,$20,PANT_CTRL_control_pantalla  ; SI CALC_TICKS es 0 sigue
        LDAB VELOC      ; DIVISOR
        CLRA
        TFR D,X
        LDD #16479         ; Calculo de tiempo (ver hoja de calculo informe)
        IDIV              ; Calculo de  tiempo
        TFR X,D
        STD TICK_EN        ;guardando tiempo habilitacion
        LDAB VELOC      ; DIVISOR
        CLRA
        TFR D,X
        LDD #32958         ; Calculo de tiempo (ver hoja de calculo informe)
        IDIV              ; Calculo de  tiempo
        TFR X,D
        STD TICK_DIS        ;guardando tiempo habilitacion
        ;LSLD               ; TICK_EN * 2
        ;STD TICK_DIS
        BSET BANDERAS,$20  ; CALC_TICKS = 1, para que solo se haga una vez
        BRA PANT_CTRL_control_pantalla
PANT_CTRL_vel_no_valida:   ; Si la velocidad no es valida, para imrpimir guiones 2 seg
        LDAA #$AA
        CMPA VELOC
        BEQ PANT_CTRL_control_pantalla
        MOVW #$0001,TICK_EN     ; Habilitando 2 segundos
        MOVW #$005B,TICK_DIS
        MOVB #$AA,VELOC     ; Para no volver a entrar aqui

PANT_CTRL_control_pantalla: ; Demas logica de la pantalla
        BRCLR BANDERAS,$08,PANT_CTRL_pant_encendida ; si pant_flh es 0 salta
        LDAA #$BB                   ; Verificando si ya se imprimio la pantalla 1 vez
        CMPA BIN1
        BEQ PANT_CTRL_pant_vel_encendida
        RTS
PANT_CTRL_pant_vel_encendida: ; Se pone la vel lim y la velocidad
        LDX #Msj_medicion_1       ; Cargando LCD
        LDY #Msj_medicion_su_vel_vel_lim_2
        JSR CARGAR_LCD
        MOVB V_LIM,BIN1       ; Cargando valores a displays
        MOVB VELOC,BIN2
        RTS

PANT_CTRL_pant_encendida:
        LDAA #$BB                   ; Verificando si ya se llego de PANT_FLH = 1
        CMPA BIN1
        BNE PANT_CTRL_ultimo_ciclo
        RTS
PANT_CTRL_ultimo_ciclo:
        LDX #Msj_medicion_1       ; Cargando LCD
        LDY #Msj_medicion_esperando_2
        JSR CARGAR_LCD
        LDAA #$BB                ; Dejando variables listas por ser ultimo ciclo
        STAA BIN1
        STAA BIN2
        CLR VELOC
        BSET PIEH,$09           ; Activando interrupcion PH0,PH3
        BCLR BANDERAS,$30       ; CALC_TICKS = 0 y ALERTA = 0
PANT_CTRL_retornar:
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---




;*******************************************************************************
;                             SUBRUTINA LCD
;*******************************************************************************
;Descripcion: Esta subrutina inicializa la subrutina LCD

LIBRE:
        BRSET BANDERAS,$40,mod_libre_actualizar_lcd
        RTS
mod_libre_actualizar_lcd:
        BSET LEDS,$04           ; Encendiendo el led correspondiente de modo libre
        BCLR LEDS,$03
        LDX #Msj_libre_1       ; Cargando LCD
        LDY #Msj_libre_2
        JSR CARGAR_LCD
        MOVB #$BB,BIN1
        MOVB #$BB,BIN2          ; Cargando 0s en displays de la izq
        BCLR BANDERAS,$40       ; Borrando bandera cambio modo
        RTS
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
;                             SUBRUTINA MODO_CONFIG
;*******************************************************************************
;Descripcion:


;FALTA PROBAR

MODO_CONFIG:
        BRSET BANDERAS,$04,MODO_CONFIG_tcl_lista ;Verificando si Ya hay una tecla lista
        JSR TAREA_TECLADO                        ;Leyendo una tecla
        MOVB V_LIM,BIN1                        ; Moviendo valor de V_lim a BIN1
        RTS
MODO_CONFIG_tcl_lista: ;Ya hay una tecla lista
        JSR BCD_BIN          ;Pasando de BCD a binario
        BCLR BANDERAS,$04   ; Borrando array_ok
        LDAA V_LIM          ; Verificando si tecla es valida
        CMPA #30
        BLO MODO_CONFIG_tcl_no_valida
        CMPA #99
        BHI MODO_CONFIG_tcl_no_valida
        MOVB V_LIM,BIN1     ; Pasando el valor programado a BIN1
        RTS
MODO_CONFIG_tcl_no_valida:
        CLR V_LIM           ; Valor no valido
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---














;*******************************************************************************
;                             SUBRUTINA BCD_BIN
;*******************************************************************************
;Descripcion: Esta subrutina se encarga de realizar la conversion de los numeros
; leidos en el teclado a binario y guardarlo en CPROG.
BCD_BIN:
        LDX #NUM_ARRAY
        LDAA #10
        LDAB 1,X+
        MUL             ; NUMERO MAS SIGNIFICATIVO MULTIPLICADO POR 10
        LDAA 0,X
        CMPA #$FF
        BEQ BCD_BIN_continuar
        ADDB 0,X         ; Sumando parte baja
        STAB V_LIM         ; Guardando valor binario en cprog
BCD_BIN_continuar:
        MOVB #$FF,0,X
        MOVB #$FF,1,-X
        RTS


;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---








;*******************************************************************************
;                             SUBRUTINA BIN_BCD
;*******************************************************************************

;Descripcion: Esta subrutina convierte un numero pasado como parametro por el acu-
; mulador A en binario y devuelve su valor en BCD en la variable BCD_L. Utiliza
; Como variables BCD_H y BCD_L

BIN_BCD:
        LDAB #7
        CLR BCD_L
BIN_BCD_2_main_loop:
        LSLA
        ROL BCD_L
        PSHA
        LDAA #$0F                ; Mascara de BCDX con 0F en A
        ANDA BCD_L
        CMPA #5                  ; R1 mayor igual 5
        BLO BIN_BCD2_cont
        ADDA #3
BIN_BCD2_cont:
        STAA BCD_H      ; UTILIZADO COMO VARIABLE TEMPORAL LOW
        LDAA #$F0                ; Mascara de BCDX con F0 en A
        ANDA BCD_L
        CMPA #$50
        BLO BIN_BCD2_cont_2
        ADDA #$30
BIN_BCD2_cont_2:
        ADDA BCD_H      ; BCD_H = LOW
        STAA BCD_L
        PULA
        DBEQ B, BIN_BCD2_fin
        BRA BIN_BCD_2_main_loop
BIN_BCD2_fin:              ; RETORNANDO
        LSLA
        ROL BCD_L
        RTS

;*******************************************************************************
;                             SUBRUTINA CONV_BIN_BCD
;*******************************************************************************

;Descripcion: Esta subrutina llama a BIN_BCD y guarda los valores en BCD1 y BCD2
; y hace el control de cuando poner en BCD1 y BCD2 los valores de AA o BB con los
; cuales se desplegaran -- o nada en los display de 7 segmentos
CONV_BIN_BCD:
        LDAA BIN1                         ; Verificando si BIN1 es AA o BB
        CMPA #$BB
        BEQ CONV_BIN_BCD_guardar_bin1
        CMPA #$AA
        BEQ CONV_BIN_BCD_guardar_bin1
        JSR BIN_BCD                       ; Calculando numero en BCD
        BRCLR BCD_L,$F0,CONV_BIN_BCD_borrar_1_display ; Verificando si hay que apagar algun display
        BRA CONV_BIN_BCD_guardar_bcd_l
CONV_BIN_BCD_borrar_1_display:      ; Poniendo B en el display que debe apagarse
        BSET BCD_L,%10110000
        BCLR BCD_L,%01000000
        BRA CONV_BIN_BCD_guardar_bcd_l
CONV_BIN_BCD_guardar_bin1:             ; Copia AA o BB en BCD1 segun corresponga
        MOVB BIN1,BCD1
        BRA CONV_BIN_BCD_analizar_bin2
CONV_BIN_BCD_guardar_bcd_l:           ;Guardando el dato en BCD1
        MOVB BCD_L,BCD1

CONV_BIN_BCD_analizar_bin2: ; Repite el proceso anterior con BIN2
        LDAA BIN2                         ; Verificando si BIN1 es AA o BB
        CMPA #$BB
        BEQ CONV_BIN_BCD_guardar_bin2
        CMPA #$AA
        BEQ CONV_BIN_BCD_guardar_bin2
        JSR BIN_BCD                       ; Calculando numero en BCD
        BRCLR BCD_L,$F0,CONV_BIN_BCD_borrar_1_display2 ; Verificando si hay que apagar algun display
        BRA CONV_BIN_BCD_guardar_bcd_2
CONV_BIN_BCD_borrar_1_display2:      ; Poniendo B en el display que debe apagarse
        BSET BCD_L,%10110000
        BCLR BCD_L,%01000000
        BRA CONV_BIN_BCD_guardar_bcd_2
CONV_BIN_BCD_guardar_bin2:             ; Copia AA o BB en BCD1 segun corresponga
        MOVB BIN2,BCD2
        BRA CONV_BIN_BCD_retornar
CONV_BIN_BCD_guardar_bcd_2:           ;Guardando el dato en BCD1
        MOVB BCD_L,BCD2
CONV_BIN_BCD_retornar:
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
;-------------------SUBRUTINAS RELACIONADAS A TECLADO---------------------------
;-------------------------------------------------------------------------------
;*******************************************************************************














;*******************************************************************************
;                             SUBRUTINA TAREA_TECLADO
;*******************************************************************************
; Descripcion: Esta subrutina se encarga de hacer toda la logica para leer una
; tecla de manera correcta.
TAREA_TECLADO:
        LDX #TECLAS
        LDY #NUM_ARRAY
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
;Descripcion: Esta subrutina se encarga de formar el array con las teclas presio-
; nadas por el usuario, tambien realiza el control y validacion de las distintas
; teclas presionadas. Al llenar el array esta subrutina pone la bandera ARRAY_OK
; en alto y el CONT_TCL en 0. El arreglo NUM_ARRAY utiliza como byte no valido
; el valor $FF

FORMAR_ARRAY:
        LDAB CONT_TCL        ; Cargando valores a utilizar
        CMPB MAX_TCL         ; Verificando Si ya se leyo la cantidad maxima de digitos
        BEQ FORMAR_ARRAY_lleno
        LDAA #$0E             ; Si la tecla es enter y MAX_TCL != Cont_TCL
        CMPA TECLA_IN
        BEQ FORMAR_ARRAY_enter_presionado
        LDAA #$0B             ; Si la tecla es borrar y MAX_TCL != Cont_TCL
        CMPA TECLA_IN
        BEQ FORMAR_ARRAY_borrar_presionado
        MOVB TECLA_IN,B,Y     ; Guardando la tecla
        INC CONT_TCL
        RTS
FORMAR_ARRAY_enter_presionado: ; Se presiono un enter y MAX_TCL != Cont_TCL
        TBNE B, FORMAR_ARRAY_array_ok ; Si hay al menos 1 digito
        RTS
FORMAR_ARRAY_borrar_presionado: ; Se presiono un borrar y MAX_TCL != Cont_TCL
        TBNE B, FORMAR_ARRAY_borrar_digito ; Si hay al menos 1 digito
        RTS
FORMAR_ARRAY_borrar_digito:    ; Borrando un digito
        DECB
        MOVB #$FF,B,Y
        DEC CONT_TCL
        RTS
FORMAR_ARRAY_array_ok: ;Validando el array
        CLR CONT_TCL
        BSET BANDERAS,$04
        RTS
FORMAR_ARRAY_lleno:
        LDAA #$0E             ; Si la tecla es enter y MAX_TCL = Cont_TCL
        CMPA TECLA_IN
        BEQ FORMAR_ARRAY_array_ok
        LDAA #$0B             ; Si la tecla es borrar y MAX_TCL = Cont_TCL
        CMPA TECLA_IN
        BEQ FORMAR_ARRAY_borrar_digito
        RTS

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---











;*******************************************************************************
;                                SUBRUTINA MUX_TECLADO
;*******************************************************************************
;Descripcion: Esta subrutina se encarga de leer una tecla del teclado de la
; Dragon 12. Utiliza como variable PATRON que es un contador que cuando es mayor
; a 4 (las filas del teclado) se termina la subrutina porque no se leyo ninguna
; tecla. En caso de que se lea una tecla se retorna en la variable TECLA. Si
; no existia una tecla se retorna un $FF en TECLA.

MUX_TECLADO:
        MOVB #$FF,TECLA
        MOVB #1, PATRON               ; Inicializacion de variables
        LDAA #$EF
Loop_filas:
        STAA PORTA                                 ; Poniendo en las filas el valor de prueba  (EX,DX,BX,7X)
        LDAB #10            ;Esperando un poquito mientras se escribe PORTA
wait:   DBNE B,wait         ; Ya que puede dar algunos problemas de temporizacion si no se hace esto
        LDAB PATRON                                ; Si ya se leyeron las 4 filas, termina
        CMPB #4
        BHI FIN_MUX_TECLADO
        LDAB #3
        BRCLR PORTA,$01,Tecla_encontrada           ; Verificando si alguna columna esta en 0
        DECB
        BRCLR PORTA,$02,Tecla_encontrada
        DECB
        BRCLR PORTA,$04,Tecla_encontrada
        INC PATRON                                 ; Aumentando para siguiente iteracion
        LSLA                                       ; Desplazando para obtener el siguiente valor en la parte alta del pin A (EX,DX,BX,7X)
        BRA Loop_filas
Tecla_encontrada:                                 ; Analizando cual tecla es Mediante la ecuacion: PATRON*3 - (3-Columna)
        LDAA PATRON                               ; Esta ecuacion da el indice en el areglo TECLAS
        PSHB                                      ; Guardando para utilizar posteriormente
        LDAB #3
        MUL
        TFR B,A
        PULB                                      ; Restaurando de pila
        SBA
        MOVB A,X,TECLA
FIN_MUX_TECLADO:                                 ; Retornando
        RTS

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---






;*******************************************************************************
;                                SUBRUTINA PATRON_LEDS
;*******************************************************************************
;Descripcion:


PATRON_LEDS:
        BRSET BANDERAS,$10,PATRON_LEDS_desplazar_leds ;
        LDAA #$07            ; Asegurando que no este puesto el patron de emergencia
        ANDA LEDS
        STAA LEDS
        RTS
PATRON_LEDS_desplazar_leds:            ; Logica de patron de emergencia
        LDAA #$F8
        ANDA LEDS
        LSRA
        CMPA #4
        BLS PATRON_LEDS_reiniciar_patron  ; De nuevo se enciende el LED pb7
        LDAB #$07            ; Guardanto en Leds el nuevo led encendido
        ANDB LEDS
        ABA
        STAA LEDS
        RTS
PATRON_LEDS_reiniciar_patron:
        BSET LEDS,$80
        BCLR LEDS,$08
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

RTI_ISR:        ; Teclado
                BSET CRGFLG,#$80
                TST CONT_REB      ; Si contador de rebotes es 0, no hace nada
                BEQ FIN_RTI_ISR_cont_reb
                DEC CONT_REB      ; decrementando contador de rebotes
FIN_RTI_ISR_cont_reb:                  ; Timer cuenta (modo run)
                RTI

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                                INTERRUPCION PHO_ISR
;*******************************************************************************
;Descripcion: Esta interrupcion se divide en 4 subrunitas:
; PTH0:

; PTH3:
CALCULAR:
                BRSET PIFH,$01,PTH0
                BRSET PIFH,$08,PTH3


PTH0:
        TST CONT_REB      ;Control de rebotes
        BNE PTH0_retornar
        LDAA #20          ; Para controlar rebotes
        STAA CONT_REB
        LDAB TICK_VEL      ; DIVISOR
        CLRA
        TFR D,X
        LDD #6624         ; Calculo de velocidad (ver hoja de calculo informe)
        IDIV              ; Calculo de la velocidad
        TFR X,D
        STAB VELOC         ;guardando velocidad
        CLR TICK_VEL
PTH0_retornar:
        BSET PIFH,$01     ; Desactivando interrupcion
        RTI


PTH3:
        TST CONT_REB      ;Control de rebotes
        BNE PTH3_retornar
        LDAA #20          ; Para controlar rebotes
        STAA CONT_REB
        CLR TICK_VEL
        LDX #Msj_medicion_1   ; Cargando LCD
        LDY #Msj_medicion_calculando_2
        BSET PIFH,$08     ; Desactivando interrupcion
        CLI               ; activando interrupciones
        JSR CARGAR_LCD
PTH3_retornar:
        BSET PIFH,$08     ; Desactivando interrupcion
        RTI






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
        CMPA CONT_TICKS            ; llego a 100.
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
OC4_ISR_continuar2
        LDD CONT_7SEG                 ; Calculando si ya pasaron 100ms
        CPD #5000
        BEQ OC4_ISR_llamar
        ADDD #1                       ; sumando 1 a CONT_7SEG
        STD CONT_7SEG                 ; Guaradndolo
        BRA OC4_ISR_continuar3
OC4_ISR_llamar:                       ; Cada 100ms se actualizan los datos de los display
        MOVW #0,CONT_7SEG
        JSR CONV_BIN_BCD
        JSR BCD_7SEG
OC4_ISR_continuar3:                    ; Decrementando contador de delay si no es 0
        TST CONT_DELAY
        BEQ OC4_ISR_continuar4
        DEC CONT_DELAY
OC4_ISR_continuar4:

        LDD CONT_200                ; Calculando si ya pasaron 100ms
        CPD #10000
        BEQ OC4_ISR_llamar2
        ADDD #1                       ; sumando 1 a CONT_7SEG
        STD CONT_200                 ; Guaradndolo
        BRA OC4_ISR_retornar
OC4_ISR_llamar2:                       ; Cada 100ms se actualizan los datos de los display
        MOVW #0,CONT_200
        JSR PATRON_LEDS
        MOVB #%10000111,ATD0CTL5
OC4_ISR_retornar:
        LDD TCNT                       ; Guardando en TC4 la siguiente interrupcion
        ADDD #60
        STD TC4
        BSET TFLG1,$10  ; Borrando bandera interrupcion
        RTI
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---






;*******************************************************************************
;                                INTERRUPCION ATD_ISR
;*******************************************************************************
;Descripcion: Esta subrutina se encarga de leer 6 valores guardados en los reg
; del convertidor analogico a digital en el cual esta conectado el potenciometro
; y hacer un promedio de los mismos que es guardado en la variable POT. Por
; ultimo se calcula el valor de 0 a 100 (en intervalos de 5 en 5) del brillo
; a ser mostrado en los display, este brillo es guardado en la variable BRILLO.

ATD_ISR:
        BSET ATD0STAT0,$80
        LDD ADR00H      ; Haciendo un promedio de los valores del CAD que esta
        ADDD ADR01H     ; leyendo el potenciometro
        ADDD ADR02H
        ADDD ADR03H
        ADDD ADR04H
        ADDD ADR05H

        LDX #6          ; Calculando promedio entre los 6 datos
        IDIV
        TFR x,d         ; Pasando resultado a D

        STAB POT

        LDAA #20        ; Calculando el valor de brillo
        MUL             ; 20 * POT

        LDX #255
        IDIV            ; (20 * POT) / 255
        TFR x,d         ; Pasando resultado a D

        LDAA #5         ; Calculando resultado de brillo en escala de 0 a 100
        MUL             ;( (20 * POT) / 255 ) * 5
        STAB BRILLO



        RTI

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                                INTERRUPCION TCNT_ISR
;*******************************************************************************
;Descripcion:

TCNT_ISR:
        INC TICK_VEL
        LDD TICK_EN     ; Verificando si TICK_EN llego a 0, sino lo decrementa
        BEQ TCNT_ISR_set_pant_flag
        SUBD #1
        STD TICK_EN
        BRA TCNT_ISR_continuar
TCNT_ISR_set_pant_flag:
        BSET BANDERAS, $08      ; Pantflag = 1
TCNT_ISR_continuar:
        LDD TICK_DIS     ; Verificando si TICK_EN llego a 0, sino lo decrementa
        BEQ TCNT_ISR_clear_pant_flag
        SUBD #1
        STD TICK_DIS
        BRA TCNT_ISR_retornar
TCNT_ISR_clear_pant_flag:
        BCLR BANDERAS, $08      ; Pantflag = 0
TCNT_ISR_retornar:
        BSET TFLG2,$80  ; Borrando bandera interrupcion
        RTI