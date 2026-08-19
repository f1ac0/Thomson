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
	
	//Register selection
		
	//Control registers
	// - writable CRB[2] in order to set data direction
	// - writable CRA[0] and CRB[0] to enable CA1 and CB1 interrupts
	// - writable CRA[3] and CRB[3] in conjunction to CRA[5]=0 or CRB[5]=0 to enable CA2 and CB2 interrupts
	// - readable CRA[7:6] and CRB[7:6] as interrupt flags, cleared on read
	// - maybe CRAB[1] and CRAB[3] for interrupt transition selection ?
	//here we need to simulate read and write operation since sddrive selector use them to detect the expansion
	reg [7:0] cra = 8'b0;
	reg [7:0] crb = 8'b0;
	
	//Setting and reset of control registers
	wire regset = cs & rs[0] & !RW & E;
	wire regclr = !_RST;
	always @(posedge regset, posedge regclr)
		if(regclr) begin
			cra[5:0] <= 6'b0;
			crb[5:0] <= 6'b0;
		end
		else if(!rs[1]) //0 for A, 1 for B
			cra[5:0] <= D[5:0];
		else
			crb[5:0] <= D[5:0];

	//Data direction registers
	// - Only B[3:2] are bidirectional, either second button input or snd output
	//here we dont care since we have separate pins for them: write op goes to output and read comes from input 
	reg [7:0] ddra = 8'b0;
	reg [7:0] ddrb = 8'b0;
	 
	//Peripheral registers
	
	//- B[5:0] are outputs for the sound generation
	reg [7:0] pb_out = 8'b0;
	assign SON = ddrb[5:0] & pb_out[5:0];

	//- A[7:0], B[7:6], B[3:2] are inputs for respectively joy directions, 1st Buttons and 2nd Buttons
	wire [7:0] pa_in = {J2[3],J2[2],J2[1],J2[0],J1[3],J1[2],J1[1],J1[0]};
	wire [7:0] pb_in = {ddrb[7]?pb_out[7]:J2[4], ddrb[6]?pb_out[6]:J1[4], ddrb[5]?pb_out[5]:1'b1, ddrb[4]?pb_out[4]:1'b1, ddrb[3]?pb_out[3]:J2[5], ddrb[2]?pb_out[2]:J1[5], ddrb[1]?pb_out[1]:1'b1, ddrb[0]?pb_out[0]:1'b1};
	 
	//Write operations to output and ddr register
	//We need to track whether DDR or OR register is accessed to avoid playing direction selection as sound
	//snd on port B is our only output and read op port A would be affected by joy position even in output anyway, so we ignore port A output
	wire outset = cs & !rs[0] & !RW & E;
	wire outclr = !_RST;
	always @(posedge outset, posedge outclr)
		if(outclr) begin
			pb_out <= 8'b0;
			ddra <= 8'b0;
			ddrb <= 8'b0;
		end
		else if(rs[1] & crb[2])
			pb_out <= D;
		else if(!rs[1] & !cra[2])
			ddra <= D;
		else if(rs[1] & !crb[2])
			ddrb <= D;
			
	//read operations
	//here we don't care if DDR or Peripheral register is selected. Maybe we should ?
	assign D_o[7:0]= rs[0]? (rs[1]?crb:cra) : (rs[1]? (crb[2]?pb_in:ddrb) : (cra[2]?pa_in:ddra));
	assign D_oe = cs & RW & E;

	//Interrupts
	//Interrupts are disabled by default
	//CA1, CA2, CB1 and CB2 are wired respectively to 2nd and 1st Buttons of 1st port and 2nd and 1st Buttons of 2nd port
	//CA1 and CB1 (2nd buttons) transition direction is selectable
	//All interrupts are combined to the _IRQ pin

	//Interrupt set and clear
	//Properly detect transistions on interrupt inputs otherwise an interrupt will fire inside sddrive selector during expansion detection that will not be serviced and will lock the system when exiting the selector
	wire ca1 = J1[5];
	wire ca2 = J1[4];
	wire cb1 = J2[5];
	wire cb2 = J2[4];
	reg ca1p = 1'b0;
	reg ca2p = 1'b0;
	reg cb1p = 1'b0;
	reg cb2p = 1'b0;
	always @(posedge E) begin
		ca1p <= ca1;
		ca2p <= ca2;
		cb1p <= cb1;
		cb2p <= cb2;
	end
	
	wire irqa1set = cra[0] & (cra[1] ? (!ca1p&ca1) : (ca1p&!ca1));
	wire irqa2set = (!cra[5]) & cra[3] & (cra[4] ? (!ca2p&ca2) : (ca2p&!ca2));
	wire irqaclr = !_RST | (cs & !rs[0] & !rs[1] & cra[2] & RW & E);  //reset or read of the register !
	wire irqb1set = crb[0] & (crb[1] ? (!cb1p&cb1) : (cb1p&!cb1));
	wire irqb2set = (!crb[5]) & crb[3] & (crb[4] ? (!cb2p&cb2) : (cb2p&!cb2));
	wire irqbclr = !_RST | (cs & !rs[0] & rs[1] & crb[2] & RW & E); //reset or read of the register !
	always @(posedge irqa1set, posedge irqaclr)
		if(irqaclr)
			cra[7] <= 1'b0;
		else
			cra[7] <= 1'b1;
	always @(posedge irqa2set, posedge irqaclr)
		if(irqaclr)
			cra[6] <= 1'b0;
		else
			cra[6] <= 1'b1;
	always @(posedge irqb1set, posedge irqbclr)
		if(irqbclr)
			crb[7] <= 1'b0;
		else
			crb[7] <= 1'b1;
	always @(posedge irqb2set, posedge irqbclr)
		if(irqbclr)
			crb[6] <= 1'b0;
		else
			crb[6] <= 1'b1;
			
	assign _IRQ = !( cra[6] | cra[7] | crb[6] | crb[7] ); //IRQA and IRQB pins are tied together

endmodule
