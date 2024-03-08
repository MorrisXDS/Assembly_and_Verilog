.global _start
_start:
        LDR R4, =0xFF20005C //R4 points to Edgecapture register
        LDR R5, =0xFF200020
        LDR R3, =0xFFFFFFFF
        MOV R7, #0

CLEAN_BITS:
        MOV R0, #0
        MOV R1, #0

DISPLAY:
        LDR R7, [R4]
        CMP R7, #0
        BNE RESET
        CMP R3,#99
        MOVGT R3, #0
        ADD R3,#1
        MOV R0, R3
        BL  DIVISION
        PUSH {R1}
        BL  PATTERN
        MOV R6, R0

        POP {R1}
        MOV R0, R1
        BL  PATTERN
        LSL R0, #8
        ORR R6, R0

        STR R6, [R5]

        B   DELAY

RESET:
        STR R7, [R4]

ANY_KEY:
        LDR R7, [R4]
        CMP R7 ,#0
        BEQ ANY_KEY
        STR R7, [R4]
        
DELAY:  
        LDR R6, =500000
SUB:    SUBS R6, #1
        BNE SUB
        B   CLEAN_BITS
        
DIVISION:
        CMP R0, #10
        MOVLT PC,LR
        SUB R0, #10
        ADD R1, #1
        B   DIVISION

PATTERN:
         MOV R1, #BIT_CODES  //R1 gets the bit code
         ADD R1, R0          //index inro the array by R0
         LDRB R0, [R1]       //load by byte the bit pattern into R0
         MOV PC, LR          //return
         
BIT_CODES: .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .end
