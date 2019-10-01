;*******************************************************************************
;                               TAREA 3
;                          VARIAS SUBRUTINAS
;*******************************************************************************
;
;       UNIVERSIDAD DE COSTA RICA
;       FECHA x/x/19
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074
;       COREREO: yeisonrodriguezpacheco@gmail.com
;
;
; Descripcion:



;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS
;*******************************************************************************
        ORG $1000
;**********************************
; DECLARACIONES GENERALES
;**********************************
CUAD:   db 4,9,16,25,36,49,64,81,100,121,144,169,196,225

;**********************************
; DECLARACIONES SUBRUTINA RAIZ
;**********************************
H__:    ds 1
X__:    ds 1


;*******************************************************************************
;                              PROGRAMA PRINCIPAL
;*******************************************************************************
        ORG $2000
        LDS #$3000
        LDX #CUAD
LOOP:
        LDAA 1,X+
        PSHX
        PSHA
        JSR RAIZ
        PULA
        PULX
        BRA LOOP

;*******************************************************************************
;                                SUBRUTINA RAIZ
;*******************************************************************************

; Esta subrutina recibe un numero de 1 byte como parametro de entrada, a este
; numero se le calcula la raiz cuadrada y el resultado tambien es devuelto por
; la pila en un dato de 1 byte, que seria la raiz cuadrada del dato.
; Esta funcion modifica todos los registros.

; Calcula la raiz cuadrada de un numero

; Parametros que usa
; H__ Variable tipo byte. Uso igual al del enunciado de la tarea (raiz)
; X__ Variable tipo byte. Uso igual al del enunciado de la tarea (raiz)

        ORG $1100
RAIZ:
        PULY             ;Guardando direccion retorno
        MOVB #1,H__
        PULA
        STAA X__         ; Guardando numero a calcular raiz en X__
        PSHA
RAIZ_main_loop:
        PULB
        CMPB H__
        BEQ RAIZ_Fin
        ADDB H__
        LSRB              ; Dividiendo por 2
        PSHB              ; Resultado se guarda en pila
        TFR B,X            ; Cargando datos de division
        CLRA
        LDAB X__
        IDIV
        XGDX
        STAB H__          ; Guardando resultado en H__
        BRA RAIZ_main_loop
RAIZ_Fin:
        PSHB            ; Valor a retornar
        PSHY            ; Direccion retorno
        RTS



;*******************************************************************************
;                                SUBRUTINA BUSCAR
;*******************************************************************************
        