`timescale 1ns / 1ps

module SpiCtrl(
    input logic CLK,
    input logic RST,
    input logic SPI_EN,
    input logic [7:0] SPI_DATA,
    output logic CS,
    output logic SDO,
    output logic SCLK,
    output logic SPI_FIN
    );

    typedef enum logic[$clog2(7)-1:0] {
        Idle,
        Send,
        Hold,
        Done} state_t;

	state_t current_state = Idle;		// Signal for state machine
	
	logic [7:0] shift_register = 8'h00;		// Shift register to shift out SPI_DATA saved when SPI_EN was set
	logic [3:0] shift_counter = 4'h0;		// Keeps track how many bits were sent
	logic clk_divided;						// Used as SCLK
	logic [4:0] counter = 5'b00000;			// Count clocks to be used to divide CLK
	logic temp_sdo = 1'b1;					// Tied to SDO
	logic falling = 1'b0;					// signal indicating that the clk has just fell

    logic [3:0] wait_counter= 4'b0000;;

	always_comb
	   clk_divided = ~counter[4];
	always_comb
	   SCLK = clk_divided;
	always_comb
	   SDO = temp_sdo;
	always_comb	
	   CS = (current_state == Idle && SPI_EN == 1'b0) ? 1'b1 : 1'b0;
	always_comb
	   SPI_FIN = (current_state == Done) ? 1'b1 : 1'b0;
	
	//  State Machine
	always @(posedge CLK) begin
			if(RST == 1'b1) begin							// Synchronous RST
				current_state <= Idle;
			end
			else begin			
				unique case(current_state)
					// Wait for SPI_EN to go high
					Idle : begin
						if(SPI_EN == 1'b1) begin
							current_state <= Send;
						end
					end
					// Start sending bits, transition out when all bits are sent and SCLK is high
					Send : begin
						if(shift_counter == 4'h8 && falling == 1'b0) begin
							current_state <= Hold;
						end
					end
					Hold : begin
					   // wait 4 clocks
					   wait_counter <= wait_counter + 1;
					   if (wait_counter == 'b1111) begin
					       current_state <= Done;
					       wait_counter <= 0;
					   end
                    end
					// Finish SPI transimission wait for SPI_EN to go low
					Done : begin
						if(SPI_EN == 1'b0) begin
							current_state <= Idle;
						end
					end
					default :
					   current_state <= Idle;
				endcase
			end
	end
	//  End of State Machine
	
	//  Clock Divider
	always @(posedge CLK) begin
			if(current_state == Send) 
				counter <= counter + 1'b1; //  start clock counter when in send state
			else 
				counter <= 5'b00000;       //  reset clock counter when not in send state
	end
	//  End Clock Divider

	//  SPI_SEND_BYTE,  sends SPI data formatted SCLK active low with SDO changing on the falling edge
	always @(posedge CLK) begin
			if(current_state == Idle) begin
					shift_counter <= 4'h0;
					// keeps placing SPI_DATA into shift_register so that when state goes to send it has the latest SPI_DATA
					shift_register <= SPI_DATA;
					temp_sdo <= 1'b1;
			end
			else if(current_state == Send) begin
					//  if on the falling edge of Clk_divided
					if(clk_divided == 1'b0 && falling == 1'b0) begin
							//  Indicate that it is passed the falling edge
							falling <= 1'b1;
							// send out the MSB
							temp_sdo <= shift_register[7];
							//  Shift through SPI_DATA
							shift_register <= {shift_register[6:0],1'b0};
							//  Keep track of what bit it is on
							shift_counter <= shift_counter + 1'b1;
					end
					//  on SCLK high reset the falling flag
					else if(clk_divided == 1'b1) 
						falling <= 1'b0;
			end
	end
endmodule
