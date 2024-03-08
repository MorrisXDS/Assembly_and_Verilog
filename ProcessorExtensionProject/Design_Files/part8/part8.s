DEPTH 4096
.define LED_ADDRESS 0x1000
.define HEX_ADDRESS 0x2000
.define SW_ADDRESS 0x3000
.define DEFAULT_SPED 0x7f

START:
    mvt sp, #0x10
    mv r0, =DATA
    mv r3, r0
    mv r4, =DEFAULT_SPED

proceed:
    mv r2, =HEX_ADDRESS
    mv r3, r0
    add r3, #5
    bl _range_check
    ld r1, [r3]
    st r1, [r2]
    push r4

display:
    mv r4, #5

display_loop:
    sub r4, #1
    mv r3, r0
    add r3, r4
    bl _range_check
    ld r1, [r3]
    add r2, #1
    st r1, [r2]
    cmp r4, #0
    bne display_loop
    pop r4

_flip:
    mv r3, =SW_ADDRESS
    ld r2, [r3]
    and r2, #0b1
    b _move_direction

_move_direction:
    cmp r2, #1
    beq flipped
    b direct

flipped:
    sub   r0, #1
    push r1
    mv r2, =LED_ADDRESS
    ld r1, [r2]
    add r1, #0b1
    st r1, [r2]
    pop r1
    b     valid_range

direct:
    add   r0, #1
    b     valid_range

valid_range:
    mv    r3, r0
    bl    _range_check
    mv    r0, r3

LOOP:
    push r1
    mv r1, =0x7f
    mv r1, r4

LED_display:
    push r2
    cmp r1, DEFAULT_SPED
    bmi SHOW_KEY_1
    bpl SHOW_KEY_2
    b   _speed_control
    
SHOW_KEY_1:
    push r1
    mv r2, =LED_ADDRESS
    ld r1, [r2]
    add r1, #0b10
    st r1, [r2]
    pop r1
    b _speed_control

SHOW_KEY_2:
    push r1
    mv r2, =LED_ADDRESS
    ld r1, [r2]
    add r1, #0b100
    st r1, [r2]
    pop r1
    b _speed_control

_speed_control:
    mv r3, =SW_ADDRESS 
    ld r2, [r3]
    lsr r2, #1
    and r2, #0b1
    cmp r2, #1
    beq speed_up
    ld r2, [r3]
    lsr r2, #2
    and r2, #0b1
    cmp r2, #1
    beq slow_down
    ld r2, [r3]
    lsr r2, #3
    and r2, #0b1
    cmp r2, #1
    beq default_speed
    b   LOOP_IN_PROGRESS
 
default_speed:
    ld r2, [r3]
    lsr r2, #3
    and r2, #0b1
    cmp r2, #0
    mv r4, =DEFAULT_SPED
    mv r1, r4
    b   LOOP_IN_PROGRESS

speed_up:
    ld r2, [r3]
    lsr r2, #1
    and r2, #0b1
    cmp r2, #0
    bne speed_up
    lsr r1, #1
    bl maintain_min
    mv  r4, r1

    ld r2, [r3]
    lsr r2, #2
    and r2, #0b1
    cmp r2, #1
    beq slow_down
    b   LOOP_IN_PROGRESS

slow_down:
    ld r2, [r3]
    lsr r2, #2
    and r2, #0b1
    cmp r2, #0
    bne slow_down
    lsl r1, #1
    bl maintain_max
    mv  r4, r1
    b   LOOP_IN_PROGRESS

LOOP_IN_PROGRESS:
    sub r1, #1
    bne LOOP_IN_PROGRESS
    pop r1
    b proceed
    
_range_check:
    mv r1, =DATA
    cmp r3, r1
    bmi adjust_front
    add r1, #18
    cmp r3, r1
    bpl out_range
    b    _return

adjust_front:
    add r3, #18
    b    _return

out_range:
    sub r3, #18
    b    _return

_return:
    mv pc, lr

maintain_min:
    cmp r1, #0
    beq min
    mv pc, lr

min:
    mv r1, #1
    mv pc, lr

maintain_max:
    push r2
    mv r2, =0x1FF
    cmp r1, r2
    bpl max
    pop r2
    mv pc, lr

max:
    mv r1, =0x1FF
    pop r2
    mv pc, lr

DATA:
    .word 0b01011110 //0x5E "d"
    .word 0b00111111 //0x3F "O"
    .word 0b00110111 //0x37 "N"
    .word 0b01111001 //0x79 "E"
    .word 0b00000000 //0x00 " "
    .word 0b01111001 //0x79 "E"
    .word 0b00111001 //0x39 "C"
    .word 0b01111001 //0x79 "E"
    .word 0b01000000 //0x40 "-"
    .word 0b01011011 //0x5B "2"
    .word 0b01100110 //0x66 "4"
    .word 0b01001111 //0x4F "3"
    .word 0b00000000 //0x00 " "
    .word 0b00111000 //0x38 "L"
    .word 0b01110111 //0x77 "A"
    .word 0b01111100 //0x7c "b"
    .word 0b01100111 //0x6D "9"
    .word 0b00000000 //0x00 " "
