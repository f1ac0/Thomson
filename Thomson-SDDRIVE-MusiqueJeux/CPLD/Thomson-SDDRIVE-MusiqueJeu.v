`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:06:48 05/06/2024 
// Design Name: 
// Module Name:    thomson-sddrive 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module thomson_sddrive_musiquejeu(
	input E,
	input RW,
	inout [7:0] D,
	input _CSE,
//	input E7N, //generate it internally
	input [11:0] A,
	output _IRQ, //Open Drain
	input _RST,
	 
	output _ROMCE,
	output SD_CS,
	output SD_SCK,
	output SD_MOSI,
	input  SD_MISO,

	output [5:0] SON,
	input [5:0] J1,
	input [5:0] J2
	);

	wire sdd_D7;
	wire sdd_D_oe;
	wire [7:0] mj_D;
	wire mj_D_oe;
	wire _E7CX = !(!_CSE & !A[11] & A[10] & A[9] & A[8] & A[7] & A[6] & !A[5] & !A[4] );
	thomson_sddrive sdd(E, RW, sdd_D7, sdd_D_oe, D[0], _CSE, A[11:6], _ROMCE, SD_CS, SD_SCK, SD_MOSI, SD_MISO);
	thomson_musiquejeu mj(mj_IRQ, _RST, E, RW, _E7CX, A[3:0], D[7:0], mj_D[7:0], mj_D_oe, SON[5:0], J1[5:0], J2[5:0]);
	
	assign D = sdd_D_oe?{sdd_D7,7'bZ}:(mj_D_oe?mj_D:8'bZ);
	assign _IRQ = mj_IRQ?1'bZ:1'b0;
endmodule


// Module Name:    thomson-sddrive
module thomson_sddrive(
	input E,
	input RW,
	output D7,
	output D7_oe,
	input D0,
	input _CSE,
	input [11:6] A,
	output _ROMCE,
	output SD_CS,
	output SD_SCK,
	output SD_MOSI,
	input  SD_MISO
	);

	//SDDrive
	//assign _ROMCE = !( !_CSE & !A[11] & !( A[10] & A[9] & A[8]) ); //ROM active for addresses E000-E6FF
	assign _ROMCE = !( RW & !_CSE & !A[11] & !( A[10] & A[9] & A[8]) ); //add active on read operation only
	assign SD_CS = 1'b0;
	//wire _sck = !( !_CSE & !A[11] & A[10] & A[9] & A[8] & !A[6] & E ); //implemented as E700-E73F or E780-E7BF in original board
	wire _sck = !( !_CSE & !A[11] & A[10] & A[9] & A[8] & A[7] & !A[6] & E ); //but E7BF according to https://forum.system-cfg.com/viewtopic.php?p=133022#p133022 but implemented as  !( !_CSE & !A[11] & A[10] & A[9] & A[8] & !A[6] & E ) = E700-E73F or E780-E7BF)
	assign SD_SCK = _sck;
	wire _bi = !( !RW & !_sck );
	assign SD_MOSI = _bi ? 1'b1 : D0; //pullup in original board
	wire _bo = !( RW & !_sck );
	assign D7 = SD_MISO; //_bo ? 1'bz : SD_MISO;
	assign D7_oe = !_bo;
endmodule


// Module Name:    thomson-musiquejeu
module thomson_musiquejeu(
	output _IRQ, //Open Drain
	input _RST,
	input E,
	input RW,
	input _E7CX,
	input [3:0] A,
	input [7:0] D,
	output [7:0] D_o,
	output D_oe,
	output [5:0] SON,
	input [5:0] J1,
	input [5:0] J2
	);

	wire cs = !_E7CX & A[3] & A[2];
	wire [1:0] rs = {A[0], A[1]};

	//Peripherals
	//A[7:0], B[7:6], B[3:2] are inputs for respectively joy directions, 1st Buttons and 2nd Buttons
	//B[5:0] are outputs for the sound generation
	//For simplification we consider that a read from peripheral register will get the unbuffered peripheral inputs, and a write will set the SND register
	reg [5:0] snd = 6'b0;
	assign SON = snd;
	
	//Register selection
	//We need to track whether DDR or OR register is accessed to avoid playing direction selection as sound
	reg [1:0] ddr = 2'b0;
	
	//Interrupts
	//Interrupts are disabled by default
	//CA1, CA2, CB1 and CB2 are wired respectively to 2nd and 1st Buttons of 1st port and 2nd and 1st Buttons of 2nd port
	//CA1 and CB1 (2nd buttons) transition direction is selectable
	//For simplification all interrupts are combined to one single signal
	reg [3:0] inten = 4'b0;
	reg [3:0] inttr = 4'b0; //0 for high to low, 1 for low to high
	reg intr = 1'b0;
	assign _IRQ = !intr;
	
	//Peripheral registers
	// - Only B[5:0] are outputs; A[7:0] and B[7:6] are only inputs here
	//reg [5:0] PRB = 6'b0;
	 
	//Data direction registers
	// - Only B[3:2] are bidirectional, either second button input or snd output
	//reg [3:2] DDRB = 2'b0;
	 
	//Control registers
	// - writable CRB[2] in order to set data direction
	// - writable CRA[0] and CRB[0] to enable CA1 and CB1 interrupts
	// - writable CRA[3] and CRB[3] in conjunction to CRA[5]=0 or CRB[5]=0 to enable CA2 and CB2 interrupts
	// - readable CRA[7:6] and CRB[7:6] as interrupt flags, cleared on read
	// - maybe CRAB[1] and CRAB[3] for interrupt transition selection ?
	//reg [3:2] CRA = 6'b0;
	
	//Write operations
	wire outset = cs & !rs[0] & !RW & E;
	wire outclr = !_RST;
	always @(posedge outset, posedge outclr)
		if(outclr)
			snd <= 6'b0;
		else if(rs[1]==1'b1 & ddr[1]==1'b1)
			snd <= D[5:0];
	 
	//read operations
	//here we don't care if DDR or Peripheral register is selected. Maybe we should ?
	assign D_o[7:0]= rs[1]?{J2[4],J1[4],1'b1,1'b1,J2[5],J1[5],1'b1,1'b1}:{J2[3],J2[2],J2[1],J2[0],J1[3],J1[2],J1[1],J1[0]};
	assign D_oe = cs & !rs[0] & RW & E;

	//Setting and reset of control registers
	wire regset = cs & rs[0] & !RW & E;
	wire regclr = !_RST;
	always @(posedge regset, posedge regclr)
		if(regclr) begin
			inten <= 4'b0;
			inttr <= 4'b0;
			ddr <= 2'b0;
		end
		else if(rs[1]==1'b0) begin //0 for A, 1 for B
			{inten[1], inttr[1], ddr[0]} <= {D[0], D[1], D[2]};
			if(D[5]) //only when CA2 is input
				{inten[0], inttr[0]} <= {D[3], D[4]};
		end
		else begin
			{inten[3], inttr[3], ddr[1]} <= {D[0], D[1], D[2]};
			if(D[5]) //only when CB2 is input
				{inten[2], inttr[2]} <= {D[3], D[4]};
		end

	//Interrupt set and clear
	wire intset = (inten[0]&(inttr[0]?J1[4]:!J1[4])) | (inten[1]&(inttr[1]?J1[5]:!J1[5])) | (inten[2]&(inttr[2]?J2[4]:!J2[4])) | (inten[3]&(inttr[3]?J2[5]:!J2[5]));
	wire intclr = !_RST | (cs & !rs[0] & RW & E); //reset or read of the register !
	always @(posedge intset, posedge intclr)
		if(intclr)
			intr <= 1'b0;
		else
			intr <= 1'b1; //intset ?
	
endmodule
