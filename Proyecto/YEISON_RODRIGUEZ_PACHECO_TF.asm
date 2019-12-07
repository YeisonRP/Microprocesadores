;*******************************************************************************
;                              PROYECTO FINAL                                  *
;                                RADAR 623                                     *
;*******************************************************************************
;                                                                              *
;       UNIVERSIDAD DE COSTA RICA                                              *
;       FECHA 09/12/19                                                         *
;       AUTOR: YEISON RODRIGUEZ PACHECO B56074                                 *
;       COREREO: yeisonrodriguezpacheco@gmail.com                              *
;       PROFESOR: GEOVANNY DELGADO.                                            *
;                                                                              *
; Descripcion: Este proyecto consiste en un producto que se encarga de calcu-  *
; lar la velocidad a la que se despliega un carro (al pasar por encima de dos  *
; sensores), y respectivamente mostrarla en una pantalla cuando el conductor   *
; se encuentre a 100 metros de la pantalla.                                    *
; Este producto permite configurar una velocidad maxima, en caso de que el con-*
; ductor vaya mas rapido que dicha velocidad, se encenderan unos leds de alarma*
; que serviran de aviso para que el chofer reduzca la velocidad.               *
                                   
; Debido a que es un prototipo, los sensores que detectan el carro son acciona-*
; dos con los botones ph3 y ph0.                                               *

; El sistema tiene 3 modos de funcionamiento:


; Modo libre: En este modo el sistema simplemente está esperando y no hace nada
; mas que mostrar el nombre del producto. Para este modo se debe tener ph7 ON
; y PH6 OFF. En este modo se encendera el LED PB3.

; A continuacion tenemos una ilustracion del modo:
;______________________________________________________________________________
;                 C0  C1  C2                                                   *
;                 PA0 PA1 PA2                                                  *
;                  |   |   |            PH7     PH6                            *
;                -------------        ------   ------                          *
;                |   |   |   |        ||||||   |    |                          *
;     PA4, R0 -  | 1 | 2 | 3 |        ||||||   |    |                          *
;                -------------        |    |   ||||||                          *
;                |   |   |   |        |    |   ||||||                          *
;     PA5, R1 -  | 4 | 5 | 6 |        ------   ------                          *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA6, R2 -  | 7 | 8 | 9 |                                                 *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA7, R3 -  | B | 0 | E |                                                 *
;                -------------                                                 *
;                                                                              *
;                  ----        ----        ----                                *
;                (||||||)    (      )    (      )                              *
;                  ----        ----        ----                                *
;                 LIBRE        MED.        CONF                                *
;                                                                              *
;______________________________________________________________________________


; Modo Medicion: En este Modo de funcionamiento el sistema esta esperando que 
; un carro pase por el primer sensor (ph3), al pasar por este se pone ne la LCD
; el mensaje (CALCULANDO), y cuando se presiona ph0 se calcula la velocidad del 
; vehiculo. Pero no es desplegada hasta que el vehiculo este a 100 metros de la
; misma. En este modo se enciende el led pb1.

; A continuacion tenemos una ilustracion del modo:
;______________________________________________________________________________
;                 C0  C1  C2                                                   *
;                 PA0 PA1 PA2                                                  *
;                  |   |   |            PH7     PH6                            *
;                -------------        ------   ------                          *
;                |   |   |   |        ||||||   ||||||                          *
;     PA4, R0 -  | 1 | 2 | 3 |        ||||||   ||||||                          *
;                -------------        |    |   |    |                          *
;                |   |   |   |        |    |   |    |                          *
;     PA5, R1 -  | 4 | 5 | 6 |        ------   ------                          *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA6, R2 -  | 7 | 8 | 9 |                                                 *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA7, R3 -  | B | 0 | E |                                                 *
;                -------------                                                 *
;                                                                              *
;                  ----        ----        ----                                *
;                (      )    (||||||)    (      )                              *
;                  ----        ----        ----                                *
;                 LIBRE        MED.        CONF                                *
;______________________________________________________________________________



; Modo Configuracion:  En este modo el sistema esta esperando para ser configu-
; rado con una velocidad maxima, para esto se tiene el teclado del producto 
; con el cual se pueden ingresar numeros de 45 a 90 KM/H. El led PB0 estara
; encendido en este modo

; A continuacion tenemos una ilustracion del modo:
;______________________________________________________________________________
;                                                                              *
;                 C0  C1  C2                                                   *
;                 PA0 PA1 PA2                                                  *
;                  |   |   |            PH7     PH6                            *
;                -------------        ------   ------                          *
;                |   |   |   |        |    |   |    |                          *
;     PA4, R0 -  | 1 | 2 | 3 |        |    |   |    |                          *
;                -------------        ||||||   ||||||                          *
;                |   |   |   |        ||||||   ||||||                          *
;     PA5, R1 -  | 4 | 5 | 6 |        ------   ------                          *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA6, R2 -  | 7 | 8 | 9 |                                                 *
;                -------------                                                 *
;                |   |   |   |                                                 *
;     PA7, R3 -  | B | 0 | E |                                                 *
;                -------------                                                 *
;                                                                              *
;                  ----        ----        ----                                *
;                (      )    (      )    (||||||)                              *
;                  ----        ----        ----                                *
;                 LIBRE        MED.        CONF                                *
;______________________________________________________________________________

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *











;*******************************************************************************
;                        DECLARACION DE ETIQUETAS                              *
;*******************************************************************************


;-------------------------------------------------------------------------------
EOM:     EQU $FF

; Descripcion: Es utilizado como simbolo de fin de mensaje para todos los mensa-
; jes enviados a la pantalla LCD.
;_______________________________________________________________________________


;-------------------------------------------------------------------------------
#include registers.inc
;_______________________________________________________________________________
















;*******************************************************************************
;                        DECLARACION ESTRUCTURAS DE DATOS                      *
;*******************************************************************************


        ORG $1000
;-------------------------------- $1000 a $1001 --------------------------------
BANDERAS:       ds 2        ; Banderas del sistema:

; Descripcion: Se almacena en un WORD todas las banderas del sistema, veremos
; que la distribucion es de la siguiente forma:

; --------- $1000 ----------
; X : X : X : MOD_LIB_ACTUAL : MOD_CONF_ACTUAL : MOD_MED_ACTUAL : PH3_EN : PH0_EN

