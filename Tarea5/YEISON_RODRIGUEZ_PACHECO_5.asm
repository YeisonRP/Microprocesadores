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
;                        DECLARACION ESTRUCTURAS DE DATOS
;*******************************************************************************
EOM:     EQU $FF
        ORG $1000
MAX_TCL:        db $02      ;Cantidad de teclas que se van a leer  (longitud)
TECLA:          ds 1        ;Tecla leida en un momento t0
TECLA_IN:       ds 1        ;Tecla leida en un momento t1
CONT_REB:       ds 1        ;Contador de rebotes que espera 10ms por la subrutina RTI_ISR
CONT_TCL:       ds 1        ;Contador de teclas que han sido escritas, usada en FORMAR_ARRAY
PATRON:         ds 1        ;Contador que va hasta 5, usado por MUX_TECLADO
BANDERAS:       ds 1        ;COMANDO_DATO:X:X:MODSEL:CAMBIO_MODO:ARRAY_OK:TLC_LEIDA:TCL_LISTA
                            ; CAMBIO_MODO es para que la pantalla LCD solo se refresque una vez entre cada cambio de modo
                            ; MODSEL. 1 es para modo CPROG, 0 MODO RUN
                            ; COMANDO_DATO: Esta bandera es 0 si se envia un comando, 1 si se envian datos
CUENTA:         ds 1        ; Lleva la cuenta de los tornillos
ACUMUL:         ds 1        ; Contador de empaques procesados, llega a 99 y rebasa hasta 0 al sumarle mas
CPROG:          ds 1        ; Con cuanto se llena una bolsita de tornillos
VMAX:           db 250      ; Cuenta maxima a la que llega TIMER_CUENTA (subrutina run)

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
D2mS:           dB 100
D260uS:         dB 13
D60uS:          dB 3
CLEAR_LCD:      ds 1
ADD_L1:         dB $80
ADD_L2:         dB $C0
BIN1:           ds 1
BIN2:           ds 1
BCD1_aux:           ds 1        ; Digitos en BCD, los guarda la subrutina BIN_BCD
BCD2_aux:           ds 1

        ORG $1030
NUM_ARRAY:      db $ff,$ff,$ff,$ff,$ff,$ff             ;Guarda los numeros ingresados en el teclado

	ORG $1040
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E ;Tabla de teclas del teclado

	ORG $1050
SEGMENT:       dB $3f,$06,$5b,$4f,$66,$6d,$7d,$07,$7f,$6f

	ORG $1060
iniDsp:         db $04,$28,$28,$06,%00001100 ;disp on, cursor off, no blinkin
                db EOM


        
          ORG $1070       ; mensajes
Msj_config_1:    fcc "MODO CONFIG"
        db EOM
Msj_config_2:    fcc "INGRESE CPROG:"
        db EOM
Msj_run_1:    fcc "MODO RUN   "
        db EOM
Msj_run_2:    fcc "ACUMUL.-CUENTA"
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
        dw PHO_ISR
        


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
        MOVB #$F0,DDRA      ;Puerto A, parte alta salidas, parte baja entradas
        
        ;subrutina RTI_ISR:
        movb #$23,RTICTL        ; M = 2 n = 3
        bset CRGINT,#$80        ; activa rti
        
        ;subrutina PHO_ISR:
        bset PIEH,$0F           ; Activando interrupcion PH0,PH1,PH2,PH3,

        ;Inicializacion de Output compare canal 4.
        BSET TSCR1,$90 ; TEN = 1 , TFFCA = 1. Habilitando modulo timers y el borrado rapido
        CLR TSCR2 ; Preescalador = 1
        BSET TIE,$10    ; Habilitando interrupcion output compare canal 4
        BSET TIOS,$10   ; Pone como salida canal 4

        
        ; Inicializacion de Puerto B y P para uso de los display de 7 seg.
        MOVB #$FF,DDRB            ; Todas salidas puerto B (segentos de display)
        MOVB #$0F,DDRP            ; 4 salidas puerto P (activan cada display)

        ;Inicializacion puerto J para usar leds
        bset DDRJ,$02             ; Salida puerto j

        ; Inicializacion del relay
        BSET    DDRE,%00000100     ;PE2 salida para rele

        ; Pantalla LED
        MOVB #$FF,DDRK  ; Puerto K como salidas
        
