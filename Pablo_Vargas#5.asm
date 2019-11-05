;*********************************************************************************
;                             T5_MANEJO DE PANTALLAS
;*********************************************************************************
;           FECHA: 5 NOVIEMBRE 2019
;           AUTOR: Pablo Vargas 
;           CARNE: B57564
;           CURSO: Microprocesadores.
;           PROFESOR: Geovanny Delgado.
;
; DESCRIPCION: Este programa se trata de un sistema de conteo de tornillos el cual 
;              hace uso de la pantalla LCD, el teclado matricial, los display de 7 segmentos 
;              algunos leds, el Relay y las interrupciones de la tarjeta Dragon 12.
;.................................................................................
;.................................................................................
;                   DECLARACION DE LAS ESTRUCTURAS DE DATOS
;.................................................................................
                ORG $1000
MAX_TCL:        db 2
Tecla:          ds 1
Tecla_IN:       ds 1
Cont_Reb:       ds 1
Cont_TCL:       ds 1
Patron:         ds 1
Banderas:       ds 1      ;BANDERAS = X : X : CAMBIO_MODO : MOD_SEL : RS:ARRAY_OK : TCL_LEIDA : TCL_LISTA
CUENTA:         ds 1
ACUMUL:         ds 1
CPROG:          ds 1
VMAX:           db 250     
TIMER_CUENTA:   ds 1
LEDS:           ds 1
BRILLO:         ds 1
CONT_DIG:       ds 1
CONT_TICKS:     ds 1
DT:             ds 1 
LOW:            ds 1
BCD1:           ds 1                   
BCD2:           ds 1              ; Valores en 7 segmentos para cada display
DISP1:          ds 1
DISP2:          ds 1
DISP3:          ds 1
DISP4:          ds 1
Ajuste:         db 0              ; Constante usada en el programa del teclado
CONT_7SEG:      ds 2
Cont_Delay:     ds 1
D2mS:           db 100            ; Constantes de tiempo para la subrutina DELAY
D260uS:         db 13
D60uS:          db 3
Clear_LCD:      db $01
ADD_L1:         db $80            ; Posiciona la panatalla en la linea 1
ADD_L2:         db $C0            ; Posiciona la panatalla en la linea 2
              
                ORG $1030
Num_Array:      db $FF,$FF,$FF,$FF,$FF,$FF
                ORG $1040
Teclas:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E
                ORG $1050
SEGMENT:        db $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
                ORG $1060
IniDsp:         db $04, $28,$28,$06,$0C
                db $FF
                ORG $1070
CNF_MEN_L1:     FCC "MODO CONFIG"
                db $FF
CNF_MEN_L2:     FCC "INGRESE CPROG:"
                db $FF
RUN_MEN_L1:     FCC "MODO RUN:   "
                db $FF
RUN_MEN_L2:     FCC "ACUMUL.-CUENTA"
                db $FF
                ORG $1150             
BIN1:           ds 1
BIN2:           ds 1
BCD_L:          ds 1
;.................................................................................
;                      DECLARACION DEL VECTOR DE INTERRUPCIONES
;.................................................................................

                ORG $3E4C       ;PHO
                dw PTH_ISR
;--------------------------------------------------------------------------------
                ORG $3E66       ;OC4
                dw OC4_ISR
;--------------------------------------------------------------------------------
                ORG $3E70       ;RTI
                dw RTI_ISR
;--------------------------------------------------------------------------------

;-----------------------Etiquetas con Registros-----------------------------
;---------------------------------------------------------------------------
#include registers.inc
;.................................................................................
;.................................................................................
;                             PROGRAMA PRINCIPAL
;.................................................................................

                ORG $2000
                lds #$3bff          ; Se define la pila 

;__________________________________________________________________________________
; CONFIGURACION DE HARWARE:
;__________________________________________________________________________________

;//////////////////////////////////////// RTC /////////////////////////////////////////

                movb #$23,RTICTL           ; Se configura un tiempo de 1ms para la RTI
                bset CRGINT,#$80           ; Se habilitan las interrupciones RTI

