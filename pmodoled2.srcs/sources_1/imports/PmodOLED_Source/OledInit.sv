`timescale 1ns / 1ps

module OledInit(
	input logic CLK,
	input logic EN,
	output logic RST,
	output logic CS,
	output logic DC = 1'b0,
	output logic FIN = 1'b0,
	output logic RES = 1'b1,
	output logic SCLK,
	output logic SDO,
	output logic VBAT = 1'b1,
	output logic VDD = 1'b1
);

	typedef enum logic[$clog2(27)-1:0] {
		Idle,
		VddOn,
		Wait1,
		Wait2,
		Wait3,
		Transition1,
		Transition2,
		Transition3,
		Transition4,
		Transition5,
		ResetOn,
		ResetOff,
		ChargePump1,
		ChargePump2,
		PreCharge1,
		PreCharge2,
		VbatOn,
		DispContrast1,
		DispContrast2,
		InvertDisp1,
		InvertDisp2,
		ComConfig1,
		ComConfig2,
		DispOff,
		DispOn,
		FullDisp,
		Done} state_t;

	state_t current_state = Idle;
	state_t after_state = Idle;

	logic temp_delay_en = 1'b0;
	logic temp_spi_en = 1'b0;
	logic [7:0] temp_spi_data = 8'h00;

	logic [11:0] temp_delay_ms;
	logic temp_delay_fin;
	logic temp_spi_fin;

	SpiCtrl SPI_COMP(
		.CLK(CLK),
		.RST(RST),
		.SPI_EN(temp_spi_en),
		.SPI_DATA(temp_spi_data),
		.CS(CS),
		.SDO(SDO),
		.SCLK(SCLK),
		.SPI_FIN(temp_spi_fin)
	);

	Delay DELAY_COMP(
		.CLK(CLK),
		.RST(RST),
		.DELAY_MS(temp_delay_ms),
		.DELAY_EN(temp_delay_en),
		.DELAY_FIN(temp_delay_fin)
	);

	// Delay 100 ms after VbatOn
	always_comb
		temp_delay_ms = (after_state == DispContrast1) ? 12'h064 : 12'h001;

	// State Machine
	always @(posedge CLK) begin
		if(RST == 1'b1) begin
			current_state <= Idle;
			RES <= 1'b0;
		end
		else begin
			RES <= 1'b1;
			unique case(current_state)
				// Idle State
				Idle : begin
					if(EN == 'b1) begin
						DC <= 'b0;
						current_state <= VddOn;
					end
				end

				// Initialization Sequence
				// This should be done everytime the PmodOLED is started
				VddOn : begin
					VDD <= 'b0;
					current_state <= Wait1;
				end

				// 3
				Wait1 : begin
					after_state <= DispOff;
					current_state <= Transition3;
				end

				// 4
				DispOff : begin
					temp_spi_data <= 8'hAE; // 0xAE
					after_state <= ResetOn;
					current_state <= Transition1;
				end

				// 5
				ResetOn : begin
					// temp_res <= 'b0;
					RES <= 'b0;
					current_state <= Wait2;
				end

				// 6
				Wait2 : begin
					after_state <= ResetOff;
					current_state <= Transition3;
				end

				// 7
				ResetOff : begin
					// temp_res <= 'b1;
					RES <= 'b1;
					after_state <= ChargePump1;
					current_state <= Transition3;
				end

				// 8
				ChargePump1 : begin
					temp_spi_data <= 8'h8D; //0x8D
					after_state <= ChargePump2;
					current_state <= Transition1;
				end

				// 9
				ChargePump2 : begin
					temp_spi_data <= 8'h14; // 0x14
					after_state <= PreCharge1;
					current_state <= Transition1;
				end

				// 10
				PreCharge1 : begin
					temp_spi_data <= 8'hD9; // 0xD9
					after_state <= PreCharge2;
					current_state <= Transition1;
				end

				// 11
				PreCharge2 : begin
					temp_spi_data <= 8'hF1; // 0xF1
					after_state <= VbatOn;
					current_state <= Transition1;
				end

				// 12
				VbatOn : begin
					// temp_vbat <= 'b0;
					VBAT <= 'b0;
					current_state <= Wait3;
				end

				// 13
				Wait3 : begin
					after_state <= DispContrast1;
					current_state <= Transition3;
				end

				// 14
				DispContrast1 : begin
					temp_spi_data <= 8'h81; // 0x81
					after_state <= DispContrast2;
					current_state <= Transition1;
				end

				// 15
				DispContrast2 : begin
					temp_spi_data <= 8'h0F; // 0x0F
					after_state <= InvertDisp1;
					current_state <= Transition1;
				end

				// 16
				InvertDisp1 : begin
					temp_spi_data <= 8'hA1; // 0xA1
					after_state <= InvertDisp2;
					current_state <= Transition1;
				end

				// 17
				InvertDisp2 : begin
					temp_spi_data <= 8'hC8; // 0xC8
					after_state <= ComConfig1;
					current_state <= Transition1;
				end

				// 18
				ComConfig1 : begin
					temp_spi_data <= 8'hDA; // 0xDA
					after_state <= ComConfig2;
					current_state <= Transition1;
				end

				// 19
				ComConfig2 : begin
					temp_spi_data <= 8'h20; // 0x20
					after_state <= DispOn;
					current_state <= Transition1;
				end

				// 20
				DispOn : begin
					temp_spi_data <= 8'hAF; // 0xAF
					after_state <= Done;
					current_state <= Transition1;
				end
				// ************ END Initialization sequence ************

				// Used for debugging, This command turns the entire screen on regardless of memory
				FullDisp : begin
					temp_spi_data <= 8'hA5; // 0xA5
					after_state <= Done;
					current_state <= Transition1;
				end

				// Done state
				Done : begin
					if(EN == 'b0) begin
						FIN <= 'b0;
						current_state <= Idle;
					end
					else begin
						FIN <= 'b1;
					end
				end

				// SPI transitions
				// 1. Set SPI_EN to 1
				// 2. Waits for SpiCtrl to finish
				// 3. Goes to clear state (Transition5)
				Transition1 : begin
					temp_spi_en <= 'b1;
					current_state <= Transition2;
				end

				// 24
				Transition2 : begin
					if(temp_spi_fin == 'b1) begin
						current_state <= Transition5;
					end
				end

				// Delay Transitions
				// 1. Set DELAY_EN to 1
				// 2. Waits for Delay to finish
				// 3. Goes to Clear state (Transition5)
				Transition3 : begin
					temp_delay_en <= 'b1;
					current_state <= Transition4;
				end

				// 26
				Transition4 : begin
					if(temp_delay_fin == 'b1) begin
						current_state <= Transition5;
					end
				end

				// Clear transition
				// 1. Sets both DELAY_EN and SPI_EN to 0
				// 2. Go to after state
				Transition5 : begin
					temp_spi_en <= 'b0;
					temp_delay_en <= 'b0;
					current_state <= after_state;
				end

				default : current_state <= Idle;
			endcase
		end
	end
endmodule