;INICIALIZACION DE VARIABLES:
        CLI                     ; Activando interrupciones
        MOVB #$FF,TECLA
        MOVB #$FF,TECLA_IN
        CLR CONT_REB
        CLR BANDERAS
        BSET BANDERAS,$10       ; Poniendo el sistema en modo CONFIG
        CLR CONT_TCL
        ; DISPLAYS
        CLR CPROG
        CLR CONT_DIG
        CLR CONT_TICKS
        CLR BRILLO
        CLR BIN1
        CLR BIN2
        MOVW #0,CONT_7SEG

        LDD TCNT        ; Inicializa TC4  , esto va mas abajo
        ADDD #480
        STD TC4

        jsr LCD
        
M_loop:
        TST CPROG                 ; Si cprog es 0, solo llama a modo_config
        Beq cargar_lcd_modo_cprog:
        BRSET PTIH,$80,modsel_es_0 ; Revisando por pulling el modo (config o run(
        BCLR BANDERAS,$10
        BRA contin_main
modsel_es_0:
        BSET BANDERAS,$10
contin_main:
        BRSET BANDERAS,$10,cprog_listo    ; Salta si ya CPROG se configuro
        BRset BANDERAS,$08,invocar_run    ; Salta si se esta en modo config
        Bset BANDERAS,$08                 ; Cambio modo
        MOVB #$01,LEDS                    ; Cambian leds por el modo
        LDX #Msj_run_1
        LDY #Msj_run_2
        JSR CARGAR_LCD
invocar_run:
        JSR MODO_RUN
        LDAA CUENTA                     ; Verificando si se debe activar el rele
        CMPA CPROG
        BEQ act_rele
        BCLR PORTE,%00000100           ;Desactivando rele
        bra bin_a_bcd
act_rele:
        BSET PORTE,%00000100           ;Activando rele
        bra bin_a_bcd

cargar_lcd_modo_cprog:
        CLR CPROG            ; Reiniciando valores por el cambio de modo run a config
        CLR CUENTA
        CLR ACUMUL
        BCLR PORTE,%00000100 ;desactivando rele
        clr bin1
        BCLR BANDERAS,$08
        MOVB #$02,LEDS
        LDX #Msj_config_1
        LDY #Msj_config_2
        JSR CARGAR_LCD
        JSR MODO_CONFIG
        BRA bin_a_bcd
cprog_listo:
        BRSET BANDERAS,$08,cargar_lcd_modo_cprog   ; Verificando cambio modo
Mod_conf:
        JSR MODO_CONFIG
bin_a_bcd:
        JSR BIN_BCD
        BRA M_loop                    ; Comenzar de nuevo
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




;*******************************************************************************
;                             SUBRUTINA SEND
;*******************************************************************************
;Descripcion: Esta subrutina envia datos o comandos a pantalla LCD

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
;Descripcion: Esta subrutina se encarga de realizar la logica del modo de confi-
;guracion, principalmente el hecho de guardar el valor ingresado en el teclado en
;CPROG y posteriormente en BIN1. Ademas valida si el valor ingresado por el usua-
;rio es valido (entre 12 y 96).

MODO_CONFIG:
        BRSET BANDERAS,$04,MODO_CONFIG_tcl_lista ;Verificando si Ya hay una tecla lista
        JSR TAREA_TECLADO                        ;Leyendo una tecla
        RTS
MODO_CONFIG_tcl_lista: ;Ya hay una tecla lista
        JSR BCD_BIN          ;Pasando de BCD a binario
        BCLR BANDERAS,$04   ; Borrando array_ok
        LDAA CPROG          ; Verificando si tecla es valida
        CMPA #12
        BLO MODO_CONFIG_tcl_no_valida
        CMPA #96
        BHI MODO_CONFIG_tcl_no_valida
        MOVB CPROG,BIN1     ; Pasando el valor programado a BIN1
        RTS
MODO_CONFIG_tcl_no_valida:
        CLR CPROG           ; Valor no valido
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
        STAB CPROG         ; Guardando valor binario en cprog
BCD_BIN_continuar:
        MOVB #$FF,0,X
        MOVB #$FF,1,-X
        RTS
        

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                             SUBRUTINA MODO_RUN
;*******************************************************************************

;Descripcion: Esta subrutina se encarga de hacer todo el control del modo run
; Para mas informacion ver el enunciado de la tarea/

MODO_RUN:
        LDAA CPROG            ;Verificando Si CPROG = CUENTA
        CMPA CUENTA
        BEQ MODO_RUN_fin
        TST TIMER_CUENTA       ; SI timer cuenta no es 0 aun
        BNE MODO_RUN_fin
        INC CUENTA             ; Incrementando cuenta
        MOVB VMAX,TIMER_CUENTA ; Recargando Timer_Cuenta
        CMPA CUENTA
        BNE MODO_RUN_fin
        LDAA #99                      ; RESETEANDO ACUMUL A 0 SI PASA DE 99
        CMPA ACUMUL
        BEQ MODO_RUN_resetar_acum
        INC ACUMUL             ; Si CPROG = nueva cuenta
        BRA MODO_RUN_fin
MODO_RUN_resetar_acum:
        CLR ACUMUL
MODO_RUN_fin:                  ; Cargando valores en BIN1 y BIN2
        MOVB CUENTA,BIN1
        MOVB ACUMUL,BIN2
        RTS

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---














;*******************************************************************************
;                             SUBRUTINA BIN_BCD
;*******************************************************************************

;Descripcion: Esta subrutina pasa valores de BIN1 y BIN2 a BCD1 y BCD2

BIN_BCD:
        LDX #BIN1  ; Cargando valores iniciales
        LDY #BCD1_aux
        CLR BCD1_aux
        CLR BCD2_aux
        LDAB #3
BIN_BCD_main_loop:
        DBEQ B,BIN_BCD_fin     ; Verificando si ya se analizaron todos los numeros en BCD
        PSHB                   ; Inicializando valores  a utilizar
        LDAB #7
        LDAA 1,X+
BIN_BCD_second_loop:              ; Analizando primer nibble
        LSLA                          ;Rotando
        ROL 0,Y
        PSHA
        LDAA #$0F                ; Mascara de BCDX con 0F en A
        ANDA 0,Y
        CMPA #5                  ; R1 mayor igual 5
        BLO BIN_BCD_cont
        ADDA #3
BIN_BCD_cont:                   ; Analizando primer nibble
        STAA LOW
        LDAA #$F0                ; Mascara parte alta
        ANDA 0,Y
        CMPA #$50
        BLO BIN_BCD_cont_2
        ADDA #$30
BIN_BCD_cont_2:               ; Analizando segundo nibble
        ADDA LOW
        STAA 0,Y
        PULA
        DBEQ B, BIN_BCD_fin_loop_2
        BRA BIN_BCD_second_loop
BIN_BCD_fin_loop_2:
        PULB
        LSLA                     ; Rotando
        ROL 1,Y+                ; Desplazando
        BRA BIN_BCD_main_loop   ; Volviendo al loop principal
BIN_BCD_fin:                     ; Final del algoritmo que revisa si hay valores no validos, si es asi los pone en FF
        BRCLR BCD1_aux,$F0,BIN_BCD_bcd1_borrar
        BRA BIN_BCD_continuar:
BIN_BCD_bcd1_borrar:
        BSET BCD1_aux,$F0             ; Escribiendo un F en parte alta que no es valida
BIN_BCD_continuar:
        BRCLR BCD2_aux,$F0,BIN_BCD_bcd2_borrar
        BRA BIN_BCD_fin_2
BIN_BCD_bcd2_borrar:                   ; Escribiendo un F en parte alta que no es valida
        BSET BCD2_aux,$F0
BIN_BCD_fin_2:
        MOVB BCD1_aux,BCD1
        MOVB BCD2_aux,BCD2
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
                TST TIMER_CUENTA      ; Si contador de rebotes es 0, no hace nada
                BEQ FIN_RTI_ISR_timer_cuenta
                DEC TIMER_CUENTA
FIN_RTI_ISR_timer_cuenta:
                RTI

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                                INTERRUPCION PHO_ISR
;*******************************************************************************
;Descripcion: Esta interrupcion se divide en 4 subrunitas:
; PTH0: Borra CUENTA
; PTH1: Borra ACUMUL
; PTH2: Decrementa el brillo de los display de 7 segmentos
; PTH3: Incrementa el brillo de los display de 7 segmentos
PHO_ISR:
                BRSET PIFH,$01,PTHO
                BRSET PIFH,$02,PTH1
                BRSET PIFH,$04,PTH2
                BRSET PIFH,$08,PTH3
PTHO:
        CLR CUENTA
        BSET PIFH,$01     ; Desactivando interrupcion
        RTI
        
        
PTH1:
        CLR ACUMUL
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
        BRCLR BANDERAS,$10,OC4_ISR_continuar23    ; Apagando dos display en modo config
        BSET PTP,$03
OC4_ISR_continuar23:
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