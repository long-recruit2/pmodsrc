`timescale 1ns / 1ps
module PmodOLEDCtrl(
	input logic CLK,
	input logic RST,
	output logic CS,
	output logic SDIN,
	output logic SCLK,
	output logic DC,
	output logic RES,
	output logic VBAT,
	output logic VDD,
	input logic [3:0] KEY,
	input logic [3:0] KEYS[2:0],
	input logic KEYTRIGGER
);

	typedef enum logic[$clog2(4)-1:0] {
		Idle,
		OledInitialize,
		OledExample,
		Done} state_t;

	state_t current_state = Idle;

	logic init_en;
	logic init_done;
	logic init_cs;
	logic init_sdo;
	logic init_sclk;
	logic init_dc;

	logic example_en;
	logic example_cs;
	logic example_sdo;
	logic example_sclk;
	logic example_dc;
	logic example_done;

	OledInit Init(
		.CLK(CLK),
		.RST(RST),
		.EN(init_en),
		.CS(init_cs),
		.SDO(init_sdo),
		.SCLK(init_sclk),
		.DC(init_dc),
		.RES(RES),
		.VBAT(VBAT),
		.VDD(VDD),
		.FIN(init_done)
	);

	OledEX Example(
		.CLK(CLK),
		.RST(RST),
		.EN(example_en),
		.CS(example_cs),
		.SDO(example_sdo),
		.SCLK(example_sclk),
		.DC(example_dc),
		.FIN(example_done),
		.KEY(KEY),
		.KEYS(KEYS),
		.KEYTRIGGER(KEYTRIGGER)
	);

	//MUXes to indicate which outputs are routed out depending on which block is enabled
	always_comb
		CS = (current_state == OledInitialize) ? init_cs : example_cs;
	always_comb
		SDIN = (current_state == OledInitialize) ? init_sdo : example_sdo;
	always_comb
		SCLK = (current_state == OledInitialize) ? init_sclk : example_sclk;
	always_comb
		DC = (current_state == OledInitialize) ? init_dc : example_dc;
	//END output MUXes

	//MUXes that enable blocks when in the proper states
	always_comb
		init_en = (current_state == OledInitialize) ? 'b1 : 'b0;
	always_comb
		example_en = (current_state == OledExample) ? 'b1 : 'b0;
	//END enable MUXes

	//  State Machine
	always @(posedge CLK) begin
		if(RST == 'b1) begin
			current_state <= Idle;
		end
		else begin
			unique case(current_state)
				Idle :
					current_state <= OledInitialize;
				// Go through the initialization sequence
				OledInitialize : begin
					if(init_done == 'b1)
						current_state <= OledExample;
				end
				// Do example and Do nothing when finished
				OledExample : begin
					if(example_done == 'b1)
						current_state <= Done;
				end
				// Do Nothing
				Done :
					current_state <= Done;
				default :
					current_state <= Idle;
			endcase
		end
	end
endmodule