;*******************************************************************************
;                                 TAREA 4
;                            TECLADO MATRICIAL
;*******************************************************************************
;
;       UNIVERSIDAD DE COSTA RICA
;       FECHA 25/10/19
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074
;       COREREO: yeisonrodriguezpacheco@gmail.com
;
;
; Descripcion:



;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS
;*******************************************************************************

        ORG $1000
MAX_TCL:        db $06      ;Cantidad de teclas que se van a leer  (longitud)
TECLA:          ds 1        ;Tecla leida en un momento t0
TECLA_IN:       ds 1        ;Tecla leida en un momento t1
CONT_REB:       db $0a      ;Contador de rebotes que espera 10ms por la subrutina RTI_ISR
CONT_TCL:       ds 1        ;
PATRON:         ds 1        ;Contador que va hasta 5, usado por MUX_TECLADO
BANDERAS:       ds 1        ;X:X:X:X:X:ARRAY_OK:TLC_LEIDA:TCL_LISTA
NUM_ARRAY:      db $ff,$ff,$ff,$ff,$ff,$ff             ;Guarda los numeros ingresados en el teclado
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E ;Tabla de teclas del teclado

#include registers.inc




;*******************************************************************************
;                       DECLARACION VECTORES INTERRUPCION
;*******************************************************************************
        ORG $3e70
        dw RTI_ISR
        
        ;
        ORG $3e4c
        dw PHO_ISR
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---



                
;*******************************************************************************
;                              PROGRAMA PRINCIPAL
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
;INICIALIZACION DE VARIABLES:
        CLI                     ; Activando interrupciones
        MOVB #$FF,TECLA
        MOVB #$FF,TECLA_IN
        CLR CONT_REB
        CLR BANDERAS
        CLR CONT_TCL
        LDX #TECLAS
        LDY #NUM_ARRAY
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
;                                INTERRUPCION RTI_ISR
;*******************************************************************************
;Descripcion: Esta subrutina se encarga de decrementar la variable CONT_REB en 1
; cada 1 ms aproximadamente, si CONT_REB es cero la subrutina no hace nada.

RTI_ISR:        BSET CRGFLG,#$80
                TST CONT_REB      ; Si contador de rebotes es 0, no hace nada
                BEQ FIN_RTI_ISR
                DEC CONT_REB      ; decrementando contador de rebotes
FIN_RTI_ISR:
                RTI

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                                INTERRUPCION PHO_ISR
;*******************************************************************************
;Descripcion: Esta subrutina se encarga de decrementar la variable CONT_REB en 1
; cada 1 ms aproximadamente, si CONT_REB es cero la subrutina no hace nada.

PHO_ISR:        BCLR BANDERAS,$04 ; Borrando bandera ARRAY_OK
                LDAB #0
                LDY #NUM_ARRAY
PHO_ISR_loop:   MOVB #$FF,B,Y
                INCB
                CMPB MAX_TCL
                BNE PHO_ISR_loop
                BSET PIFH,$01
                RTI
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---
