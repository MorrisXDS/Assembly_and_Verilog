.global _start
_start:
        MOV R0, #0  //initialization
        MOV R1, #0
        MOV R9, #0
        MOV R3, #0
		MOV R6, #0
        LDR R4,=0xff200020 //R4 <=Display
        LDR R5,=0xFF20005C //R5 <= Edge Capture register
        LDR R13,=0xFFFF1000 //place Stack Pointer somewhere
        LDR R11, =2000000  //load value to achieve 0.01 seconds
        LDR R10,=0xFFFEC600 //R10 now points to load value register
        STR R11,[R10] //Store load value
        LDR R12,=3 //R12 <<== 0b11
          
DISPLAY:   MOV R1, #0 //R1 <<== 0
		   MOV R0, R3 //load current value in tenth and hundreth of secondsto display into R0
           CMP R3,#99 //compare R3 with 99
           MOVGT R0,#0 //if R3 >99, R3 <<== 0
           BL DIGITS //store ones digit in R0, tens digit in R1
           PUSH {R1} //store R1 onto Stack
           BL PATTERN //store bit patterns of hundreth place in R0
           MOV R2,R0 //R2 gets the pattern of ones digit of hundreth digit
           
           POP {R1}  //restore the value of R1
           MOV R0,R1 //R0 <<== R1
           BL PATTERN //store bit patterns of tenth place in R0
           LSL R0,#8 //left shift R0 by 8
           ORR R2,R0 //R2 == {tenth_pattern,hundreth_pattern}

		   CMP R6,#59 //compare R6 with 59
		   MOVGT R6,#0 //if R6 >59, R6 <<== 0
		   MOV R1,#0 //R1 <<== 0
		   MOV R0,R6 //load current value in seconds to display into R0
           BL DIGITS //store ones digit in R0, tens digit in R1
           PUSH {R1} //store R1 onto Stack
           BL PATTERN //store bit patterns of ones place in R0
		   LSL R0,#16 //left shift R0 by 16
           ORR R2,R0 //R2 == {ones_pattern,tenth_pattern,hundreth_pattern}
           POP {R1} //restore the value of R1
           MOV R0,R1 //R0 <<== R1
           BL PATTERN //store bit patterns of tenth place in R0
           LSL R0,#24 //left shift R0 by 24
           ORR R2,R0 //R2 == {tens_pattern,ones_pattern,tenth_pattern,hundreth_pattern}
           
		   
RELOAD:
		 STR R2,[R4] //Seven Segment Display now gets the pattern
      
START_AND_RELOAD:
		   CMP R3,#99 //compare R3 with 99
		   ADDEQ R6,#1 //if R3 == 99, R6 +=1
           CMP R3,#99 //compare R3 with 99
		   LDREQ R3,=0xffffffff //if R3 == 99, R3 equal to -1 in 2's compelment
           LDR R9, [R5] //load value from Edgecapture register
           CMP R9, #0 //check if any key is pressed
           BNE SET_ZERO //Yes, branch
           STR R12,[R10,#0x8] //Enable A and E bits of Control Register
		   B   DO_DELAY //branch

SET_ZERO: STR R9,[R5] //Reset Edgecapture register to 0
          MOV R9, #0 //R9 <<== 0
          STR R9,[R10,#0x8] //Reset control bit register to zero

ANY_KEY:
          LDR R9, [R5] //load value from Edgecapture register
          CMP R9, #0 //check if any key is pressed
          BEQ ANY_KEY //if not pressed, check agian
          STR R9, [R5] //clear bits in Edgecapture register
		  B	  DISPLAY


DO_DELAY:  LDR R8,[R10,#0xc] //load interrupt bit value into R8
           CMP R8,#1 //check if the load value coutns down to 0
           BNE DO_DELAY //if not, loop back and re-check
           STR R8,[R10,#0xc] //if it is, reset Interrupt Status Register to 0
           ADD R3,#1 //increment R3
		   B   DISPLAY //branch
		   

DIGITS:  CMP R0,#10 //compare R0 with 10
         BLT RETURN //if R0 <10, go back to caller
         SUB R0,#10 //R0 -=10
         ADD R1,#1 //R1 +=1
         B     DIGITS //repeat until R0 < 10
RETURN: MOV PC,LR //return

PATTERN:
         MOV R1, #BIT_CODES  //R1 gets the bit code
         ADD R1, R0          //index inro the array by R0
         LDRB R0, [R1]       //load by byte the bit pattern into R0
         MOV PC, LR          //return
         
BIT_CODES: .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .end
	
	
