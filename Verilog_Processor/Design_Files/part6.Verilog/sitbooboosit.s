.define LED_ADDRESS 0x10
.define HEX_ADDRESS 0x20
.define SW_ADDRESS 0X30

// shows on HEX displays either PASSEd or FAILEd
	mvt r0, #LED_ADDRESS
	mvt r3, #SW_ADDRESS
	mv r1, #0
	st r1, [r0]
	mv r2, #0x80

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
	mv r4, r2

INNER_LOOP:
	sub r4, #1
	bne INNER_LOOP
	st r1, [r0]
	b   CHECK_SWTICHES

	