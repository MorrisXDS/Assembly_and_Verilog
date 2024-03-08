.define LED_ADDRESS 0x10
.define HEX_ADDRESS 0x20
.define SW_ADDRESS 0X30

// shows on HEX displays either PASSEd or FAILEd
	mvt r0, #HEX_ADDRESS
	mvt r3, #SW_ADDRESS
	mv r6, pc
	mv pc, #BLANK
	mv r1, #0
	st r1, [r0]
	mv r2, #0x64




	




CHECK_SWTICHES:
	ld r4, [r3]
	and r4, #0X3
	sub r4, #2
	bpl SLOW_DOWN
	add r4, #2
	sub r4, #1
	beq SPEED_UP
	b	INCREMENT

SLOW_DOWN:
	mv r5, #32
	add r2, r5
	sub r4, #1
	bne INCREMENT

SPEED_UP:
	mv r5, #32
	sub r2, r5
	beq SLOW_DOWN

INCREMENT:
	add r1, #1
	sub r1, #10
	bpl MAKE
	mv r4, r2
	b INNER_LOOP

MAKE:
	mv r4, #DATA
	add r4, #4
	ld r5, [r4]
	st r5, [r0]
	sub r3, #0
	mv r4, r2


INNER_LOOP:
	sub r4, #1
	bne INNER_LOOP
	b   CHECK_SWTICHES

//Quotient in r3, remainder in r5
DIVIDE:
	mv r3, #0
DLOOP:
	mv r4, #9
	sub r4, r5
	bcs RETDIV

INC:
	add r3, #1
	sub r5, #0
	b	DLOOP
RETDIV:
	add r6, #1
	mv pc, r6

BLANK:
	st r1, [r0]
	add r6, #1
	mv pc, r6
	
DATA:
	.word 0b00111111
	.word 0b00000110
	.word 0b01011011
	.word 0b01001111
	.word 0b01100110
	.word 0b01101101
	.word 0b01111101
	.word 0b00000111
	.word 0b01111111
	.word 0b01100111