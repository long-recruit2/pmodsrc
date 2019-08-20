`timescale 1ns / 1ps

module OledEX(
    input logic CLK,
    input logic RST,
    input logic EN,
    output logic CS,
    output logic SDO,
    output logic SCLK,
    output logic DC,
    output logic FIN,
    input logic [3:0] KEY,
    input logic [3:0] KEYS[2:0],
    input logic KEYTRIGGER
    );

	// wire CS, SDO, SCLK, DC, FIN;

   //Variable that contains what the screen will be after the next UpdateScreen state
   logic [7:0]        current_screen[0:3][0:15];

   //Constant that contains the screen filled with the Alphabet and numbers
   parameter [7:0]  alphabet_screen[0:3][0:15] = '{'{8'h41, 8'h42, 8'h43, 8'h44, 8'h45, 8'h46, 8'h47, 8'h48, 8'h49, 8'h4A, 8'h4B, 8'h4C, 8'h4D, 8'h4E, 8'h4F, 8'h50}, '{8'h51, 8'h52, 8'h53, 8'h54, 8'h55, 8'h56, 8'h57, 8'h58, 8'h59, 8'h5A, 8'h61, 8'h62, 8'h63, 8'h64, 8'h65, 8'h66}, '{8'h67, 8'h68, 8'h69, 8'h6A, 8'h6B, 8'h6C, 8'h6D, 8'h6E, 8'h6F, 8'h70, 8'h71, 8'h72, 8'h73, 8'h74, 8'h75, 8'h76}, '{8'h77, 8'h78, 8'h79, 8'h7A, 8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35, 8'h36, 8'h37, 8'h38, 8'h39, 8'h7F, 8'h7F}};
   //Constant that fills the screen with blank (spaces) entries
   parameter [7:0]  clear_screen[0:3][0:15] = '{'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
   //Constant that holds "This is Digilent's PmodOLED"   //Constant that holds "This is Digilent's PmodOLED"
   parameter [7:0]  digilent_screen[0:3][0:15] = '{'{8'h54, 8'h68, 8'h69, 8'h73, 8'h20, 8'h69, 8'h73, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, '{8'h44, 8'h69, 8'h67, 8'h69, 8'h6C, 8'h65, 8'h6E, 8'h74, 8'h27, 8'h73, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, '{8'h50, 8'h6D, 8'h6F, 8'h64, 8'h4F, 8'h4C, 8'h45, 8'h44, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, '{8'h53, 8'h65, 8'h69, 8'h6A, 8'h69, 8'h20, 8'h48, 8'h69, 8'h6e, 8'h6f, 8'h6b, 8'h69, 8'h79, 8'h61, 8'h20, 8'h20}};
   // parameter [7:0]  digilent_screen[0:3][0:15] = {"This is", "Digilent's", "PmodOLED", "Seiji Hinokiya"};

   logic [7:0]  clear_screen2[0:3][0:15];
   always_ff @(posedge CLK) begin
        if (KEY != 4'hA)
            clear_screen2 <= '{'{KEYS[1] + 'h30, KEYS[0] + 'h30, KEY + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
    end

    typedef enum logic[$clog2(27)-1:0] {
        Idle,
        Wait1,
        Wait2,
        Transition1,
        Transition2,
        Transition3,
        Transition4,
        Transition5,
        ClearDC,
        Alphabet,
        UpdateScreen,
        ClearScreen,
        DigilentScreen,
        SendChar1,
        SendChar2,
        SendChar3,
        SendChar4,
        SendChar5,
        SendChar6,
        SendChar7,
        SendChar8,
        SetPage,
        PageNum,
        LeftColumn1,
        LeftColumn2,
        SetDC,
        ReadMem,
        ReadMem2,
        WaitInput,
        Done} state_t;

   //Current overall state of the state machine
   state_t current_state;
   //State to go to after the SPI transmission is finished
   state_t after_state;
   //State to go to after the set page sequence
   state_t after_page_state;
   //State to go to after sending the character sequence
   state_t after_char_state;
   //State to go to after the UpdateScreen is finished
   state_t after_update_state;

	integer i = 0;
	integer j = 0;

   //Contains the value to be outputted to DC
   // reg temp_dc;
   
   //-------------- Variables used in the Delay Controller Block --------------
   logic [11:0] temp_delay_ms;		//amount of ms to delay
   logic temp_delay_en;				//Enable signal for the delay block
   wire temp_delay_fin;				//Finish signal for the delay block
   
   //-------------- Variables used in the SPI controller block ----------------
   logic temp_spi_en;					//Enable signal for the SPI block
   logic [7:0] temp_spi_data;		//Data to be sent out on SPI
   wire temp_spi_fin;				//Finish signal for the SPI block
   
   logic [7:0] temp_char;				//Contains ASCII value for character
   logic [10:0] temp_addr;			//Contains address to BYTE needed in memory
   wire [7:0] temp_dout;			//Contains byte outputted from memory
   logic [1:0] temp_page;				//Current page
   logic [3:0] temp_index;			//Current character on page

	// ===========================================================================
	// 										Implementation
	// ===========================================================================

   // assign DC = temp_dc;
   //Example finish flag only high when in done state
   assign FIN = (current_state == Done) ? 1'b1 : 1'b0;

   //Instantiate SPI Block
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

   //Instantiate Delay Block
   Delay DELAY_COMP(
			.CLK(CLK),
			.RST(RST),
			.DELAY_MS(temp_delay_ms),
			.DELAY_EN(temp_delay_en),
			.DELAY_FIN(temp_delay_fin)
	);

   //Instantiate Memory Block
   charLib CHAR_LIB_COMP(
			.clka(CLK),
			.addra(temp_addr),
			.douta(temp_dout)
	);
	
	//  State Machine
	always @(posedge CLK) begin
			
		case(current_state)

			// Idle until EN pulled high than intialize Page to 0 and go to state Alphabet afterwards
			Idle : begin
					if(EN == 1'b1) begin
						current_state <= ClearDC;
						// after_page_state <= Alphabet;
						after_page_state <= DigilentScreen;
						temp_page <= 2'b00;
					end
			end
			
			// Set current_screen to constant alphabet_screen and update the screen.  Go to state Wait1 afterwards
			Alphabet : begin
					for(i = 0; i <= 3 ; i=i+1) begin
						for(j = 0; j <= 15 ; j=j+1) begin
								current_screen[i][j] <= alphabet_screen[i][j];
						end
					end
					
					current_state <= UpdateScreen;
					after_update_state <= Wait1;
			end
			
			// Wait 4ms and go to ClearScreen
			Wait1 : begin
					temp_delay_ms <= 12'b111110100000; //4000
					after_state <= ClearScreen;
					current_state <= Transition3; // Transition3 = The delay transition states
			end
			
			// set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
			ClearScreen : begin
					for(i = 0; i <= 3 ; i=i+1) begin
						for(j = 0; j <= 15 ; j=j+1) begin
								current_screen[i][j] <= clear_screen[i][j];
						end
					end
					
					after_update_state <= Wait2;
					current_state <= UpdateScreen;
			end
			
			// Wait 1ms and go to DigilentScreen
			Wait2 : begin
					temp_delay_ms <= 12'b001111101000; //1000
					after_state <= DigilentScreen;
					current_state <= Transition3; // Transition3 = The delay transition states
			end
			
			// Set currentScreen to constant digilent_screen and update the screen. Go to state Done afterwards
			DigilentScreen : begin
					for(i = 0; i <= 3 ; i=i+1) begin
						for(j = 0; j <= 15 ; j=j+1) begin
								// current_screen[i][j] <= digilent_screen[i][j];
								current_screen[i][j] <= clear_screen2[i][j];
						end
					end
					
					after_update_state <= WaitInput;
					current_state <= UpdateScreen;
			end

			WaitInput : begin
                 if(KEYTRIGGER == 'b1)
				    current_state <= DigilentScreen;
			end
			
			// Do nothing until EN is deassertted and then current_state is Idle
			Done : begin
					if(EN == 1'b0) begin
						current_state <= Idle;
					end
			end
			
			//UpdateScreen State
			//1. Gets ASCII value from current_screen at the current page and the current spot of the page
			//2. If on the last character of the page transition update the page number, if on the last page(3)
			//			then the updateScreen go to after_update_state after
			UpdateScreen : begin

					temp_char <= current_screen[temp_page][temp_index];

					if(temp_index == 'd15) begin

						temp_index <= 'd0;
						temp_page <= temp_page + 1'b1;
						after_char_state <= ClearDC;

						if(temp_page == 2'b11) begin
							after_page_state <= after_update_state;
						end
						else	begin
							after_page_state <= UpdateScreen;
						end
					end
					else begin

						temp_index <= temp_index + 1'b1;
						after_char_state <= UpdateScreen;

					end
					
					current_state <= SendChar1;

			end
			
			//Update Page states
			//1. Sets DC to command mode
			//2. Sends the SetPage Command
			//3. Sends the Page to be set to
			//4. Sets the start pixel to the left column
			//5. Sets DC to data mode
			ClearDC : begin
					DC <= 1'b0;
					current_state <= SetPage;
			end
			
			SetPage : begin
					temp_spi_data <= 8'b00100010;
					after_state <= PageNum;
					current_state <= Transition1;
			end
			
			PageNum : begin
					temp_spi_data <= {6'b000000,temp_page};
					after_state <= LeftColumn1;
					current_state <= Transition1;
			end
			
			LeftColumn1 : begin
					temp_spi_data <= 8'b00000000;
					after_state <= LeftColumn2;
					current_state <= Transition1;
			end
			
			LeftColumn2 : begin
					temp_spi_data <= 8'b00010000;
					after_state <= SetDC;
					current_state <= Transition1;
			end
			
			SetDC : begin
					DC <= 1'b1;
					current_state <= after_page_state;
			end
			
			//Send Character States
			//1. Sets the Address to ASCII value of char with the counter appended to the end
			//2. Waits a clock for the data to get ready by going to ReadMem and ReadMem2 states
			//3. Send the byte of data given by the block Ram
			//4. Repeat 7 more times for the rest of the character bytes
			SendChar1 : begin
					temp_addr <= {temp_char, 3'b000};
					after_state <= SendChar2;
					current_state <= ReadMem;
			end
			
			SendChar2 : begin
					temp_addr <= {temp_char, 3'b001};
					after_state <= SendChar3;
					current_state <= ReadMem;
			end
			
			SendChar3 : begin
					temp_addr <= {temp_char, 3'b010};
					after_state <= SendChar4;
					current_state <= ReadMem;
			end
			
			SendChar4 : begin
					temp_addr <= {temp_char, 3'b011};
					after_state <= SendChar5;
					current_state <= ReadMem;
			end
			
			SendChar5 : begin
					temp_addr <= {temp_char, 3'b100};
					after_state <= SendChar6;
					current_state <= ReadMem;
			end
			
			SendChar6 : begin
					temp_addr <= {temp_char, 3'b101};
					after_state <= SendChar7;
					current_state <= ReadMem;
			end
			
			SendChar7 : begin
					temp_addr <= {temp_char, 3'b110};
					after_state <= SendChar8;
					current_state <= ReadMem;
			end
			
			SendChar8 : begin
					temp_addr <= {temp_char, 3'b111};
					after_state <= after_char_state;
					current_state <= ReadMem;
			end
			
			ReadMem : begin
					current_state <= ReadMem2;
			end

			ReadMem2 : begin
					temp_spi_data <= temp_dout;
					current_state <= Transition1;
			end
			//  End Send Character States

			// SPI transitions
			// 1. Set SPI_EN to 1
			// 2. Waits for SpiCtrl to finish
			// 3. Goes to clear state (Transition5)
			Transition1 : begin
					temp_spi_en <= 1'b1;
					current_state <= Transition2;
			end

			Transition2 : begin
					if(temp_spi_fin == 1'b1) begin
						current_state <= Transition5;
					end
			end

			// Delay Transitions
			// 1. Set DELAY_EN to 1
			// 2. Waits for Delay to finish
			// 3. Goes to Clear state (Transition5)
			Transition3 : begin
					temp_delay_en <= 1'b1;
					current_state <= Transition4;
			end

			Transition4 : begin
					if(temp_delay_fin == 1'b1) begin
						current_state <= Transition5;
					end
			end

			// Clear transition
			// 1. Sets both DELAY_EN and SPI_EN to 0
			// 2. Go to after state
			Transition5 : begin
					temp_spi_en <= 1'b0;
					temp_delay_en <= 1'b0;
					current_state <= after_state;
			end
			//END SPI transitions
			//END Delay Transitions
			//END Clear transition

			default : current_state <= Idle;

		endcase
	end



endmodule
