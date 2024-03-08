        .text
        .global _start
_start: MOV     R1,#0      //R3 <= 0
        MOV     R4,#0      //R4 <<= 0
        MOV     R3, #TEST_NUM   //R3 points to TEST_NUM

LOOP:   LDR     R1, [R3], #4    //load Value from R3 to R1, after which R3 goes to next address
        CMP     R1, #0      //if R1 reaches bottom
        BEQ     STORE       //branch
        BL      ONES        //find the longest string of 1s
        CMP     R4, R0      //compare R4 with R0
        MOVLT   R4, R0      //if R4 < R0 update the longest string so far int oR4
        B       LOOP        //branch back for looping

STORE:  MOV     R5, R4      //store the largest number of consecutive 1s into R5

END:     B      END         //END of program

ONES:   MOV     R0,#0       //R1 <<= 0
RUN:    CMP     R1,#0       //check if R1 is 0x0
        BEQ     RETURN      //if it is, branch
        LSR     R2, R1, #1  //Left Shift R1 by 1 bit & store result into R2
        AND     R1, R1, R2  //AND operation on R1 and R2
        ADD     R0, #1      //length of conseutive 1s increments by 1
         B      RUN         //Loop back
    
RETURN: MOV     PC,LR       //return

TEST_NUM:.word   0x103fe00f
         .word   0x11ff1f1f
         .word   0xC81DA58E
         .word   0x91C90091
         .word   0x270755B3
         .word   0xA1C71B3E
         .word   0xF5E21096
         .word   0x0472ABF5
         .word   0x9AA06414
         .word   0x3F9AA55E
         .word   0x00000000
        .end
            