; Ahora se muestra la definicion de la funcionalidad de estas banderas:
;  MOD_MED_ACTUAL: Indica con un 1 si se debe actualizar el LCD de modo MEDICION
;  MOD_CONF_ACTUAL: Indica con un 1 si se debe actualizar el LCD de modo CONFIG
;  MOD_LIB_ACTUAL: Indica con un 1 si se debe actualizar el LCD de modo LIBRE
;  PH3_EN: Se usa para habilitar ph3, debe estar en 1 al inicio
;  PH0_EN: Se usa para habilitar PH0, debe estar en 0 al inicio


; --------- $1001 ----------
; COMANDO_DATO : X : CALC_TICKS : ALERTA : PANT_FLAG : ARRAY_OK : TCL_LEIDA : TCL_LISTA

; Ahora se muestra la definicion de la funcionalidad de estas banderas:
;   CALC_TICKS: Se utiliza en la subrutina PANT_CTRL
;   ALERTA: Bandera que esta en 1 cuando se debe poner el patron de LEDS de alerta
;   PANT_FLAG: Se utiliza en la subrutina PANT_CTRL para saber cuando desplegar en pant
;   ARRAY_OK: Bandera que esta en 1 cuando el array del teclado esta listo
;   TCL_LEIDA: Bandera que se pone en 1 cuando se lee una tecla del teclado
;   TCL_LISTA: Se pone en 1 cuando la tecla es soltada (esta lista)
;   COMANDO_DATO: Esta bandera es 0 si se envia un comando, 1 si se envian datos

;_______________________________________________________________________________

;------------------------------------ $1002 ------------------------------------
V_LIM:          ds 1

; Descripcion: Variable tipo byte que almacena la velocidad limite del vehicu-
; lo.
;_______________________________________________________________________________


;------------------------------------ $1003 ------------------------------------
MAX_TCL:        db $02

; Descripcion: Indica la cantidad maxima de teclas a ser ingresadas en el tecla-
; do.
;_______________________________________________________________________________


;------------------------------------ $1004 ------------------------------------
TECLA:          ds 1

; Descripcion: Es utilizada para almacenar una tecla justo cuando se presiona
; un boton del teclado.
;_______________________________________________________________________________


;------------------------------------ $1005 ------------------------------------
TECLA_IN:       ds 1

; Descripcion: Es utilizada para comparar con TECLA y ver si la tecla presionada
; era valida
;_______________________________________________________________________________


;------------------------------------ $1006 ------------------------------------
CONT_REB:       ds 1

; Descripcion: Es utilizada para controlar rebotes de botones. Es decrementado
; por la interrupcion RTI
;_______________________________________________________________________________


;------------------------------------ $1007 ------------------------------------
CONT_TCL:       ds 1        ;Contador de teclas que han sido escritas, usada en FORMAR_ARRAY

; Descripcion: Es utilizada para contar la cantidad de teclas ya guardadas del
; teclado.
;_______________________________________________________________________________


;------------------------------------ $1008 ------------------------------------
PATRON:         ds 1

; Descripcion: Utilizada para contar hasta 5 en MUX_TECLADO, con el fin de tener
; una correcta obtencion de la tecla presionada en el teclado.
;_______________________________________________________________________________


;-------------------------------- $1009 a 100A ---------------------------------
NUM_ARRAY:      db $ff,$ff             ;Guarda los numeros ingresados en el teclado

; Descripcion: Tabla de tamano WORD usada para almacenar las teclas presionadas
; en el teclado matricial.
;_______________________________________________________________________________


;------------------------------------ $100B ------------------------------------
BRILLO:         ds 1        ; Brillo de los leds, se sube de 5 en 5. Va de 0 a 100 es la variable K

; Descripcion: Utilizada para controlar el brillo de los LEDS y los display de
; 7 segmentos. Va de 0 a 100. Es modificada por el ATD
;_______________________________________________________________________________


;------------------------------------ $100C ------------------------------------
POT:            ds 1        ; Es el valor leido en el potenciometro.

; Descripcion: Esta variable almacena el valor leido en el potenciometro.
;_______________________________________________________________________________


;-------------------------------- $100D a $100E --------------------------------
TICK_EN:        ds 2

; Descripcion: Esta variable tipo WORD almacena una cantidad de TICKS calculados
; por el programador. Cuando estos ticks llegan a 0 (TCNT los decrementa) se pone
; la bandera PANT_FLAG en 1, con lo cual se enciende la pantalla de 7 segmentos.
; Solo es valida en modo medicion.
;_______________________________________________________________________________


;-------------------------------- $100F a $1010 --------------------------------
TICK_DIS:       ds 2

; Descripcion: Esta variable tipo WORD almacena una cantidad de TICKS calculados
; por el programador. Cuando estos ticks llegan a 0 (TCNT los decrementa) se pone
; la bandera PANT_FLAG en 0, con lo cual se apaga  la pantalla de 7 segmentos.
; Solo es valida en modo medicion.
;_______________________________________________________________________________


;------------------------------------ $1011 ------------------------------------
VELOC:          ds 1

; Descripcion: Esta variable almacena la velocidad en KM/H a la que va el vehi-
; culo
;_______________________________________________________________________________


;------------------------------------ $1012 ------------------------------------
TICK_VEL:       ds 1

; Descripcion: Esta variable es utilizada para contar ticks cada vez que llega
; la interrupcion TCNT. Con estos ticks se calcula la velocidad en KM/H
;_______________________________________________________________________________


;------------------------------------ $1013 ------------------------------------
BIN1:           ds 1

; Descripcion: Variable que almacena un valor en binario con el fin de que se
; despliegue en la pantalla de 7 segmentos.
;_______________________________________________________________________________


;------------------------------------ $1014 ------------------------------------
BIN2:           ds 1

; Descripcion: Variable que almacena un valor en binario con el fin de que se
; despliegue en la pantalla de 7 segmentos.
;_______________________________________________________________________________


;------------------------------------ $1015 ------------------------------------
BCD1:           ds 1

; Descripcion: Almacena en los primeros 4 bits un numero en BCD, de igual forma
; en los ultimos 4 bits. Estos valores seran desplegados en la pantalla de 7 seg
; No se debe utilizar esta variable para mandar datos a los display, debe utili-
; zarse BIN1 o BIN2
;_______________________________________________________________________________