;////////////////////////////////////// Puerto A ///////////////////////////////////////

                movb #$F0,DDRA          ; Define las entradas y salidas del puerto A
                bset PUCR, $01               ; Pone las resistencias de pull up en el puerto A

;////////////////////////////////////// Puerto H ///////////////////////////////////////

                bset PIEH,$0F           ; Habilita la interrupcion PH0-PH3 y Mod_Sel

;/////////////////////////////////////// OC4 /////////////////////////////////////////////

                bset TSCR1,$90          ; Habilita el TC
                bset TSCR2,$04          ; Define el preescalador
                bset TIOS,$10          ; Habilita la salida 4
                bset TIE,$10

; //////////////////////////////////  LEDS y DISPLAYS ////////////////////////////////////
                movb #$FF, DDRB         
                bset DDRJ,$02         ;Habilita el pin 2 del puerto J
                bset PTJ,$02          
                movb #$0f, DDRP
                movb #$0f, PTP
                
; //////////////////////////////////// RELAY/////////////////////////////////////////////
                bset DDRE,$04

; ////////////////////////////// PANTALLA LCD //////////////////////////////////////////

                bset DDRK,$FF
                
;_________________________________________________________________________________
; INICIALIZACION DE VARIABLES:
;_________________________________________________________________________________

                CLI                                 ; Activa interrupciones
                movb #$FF,Tecla               
                movb #$FF,Tecla_IN        
                clr Cont_Reb                  ; Resetea contadores y banderas
                clr Cont_TCL
                clr Banderas
                clr Patron
                clr LEDS
                clr CPROG                     
                clr BIN1
                clr BCD1
                clr BIN2
                clr BCD2                                      
                clr BRILLO
                movw #$0000,CONT_7SEG

                ldd TCNT
                addd #30
                std TC4

;---------------------------------------------------------------------------------
; Se realiza el ciclo de configuracion de la pantalla

                ldx #IniDsp
Config_Loop:    ldaa 1,x+          ; Comienza el ciclo de configuracion del LCD
                cmpa #$FF
                beq Clr_LCD
                bclr Banderas,$08    ; Se va a enviar un comando
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
                bra Config_Loop
Clr_LCD:        bclr Banderas,$08
                ldaa Clear_LCD               ; Comando para hacer clear
                jsr SEND
                movb D2mS,Cont_Delay
                jsr DELAY

MAIN_LOOP:
                tst CPROG
                beq SET_MODO_CONF
                brset PTIH,$80,MODSEL_1 ; CONFIG: mod_sel = 1 / RUN: mod_sel = 0 DIPS_WITCH
                bclr Banderas,$10          ; Pone mod_sel en 0: Modo RUN
                bra Main_Sigue
MODSEL_1:       bset Banderas,$10          ; Pone mod_sel en 1: Modo Config

Main_Sigue:
                brclr Banderas,$10,CAMBIO_MODO_RUN  

CAMBIO_MODO_CONF:
                brclr Banderas,$20,Conf         ; Revisa si hubo un cambio de modo 
SET_MODO_CONF:  bclr Banderas,$20         ; Si hubo cambio de modo hace un toggle
                bset Banderas,$10     ;Pone mod_sel en 1 al entrar a modo config
                movb #$02,LEDS
                clr CUENTA             ; Reinicia las cuentas al ingresar a modo config 
                clr ACUMUL
                clr CPROG
                clr BIN1
                bclr PORTE,$04
                ldx #CNF_MEN_L1         ; Carga los mensajes del modo config
                ldy #CNF_MEN_L2
                jsr CARGAR_LCD
Conf:           jsr MODO_CONFIG
                bra CONVERTIR_BIN_BCD

CAMBIO_MODO_RUN:
                brset Banderas,$20,Run        ; Revisa si hubo un cambio de modo
SET_MODO_RUN:   bset Banderas,$20             ; Si hubo cambio de modo hace un toggle
                movb #$01,LEDS
                ldx #RUN_MEN_L1               ; Carga los mensajes del modo run
                ldy #RUN_MEN_L2
                jsr CARGAR_LCD
