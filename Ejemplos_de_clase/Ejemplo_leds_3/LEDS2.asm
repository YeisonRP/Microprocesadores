;---------------------------------------------------------------------------
;                           LEDS
;---------------------------------------------------------------------------
;                      ESTRUCTURAS DE DATOS:
;---------------------------------------------------------------------------
                ORG $1000
LEDS:           ds 1
CONT_INT:       ds 1
Wait:           ds 2
                ORG $3e4c
                dw PTHO_ISR                   ; Que es eso
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-----------------------Etiquetas con Registros-----------------------------
;---------------------------------------------------------------------------
#include registers.inc
;-----------------------Programa Prncipal-----------------------------------
;---------------------------------------------------------------------------
                ORG $1500
                movb #$ff,DDRB
                bset DDRJ,$02
                bclr PTJ,$02
                movb #$0f, DDRP
                movb #$0f, PTP
                bset PIEH,$01
                movb #$01, LEDS
                lds #$3bff
                CLI
                bra *
PTHO_ISR:       MOVB LEDS,PORTB
                lsl LEDS
                TST LEDS
                BNE CONTINUAR
                movb #$01,LEDS
CONTINUAR:      bset PIFH,$01
                rti
                