;------------------------------------ $1016 ------------------------------------
BCD2:           ds 1

; Descripcion: Almacena en los primeros 4 bits un numero en BCD, de igual forma
; en los ultimos 4 bits. Estos valores seran desplegados en la pantalla de 7 seg
; No se debe utilizar esta variable para mandar datos a los display, debe utili-
; zarse BIN1 o BIN2
;_______________________________________________________________________________


;------------------------------------ $1017 ------------------------------------
BCD_L:          ds 1

; Descripcion: Utilizada para calcular numeros de binario a BCD.
;_______________________________________________________________________________


;------------------------------------ $1018 ------------------------------------
BCD_H:          ds 1

; Descripcion: Utilizada para calcular numeros de binario a BCD.
;_______________________________________________________________________________


;------------------------------------ $1019 ------------------------------------
DISP1:          ds 1        ; Los 4 valores de los display que se escriben en PORTB

; Descripcion: Contiene la codificacion de 7 segmentos de un numero que sera
; desplegado en los disply de 7 segmentos.
;_______________________________________________________________________________


;------------------------------------ $101A ------------------------------------
DISP2:          ds 1

; Descripcion: Contiene la codificacion de 7 segmentos de un numero que sera
; desplegado en los disply de 7 segmentos.
;_______________________________________________________________________________


;------------------------------------ $101B ------------------------------------
DISP3:          ds 1

; Descripcion: Contiene la codificacion de 7 segmentos de un numero que sera
; desplegado en los disply de 7 segmentos.
;_______________________________________________________________________________


;------------------------------------ $101C ------------------------------------
DISP4:          ds 1

; Descripcion: Contiene la codificacion de 7 segmentos de un numero que sera
; desplegado en los disply de 7 segmentos.
;_______________________________________________________________________________


;------------------------------------ $101D ------------------------------------
LEDS:           ds 1

; Descripcion: Esta variable controla cuales LEDS estan encendidos y cuales no.
;_______________________________________________________________________________


;------------------------------------ $101E ------------------------------------
CONT_DIG:       ds 1

; Descripcion: Esta variable es utilizada por la interrupcion OC4 con el fin de
; controlar cual de los display se va a encender, debido a que se encienden por
; multiplexacion de pantalla.
;_______________________________________________________________________________


;------------------------------------ $101F ------------------------------------
CONT_TICKS:     ds 1

; Descripcion: Cuenta ticks en la subrutina output compare, con el fin de contro
; lar el ciclo de trabajo de cada una de los display de 7 segmentos, y asi bajar
; les o subirles el brillo segun corresponda.
;_______________________________________________________________________________


;------------------------------------ $1020 ------------------------------------
DT:             ds 1

; Descripcion: Es utilizada para calcular el ciclo de trabajo en la interrupcion
; OC4, con el fin de controlar el tiempo de encendido de los display de 7 seg.
;_______________________________________________________________________________


;-------------------------------- $1021 a $1022 --------------------------------
CONT_7SEG:      ds 2

; Descripcion: Contador controlado por OC4 con el fin de que cada 1/10 s se
; llame a BCD_7SEG para que actualice los valores de la pantalla de 7 seg.
;_______________________________________________________________________________


;-------------------------------- $1023 a $1024 --------------------------------
CONT_200:       ds 2

; Descripcion: Contador controlado por la interrupcion OC4 con el fin de que
; cada 1/5 s se escriba el registro ATD0CTRL5 para iniciar un ciclo de conver-
; sion del ATD. Tambien para llamar a Patron Leds
;_______________________________________________________________________________


;------------------------------------ $1025 ------------------------------------
CONT_DELAY:     ds 1

; Descripcion: Variable utilizada para que se decremente en la subrutina OC4, con
; el fin de que se pueda contar delay de tiempos para controlar la pantalla LCD.
;_______________________________________________________________________________


;------------------------------------ $1026 ------------------------------------
D2mS:           dB 100

; Descripcion: Utilizado para generar un delay de 2 mili segundos.
;_______________________________________________________________________________


;------------------------------------ $1027 ------------------------------------
D260uS:         dB 13

; Descripcion: Utilizado para generar un delay de 260 u segundos.
;_______________________________________________________________________________


;------------------------------------ $1028 ------------------------------------
D60uS:          dB 3

; Descripcion: Utilizado para generar un delay de 60 u segundos.
;_______________________________________________________________________________


;------------------------------------ $1029 ------------------------------------
CLEAR_LCD:      ds 1

; Descripcion: Utilizada para el control de la pantalla LCD
;_______________________________________________________________________________


;------------------------------------ $102A ------------------------------------
ADD_L1:         dB $80

; Descripcion: Utilizada para el control de la pantalla LCD
;_______________________________________________________________________________


;------------------------------------ $102B ------------------------------------
ADD_L2:         dB $C0

; Descripcion: Utilizada para el control de la pantalla LCD
;_______________________________________________________________________________


;-------------------------------- $1030 a $103B --------------------------------
        ORG $1030
TECLAS:         db $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E

; Descripcion: Tabla que contiene los valores de las teclas presionadas en el
; teclado matricial
;_______________________________________________________________________________


;-------------------------------- $1040 a $104B --------------------------------
        ORG $1040
SEGMENT:       dB $3f,$06,$5b,$4f,$66,$6d,$7d,$07,$7f,$6f,$40,$00

; Descripcion: Tabla que contiene las traducciones de BCD a 7 segmentos de los
; numeros del 0 al 9. Ademas de que el numero A de la tabla es utilizado para
; encender dos guiones y el numero B para apagar los display.
;_______________________________________________________________________________


;-------------------------------- $1050 a $1055 --------------------------------
        ORG $1050
iniDsp:         db $04,$28,$28,$06,%00001100 ;disp on, cursor off, no blinkin
                db EOM

; Descripcion: Tabla de comandos utilizados para inicializar la pantalla LCD.
;_______________________________________________________________________________


;-------------------------------- $1060 a $1071 --------------------------------
        ORG $1060
Msj_config_1:    fcc "  MODO CONFIG.  "
        db EOM
        
; Descripcion: Mensaje utilizado en el modo configuracion, es desplegado en el
; LCD
;_______________________________________________________________________________