Run:
                jsr MODO_RUN
                ldaa CUENTA                   ; Si CPROG = CUENTA se enciende el RELAY
                cmpa CPROG
                beq ACTIVAR_RELAY
                bclr PORTE,$04                ; Apaga el RELAY
                bra CONVERTIR_BIN_BCD

ACTIVAR_RELAY:  bset PORTE,$04                ; Enciende el RELAY

CONVERTIR_BIN_BCD:
                jsr TOP_BIN_BCD
                lbra MAIN_LOOP


;.................................................................................
;                             SUBRUTINA MODO_CONFIG
;.................................................................................
; Esta subrutina se encarga de recibir la cantidad de tornillos a contar y verifica
;  que la cantidad ingresada sea un valor permitido entre 12 y 96.

MODO_CONFIG:
                brset BANDERAS,$04,Valor_Listo ;Verificando si Ya hay una tecla lista
                jsr TAREA_TECLADO
                rts
Valor_Listo:
                jsr BCD_BIN          ;Convierte de BCD a binario el valor
                bclr BANDERAS,$04   ; Pone en cero la bandera array_ok
                ldx #Num_Array
                movb #$FF,1,x+
                movb #$FF,0,x
                ldaa CPROG
                cmpa #12
                blo Valor_INV       ; Se valida el valor
                cmpa #96
                bhi Valor_INV
                movb CPROG,BIN1     ; Mueve el valor valido ingresado a BIN1
                rts
Valor_INV:
                clr CPROG           ; Valor no valido
                rts


;*******************************************************************************
;                             SUBRUTINA MODO_RUN
;*******************************************************************************

;Descripcion: Esta subrutina se encarga de hacer todo el control del modo run
; Para mas informacion ver el enunciado de la tarea/

MODO_RUN:
                ldaa CUENTA            ;Verificando Si CPROG = CUENTA
                cmpa CPROG
                beq M_R_Retornar

                tst TIMER_CUENTA       ; SI timer cuenta no es 0 aun
                bne M_R_Retornar

                inc CUENTA             ; Incrementando cuenta
                movb VMAX,TIMER_CUENTA ; Recargando Timer_Cuenta
                ldaa CPROG
                cmpa CUENTA
                bne M_R_Retornar

                inc ACUMUL
                ldaa ACUMUL                      ; Pone ACUMUL en 0 si pasa 99
                cmpa #100
                bne M_R_Retornar

                clr ACUMUL

M_R_Retornar:   movb CUENTA,BIN1
                movb ACUMUL,BIN2
                rts                    ; Cargando valores en BIN1 y BIN2 y retorna





;.................................................................................
;                             SUBRUTINA BCD_BIN
;.................................................................................
; Esta subrutina se encarga de realizar la conversion de los numeros ingresados
;  por teclado, los cuales estan en BCD a formato binario.

BCD_BIN:
                ldx #Num_Array
                ldaa 1,x+
                ldab #$0a
                mul
                ldaa 0,x
                cmpa #$FF
                bne Valor_Correcto
                clr CPROG
                rts
Valor_Correcto:	aba
                staa CPROG
                rts
;.................................................................................
;                             SUBRUTINA BCD_7SEG
;.................................................................................
; Esta subrutina se encarga de realizar la conversion de los numeros en BCD al
; formato 7 segmentos.

BCD_7SEG:
                ldx #SEGMENT
                ldaa BCD1
                anda #$0f
                movb a,x,DISP4
                ldaa BCD1
                anda #$f0
                lsra
                lsra
                lsra
                lsra
                bne Mandar_DIS3
                clr DISP3
                bra PARTE_ALTA
Mandar_DIS3:    movb a,x,DISP3
PARTE_ALTA      brset Banderas,$20,Seguir_BCD2   ; Pregunta si esta en modo RUN para no prender los led de la parte alta
                clr DISP1
                clr DISP2
                rts

