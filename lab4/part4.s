               .equ      EDGE_TRIGGERED,    0x1
               .equ      LEVEL_SENSITIVE,   0x0
               .equ      CPU0,              0x01    // bit-mask; bit 0 represents cpu0
               .equ      ENABLE,            0x1

               .equ      KEY0,              0b0001
               .equ      KEY1,              0b0010
               .equ      KEY2,              0b0100
               .equ      KEY3,              0b1000

               .equ      IRQ_MODE,          0b10010
               .equ      SVC_MODE,          0b10011

               .equ      INT_ENABLE,        0b01000000
               .equ      INT_DISABLE,       0b11000000

/*********************************************************************************
 * Initialize the exception vector table
 ********************************************************************************/
                .section .vectors, "ax"

                B        _start             // reset vector
                .word    0                  // undefined instruction vector
                .word    0                  // software interrrupt vector
                .word    0                  // aborted prefetch vector
                .word    0                  // aborted data vector
                .word    0                  // unused vector
                B        IRQ_HANDLER        // IRQ interrupt vector
                .word    0                  // FIQ interrupt vector

/* ********************************************************************************
 * This program demonstrates use of interrupts with assembly code. The program 
 * responds to interrupts from a timer and the pushbutton KEYs in the FPGA.
 *
 * The interrupt service routine for the timer increments a counter that is shown
 * on the red lights LEDR by the main program. The counter can be stopped/run by 
 * pressing any of the KEYs.
 ********************************************************************************/
                .text
                .global  _start
_start:        
                MOV      R0, #0b11010010
                MSR      CPSR_c, R0
                LDR      SP, =0x40000

                MOV      R0, #0b11010011                    // interrupts masked, MODE = SVC
                MSR      CPSR, R0                                // change to supervisor mode
                LDR      SP, =0x20000  

                BL       CONFIG_GIC         // configure the ARM generic
                                            // interrupt controller
                BL       CONFIG_PRIV_TIMER  // configure A9 Private Timer

                BL       CONFIG_TIMER       //configure A9 Interval Timer

                BL       CONFIG_KEYS        // configure the pushbutton
                                            // KEYs port

/* Enable IRQ interrupts in the ARM processor */
                  MOV        R0, #0b01010011
                  MSR        CPSR_c, R0

                LDR      R5, =0xFF200000    // LEDR base address
                LDR      R6, =0xFF200020    // HEX3-0 base address
LOOP:
                LDR      R3, COUNT          // global variable
                STR      R3, [R5]           // light up the red lights
                LDR      R4, HEX_code       // global variable
                STR      R4, [R6]           // show the time in format SS:DD

                B        LOOP           

SEC_AND_LESS:   MOV      R1, #0
DOWN:           CMP      R0, #100
                BLT      RETURN
                SUB      R0, #100
                ADD      R1, #1
                B        DOWN   

RETURN:         MOV      PC, LR         


DIGITS:         MOV     R1, #0
SUBTRACT:
                CMP     R0,#10 //compare R0 with 10
                BLT     GO_BACK //if R0 <10, go back to caller
                SUB     R0,#10 //R0 -=10
                ADD     R1,#1 //R2 +=1
                B       SUBTRACT //repeat until R0 < 10
         
GO_BACK:        MOV     PC,LR //return


