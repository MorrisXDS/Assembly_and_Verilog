.define LED_ADDRESS 0x10
.define HEX_ADDRESS 0x20
.define SW_ADDRESS 0X30

// shows on HEX displays either PASSEd or FAILEd
	mvt r0, #LED_ADDRESS
	mvt r3, #SW_ADDRESS
	mv r1, #0
	st r1, [r0]
	mv r2, #0x64

CHECK_SWTICHES:
	ld r4, [r3]
	st r4, [r0]
	and r4, #0X3 // and with 2b11 which is to read the SW1-0
	sub r4, #2
	beq SLOW_DOWN
	add r4, #2
	sub r4, #1
	beq SPEED_UP 
	b   INCREMENT

SPEED_UP:
	mv r5, #0x60
	sub r2, r5
	st r2, [r0]
	b  END

SLOW_DOWN:
	mv r5, #0x9b
	add r2, r5
	st r2, [r0]
	b  END


INCREMENT:
	add r1, #1
	mv r3, r2

INNER_LOOP:
	sub r3, #1
	bne INNER_LOOP
	st r1, [r0]
	b   CHECK_SWTICHES

END:	b END
	