;''''''''''''''''''''''''''''''' BIN_BCD Estructuras''''''''''''''''''''''''''''''''''''''
         ORG $1000
LOW:            ds 1
BCD_L:          ds 1
BCD_H:          ds 1


;''''''''''''''''''''''''''''''' Delay Estructuras''''''''''''''''''''''''''''''''''''''
        ORG $1010
LAZO_EXT:          ds 1
LAZO_MED:          ds 1
LAZO_INT:          ds 1



;''''''''''''''''''''''''''''''' MAIN Estructuras''''''''''''''''''''''''''''''''''''''
        ORG $1040
VALOR_EXT:            db 50
VALOR_MED:          db 50
VALOR_INT:          db 50

CONT_BIN:          ds 1
CUENTA:          db $79
INCRE:          ds 1


 ;'''''''''''''''''''''''''''''''Subrutina BIN_BCD''''''''''''''''''''''''''''''''''''''
         ORG $2000
BIN_BCD:
        PULX                     ;inicializando
        PULA
        LDAB #7
        CLR BCD_L
        CLR BCD_H
Main_loop:
        LSLA                     ; Rotando
        ROL BCD_L
        ROL BCD_H
        PSHA
        LDAA #$0F                ; Mascara de BCD_L con 0F en A
        ANDA BCD_L
        CMPA #5                  ; R1 mayor igual 5
        BHS Sumar_3                      ; VERIFICAR CON GD
        BRA Guardar_en_low                    ;no
Sumar_3:
        ADDA #3                  ; A += 3
Guardar_en_low:
        STAA LOW
        LDAA #$F0                ; Mascara de BCD_L con F0 en A
        ANDA BCD_L
        CMPA #$50                ; R1 mayor $50
        BHS Sumar_30
        BRA continuar
Sumar_30:
        ADDA #$30                 ;Sumando 30
continuar:
        ADDA LOW
        STAA BCD_L
        PULA
        DBEQ B, Fin                        ;; Decrementando B  Y saltando si es 0
        BRA Main_loop           ; Retorna al inicio
Fin:
        LSLA                     ; Rotando
        ROL BCD_L                ; Desplazando
        ROL BCD_H
        PSHX                     ; Direccion retorno
        RTS                     ;FIN
        
;'''''''''''''''''''''''''''''''Subrutina DELAY''''''''''''''''''''''''''''''''''''''
        ORG $2200
DELAY:
        MOVB VALOR_EXT, LAZO_EXT
Loop_medio:
        MOVB VALOR_MED, LAZO_MED
Loop_corto:
        MOVB VALOR_INT, LAZO_INT
Retardo:
        DEC LAZO_INT      ;4 ciclos
        TST LAZO_INT      ;3 ciclos
        BEQ decre_lazo_medio
        BRA Retardo
decre_lazo_medio:
        DEC LAZO_MED
        TST LAZO_MED
        BEQ decre_lazo_ext
        BRA Loop_corto
decre_lazo_ext:
        DEC LAZO_EXT
        TST LAZO_EXT
        BEQ final
        BRA Loop_medio
final:
        RTS

;'''''''''''''''''''''''''''''''Programa MAIN''''''''''''''''''''''''''''''''''''''
        ORG $2800
        LDS #$4000
        CLR CONT_BIN    ; Inicializando VARIABLES
        CLR INCRE
        INC INCRE
Main:
        LDAA #1
        CMPA INCRE
        BEQ Incre_1
        DEC CONT_BIN                ;Si incre es 0
        TST CONT_BIN
        BEQ Incre_0
        BRA Cont
Incre_0:
        INC INCRE               ; INCRE = 1 porque ya era 0
        BRA Cont
Incre_1:
        INC CONT_BIN
        LDAA CONT_BIN
        CMPA CUENTA
        BEQ Bandera_baja ;INCRE SE QUEDA EN 1
        BRA Cont
Bandera_baja:
        CLR INCRE       ; INCRE = 0
Cont:
        LDAA CONT_BIN
        PSHA            ; PUSHEAR CONTADOR BINARIO
        JSR BIN_BCD
        ;LDAA VALOR_EXT
        ;STAA VALOR_INT
        ;STAA VALOR_MED
        ;STAA VALOR_EXT
        JSR DELAY
        BRA Main
        