PATTERN:
                MOV R1, #BIT_CODES  //R1 gets the bit code
                ADD R1, R0          //index inro the array by R0
                LDRB R0, [R1,#0x20]       //load by byte the bit pattern into R0   //can't reach #bit_code for some reason, not sure why. needs to ask Stephen
                MOV PC, LR          //return


/* Global variables */
                .global  COUNT
COUNT:          .word    0x0                // used by timer
                .global  RUN
RUN:            .word    0x1                // initial value to increment COUNT
                .global  TIME
TIME:           .word    0x0                // used for real-time clock
                .global  HEX_code
HEX_code:       .word    0x0

/* Configure the A9 Private Timer to create interrupts every 0.25 seconds */
CONFIG_PRIV_TIMER:
                LDR      R0, =0xFFFEC600
                LDR      R1, =50000000
                STR      R1, [R0]
                LDR      R1, =0b111
                STR      R1, [R0,#0x8]
                MOV      PC, LR
                   
/* Configure the FPGA interval timer to create interrupts at 0.01 second intervals */
CONFIG_TIMER:
                LDR      R0, =0xFF202000
                LDR      R1, =0b0100001001000000
                STR      R1, [R0,#0x8]
                LDR      R1, =0b1111
                STR      R1, [R0,#0xC]
                LDR      R1, =0b111
                STR      R1, [R0,#0x4]
                MOV      PC, LR

/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:
                LDR      R1,=0x8        //enable interrupt for key3
                LDR      R2,=0xFF200050
                STR      R1,[R2,#0x8]  
                MOV      PC, LR

/*--- IRQ ---------------------------------------------------------------------*/
IRQ_HANDLER:
                PUSH     {R0-R7, LR}
    
                /* Read the ICCIAR in the CPU interface */
                LDR      R4, =0xFFFEC100
                LDR      R5, [R4, #0x0C]         // read the interrupt ID

CHECK_Prvi_Timer:    
                CMP      R5, #29
                BNE      CHECK_Timer
                BL       PRIV_TIMER_ISR
                B        EXIT_IRQ

CHECK_Timer:    CMP      R5, #72
                BNE      CHECK_KEYS
                BL       TIMER_ISR
                B        EXIT_IRQ          

CHECK_KEYS:     CMP      R5, #73

UNEXPECTED:     BNE      UNEXPECTED 
                BL       KEY_ISR

EXIT_IRQ:
                /* Write to the End of Interrupt Register (ICCEOIR) */
                STR      R5, [R4, #0x10]
    
                POP      {R0-R7, LR}
                SUBS     PC, LR, #4

/****************************************************************************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This routine toggles the RUN global variable.
 ***************************************************************************************/
                .global  KEY_ISR
KEY_ISR:        
                LDR      R0, =0b1100
                LDR      R1, =0xFF202004
                LDR      R2, [R1]
                EOR      R2, R0
                STR      R2, [R1]

                LDR      R0, =RUN
                LDR      R1, [R0]
                LDR      R2, =0b1
                EOR      R1, R2
                STR      R1, [R0]

                LDR      R0,=0xFF20005C
                LDR      R1, [R0]
                STR      R1, [R0]

                MOV      PC, LR

/******************************************************************************
 * A9 Private Timer interrupt service routine
 *                                                                          
 * This code toggles performs the operation COUNT = COUNT + RUN
 *****************************************************************************/
                .global  PRIV_TIMER_ISR
PRIV_TIMER_ISR:
                LDR     R2, =0xFFFEC60C
                LDR     R1, [R2]
                STR     R1, [R2]
                LDR     R0, =COUNT
                LDR     R1, COUNT
                LDR     R2, RUN 
                ADD     R1, R2
                STR     R1, [R0]


                MOV      PC, LR
/******************************************************************************
 * Interval timer interrupt service routine
 *                                                                          
 * This code performs the operation ++TIME, and produces HEX_code
 *****************************************************************************/
                .global  TIMER_ISR

TIMER_ISR:      PUSH     {R0-R7,LR}
                MOV      R6, #0
                LDR      R4,=TIME
                LDR      R2,=HEX_code
                LDR      R0, [R4]
                LDR      R1, =5999
                CMP      R0, R1
                MOVGT    R0, #0
                MOV      R4, R0

                BL       SEC_AND_LESS //thousands and hundreds digit in R1, tens and ones digit in R0
                MOV      R5, R1       //Store value of R1 into R5         
                BL       DIGITS       //ones digit in R0,   tens digit in R1
                MOV      R7, R1       //store tens digit into R7
                BL       PATTERN      //pattern in R0
                MOV      R6, R0

                MOV      R0, R7
                BL       PATTERN      //pattern in R0
                LSL      R0, #8
                ORR      R6, R0

                MOV      R0, R5
                BL       DIGITS       //ones digit in R0,   tens digit in R1
                MOV      R5, R1       //R5 stores the value of tens digit
                BL       PATTERN      //pattern in R0
                LSL      R0, #16
                ORR      R6, R0

                MOV      R0, R5       //R0 gets tens digit
                BL       PATTERN      //pattern in R0
                LSL      R0, #24
                ORR      R6, R0

                STR      R6, [R2]

                MOV     R0, R4
                LDR     R4, =TIME
                ADD     R0, #1
                STR     R0, [R4]

                LDR      R0,=0xFF202000
                LDR      R1,=0b00
                STR      R1,[R0]
                POP      {R0-R7,LR}
                MOV      PC, LR

/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
                .global  CONFIG_GIC
CONFIG_GIC:
                PUSH     {LR}
                /* Enable A9 Private Timer interrupts */
                MOV      R0, #29
                MOV      R1, #CPU0
                BL       CONFIG_INTERRUPT
                
                /* Enable FPGA Timer interrupts */
                MOV      R0, #72
                MOV      R1, #CPU0
                BL       CONFIG_INTERRUPT

                /* Enable KEYs interrupts */
                MOV      R0, #73
                MOV      R1, #CPU0
                /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
                BL       CONFIG_INTERRUPT

                /* configure the GIC CPU interface */
                LDR      R0, =0xFFFEC100        // base address of CPU interface
                /* Set Interrupt Priority Mask Register (ICCPMR) */
                LDR      R1, =0xFFFF            // enable interrupts of all priorities levels
                STR      R1, [R0, #0x04]
                /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
                 * allows interrupts to be forwarded to the CPU(s) */
                MOV      R1, #1
                STR      R1, [R0]
    
                /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
                 * allows the distributor to forward interrupts to the CPU interface(s) */
                LDR      R0, =0xFFFED000
                STR      R1, [R0]    
    
                POP      {PC}
/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
                PUSH     {R4-R5, LR}
    
                /* Configure Interrupt Set-Enable Registers (ICDISERn). 
                 * reg_offset = (integer_div(N / 32) * 4
                 * value = 1 << (N mod 32) */
                LSR      R4, R0, #3               // calculate reg_offset
                BIC      R4, R4, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED100
                ADD      R4, R2, R4               // R4 = address of ICDISER
    
                AND      R2, R0, #0x1F            // N mod 32
                MOV      R5, #1                   // enable
                LSL      R2, R5, R2               // R2 = value

                /* now that we have the register address (R4) and value (R2), we need to set the
                 * correct bit in the GIC register */
                LDR      R3, [R4]                 // read current register value
                ORR      R3, R3, R2               // set the enable bit
                STR      R3, [R4]                 // store the new register value

                /* Configure Interrupt Processor Targets Register (ICDIPTRn)
                  * reg_offset = integer_div(N / 4) * 4
                  * index = N mod 4 */
                BIC      R4, R0, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED800
                ADD      R4, R2, R4               // R4 = word address of ICDIPTR
                AND      R2, R0, #0x3             // N mod 4
                ADD      R4, R2, R4               // R4 = byte address in ICDIPTR

                /* now that we have the register address (R4) and value (R2), write to (only)
                 * the appropriate byte */
                STRB     R1, [R4]
    
                POP      {R4-R5, PC}

BIT_CODES: .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .end   

