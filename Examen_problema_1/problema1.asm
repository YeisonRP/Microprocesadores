

        org $1000
CANT:   DB $07
ARRAY1: DB $FF,$02,$32,$63,$80,$23,$F8
ARRAY2: DB $EA,$E2,$60,$FF,$50,$70,$DA

        org $1100
        LDS #$3BFF
        LDX #ARRAY1
        LDY #ARRAY2
        LDAB CANT
        INCB
MLOOP:  DBEQ B,FIN
        BRCLR 0,X,%10000000,retornar
        BSR INTERC
        BRA MLOOP
retornar:
        INX
        BRA MLOOP
FIN:    BRA *

INTERC: BRSET 0,Y,%10000000,INCREMENTAR
        LDAA 0,Y
        MOVB 1,X+,1,Y+
        STAA -1,X
        RTS
INCREMENTAR:
        INY
        BRA INTERC