;-------------------------------- $1072 a $1083 --------------------------------
Msj_config_2:    fcc " VELOC. LIMITE  "
        db EOM
        
; Descripcion: Mensaje utilizado en el modo Config para indicar la velocidad
; Limite a la que puede ir un auto.
;_______________________________________________________________________________


;-------------------------------- $1084 a $1095 --------------------------------
Msj_libre_1:    fcc "  RADAR   623   "
        db EOM
        
; Descripcion: Mensaje utilizado en el modo Libre que indica el nombre del pro-
; ducto.
;_______________________________________________________________________________


;-------------------------------- $1096 a $10A7 --------------------------------
Msj_libre_2:    fcc "  MODO LIBRE    "
        db EOM
        
; Descripcion: Mensaje utilizado en el modo Libre que indica que se esta en el
; modo libre.
;_______________________________________________________________________________


;-------------------------------- $10A8 a $10B9 --------------------------------
Msj_medicion_1:    fcc " MODO MEDICION  "
        db EOM
        
; Descripcion: Mensaje utilizado en el modo Medicion que indica el modo.
;_______________________________________________________________________________


;-------------------------------- $10BA a $10CB --------------------------------
Msj_medicion_calculando_2:    fcc "  CALCULANDO... "
        db EOM
        
; Descripcion: Mensaje utilizado cuando se esta calculando la velocidad.
;_______________________________________________________________________________


;-------------------------------- $10CC a $10DD --------------------------------
Msj_medicion_esperando_2:    fcc "  ESPERANDO...  "
        db EOM
        
; Descripcion: Mensaje utilizado cuando se esta esperando a que pase un auto.
;_______________________________________________________________________________


;-------------------------------- $10DE a $10EF --------------------------------
Msj_medicion_su_vel_vel_lim_2:    fcc "SU VEL. VEL.LIM "
        db EOM
        
; Descripcion: Mensaje utilizado para mostrarle al auto la velocidad a la que
; va y la velocidad limite.
;_______________________________________________________________________________

















;*******************************************************************************
;                       DECLARACION VECTORES INTERRUPCION
;*******************************************************************************
        ; Vector interrupcion relocalizado del output compare canal 4
        ORG $3e66
        dw OC4_ISR

        ; Vector interrupcion relocalizado del real time interrupt
        ORG $3e70
        dw RTI_ISR

        ; Vector de interrupcion relocalizado de key wakeups
        ORG $3e4c
        dw CALCULAR

        ; Vector de interrupcion relocalizado ATD
        ORG $3E52
        dw ATD_ISR

        ; Vector de interrupcion relozalizado del Timmer Overflow
        ORG $3E5E
        dw TCNT_ISR
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---















;*******************************************************************************
;-------------------------------------------------------------------------------
;--------------------------------------MAIN-------------------------------------
;-------------------------------------------------------------------------------
;*******************************************************************************

        ORG $2000


;-_-_-_-_-_-_-_-_-_-_-_-_ INICIALIZACION DE HARDWARE: -_-_-_-_-_-_-_-_-_-_-_-_-_


;____________________________________ ATD ______________________________________

        MOVB #$C2,ATD0CTL2      ; Activa el ATD y las interrupciones
        LDAA #240
INICIAR_ATD:
        dbne A,INICIAR_ATD            ;retardo convertidor
        MOVB #%00110000,ATD0CTL3      ; 6 conversiones por canal
        MOVB #%10110111,ATD0CTL4      ; Define frecuencia en 500KHz y 4 periodos del itempo de muestreo
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
        BSET TSCR2, $83 ; Preescalador = 8
        BSET TIE,$10    ; Habilitando interrupcion output compare canal 4
        BSET TIOS,$10   ; Pone como salida canal 4
        BSET TSCR2,$80         ; Activando interrupcion TO

        LDD TCNT
        ADDD #60
        STD TC4
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

        LDS #$3BFF
        CLI                     ; Activando interrupciones
        MOVB #$FF,TECLA
        MOVB #$FF,TECLA_IN
        CLR CONT_REB
        MOVW #0,BANDERAS
        BSET BANDERAS,$1E  ; Activando: MOD_MED_ACTUAL,MOD_CONFIG_ACTUAL,MOD_LIB_ACTUAL,PH3_EN.
        CLR CONT_TCL
        CLR V_LIM
        CLR VELOC
        CLR CONT_DIG
        CLR CONT_TICKS
        CLR BRILLO
        CLR BIN1
        CLR BIN2
        MOVW #0,CONT_7SEG

        jsr LCD         ; Inicializar LCD
;_______________________________________________________________________________


















        ; X : X : X : MOD_LIB_ACTUAL : MOD_CONF_ACTUAL : MOD_MED_ACTUAL : PH3_EN : PH0_EN :

;-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_ Main -_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-

Main:
        TST V_LIM               ; Verificando que la velocida sea valida
        BEQ mod_conf       ; Si no es asi, solo se puede estar en modo Libre o Config
        BRSET PTIH,$C0,mod_med  ; Salta a modo medicion
        ; Este segmento inhabilita y borra todas los respectivos componentes que
        ; podrian causar problemas al venir del modo medicion.
        BCLR BANDERAS,$03     ; Desactiva habilitacion de botones ph3 y ph0
        CLR VELOC               ; Borra velocidad
        MOVW #0,TICK_EN         ; Borrando ticks habilitadores de pantalla
        MOVW #0,TICK_DIS        ; Borrando ticks deshabilitadores de pantalla
        BCLR BANDERAS+1,$38       ; Desactiva ALERTA y PANT_FLAG Y CALC_TICKS
        
        BRCLR PTIH,$C0,mod_conf ; Verificando si es modo config
        JSR LIBRE
        LBRA Main               ; Vuelve al main

mod_conf:
        BRCLR BANDERAS,$08,mod_conf_no_act_LCD
        BSET BANDERAS,$14      ; Arreglando banderas de cambios de modo
        BCLR BANDERAS,$08

        LDX #Msj_config_1      ; Cargando LCD con mensaje de modo configuracion
        LDY #Msj_config_2
        JSR CARGAR_LCD
        
        MOVB #$01,LEDS          ; Arreglando los LEDS de modo
        MOVB #$BB,BIN2          ; Para borrar BIN2 en modo config
        
        BCLR TSCR2,$80          ; Desactivando interrupciones TO y Key Wake Ups
        BCLR PIEH,$09
        
