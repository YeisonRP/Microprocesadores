;---------------------------------------------------------------------------
;                           LEDS
;---------------------------------------------------------------------------
;                      ESTRUCTURAS DE DATOS:
;---------------------------------------------------------------------------
                ORG $1600
LEDS:           ds 1
CONT_INT:       ds 1
                ORG $3e70
                dw INT_ISR                   ; Que es eso
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
                bset DDRJ,$02
                movb #$49,RTICTL
                bset CRGINT,#$80
                lds #$3bff
                CLI
                movb #$01,LEDS
                movb #05,CONT_INT
                bra *
INT_ISR:        bset CRGFLG,#$80  ; se esta borrando la interrupcion para que no veulva a entrar?
                dec CONT_INT
                beq PRENDER_LED
                bra RETORNAR
PRENDER_LED:    movb LEDS,PORTB
                lsl LEDS
                movb #05,CONT_INT
                tst LEDS
                beq REINICIAR_LEDS
                bra RETORNAR
REINICIAR_LEDS: movb #$01,LEDS
RETORNAR        rti
                