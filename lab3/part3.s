.global _start
_start:
        MOV R0, #0
        MOV R1, #0
        MOV R9, #0
        MOV R3, #0
        LDR R4,=0xff200020 //R4 <=Display
        LDR R5,=0xFF20005C //R5 <= Edge Detector
        LDR R13,=0xFFFF1000
        LDR R11, =49999999
        LDR R10,=0xFFFEC600
        STR R11,[R10]
        LDR R12,=3

SET_ZERO: STR R9,[R5]
	  MOV R9, #0
          STR R9,[R10,#0x8]

ANY_KEY:
          LDR R9, [R5]
          CMP R9, #0
          BEQ ANY_KEY
          STR R9, [R5]
		  
DISPLAY:   MOV R1, #0
           CMP R3,#99
           MOVGT R3,#0
           MOV R0,R3
           BL DIGITS
           PUSH {R1}
           BL PATTERN
           MOV R2,R0
           
           POP {R1}
           MOV R0,R1
           BL PATTERN
           LSL R0,#8
           ORR R2,R0
           STR R2,[R4]
      
START_AND_RELOAD:
           
           LDR R9, [R5]
           CMP R9, #0
           BNE SET_ZERO
           STR R12,[R10,#0x8]

DO_DELAY: LDR R8,[R10,#0xc]
           CMP R8,#1
           BNE DO_DELAY
           STR R8,[R10,#0xc]
           ADD R3,#1
		   B   DISPLAY

DIGITS:    CMP R0,#10
         BLT RETURN
         SUB R0,#10
         ADD R1,#1
         B     DIGITS
RETURN: MOV PC,LR

PATTERN:
         MOV R1, #BIT_CODES  //R1 gets the bit code
         ADD R1, R0          //index inro the array by R0
         LDRB R0, [R1]       //load by byte the bit pattern into R0
         MOV PC, LR          //return
         
BIT_CODES: .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .end

	