mod_conf_no_act_LCD:
        JSR MODO_CONFIG
        LBRA Main               ; Vuelve al main
        
mod_med:
        BRCLR BANDERAS,$04,mod_med_no_act_LCD
        BSET BANDERAS,$18      ; Arreglando banderas de cambios de modo
        BCLR BANDERAS,$04
        
        LDX #Msj_medicion_1      ; Cargando LCD con mensaje de modo medicion
        LDY #Msj_medicion_esperando_2
        JSR CARGAR_LCD
        
        MOVB #$02,LEDS          ; Arreglando los LEDS de modo
        BSET BANDERAS,$02     ; Activa boton ph3
        
        bset TSCR2,$80          ; Activando interrupciones
        BSET PIEH,$09
        
mod_med_no_act_LCD:
        JSR MODO_MEDICION
        LBRA Main               ; Vuelve al main

;_______________________________________________________________________________


















;*******************************************************************************
;                             SUBRUTINA MODO_MEDICION
;*******************************************************************************
;                                  Encabezado
; Descripcion
;
; Parametros de entrada (Como se le pasan)
;
; Parametros de salida (como se reciben)
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
;                                  Encabezado
; Descripcion: Esta subrutina es utilizada en el modo medicion para controlar
; la temporizacion de todo el proceso de control de la pantalla LCD y 7 Seg
; despues de haber presionado el boton ph0. Por lo que se hace el calculo de
; cuanto tiempo falta para que llegue el auto a 100m de la pantalla y despliega
; la velocidad del auto cuando esta a 100 metros. Cuando el auto pasa la panta-
; lla apaga los display. Esta subrutina es llamada en la subrutina MODO_MEDICION
;
; Parametros de entrada: N/A
;
; Parametros de salida: N/A
;*******************************************************************************

PANT_CTRL:
        BCLR PIEH,$09           ; Desactivando interrupcion PH0,PH3
        LDAA VELOC                  ; Verificando si VELOC es valida
        CMPA #30
        BLO PANT_CTRL_vel_no_valida
        CMPA #99
        BHI PANT_CTRL_vel_no_valida
        CMPA V_LIM              ; Verificando si es mayor a la velocidad maxima
        BLS PANT_CTRL_calcular_ticks
        BSET BANDERAS+1,$10  ; ALARMA <-- 1
PANT_CTRL_calcular_ticks:
        BRSET BANDERAS+1,$20,PANT_CTRL_control_pantalla  ; SI CALC_TICKS es 0 sigue
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
        BSET BANDERAS+1,$20  ; CALC_TICKS = 1, para que solo se haga una vez
        BRA PANT_CTRL_control_pantalla
PANT_CTRL_vel_no_valida:   ; Si la velocidad no es valida, para imrpimir guiones 2 seg
        LDAA #$AA
        CMPA VELOC
        BEQ PANT_CTRL_control_pantalla
        MOVW #$1,TICK_EN     ; Habilitando 2 segundos
        MOVW #$5B,TICK_DIS
        MOVB #$AA,VELOC     ; Para no volver a entrar aqui

PANT_CTRL_control_pantalla: ; Demas logica de la pantalla
        BRCLR BANDERAS+1,$08,PANT_CTRL_pant_encendida ; si pant_flh es 0 salta
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
        BCLR BANDERAS+1,$30       ; CALC_TICKS = 0 y ALERTA = 0
        BSET BANDERAS,$02     ; Bandera que habilita ph3
PANT_CTRL_retornar:
        RTS

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---



;*******************************************************************************
;                             SUBRUTINA LIBRE
;*******************************************************************************
;                                  Encabezado
; Descripcion: Esta subrutina controla el modo libre, simplemente se encarga de
; actualizar la pantalla LCD una unica vez cuando se llega a este modo. Tambien
; en ese instante actualiza los LEDS, desactiva las interrupciones de TO y KWU y
; apaga los display de 7 segmentos.
;
; Parametros de entrada: N/A
;
; Parametros de salida: N/A
;*******************************************************************************

LIBRE:
        BRSET BANDERAS,$10,mod_libre_actualizar_lcd
        RTS
mod_libre_actualizar_lcd:
        
        BSET BANDERAS,$0C     ; Cargando banderas correspondientes de camb modo
        BCLR BANDERAS,$10     ; Borrando bandera de este modo
        
        LDX #Msj_libre_1       ; Cargando LCD
        LDY #Msj_libre_2
        JSR CARGAR_LCD

        MOVB #$04,LEDS          ; Cargando el led correspondiente
        
        BCLR TSCR2,$80          ; Desactivando interrupciones TO y Key Wake Ups
        BCLR PIEH,$09
        
        MOVB #$BB,BIN1          ; Cargando 0s en displays
        MOVB #$BB,BIN2
        
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---




;*******************************************************************************
;                             SUBRUTINA LCD
;*******************************************************************************
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de inicializar la pantalla LCD en el
; comienzo de la ejecucion del programa. Esta operacion solo se realiza una vez
; antes de entrar al main principal.
;
; Parametros de entrada: N/A
;
; Parametros de salida: N/A
;*******************************************************************************
LCD:
        LDX #iniDsp
Loop_lcd_inic:
        LDAA 1,X+
        CMPA #EOM
        BEQ FIN_Loop_lcd_inic
        BCLR BANDERAS+1, $80            ; para mandar un comando
        JSR SEND
        MOVB D60uS,CONT_DELAY
        JSR DELAY
        BRA Loop_lcd_inic
FIN_Loop_lcd_inic:
        LDAA #$01              ; CLEAR DISPLAY
        BCLR BANDERAS+1, $80            ; para mandar un comando
        JSR SEND
        MOVB D2ms,CONT_DELAY
        JSR DELAY
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---





;*******************************************************************************
;                             SUBRUTINA SEND
;*******************************************************************************
;                                  Encabezado
; Descripcion: Esta subrutina envia datos o comandos a pantalla LCD. Es utiliza-
; da por la subrutina CARGAR_LCD y LCD.
;
; Parametros de entrada: La bandera COMANDO_DATO. Si esta en 0 se manda un co-
; mando. Si esta en 1 se desea mandar un dato.
;
; Parametros de salida: N/A
;*******************************************************************************

SEND:
        PSHA
        andA #$F0
        LSRA
        LSRA
        STAA PORTK
        BRCLR BANDERAS+1,$80,SEND_comando  ; 0 COMANDO, 1 DATO
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
        BRCLR BANDERAS+1,$80,SEND_comando2  ; 0 COMANDO, 1 DATO
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
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de enviar mensajes a la pantalla LCD.
; Solo es necesario pasar los mensajes por los punteros X y Y y la subrutina se
; encarga de hacer el resto.
;
; Parametros de entrada: En X recibe el puntero de inicio del mensaje que se
; quiere desplegar en la parte de arriba de la LCD. En Y recibe el mensaje que
; se quiere desplegar en la parte de abajo de la LCD.
;
; Parametros de salida: N/A
;*******************************************************************************

CARGAR_LCD:
        LDAA ADD_L1
        BCLR BANDERAS+1, $80            ; para mandar un comando
        JSR SEND
        MOVB D60uS,CONT_DELAY
        JSR DELAY
CARGAR_LCD_first_loop:
        LDAA 1,X+
        CMPA #EOM
        BEQ CARGAR_LCD_first_loop_end
        BSET BANDERAS+1, $80            ; para mandar un dato
        JSR SEND
        MOVB D60uS,CONT_DELAY
        JSR DELAY
        BRA CARGAR_LCD_first_loop
CARGAR_LCD_first_loop_end:
        LDAA ADD_L2
        BCLR BANDERAS+1, $80            ; para mandar un comando
        JSR SEND
        MOVB D60uS,CONT_DELAY
        JSR DELAY
        
CARGAR_LCD_SECOND_loop:
        LDAA 1,Y+
        CMPA #EOM
        BEQ CARGAR_LCD_SECOND_loop_end
        BSET BANDERAS+1, $80            ; para mandar un dato
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
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de generar delays a partir de la variable
; CONT_DELAY. Esta subrutina debe ser utilizada con precaucion ya que es senci-
; llo de notar que detiene el procesador (no las interrupciones) por alguna can-
; tidad de tiempo programada por el usuario.
;
; Parametros de entrada: Se recibe un valor en CONT_DELAY. Por ejemplo un valor
; de CONT_DELAY de 50 da una interrupcion de 1x10-3 segundos, debido a que cada
; decremento de CONT_DELAY se da cada 20us por la interrupcion OC4.
;
; Parametros de salida: N/A
;*******************************************************************************
DELAY:
        TST CONT_DELAY
        BNE DELAY
        RTS
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---







;*******************************************************************************
;                             SUBRUTINA MODO_CONFIG
;*******************************************************************************
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de administrar el modo configuracion.
; Su principal tarea es llamar a las subrutinas que controlan el teclado como
; TAREA_TECLADO. Al recibir el valor leido en el teclado verifica si es valido,
; de ser asi almacena este valor valido en V_LIM.
;
; Parametros de entrada: N/A
;
; Parametros de salida: N/A
;*******************************************************************************


MODO_CONFIG:
        BRSET BANDERAS+1,$04,MODO_CONFIG_tcl_lista ;Verificando si Ya hay una tecla lista
        JSR TAREA_TECLADO                        ;Leyendo una tecla
        MOVB V_LIM,BIN1                        ; Moviendo valor de V_lim a BIN1
        RTS
MODO_CONFIG_tcl_lista: ;Ya hay una tecla lista
        JSR BCD_BIN          ;Pasando de BCD a binario
        BCLR BANDERAS+1,$04   ; Borrando array_ok
        LDAA V_LIM          ; Verificando si tecla es valida
        CMPA #45
        BLO MODO_CONFIG_tcl_no_valida
        CMPA #90
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
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de realizar la conversion de los nume-
; ros leidos en el teclado matricial que estan en BCD y pasarlo a binario.
; Ademas esta subrutina controla que los numeros enviados sigan el formato:
; 03, 06, y no el formato 6, 3, porque genera problemas. El numero convertido
; es guardado en V_LIM.
;
; Parametros de entrada: En la direccion NUM_ARRAY se envian los numeros a con-
; vertir a binario. La cantidad de numeros esta dada por MAX_TCL.
;
; Parametros de salida: Guarda velocidad en binario en V_LIM
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
        BEQ BCD_BIN_continuar ;Si solo se presiono una tecla, no guarda V_LIM
        ADDB 0,X         ; Sumando parte baja
        STAB V_LIM         ; Guardando valor binario en cprog
BCD_BIN_continuar:      ; Borrando NUM_ARRAY
        MOVB #$FF,0,X
        MOVB #$FF,1,-X
        RTS
        

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---








;*******************************************************************************
;                             SUBRUTINA BIN_BCD
;*******************************************************************************
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de realizar la conversion de numeros
; de binario a BCD. Solo realiza conversiones de numeros de 0 a 99
;
; Parametros de entrada: Se le debe pasar un numero en binario por el acumulador
; A.
;
; Parametros de salida: Devuelve el resultado en la variable BCD_L.
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
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---


;*******************************************************************************
;                             SUBRUTINA CONV_BIN_BCD
;*******************************************************************************
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de verificar si los numeros enviados
; en BIN1 y BIN2 son $BB o $AA, de ser asi solamente guarda los valores de BIN1
; y BIN2 en BCD1 y BCD2 respectivamente. En caso de que las variables contengan
; otro valor, se llama a la subrutina BIN_BCD y se guardan los valores converti-
; dos en BCD a BCD1 y BCD2.
;
; Parametros de entrada: Las variables BIN1 y BIN2 que contienen numeros en bi-
; nario
;
; Parametros de salida: Devuelve el resultado de los numeros en BCD en las va-
; riables BCD1 y BCD2 respectivamente.
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
;                                  Encabezado
; Descripcion: Esta subrutina toma los valores almacenados en BCD1 y BCD2 y los
; codifica en codigo de 7 segmentos para ser guardados en las variables DISP1,
; DISP2, DISP3, DISP4. Cada uno de estos display representa un display de la
; dragon 12
;
; Parametros de entrada: Las variables BCD1 y BCD2 que contienen numeros en BCD
;
;
; Parametros de salida: Devuelve el resultado en DISP1,DISP2, DISP3, DISP4.
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
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de realizar toda la logica para poder
; leer una tecla del teclado, esto se realiza mediante distintos llamados a
; subrutinas como MUX_TECLADO y FORMAR_ARRAY.
;
; Parametros de entrada:
;       TECLAS: Contiene la tecla que se acaba de pulsar.

