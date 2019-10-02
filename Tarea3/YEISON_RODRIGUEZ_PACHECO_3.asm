;*******************************************************************************
;                                 TAREA 3
;                          SUBRUTINAS DEL DEBUG 12
;*******************************************************************************
;
;       UNIVERSIDAD DE COSTA RICA
;       FECHA 2/10/19
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074
;       COREREO: yeisonrodriguezpacheco@gmail.com
;
;
; Descripcion: Este programa se encarga de analizar un conjunto de datos de 1
; byte almacenados en DATOS con longitud LONG (1 byte), el programa pide al usua-
; rio la cantidad de numeros maxima a encontrar y lo almacena en una variable
; tipo byte llamada CANT. Seguidamente mostrara en pantalla las raices cuadradas
; de los numeros encontrados en DATOS.



;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS
;*******************************************************************************
        ORG $1000
LONG:   db 11
CANT:   ds 1
CONT:   ds 1

        ORG $1020
DATOS:  db 4,9,18,4,27,63,12,32,36,15,36,121,144,169,196,225,230

        ORG $1040
CUAD:   db 4,9,16,25,36,49,64,81,100,121,144,169,196,225

        ORG $1100
ENTERO: ds 13

;**********************************
; DECLARACIONES in/out DEBUG 12
;**********************************
GETCHAR: EQU $EE84
PUTCHAR: EQU $EE86
printf:  EQU $EE88
FIN:     EQU $0
CR:      EQU $0D
LF:      EQU $0A

;**********************************
; DECLARACIONES EXTRAS
;**********************************
        ORG $1300
H__:    ds 1
X__:    ds 1

Msj_0:    fcc "INGRESE EL VALOR DE CANT (ENTRE 1 Y 99):"
          db FIN
Msj_null: fcc ""
          db CR,LF,CR,LF,FIN
Msj_1:    fcc "LA CANTIDAD DE NUMEROS ENCONTRADOS : %i"
          db CR,LF,CR,LF,FIN
Msj_2:    fcc "ENTERO: "
          db FIN
Msj_3:    fcc "%i, "
          db FIN
Msj_4:    fcc "%i"
          db CR,LF,CR,LF,FIN
          
          
          
;*******************************************************************************
;                              PROGRAMA PRINCIPAL
;*******************************************************************************

	ORG $2000
        LDS #$3000
main:
	JSR LEER_CANT
        JSR BUSCAR
        JSR Print_RESULT
        BRA main
        

;*******************************************************************************
;                                SUBRUTINA LEER_CANT
;*******************************************************************************

LEER_CANT:
        LDX #0
        LDD #Msj_0
        JSR [printf,x]  ; Imprimiendo "INGRESE EL VALOR DE CANT (ENTRE 1 Y 99):"
        LDX #0
        LDAA #2
Leyendo_dato:
        PSHA
        JSR [GETCHAR,x]
        PULA
        CMPB #$30
        BMI Leyendo_dato         ; Verificando si es menor que 0
        CMPB #$3a
        BPL Leyendo_dato         ; Verificando si es mayor que 9
        DBEQ A,Procesar
	LDX #0
        JSR [PUTCHAR,x]
        STAB CANT
        BRA Leyendo_dato
Procesar:
        LDAA CANT                      ; Verificando si ambos son 0, si es asi
        CMPA #$30                      ; vuelve a pedir el segundo numero
        BNE Continuar
        CMPB #$30                      ; vuelve a pedir el segundo numero
        BNE Continuar
        LDAA #1
        BRA Leyendo_dato
Continuar:
	LDX #0
        JSR [PUTCHAR,x]
        SUBB #$30       		; calculando el numero en binario
        PSHB                            ;guardando el numero
        LDAB #10
        LDAA CANT
        SUBA #$30                       ; calculando valor binario del num mas signif
        MUL
        STAB CANT
        PULB
        ADDB CANT
        STAB CANT
        LDX #0         ; Imprimiendo "INGRESE EL VALOR DE CANT (ENTRE 1 Y 99):";Imprimiendo espacios de linea
        LDD #Msj_null
        JSR [printf,x]
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
        CLR CONT
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
;                                SUBRUTINA Print_RESULT
;*******************************************************************************
;Descripcion: Esta subrutina se encarga de imprimir la cantidad de numeros con
; raiz cuadrada encontrados, ademas de que imprime el resultado de estas raices.
; Se utiliza la subrutina printf del DEBUG12.

Print_RESULT:
        LDX #0
        CLRA            ; Guardando la cantidad de datos encontrados en pila para
        LDAB CONT       ; desplegar en pantalla
        PSHD
        LDD #Msj_1
        JSR [printf,x]  ; Imprimiendo mensaje "LA CANTIDAD DE NUMEROS ENCONTRADOS : %i"
        LEAS 2,SP
        LDX #0
        LDD #Msj_2
        JSR [printf,x]   ; Imprimiendo mensaje "ENTERO: "
        LDY #ENTERO
        LDAB CONT
Print_imprimiendo:       ; Imprimiendo numeros resultados
        DBEQ B,Print_impr_final ; Si es el ultimo numero, salta
        LDX #0
        CLRA                    ; parte alta en 0 para cargar numero de 1 byte
        PSHB                    ; en el acumulador D
        LDAB 1,Y+               ; numero en parte baja de D
        PSHY                    ; GUARDANDO direccion de imprimir sig num en pila
        PSHD
        LDD #Msj_3
        JSR [printf,x]   ; Imprimiendo Mensaje "%i,"
        LEAS 2,SP
        PULY             ; Retornar direccion de imprimir sig numero de pila
        PULB             ; Retornando contador
        BRA Print_imprimiendo
Print_impr_final:             ; Imprimiendo ultimo numero que no lleva ,
        LDX #0
        CLRA
        LDAB 0,Y
        PSHD
        LDD #Msj_4
        JSR [printf,x]   ;Imprimiendo Mensaje "%i"
        LEAS 2,SP
        RTS             ; Retornando
        
        
        
        
        

        
        