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
ENTERO: ds 10
CUAD:   db 4,9,16,25,36,49,64,81,100,121,144,169,196,225
LONG:   db 10
DATOS:  db 4,9,18,4,27,63,12,32,36,15

CANT:   db 7

;**********************************
; DECLARACIONES SUBRUTINA RAIZ
;**********************************
H__:    ds 1
X__:    ds 1

;**********************************
; DECLARACIONES SUBRUTINA BUSCAR
;**********************************
CONT:   ds 1
;*******************************************************************************
;                              PROGRAMA PRINCIPAL
;*******************************************************************************
        ; Raiz
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
        
        ; Buscar
        ORG $2100
        LDS #$3000
        JSR BUSCAR
        BRA *
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
;Descripcion: Esta subrutina se encarga de buscar los datos en el arreglo DATOS
; que tengan raiz cuadrada entera, ademas se debe calcular la raiz de estos nu-
; meros y guardarse en el arreglo ENTEROS. Tambien se debe llevar la cuenta de
; la cantidad de datos con raiz cuadrada entera se han encontrado, si se supera
; el limite de datos encontrados (dado por CANT) se deja de revisar el arreglo
; datos

BUSCAR:
        LDX #DATOS      ; Inicializando datos
        LDAB LONG
BUSCAR_Main_loop:
        LDAA CONT       ; Terminando el programa si ya se encontraron CANT datos
        CMPA CANT
        BEQ BUSCAR_FIN
        LDY #CUAD
        LDAA 1,X+       ; Cargando en A el valor a buscar si tiene raiz cuadrada
        PSHB            ; Guardando contador en pila
        LDAB #225       ; Para saber si ya se termino la tabla CUAD
BUSCAR_buscan_cuad:     ; Buscando si el numero esta en CUAD
        CMPA 0,Y
        BEQ BUSCAR_RAIZ ; Si esta en CUAD
        CMPB 1,Y+
        BEQ BUSCAR_Dec_cont
        BRA BUSCAR_buscan_cuad
BUSCAR_RAIZ:            ; Calculando la raiz cuadrada del numero y guardando en entero
        PSHX            ; Dato actual, guardando
        PSHA            ; Numero a calcular raiz
        JSR RAIZ        ; Calcula raiz cuadrada
        PULA            ; Raiz del numero
        PULX            ; Recuperando dato actual
        LDAB CONT
        LDY #ENTERO
        STAA B,Y        ; Guardando resultado de la raiz cuadrada en ENTERO
        INC CONT        ; Incre contador de numeros con raiz cuadrada encontrados
BUSCAR_Dec_cont:
        PULB            ; Sacando el contador de la pila
        DBEQ B,BUSCAR_FIN ; Si ya se analizo todo DATOS, termina.
        BRA BUSCAR_Main_loop
BUSCAR_FIN:
        RTS