Seguir_BCD2:    ldab BCD2             ; En caso de estar en modo run se activa los displays 1 y 2
                andb #$0f
                movb b,x,DISP2
                ldab BCD2
                andb #$f0
                beq DISP_OFF
                lsrb
                lsrb
                lsrb
                lsrb
                movb b,x,DISP1
                rts

DISP_OFF        clr DISP1
                rts
                
;.................................................................................
;                             SUBRUTINA BIN_BCD
;.................................................................................
; Esta subrutina se encarga de realizar la conversion BIN_BCD de los numeros ingresados
;
TOP_BIN_BCD:    ldaa BIN1             ; Se llama al algoritmo para BIN1 y BIN2
                jsr BIN_BCD
                movb BCD_L,BCD1
                ldaa BIN2
                jsr BIN_BCD
                movb BCD_L,BCD2
                rts

BIN_BCD:        ldab #$07         ; Este es el algoritmo que realiza la conversion
                clr BCD_L                 
LOOP1:          lsla
                rol BCD_L
                psha
                ldaa #$0F
                anda BCD_L
                cmpa #5
                blo SIGA1
                adda #3
SIGA1:          staa LOW
                ldaa #$F0
                anda BCD_L
                cmpa #$50
                blo SIGA2
                adda #$30
SIGA2:          adda LOW
                staa BCD_L
                pula
                decb
                bne LOOP1
                lsla
                rol BCD_L
                rts

;.................................................................................
;                             SUBRUTINA DELAY
;.................................................................................
; Esta subrutina genera un retardo programable por el usuario utilizando OC4

DELAY:      
Delay_Loop:     tst Cont_Delay
                beq Retornar_Delay
                bra Delay_Loop
Retornar_Delay: rts

;.................................................................................
;                             SUBRUTINA CARGAR LCD
;.................................................................................
; Esta subrutina se encarga de poner los mensajes en las lineas 1 y 2 de la
;  pantalla LCD

CARGAR_LCD:
                bclr Banderas, $08   ; Para enviar un comando
                ldaa ADD_L1            ; Se ubica en la primera linea del LCD
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
LoopM1          bset Banderas, $08    ; Para enviar un Dato
                ldaa 1,x+
                cmpa #$FF
                beq L2
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
                bra LoopM1
L2:             bclr Banderas, $08   ; Para enviar un comando
                ldaa ADD_L2          ; Se ubica en la Segunda linea del LCD
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
LoopM2:         bset Banderas, $08    ; Para enviar un Dato
                ldaa 1,y+
                cmpa #$FF
                beq RetornarLCD
                jsr SEND
                movb D60uS,Cont_Delay
                jsr DELAY
                bra LoopM2
RetornarLCD:    rts


;.................................................................................
;                             SUBRUTINA SEND (COMMAND / DATA)
;.................................................................................
; Esta subrutina se encarga de enviar un commando o un dato a la pantalla LCD, 
;  y estos se envian a travez de PORTK.2-PORTk.5

SEND:
                psha
                anda #$F0
                lsra
                lsra
                staa PORTK
                brset Banderas,$08, Dato1
Comando:        bclr PORTK,$01
                bra Enable1
Dato1:          bset PORTK,$01
Enable1:        bset PORTK,$02
                movb D260uS,Cont_Delay
                jsr DELAY
                bclr PORTK,$02
                pula
                anda #$0F
                lsla
                lsla
                staa PORTK
                brset Banderas,$08, Dato2
                bclr PORTK,$01
                bra Enable2
Dato2:          bset PORTK,$01
Enable2:        bset PORTK,$02
                movb D260uS,Cont_Delay
                jsr DELAY
                bclr PORTK,$02
                rts

;.................................................................................
;                             SUBRUTINA TAREA_TECLADO
;.................................................................................
; Esta subrutina gestiona todo el proceso de ingreso y procesado de la tecla

