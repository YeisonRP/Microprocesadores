        ORG $1000
U:      ds 1
V:      ds 1
W:      ds 1
Temp:   ds 1

        ORG $1010
R:      ds 1
S:      ds 1
T:      ds 1

	ORG $4000
        Ldaa U
        Cmpa V
        Blt U_menor
        Staa S
        Ldaa V
        Staa R
        Bra W_con_s
U_menor:
        Staa R
        Ldaa V
        Staa S
W_con_s:
        Ldaa W
        Cmpa S
        Blt W_menor
        Staa T
        Bra fin
W_menor:
        Ldaa S
        Staa T
        Ldaa W
        Staa S
        Cmpa R
        Bge fin
        Ldaa R
        Staa Temp
        Ldaa S
        Staa R
        Ldaa Temp
        Staa S
fin     bra *