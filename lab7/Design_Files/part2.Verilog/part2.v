// Reset with SW[0]. Clock counter and memory with KEY[0]. Clock
// each instuction into the processor with KEY[1]. SW[9] is the Run input.
// Use KEY[0] to advance the memory as needed before each processor KEY[1]
// clock cycle.
module part2 (KEY, SW, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
    input [1:0] KEY;
    input [9:0] SW;
    output [9:0] LEDR;	
    output wire [6:0] HEX0;     // DE-series HEX displays
    output wire [6:0] HEX1;
    output wire [6:0] HEX2;
    output wire [6:0] HEX3;
    output wire [6:0] HEX4;
    output wire [6:0] HEX5;

    wire Done, Resetn, PClock, MClock, Run;
    wire [15:0] DIN;
    wire [4:0] pc;
    wire [2:0] FSM;

    assign Resetn = SW[0];
    assign MClock = KEY[0];
    assign PClock = KEY[1];
    assign Run = SW[9];

    proc U1 (DIN, Resetn, PClock, Run, Done, FSM);
    assign LEDR[0] = Done;
    assign LEDR[9] = Run;
    assign LEDR[3:1] = FSM;

    inst_mem U2 (pc, MClock, DIN);
    count5 U3 (Resetn, MClock, pc);

    hex7seg U4 ({3'b000,pc[4]}, HEX5);
    hex7seg U5 (pc[3:0], HEX4);
    hex7seg U6 (DIN[15:12], HEX3);
    hex7seg U7 (DIN[11:8], HEX2);
    hex7seg U8 (DIN[7:4], HEX1);
    hex7seg U9 (DIN[3:0], HEX0);
endmodule

module count5 (Resetn, Clock, Q);
    input Resetn, Clock;
    output reg [4:0] Q;

    always @ (posedge Clock, negedge Resetn)
        if (Resetn == 0)
            Q <= 5'b00000;
        else
            Q <= Q + 1'b1;
endmodule

module hex7seg (hex, display);
	input [3:0] hex;
	output [0:6] display;

	reg [0:6] display;

	/*
	 *       0  
	 *      ---  
	 *     |   |
	 *    5|   |1
	 *     | 6 |
	 *      ---  
	 *     |   |
	 *    4|   |2
	 *     |   |
	 *      ---  
	 *       3  
	 */
	always @ (*)
		case (hex)
			4'h0: display = 7'b1000000;
			4'h1: display = 7'b1111001;
			4'h2: display = 7'b0100100;
			4'h3: display = 7'b0110000;
			4'h4: display = 7'b0011001;
			4'h5: display = 7'b0010010;
			4'h6: display = 7'b0000010;
			4'h7: display = 7'b1111000;
			4'h8: display = 7'b0000000;
			4'h9: display = 7'b0011000;
			4'hA: display = 7'b0001000;
			4'hb: display = 7'b0000011;
			4'hC: display = 7'b1000110;
			4'hd: display = 7'b0100001;
			4'hE: display = 7'b0000110;
			4'hF: display = 7'b0001110;
			default: display = 7'b1111111;
		endcase
endmodule