Tarea_Teclado:  tst Cont_Reb
                bne Retorno
                jsr Mux_Teclado
                brset Tecla,$FF,ProcesaTecla
                brset Banderas,$02,Tecla_Leida    ; Revisa que la tecla este leida
                movb Tecla, Tecla_IN
                bset Banderas, $02                  ; Pone la tecla como leida
                movb #$0A,Cont_Reb                 ; Pone 10 al contador de rebotes
                bra Retorno
Tecla_Leida:    ldaa Tecla
                cmpa Tecla_IN
                beq Tecla_Lista                
                movb #$FF,Tecla
                movb #$FF,Tecla_IN
                bclr Banderas,$03       ; Borra las banderas TCL_LISTA y TCL_LEIDA 
                bra Retorno
Tecla_Lista:    bset Banderas, $01      ; Pone la bandera TCL_LISTA en 1
                bra Retorno

ProcesaTecla:   brset Banderas,$01,Guardar_Tecla  ; Si la tecla esta lista la guarda
                bra Retorno

Guardar_Tecla:  bclr Banderas,$03       ; Borra las banderas TCL_LISTA y TCL_LEIDA 
                jsr Formar_Array
Retorno:        rts

;.................................................................................
;                         SUBRUTINA MUX_TECLADO
;.................................................................................
; Esta subrutina revisa constantemente el teclado para ver si una tecla fue presionada

Mux_Teclado:    movb #$FF, Tecla
                ldaa #$EF           ; Primer patron
                movb #$01,Patron
Loop_Teclado:   ldab Patron
                cmpb #$04
                bgt Retorno_Teclado
                staa PORTA           ; Envia el patron al puerto A
                movb #$03,Ajuste
                brclr PORTA,$01,Calculo
                dec Ajuste                  ; Busca en las columnas si hay alguna tecla presionada
                brclr PORTA,$02,Calculo
                dec Ajuste
                brclr PORTA,$04,Calculo
                inc Patron
                asla                    ; Cambia al siguiente patron
                bra Loop_Teclado
Calculo:        ldaa Patron
                ldab #$03               ; Usando el patron y el ajuste calculado con el barrido de las columnas
                mul                     ; Calcula el indice de la tecla para buscarlo en la tabla de teclas
                tfr b,a
                ldab Ajuste
                sba
                clrb
                ldy #Teclas
                movb a,y,tecla
Retorno_Teclado:rts

;.................................................................................
;                         SUBRUTINA FORMAR_ARRAY
;.................................................................................
; Esta subritina se encarga de guardar en un arreglo las teclas ingresadas por el usuario
; e ignorar las teclas que no correspondan o en el momento en que no correspondan
Formar_Array:
                ldy #Num_Array
                ldab Cont_TCL
                cmpb MAX_TCL
                beq Ultima_Tecla   ; Si es la ultima tecla solo puede recibir borrar o enter
                ldaa Tecla_IN
                cmpa #$0B
                beq Borrar_T1
                ldaa Tecla_IN
                cmpa #$0E
                beq Enter_T1 
                movb Tecla_IN,b,y
                inc Cont_TCL
                bra Retorno_Array

Borrar_T1:      tst Cont_TCL         ; Prueba si es la primera tecla que se ingresa para ignorar el enter y el borrar
                bne Borrar
                bra Retorno_Array
Enter_T1:       tst Cont_TCL
                bne Enter
                bra Retorno_Array

Ultima_Tecla:   ldaa Tecla_IN
                cmpa #$0B
                beq Borrar
                ldaa Tecla_IN
                cmpa #$0E
                beq Enter
                bra Retorno_Array

Enter:          bset Banderas,#$04    ; Cuano se da enter Array_OK pasa a 1
                clr Cont_TCL            
                bra Retorno_Array

Borrar:         dec Cont_TCL 
                ldab Cont_TCL
                movb #$FF,b,y         ; Llena los espacios borrados con FF
Retorno_Array:  rts


;.................................................................................
;                        SUBRUTINA DE ATENCION DE INTERUPCION PH0
;.................................................................................

