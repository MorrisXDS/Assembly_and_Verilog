.global _start
_start:
        LDR R6,=0xFF200020
        LDR R4,=0xFF20005C
		LDR R5,=BIT_CODES
		LDRB R2,[R5]
		MOV R0,#1

KEY:    
		LDR R1, [R4]
	    CMP R1, #0
		BEQ KEY

KEY_SELECTION:
		CMP R1,#8
		BEQ KEY_3
		CMP R0,#1
		BEQ KEY_0
		CMP R1,#1
		BEQ KEY_0
		CMP R1,#2
		BEQ KEY_1
		CMP R1,#4
		BEQ KEY_2
		
		
KEY_0: 
		LDRB R2,[R5]
		MOV R3,#0
		STR R2,[R6]
		B	CLEAR_BIT

KEY_1: CMP	R3,#8
		BGT	 RESET
		ADD	 R3,#1
		LDRB R2,[R5,R3]
		STR  R2,[R6]
		B	CLEAR_BIT
		
KEY_2:  CMP  R3,#0
	    SUBGT R3,#1
   		LDRB R2,[R5,R3]
		STR  R2,[R6]
		B CLEAR_BIT
		
KEY_3:	
		MOV R3,#0x0
		STR R3,[R6]
		STR R1,[R4]
		MOV	R0, #1
		 B   KEY

RESET:	MOV	R3,#9
		 LDRB R2,[R5,R3]
		 STR  R2,[R6]

CLEAR_BIT:
		STR R1,[R4]
		MOV	R0,#0
		B	KEY
		 

END:    B   END
        
BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .end