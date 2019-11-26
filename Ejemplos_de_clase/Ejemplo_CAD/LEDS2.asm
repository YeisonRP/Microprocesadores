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
                
                MOVB #$49,RTICTL
                BSET CRGINT, $80
                
                BSET SPI0CR1, $50
                CLR SPI0CR2
                MOVB #$45,#$SPI0BR
                
                BSET DDRM,$40
                BSET PTM. $40
                
                BSET DDRB,$01
                BCLR PORTB,$02
                
                LDS #3BFF
                CLI
                
                CLR CONT_DA
                
                BRA

                
                
RTI_ISR:
                INC CONT_DA
                LDAA #1024
                CMPA CONT_DA
                BNE RTI_ISR_continuar
                CLR CONT_DA
                LDD #$01
                EORA
                STAA PORTB
RTI_ISR_cont_dat_1024:
                BCLR PM, $20
RTI_ISR_LOOP:
                LDAA #1
vuelva:         CMPA SPTEF
                BEQ RTI_ISR_continuar2
                bra vuelva
RTI_ISR_continuar2
                LDD CONT_DA
                LSLD
                LSLD
                ANDA #$0F
                ADDA #$90
                LDAA SPS0DR
                
                LDAA #1
vuelva2:        CMPA SPTEF
                BEQ RTI_ISR_continuar2
                bra vuelva2
                BSET PM,$40
                BSET CRGFLAG,$80
                RTI