PTH_ISR:        bclr Banderas,$04      ; Pone Array_OK en cero
                brset PIFH,$01,PTHO
                brset PIFH,$02,PTH1
                brset PIFH,$04,PTH2
                brset PIFH,$08,PTH3
                rts
PTHO:
                clr CUENTA
                ldaa MAX_TCL
                ldy #Num_Array
                leay a,y
Borrar_Arreglo: movb #$FF,1,-y         ; Pone FF en los espacios del arrreglo
                cpy #Num_Array
                bne Borrar_Arreglo
                bset PIFH,$01             ; Desactivando interrupcion
                rti
PTH1:
                clr ACUMUL
                bset PIFH,$02     ; Desactivando interrupcion
                rti

PTH2:
                tst BRILLO       ; restando 5 a brillo si no es 0
                bls Brillo_Min
                dec BRILLO
                dec BRILLO
                dec BRILLO
                dec BRILLO
                dec BRILLO
Brillo_Min:
                BSET PIFH,$08     ; Desactivando interrupcion
                RTI

PTH3:
                ldaa BRILLO        ; sumando 5 al brillo si no es 100
                cmpa #100
                bhi Brillo_Max
                inc BRILLO          
                inc BRILLO
                inc BRILLO
                inc BRILLO
                inc BRILLO
Brillo_Max:
                bset PIFH,$04     ; Desactivando interrupcion
                rti


;.................................................................................
;         SUBRUTINA DE ATENCION DE INTERRUPCIONES OUTPUT COMPARE CHANNEL 4
;.................................................................................
; Esta subrutina define un contador con uso de la interrupcion OC4.
; Decrementa Cont_Delay y carga TC4

OC4_ISR:
                tst CONT_7SEG
                bne Sigue
                movw #5000,CONT_7SEG
                jsr BCD_7SEG
Sigue:          ldaa CONT_TICKS
                cmpa #100                       ; Revisa si pasaron 100 TICKS
                blt Puente1
                movb #$00, CONT_TICKS
                inc CONT_DIG            ; si CON_TICKS = 0 pone el numero el DISP correspondiente
                ldaa CONT_DIG
                cmpa #5
                blt Puente1
                clr CONT_DIG
                bset PTJ, $02                   ; Desconecta los leds
Puente1:        ldab #$F7
                tst CONT_TICKS
                beq DISPLAYS
                ldaa #100
                suba BRILLO
                staa DT
                ldaa CONT_TICKS
                cmpa DT
                blt Puente2
                movb #$FF,PTP

Puente2:        tst Cont_Delay
                beq CargarTC4             ; Carga el OC4
                dec Cont_Delay
CargarTC4:      ldd TCNT
                addd #30
                std TC4
                inc CONT_TICKS
                dec CONT_7SEG
                rti

DISPLAYS:       ldaa CONT_DIG
                cmpa #0
                bne DIS3                   ; Hace el ciclo de refrescamiento
                movb DISP4,PORTB
                stab PTP
                lbra Puente2

DIS3:           rorb
                cmpa #1
                bne DIS2
                movb DISP3,PORTB
                stab PTP
                lbra Puente2
                
DIS2:           rorb
                cmpa #2
                bne DIS1
                movb DISP2,PORTB
                stab PTP
                lbra Puente2

DIS1:           rorb
                cmpa #3
                bne ENCENDER_LEDS
                movb DISP1,PORTB
                stab PTP
                lbra Puente2

ENCENDER_LEDS:  movb #$FF,PTP
                bclr PTJ,$02
                movb LEDS,PORTB
                lbra Puente2

;.................................................................................
;                        SUBRUTINA DE ATENCION DE INTERUPCION RTI
;.................................................................................
RTI_ISR:        bset CRGFLG,#$80    ; Se deshabilitan las interrupciones RTI
                tst Cont_Reb
                beq Cuenta_Timer        ; Esta suburutina se dedica exclusivamente a reducir el contador de rebotes y
                dec Cont_Reb
Cuenta_Timer:   tst TIMER_CUENTA
                beq Retornar
                dec TIMER_CUENTA
Retornar:       rti