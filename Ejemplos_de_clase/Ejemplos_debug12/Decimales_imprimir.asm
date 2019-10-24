        org $1000

printf:  EQU $EE88
Mensaje: fcc "EL MAXIMO COMUN DIVISOR DE %i y %i es %i"
n:       dw 24
m:       dw 16
gcd:     dw 8


        org $1100
        lds #$3BFF
        ldx #0
        ldd gcd
        pshd
        ldd n
        pshd
        ldd m
        pshd
        ldd #Mensaje
        jsr [printf,x]
        leas 6,SP
        bra *