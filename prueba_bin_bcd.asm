

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
VMAX:           db 5     ; Cuenta maxima a la que llega TIMER_CUENTA (subrutina run)
TIMER_CUENTA:   ds 1        ; Variable utilizada para contar con RTI hasta VMAX (subrutina run)
LEDS:           ds 1        ; LEDS a ser encendidos
BRILLO:         ds 1        ; Brillo de los leds, se sube de 5 en 5. Va de 0 a 100
CONT_DIG:       ds 1
CONT_TICKS:     ds 1
DT:             ds 1
LOW:            ds 1
BCD1:           ds 1
BCD2:           ds 1
DISP1:          ds 1
DISP2:          ds 1
DISP3:          ds 1
DISP4:          ds 1
CONT_7SEG:      ds 2
CONT_DELAY:     ds 1
D2mS:           db 10   ; falta definir valor
D240uS:         db 10   ; falta definir valor
D60uS:          db 10   ; falta definir valor
CLEAR_LCD:      db 10   ; falta definir valor
ADD_L1:         db 10
ADD_L2:         db 10
BIN1:           db $08     ; No estaban en la declaracion original
BIN2:           db $14     ; No estaban en la declaracion original

        ORG $1030
NUM_ARRAY:      db $ff,$ff,$ff,$ff,$ff,$ff             ;Guarda los numeros ingresados en el teclado
        ORG $1040
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E ;Tabla de teclas del teclado
        ORG $1050
SEGMENT:       dB $3f,$06,$5b,$4f,$66,$6d,$7d,$07,$7f,$6f
        ORG $1060
iniDsp:         ds 10
        ORG $1070       ; mensajes
        





;*******************************************************************************
;-------------------------------------------------------------------------------
;--------------------------------------MAIN-------------------------------------
;-------------------------------------------------------------------------------
;*******************************************************************************

        ORG $2000
        LDS #$3BFF
        JSR BIN_BCD
        JSR BCD_7SEG
        BRA *
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---






;*******************************************************************************
;                             SUBRUTINA BIN_BCD
;*******************************************************************************

;DESCRIPCION:

BIN_BCD:
        LDX #BIN1  ; Cargando valores iniciales
        LDY #BCD1
        CLR BCD1
        CLR BCD2
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
BIN_BCD_fin:                              ; Final del algoritmo que revisa si hay valores no validos, si es asi los pone en FF
        BRCLR BCD1,$F0,BIN_BCD_bcd1_borrar
        BRA BIN_BCD_continuar:
BIN_BCD_bcd1_borrar:
        BSET BCD1,$F0             ; Escribiendo un F en parte alta que no es valida
BIN_BCD_continuar:
        BRCLR BCD1,$F0,BIN_BCD_bcd2_borrar
        RTS
BIN_BCD_bcd2_borrar:                   ; Escribiendo un F en parte alta que no es valida
        BSET BCD2,$F0
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---



;*******************************************************************************
;                             SUBRUTINA BCD_7SEG
;*******************************************************************************

BCD_7SEG:
        LDX #BCD2          ;Declaracion punteros iniciales
        LDY #DISP1
        LDAA #2
BCD_7SEG_main_loop:
        BEQ BCD_7SEG_FIN
        PSHA
        LDAA 0,X            ; CARGANDO NUMEROS A PROCESAR
        LDAB 0,X
        PSHX
        LDX #SEGMENT
        LSRA
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
        ANDB #$0F
        MOVB B,X,1,Y+
        PULX                         ; Preparando para el sig ciclo
        PULA
        DEX
        DECA
        BRA BCD_7SEG_main_loop
BCD_7SEG_FIN:
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---