;       TECLA_IN: Contiene la tecla validada cuando se suelta el boton pre-
;               sionado
;                      
;       NUM_ARRAY: Arreglo de tamano MAX_TCL que contendra los valores de las
; 		    teclas leidas

; 	CONT_REB: Variable que es cargada en esta subrutina, la decrementa la 
;               interrupcion RTI, con el fin de controlar rebotes

; 	TECLA LISTA: Bandera que indica que la tecla esta lista y se puede
;                       almacenar.

;T      ECLA LEIDA: Bandera que Indica que se leyo una tecla.

; Parametros de salida:
;       NUM_ARRAY: Arreglo de tamano MAX_TCL que contendra los valores de las
; 		    teclas leidas
;*******************************************************************************

TAREA_TECLADO:
        LDX #TECLAS
        LDY #NUM_ARRAY
        TST CONT_REB                 ;Verificando si ya pasaron los rbotes
        BNE FIN_TAREA_TECLADO
        JSR MUX_TECLADO             ; Ver si hay alguna tecla presionada
        LDAA #$FF                   ; Verifica si ya no hay presionada una telca
        CMPA TECLA
        BEQ TECLA_LISTA_TT         
        BRSET BANDERAS+1,$02,TECLA_LEIDA_TT
        MOVB TECLA, TECLA_IN      
        BSET BANDERAS+1,$02       ; TECLA LEIDA = 1
        MOVB #10, CONT_REB
        RTS
TECLA_LEIDA_TT:                  ; Verificando si la tecla esta lista
        LDAA TECLA               
        CMPA TECLA_IN
        BEQ PONER_BANDERA_TCL_LISTA
        MOVB #$FF,TECLA
        MOVB #$FF,TECLA_IN
        BCLR BANDERAS+1,$01       ; TECLA LISTA = 0
        BCLR BANDERAS+1,$02       ; TECLA LEIDA = 0
        RTS
PONER_BANDERA_TCL_LISTA:
        BSET BANDERAS+1,$01       ; TECLA LISTA = 1
        RTS
TECLA_LISTA_TT:
        BRSET BANDERAS+1,$01,FORM_ARR_TT ; TECLA LISTA = 1?
        RTS
FORM_ARR_TT:
        BCLR BANDERAS+1,$01       ; TECLA LISTA = 0
        BCLR BANDERAS+1,$02       ; TECLA LEIDA = 0
        JSR FORMAR_ARRAY          ; Tecla lista para formar el araray
FIN_TAREA_TECLADO:
        RTS

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---















;*******************************************************************************
;                                SUBRUTINA FORMAR_ARRAY
;*******************************************************************************
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de formar el array con las teclas presio-
; nadas por el usuario, tambien realiza el control y validacion de las distintas
; teclas presionadas. Al llenar el array esta subrutina pone la bandera ARRAY_OK
; en alto y el CONT_TCL en 0. El arreglo NUM_ARRAY utiliza como byte no valido
; el valor $FF
;
; Parametros de entrada:
;       TECLA_IN: Contiene la tecla ya validada para analizarla

;       NUM_ARRAY: Arreglo de tamano MAX_TCL que contendra los valores de las
; 		    teclas leidas

;       CONT_TCL: Cuenta la cantidad de teclas ya almacenadas en el array.
;       

; Parametros de salida:
;       NUM_ARRAY: Arreglo de tamano MAX_TCL que contendra los valores de las
; 		    teclas leidas
;       ARRAY_OK: Bandera que se encarga de validar que el arreglo esta listo.
;*******************************************************************************

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
        BSET BANDERAS+1,$04   ; Array_ok <-- 1
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
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de leer una tecla del teclado de la
; Dragon 12. Utiliza como variable PATRON que es un contador que cuando es mayor
; a 4 (las filas del teclado) se termina la subrutina porque no se leyo ninguna
; tecla. En caso de que se lea una tecla se retorna en la variable TECLA. Si
; no existia una tecla se retorna un $FF en TECLA.

; Parametros de entrada:
;       PATRON: Se utiliza como constante para leer el teclado de 3x4.

;       
; Parametros de salida:
;       TECLA: Retorna la tecla leida en el teclado. Si no se encuentra tecla
;              presionada, se devuelve $FF.
;*******************************************************************************

;Descripcion: 

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
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de encender los leds en manera de 
; alarma desde PH7 hasta PH3 cuando se pone en alto la bandera. 

; Parametros de entrada:
;       ALARMA: Bandera que si esta en 1 hace que la subrutina funcione
;       LEDS: Para tomar lo que ya tiene y almacenar el led extra a encender
;       
; Parametros de salida:
;       LEDS: Enciende el led correspondiente sin apagar el led de modo.
;*******************************************************************************

PATRON_LEDS:
        BRSET BANDERAS+1,$10,PATRON_LEDS_desplazar_leds ; Si ALARMA = 1, se procede a hacer la alarma
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
PATRON_LEDS_reiniciar_patron: ; Reiniciando el patron de los LEDS en ph7
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
;                                  Encabezado
; Descripcion: Esta interrupcion se encarga de decrementar la variable CONT_REB en 1
; cada 1 ms aproximadamente, si CONT_REB es cero la subrutina no hace nada.

; Parametros de entrada:
;       CONT_REB: Lo revisa a ver si es 0, sino lo decrementa
;       
; Parametros de salida:
;       CONT_REB: Lo devuelve en 0 o decrementado por 1
;*******************************************************************************

;Descripcion: 

RTI_ISR:        ; Teclado

                BSET CRGFLG,#$80
                TST CONT_REB      ; Si contador de rebotes es 0, no hace nada
                BEQ FIN_RTI_ISR_cont_reb
                DEC CONT_REB      ; decrementando contador de rebotes
FIN_RTI_ISR_cont_reb:                  ; Timer cuenta (modo run)

                RTI

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---












