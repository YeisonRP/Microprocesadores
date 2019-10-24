
	org $1000
#include registers.inc

        org $1500
        CLR DDRH
        MOVB #$FF, DDRB
	BSET DDRJ,$02
        BCLR PTJ, $02
leer:   LDAA PTIH
        STAA PORTB
        BRA leer