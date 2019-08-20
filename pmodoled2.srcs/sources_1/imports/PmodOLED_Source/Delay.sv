`timescale 1ns / 1ps

module Delay(
	input logic CLK,
	input logic RST,
	input logic [11:0] DELAY_MS,
	input logic DELAY_EN,
	output logic DELAY_FIN
);

	typedef enum logic[$clog2(3)-1:0] {
		Idle,
		Hold,
		Done} state_t;

	state_t current_state = Idle;						// Signal for state machine
	logic [16:0] clk_counter = 17'b00000000000000000;	// Counts up on every rising edge of CLK
	logic [11:0] ms_counter = 12'h000;					// Counts up when clk_counter = 100,000

	always_comb
		DELAY_FIN = (current_state == Done && DELAY_EN == 1'b1) ? 1'b1 : 1'b0;

	//  State Machine
	always @(posedge CLK) begin
		// When RST is asserted switch to idle (synchronous)
		if(RST == 1'b1)
			current_state <= Idle;
		else begin
			unique case(current_state)
				Idle : begin
					// Start delay on DELAY_EN
					if(DELAY_EN == 1'b1)
						current_state <= Hold;
				end
				Hold : begin
					// Stay until DELAY_MS has occured
					if(ms_counter == DELAY_MS)
						current_state <= Done;
				end
				Done : begin
					// Wait until DELAY_EN is deasserted to go to IDLE
					if(DELAY_EN == 1'b0)
						current_state <= Idle;
				end
				default : current_state <= Idle;
			endcase
		end
	end
	//  End State Machine

	// Creates ms_counter that counts at 1KHz
	// CLK_DIV
	always @(posedge CLK) begin
		if(current_state == Hold) begin
			if(clk_counter == 17'b11000011010100000) begin		// 100,000
				clk_counter <= 17'b00000000000000000;
				ms_counter <= ms_counter + 1'b1;					// increments at 1KHz
			end
			else
				clk_counter <= clk_counter + 1'b1;
		end
		else begin																// If not in the hold state reset counters
			clk_counter <= 17'b00000000000000000;
			ms_counter <= 12'h000;
		end
	end
endmodule