;*******************************************************************************
;                                INTERRUPCION CALCULAR
;*******************************************************************************
;                                  Encabezado
; Descripcion: Esta interrupcion se divide en dos subrutinas:
;
;
;***********************************
;*        INTERRUPCION PTH0        *
;***********************************
; Descripcion: Esta interrupcion se encarga de tomar la variable TICK_VEL y re-
; alizar el calculo de la velocida del vehiculo en KM/H que es almacenado en la
; variable VELOC. Si la velocidad es mayor a 255 se almacena 255 en VELOC. 
; Esta interrupcion habilita nuevamente el boton ph3.

; Parametros de entrada:
;       PTH3: Bandera que indica con un 1 que se viene de haber presionado ph3
;       TICK_VEL: Recibe la cantidad de ticks que han pasado. Existe una relacion
;       directa entre cada tick y el tiempo. Cada tick equivale a 0.0218 segundos
;       CONT_REB: Se utilia para controlar los rebotes de los botones
; Parametros de salida:
;       VELOC: Velocidad en KM/H


;***********************************
;*        INTERRUPCION PTH3        *
;***********************************
; Descripcion: Esta interrupcion se encarga iniciar la cuenta de TICK_VEL en 0
; ademas de activar el boton ph0 por medio de la bandera PH0 en 1. Esta subru-
; tina tambien actualiza la pantalla LCD con el mensaje "CALCULANDO".  

; Parametros de entrada:
;       CONT_REB: Se utilia para controlar los rebotes de los botones

; Parametros de salida:
;       PH0: Bandera que se pone en 1 en esta subrutina. Activa el boton ph0.


;*******************************************************************************

;Descripcion: Esta interrupcion se divide en 2 subrunitas:
; PTH0:

; PTH3:
CALCULAR:
                BRSET PIFH,$01,PTH0
                BRSET PIFH,$08,PTH3
                RTI

PTH0:
        BRCLR BANDERAS,$01,PTH0_retornar ; Para saber si realmente se presiono antes PTH3
        BCLR BANDERAS,$01 ; Desactivando boton ph0
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
        CLR TICK_VEL
        TSTA              ; Si queda algo en parte alta de A, es porque la velocidad es invalida
        BNE PTH0_velocidad_invalida
        STAB VELOC         ;guardando velocidad que es valida
        BRA PTH0_retornar
PTH0_velocidad_invalida:  ; Guardando velocidad invalida
        MOVB #$FF,VELOC
PTH0_retornar:
        BSET PIFH,$01     ; Desactivando bandera de interrupcion
        RTI


PTH3:

        TST CONT_REB      ;Control de rebotes
        BNE PTH3_retornar
        BRCLR BANDERAS,$02,PTH3_retornar
        BSET BANDERAS,$01       ; Activando boton ph0
        BCLR BANDERAS,$02       ; desActivando boton ph3
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
;                                  Encabezado
; Descripcion: Esta interrupcion da cada 20us, dentro de sus tareas esta:

; - Control del ciclo de encendido y apagado (multiplexacion) de los display
;   de 7 segmentos.
; - Llamar cada 100 ms a las subrutinas CONV_BIN_BCD y BCD_7SEG, con el fin
;   de actualizar los valores en los display de 7 seg
; - Iniciar cada 200ms la conversion analogica digital ademas de llamar la 
;   subrutina PATRON_LEDS que actualiza el patron de leds.

; Parametros de entrada:
;       DISP1, DISP2, DISP3, DISP4: Cada uno de los display
;       LEDS: Contiene los LEDS a desplegar
;       BRILLO: Contiene el brillo de la pantalla      
; Parametros de salida: N/A

;*******************************************************************************

OC4_ISR:
        BSET TFLG1,$10                ; Borrando bandera interrupcion
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
OC4_ISR_continuar3:
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
                   ; Decrementando contador de delay si no es 0
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
        RTI
;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---






;*******************************************************************************
;                                INTERRUPCION ATD_ISR
;*******************************************************************************
;                                  Encabezado
; Descripcion: Esta subrutina se encarga de leer 6 valores guardados en los reg
; del convertidor analogico a digital en el cual esta conectado el potenciometro
; y hacer un promedio de los mismos que es guardado en la variable POT. Por
; ultimo se calcula el valor de 0 a 100 (en intervalos de 5 en 5) del brillo
; a ser mostrado en los display, este brillo es guardado en la variable BRILLO.


; Parametros de entrada: N/A
;          
; Parametros de salida: POT, BRILLO 

;*******************************************************************************


ATD_ISR:
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
;                                  Encabezado
; Descripcion: Esta interrupcion se encarga de contar los ticks cada aprox 0.0218ms
; incrementando TICK_VEL. Tambien controla el encendido y apagado de una bandera 
; llamada PANT_FLAG que controla el encendido y apagado de la pantalla de 7 SEG.


; Parametros de entrada: N/A
;          
; Parametros de salida: Pantflag: Bandera que si es 1 significa que se debe 
; encender la pantalla de 7 seg.
;*******************************************************************************

TCNT_ISR:
        BRCLR BANDERAS,$01,TCNT_ISR_no_contar ; Si ph0 no esta activa, no cuenta.
        LDAA #$FF                               ; Si se va a rebasar, no cuenta mas.
        CMPA TICK_VEL
        BEQ TCNT_ISR_no_contar
        INC TICK_VEL                            ; Cuenta un tick
TCNT_ISR_no_contar:
        LDD TICK_EN     ; Verificando si TICK_EN llego a 0, sino lo decrementa
        BEQ TCNT_ISR_set_pant_flag
        SUBD #1
        STD TICK_EN
        BRA TCNT_ISR_continuar
TCNT_ISR_set_pant_flag:
        BSET BANDERAS+1, $08      ; Pantflag = 1
TCNT_ISR_continuar:
        LDD TICK_DIS     ; Verificando si TICK_EN llego a 0, sino lo decrementa
        BEQ TCNT_ISR_clear_pant_flag
        SUBD #1
        STD TICK_DIS
        BRA TCNT_ISR_retornar
TCNT_ISR_clear_pant_flag:
        BCLR BANDERAS+1, $08      ; Pantflag = 0
TCNT_ISR_retornar:
        movb #$80,TFLG2  ; Borrando bandera interrupcion
        RTI

;---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---  ---