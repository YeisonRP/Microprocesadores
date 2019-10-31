;*******************************************************************************
;                                 TAREA 5                                      *
;                         PANTALLAS MULTIPLEXADAS                              *
;*******************************************************************************
;                                                                              *
;       UNIVERSIDAD DE COSTA RICA                                              *
;       FECHA 25/10/19                                                         *
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074                                 *
;       COREREO: yeisonrodriguezpacheco@gmail.com                              *
;                                                                              *
;                                                                              *
; Descripcion: Este programa se encarga de realizar lecturas del teclado de la *
; Dragon 12 plus de la siguiente forma:                                        *
;                                                                              *
;                 C0  C1  C2                                                   *
;                 PA0 PA1 PA2                                                  *
;                  |   |   |                                                   *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA4, R0 -  | 1 | 2 | 3 |                                                 *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA5, R2 -  | 4 | 5 | 6 |                                                 *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA6, R3 -  | 7 | 8 | 9 |                                                 *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA7, R4 -  | B | 0 | E |                                                 *
;                -------------                                                 *
;                                                                              *
; INFORMACION GENERAL:                                                         *
; Las teclas leidas por el teclado son guardadas (cuando se suelta la tecla)   *
; NUM_ARRAY. La cantidad maxima de teclas a leer es almacenada en la variable  *
; MAX_TCL, por lo que si se desea leer 3 teclas, se debe poner el valor 3 en   *
; dicha variable. El boton B permite borrar teclas si fueron ingresadas de     *
; manera erronea. El boton E permite validar las teclas que ya han sido ingre- *
; sadas. Al presionar el boton sw5 de la dragon 12 (teniendo los dip switch en *
; alto, se resetea el arreglo NUM_ARRAY y se pone en estado bajo la bandera    *
; ARRAY_OK                                                                     *
;                                                                              *
; INFORMACION ESPECIFICA:                                                      *
; Si otro programa requiere leer las teclas ingresadas en la dragon 12 se re-  *
; comienda lo siguiente para realizar una lectura.                             *
; Cuando ARRAY_OK sea 1(bit 3 de la variable BANDERAS) significa que el arreglo*
; esta listo para ser leido. Para realizar esta accion se debe leer tecla por  *
; tecla (byte a byte) del arreglo NUM_ARRAY y se debe detener la lectura hasta *
; que se llegue a un valor $FF o hasta que se hayan leido MAX_TCL teclas.      *
; En caso de que se quieran leer mas de 6 teclas se deben agregar bytes a      *
; NUM_ARRAY inicializados en $ff.                                              *
;                                                        *                     *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS
;*******************************************************************************

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
VMAX:           db 250
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
BCD1_aux:           ds 1        ; Digitos en BCD, los guarda la subrutina BIN_BCD
BCD2_aux:           ds 1
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
        

        ORG $3e70
        dw RTI_ISR
        
        ;
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
        MOVB #$F0, DDRA      ;Puerto A, parte alta salidas, parte baja entradas
        
        ;subrutina RTI_ISR:
        movb #$23,RTICTL        ; M = 2 n = 3
        bset CRGINT,#$80        ; activa rti
        
        ;subrutina PHO_ISR:
        bset PIEH,$01           ; Activando interrupcion PH0
        bset PIEH,$02           ; Activando interrupcion PH1
        bset PIEH,$04           ; Activando interrupcion PH2
        bset PIEH,$08           ; Activando interrupcion PH3
        
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
        MOVB #0,BRILLO
        MOVB #$FF, DISP1
        MOVB #$FF, DISP2
        MOVB #$FF, DISP3
        MOVB #$FF, DISP4
        MOVW #0,CONT_7SEG
        ; BORRAR ARRIBA
;PROGRAMA PRINCIPAL
;M_loop: JSR MODO_CONFIG
;        JSR BIN_BCD
;        BRSET BANDERAS,$10 M_loop
;        movb VMAX,TIMER_CUENTA  ; borrar!!
;M_loop_:  JSR MODO_RUN
;          JSR BIN_BCD
;          bra *

;PROGRAMA PRINCIPAL
M_loop: JSR MODO_CONFIG
        BRCLR BANDERAS,$04 M_loop
        JSR MODO_CONFIG
        JSR BIN_BCD
        movb VMAX,TIMER_CUENTA ; borrar!!
M_loop_:
          JSR MODO_RUN
          JSR BIN_BCD
          bra M_loop_

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
        LDX #NUM_ARRAY + 1
        LDAA #10
        LDAB 1,X+
        MUL             ; NUMERO MAS SIGNIFICATIVO MULTIPLICADO POR 10
        ADDB 0,X         ; Sumando parte baja
        STAB CPROG         ; Guardando valor binario en cprog
        RTS
        

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---



;*******************************************************************************
;                             SUBRUTINA MODO_RUN REVISAR AGAIN!!!
;*******************************************************************************

;NOTA PARA YEISON DEL FUTURO. CUANDO EN EL MAIN CAMBIO_MODO SEA 1, (SE ACTUALICEN
; LOS DATOS DE LA LCD) Y SEA PARA EL MODO RUN, SE DEBE cargar TIMER_CUENTA en el valor VMAX

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

;DESCRIPCION:

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
;Descripcion: Esta interrupcion se encarga de borrar la bandera ARRAY_OK y de
; llenar NUM_ARRAY con $FF.

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
;Descripcion:

OC4_ISR:
        LDX #DISP1
        LDAA #125                 ;Verificando si el contador de tics ya
        CMPA CONT_TICKS            ; llego a 125.
        BEQ OC4_ISR_tic_maximo
        INC CONT_TICKS             ; Iincrementando contador de tics
        BRA OC4_ISR_continuar1
OC4_ISR_tic_maximo:               ; Se debe cambiar de display
        CLR CONT_TICKS
        INC CONT_DIG
        LDAB CONT_DIG
        ANDB #$03                 ; MASCARA para solo analizar los 2 bits primeros
        MOVB B,X,PORTB                ; Mandando leds al display
        LDAA #$F7                 ; Calculando cual display se debe encender
        LDAB CONT_DIG
        ANDB #$03
OC4_ISR_loop_1:
        BEQ OC4_ISR_fin_loop1
        LSRA                      ; Se desplaza el 0 para ver cual display se enciende
        DECB
        BRA OC4_ISR_loop_1
OC4_ISR_fin_loop1:
        STAA PTP                  ; Guardando resultado obtenido
OC4_ISR_continuar1:
        LDAA #125                 ; Calculando cuando apagar el display
        SUBA BRILLO
        STAA DT
        CMPA CONT_TICKS
        BNE OC4_ISR_continuar2
        MOVB #$FF,PTP             ; Se apaga el display
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
;-------------------------------------------------------------------------------
;-----------------PROTOCOLO DE PRUEBAS REALIZADO A ESTE PROGRAMA----------------
;-------------------------------------------------------------------------------
;*******************************************************************************
;
; ------------------------------------------------------------------------------
; PRUEBA 1.
; MAX_TECLA = 5
; SECUENCIA DE TECLAS INGRESADAS: 1 8 5 B 7 E
; RESULTADO ESPERADO: 01 08 07 FF FF FF
; ESTADO: APROBADO
; ------------------------------------------------------------------------------
; PRUEBA 2.
; MAX_TECLA = 5
; SECUENCIA DE TECLAS INGRESADAS: 1 8 5 5 0 B B 3 0 E
; RESULTADO ESPERADO: 01 08 05 03 00 FF
; ESTADO: APROBADO
; ------------------------------------------------------------------------------
; PRUEBA 3.
; MAX_TECLA = 4
; SECUENCIA DE TECLAS INGRESADAS: 1 8 5 7 4 2 0 E
; RESULTADO ESPERADO: 01 08 05 07 FF FF
; ESTADO: APROBADO
; ------------------------------------------------------------------------------
; PRUEBA 4.
; MAX_TECLA = 6
; SECUENCIA DE TECLAS INGRESADAS: E B B E
; RESULTADO ESPERADO: FF FF FF FF FF FF
; ESTADO: APROBADO
; ------------------------------------------------------------------------------
; PRUEBA 5.
; MAX_TECLA = 2
; SECUENCIA DE TECLAS INGRESADAS: 7 (MANTENER 5 SEGUNDOS ) E
; RESULTADO ESPERADO:
; ESTADO: APROBADO
; ------------------------------------------------------------------------------
; PRUEBA 6.
; MAX_TECLA = 5
; SECUENCIA DE TECLAS INGRESADAS: 9 6 8 2 4 B B 8 7 E (TODO RAPIDO)
; RESULTADO ESPERADO: 09 06 08 08 07 FF
; ESTADO: APROBADO
; ------------------------------------------------------------------------------
; PRUEBA 7.
; MAX_TECLA = 6
; SECUENCIA DE TECLAS INGRESADAS: 1 8 5 2 4 B B B B B B B E B E 6 4 3 B 2 1 E
; RESULTADO ESPERADO: 06 04 02 01 FF FF
; ESTADO: APROBADO
; ------------------------------------------------------------------------------
; PRUEBA 8.
; MAX_TECLA = 5
; SECUENCIA DE TECLAS INGRESADAS: E B 2 6 4 B B E
; RESULTADO ESPERADO: 02 FF FF FF FF FF
; ESTADO: APROBADO
; ------------------------------------------------------------------------------
; PRUEBA 9.
; MAX_TECLA = 1
; SECUENCIA DE TECLAS INGRESADAS: E B 2 B E 7 B 8 E
; RESULTADO ESPERADO: 08 FF FF FF FF FF
; ESTADO: APROBADO