        .text
        .global _start
_start:  MOV R4, #TEST_NUM  //R4 points to TEST_NUM
         MOV R1, #0         //Initialize R1
         MOV R5, #0         //R5
         MOV R6, #0         //R6
         MOV R7, #0         //R7 with zero
         MOV sp,#0x20000    //R13 points to 0x20000


LOOP:    LDR R1, [R4], #4   //load word from R4, after which R4 advance to next memory location
         CMP R1, #0         //compare R1 with 0
         BEQ SHOW            //if R1 == 0, Branch

         PUSH {R1}          //push value of R1 onto STACK
         BL  ONES           //branch into ONES
         CMP R5, R0         //compare R5 with R0
         MOVLT R5, R0       //if R5 < R0, R5 <<== R0

         POP {R1}           //restore the value of R1
         PUSH {R1}          //push value of R1 onto STACK
         BL  ZEROS          //branch into ZEROS
         CMP R6, R0         //compare R6 with R0
         MOVLT R6, R0       //if R6 < R0, R6 <<== R0

         POP {R1}           //restore the value of R1
         BL   ZEROS_1s      //branch into ZEROS_1s
         CMP R7, R0         //compare R7 with R0
         MOVLT R7, R0       //if R7 < R0, R7 <<== R0
         B   LOOP           //branch back for looping

SHOW:   LDR R8, =0xFF200020 //load 0xFF200020 into R8 where HEX3-0 are
        MOV R0, R5          //move the number of consecutive 1s into R0
        BL  DIVIDE          //divide the number and store ones digit into R0 and tens digit into R1
        
        MOV R9, R1          //Store tens digit of R5 into R9
        BL  BREAKDOWN       //save bit pattern of ones digit at R0
        MOV R4, R0          //R4 gets the bit pattern of ones digit of R5
        MOV R0, R9          //R0 gets tens digit of R5

        BL  BREAKDOWN       //save bit pattern of tens digit at R0
        LSL R0, #8          //extend R0 by left shifting by 8 bits (1 byte)
        ORR R4, R0          //R4 = {R5_tens_digit, R5_ones_digit}
  
        MOV R0, R6          //move the number of consecutive 0s into R0
        BL  DIVIDE          //divide the number and store ones digit into R0 and tens digit into R1
        
        MOV R9, R1          //Store tens digit of R5 into R9
        BL  BREAKDOWN       //save bit pattern of ones digit at R0
        LSL R0, #16         //extend R0 by left shifting by 16 bits (2 bytes)
        ORR R4, R0          //R4 = {R6_ones_digit, R5_tens_digit, R5_ones_digit}
        MOV R0, R9

        BL  BREAKDOWN       //save bit pattern of tens digit at R0
        LSL R0, #24         //extend R0 by left shifting by 24 bits (3 bytes)
        ORR R4, R0          //R4 = {R6_tens_digit, R6_ones_digit, R5_tens_digit, R5_ones_digit}
        
        STR R4, [R8]        //display R5 and R6

        LDR R8, =0xFF200030 //load 0xFF200020 into R8 where HEX5-4 are
        MOV R0, R7          //move the number of consecutive 01s into R0
        BL  DIVIDE          //divide the number and store ones digit into R0 and tens digit into R1
        
        MOV R9, R1          //Store tens digit of R7 into R9
        BL  BREAKDOWN       //save bit pattern of ones digit at R0
        MOV R4, R0          //R4 gets the bit pattern of ones digit of R7
        MOV R0, R9          //R0 gets tens digit of R7

        BL  BREAKDOWN       //save bit pattern of tens digit at R0
        LSL R0, #8          //extend R0 by left shifting by 8 bits (1 byte)
        ORR R4, R0          //R4 = {R7_tens_digit, R7_ones_digit}
        
        STR R4, [R8]        //display R7

END:    b   END //end of program

ZEROS:  LDR R0, =0xffffffff //R0 <<== 0xffffffff
        EOR R1, R0           //exclusive or operation on R1 with R0, flipping all bits of R1

ONES:   MOV R0, #0          //R0 <<==  0x0

EXTRACT:
        CMP R1, #0          //compare R1 with R0
        BEQ RETURN          //if R1 == 0, Branch
        LSR R2, R1, #1      //Logic Right Shift R1 by 1 position, and load the result into R2
        AND R1, R1, R2      //AND operation on R1 and R2, cancelling out 1 bit of 1
        ADD R0, #1          //add R0+=1;
        B   EXTRACT         //branch back

RETURN:   MOV PC, LR        //return

ZEROS_1s:
        LDR R0, =0xAAAAAAAA    //R0 <<== 0xAAAAAAAA
        EOR R1, R0          //exclusive or operation on R1 with R0, getting bits of patterns where 01 strings are represented either by consecutive ones or zeros
        
        MOV R0, #0              //R0 <<== 0x0
        PUSH {R1,R14}           //push values of R1 & R14 onto STACK
        BL  ONES                //branch to ONES
        MOV R3, R0              //R3 <<== R0
        
        POP {R1,R14}            //restore the values of R1 & R14
        PUSH {R14}              //push value of R14 onto STACK
        BL ZEROS                //branch to ZEROS
        
        CMP R0, R3              //compare R0 with R3
        MOVLT R0, R3            //if R0 < R3, R0 <<== R3
        
        POP {R14}               //restore the value of R14
        MOV PC, LR              //return

BREAKDOWN:  MOV R1, #BIT_CODES  //R1 gets the bit code
            ADD R1, R0          //index inro the array by R0
            LDRB R0, [R1]       //load by byte the bit pattern into R0
            MOV PC, LR          //return

DIVIDE:     MOV    R1, #0       //R1 <<== 0
CONT:       CMP    R0, #10      //compare R0 with #10
            BLT    DIV_END      //if R9 < 10   branch
            SUB    R0, #10      //R0 -=10
            ADD    R1, #1       //R1 +=1
            B      CONT         //branch back
DIV_END:    MOV    PC, LR       //return R1 gets tens digit, R0 gets ones digit

        
TEST_NUM:.word   0x103fe00f
         .word   0xAAAAAAAA
         .word   0xC81DA58E
         .word   0x91C90091
         .word   0x270755B3
         .word   0xA1C71B3E
         .word   0x7B73AF38
         .word   0x0472ABF5
         .word   0x9AA06414
         .word   0x3F9AA55E
         .word   0x00000000


BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .end
            
