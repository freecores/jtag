/**********************************************************************************
*                                                                                 *
*   This verilog file is a part of the Boundary Scan Implementation and comes in  *
*   a pack with several other files. It is fully IEEE 1149.1 compliant.           *
*   For details check www.opencores.org (pdf files, bsdl file, etc.)              *
*                                                                                 *
*  Copyright (C) 2000 Igor Mohor (igorm@opencores.org) and OPENCORES.ORG          *
*                                                                                 *
*  This program is free software; you can redistribute it and/or modify           *
*  it under the terms of the GNU General Public License as published by           *
*  the Free Software Foundation; either version 2 of the License, or              *
*  (at your option) any later version.                                            *
*                                                                                 *
*  See the file COPYING for the full details of the license.                      *
*                                                                                 *
*  OPENCORES.ORG is looking for new open source IP cores and developers that      *
*  would like to help in our mission.                                             *
*                                                                                 *
**********************************************************************************/


// Top module
module TAP(P_TMS, P_TCK, P_TRST, P_TDI, P_TDO, 
		TestSignal,
		InputPin,
		Output3Pin,
		Output2Pin,
		BidirectionalPin
		);

`define BSLength 14

supply1 vcc;
supply0 gnd;

// Instructions specified by the IEEE-1149.1
parameter EXTEST          = 4'b0000;
parameter SAMPLE_PRELOAD  = 4'b0001;
parameter IDCODE          = 4'b0010;
parameter BYPASS          = 4'b1111;


input P_TMS, P_TCK;
input P_TRST, P_TDI;

output P_TDO;

input [1:0] InputPin;						// Input pin
output [1:0] Output3Pin;  			// Output pin with tristate control
output [1:0] Output2Pin;  			// Output pin without tristate control
inout [1:0] BidirectionalPin;		// Input/Output pin (with tristate control)

output [5:0]TestSignal; 				// Signals for testing purposes (can be deleted)

wire TCK = P_TCK;
wire TCKn = ~P_TCK;
wire TMS = P_TMS;
wire TDI = P_TDI;

wire TRST = P_TRST;							// TRST is active high (for easier development). Should be change to active low
//wire TRST = ~P_TRST;					// active low

reg TestLogicReset;
reg RunTestIdle;
reg SelectDRScan;
reg CaptureDR;
reg ShiftDR;
reg Exit1DR;
reg PauseDR;
reg Exit2DR;
reg UpdateDR;

reg SelectIRScan;
reg CaptureIR;
reg ShiftIR;
reg Exit1IR;
reg PauseIR;
reg Exit2IR;
reg UpdateIR;



/**********************************************************************************
*																																									*
*		TAP State Machine: Fully JTAG compliant																				*
*																																									*
*		P_TRST must toggle at the beginning if PowerONReset signal is not present			*
*		in the design.																																*
*																																									*
*																																									*
*																																									*
**********************************************************************************/
//wire RESET = TRST | PowerONReset;							// If PowerONReset signal is used in the design
wire RESET = TRST;															// If no PowerONReset signal is used in the design

// TestLogicReset state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		TestLogicReset<=1;
	else
		begin
			if(TMS & (TestLogicReset | SelectIRScan))
				TestLogicReset<=1;
			else
				TestLogicReset<=0;
		end
end

// RunTestIdle state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		RunTestIdle<=0;
	else
		begin
			if(~TMS & (TestLogicReset | RunTestIdle | UpdateDR | UpdateIR))
				RunTestIdle<=1;
			else
				RunTestIdle<=0;
		end
end

// SelectDRScan state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		SelectDRScan<=0;
	else
		begin
			if(TMS & (RunTestIdle | UpdateDR | UpdateIR))
				SelectDRScan<=1;
			else
				SelectDRScan<=0;
		end
end

// CaptureDR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		CaptureDR<=0;
	else
		begin
			if(~TMS & SelectDRScan)
				CaptureDR<=1;
			else
				CaptureDR<=0;
		end
end

// ShiftDR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		ShiftDR<=0;
	else
		begin
			if(~TMS & (CaptureDR | ShiftDR | Exit2DR))
				ShiftDR<=1;
			else
				ShiftDR<=0;
		end
end

// Exit1DR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		Exit1DR<=0;
	else
		begin
			if(TMS & (CaptureDR | ShiftDR))
				Exit1DR<=1;
			else
				Exit1DR<=0;
		end
end

// PauseDR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		PauseDR<=0;
	else
		begin
			if(~TMS & (Exit1DR | PauseDR))
				PauseDR<=1;
			else
				PauseDR<=0;
		end
end

// Exit2DR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		Exit2DR<=0;
	else
		begin
			if(TMS & PauseDR)
				Exit2DR<=1;
			else
				Exit2DR<=0;
		end
end

// UpdateDR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		UpdateDR<=0;
	else
		begin
			if(TMS & (Exit1DR | Exit2DR))
				UpdateDR<=1;
			else
				UpdateDR<=0;
		end
end

// SelectIRScan state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		SelectIRScan<=0;
	else
		begin
			if(TMS & SelectDRScan)
				SelectIRScan<=1;
			else
				SelectIRScan<=0;
		end
end

// CaptureIR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		CaptureIR<=0;
	else
		begin
			if(~TMS & SelectIRScan)
				CaptureIR<=1;
			else
				CaptureIR<=0;
		end
end

// ShiftIR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		ShiftIR<=0;
	else
		begin
			if(~TMS & (CaptureIR | ShiftIR | Exit2IR))
				ShiftIR<=1;
			else
				ShiftIR<=0;
		end
end

// Exit1IR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		Exit1IR<=0;
	else
		begin
			if(TMS & (CaptureIR | ShiftIR))
				Exit1IR<=1;
			else
				Exit1IR<=0;
		end
end

// PauseIR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		PauseIR<=0;
	else
		begin
			if(~TMS & (Exit1IR | PauseIR))
				PauseIR<=1;
			else
				PauseIR<=0;
		end
end

// Exit2IR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		Exit2IR<=0;
	else
		begin
			if(TMS & PauseIR)
				Exit2IR<=1;
			else
				Exit2IR<=0;
		end
end

// UpdateIR state
always @ (posedge TCK or posedge RESET)
begin
	if(RESET)
		UpdateIR<=0;
	else
		begin
			if(TMS & (Exit1IR | Exit2IR))
				UpdateIR<=1;
			else
				UpdateIR<=0;
		end
end

/**********************************************************************************
*																																									*
*		End: TAP State Machine																												*
*																																									*
**********************************************************************************/



/**********************************************************************************
*																																									*
*		JTAG_SIR:	JTAG Shift Instruction Register: Instruction shifted in, status out	*
*		JTAG_IR:	JTAG Instruction Register: Updated on UpdateIR or TestLogicReset		*
*																																									*
*		Status is shifted out.																												*
*																																									*
**********************************************************************************/
wire [1:0]Status = 2'b10;		// Holds current chip status. Core should return this status. For now a constant is used.

reg [3:0]JTAG_SIR;	// Register used for shifting in and out
reg [3:0]JTAG_IR;		// Instruction register
reg TDOInstruction;

always @ (posedge TCK)
begin
	if(CaptureIR)
		begin
			JTAG_SIR[1:0] <= 2'b01;				// This value is fixed for easier fault detection
			JTAG_SIR[3:2] <= Status[1:0];	// Current status of chip
		end
	else
		begin
			if(ShiftIR)
				begin
					JTAG_SIR[3:0] <= JTAG_SIR[3:0] >> 1;
					JTAG_SIR[3] <= TDI;
				end
		end
end

// Updating JTAG_IR (Instruction Register)
always @ (posedge TCK or posedge TestLogicReset)
begin
	if(TestLogicReset)
		JTAG_IR <= IDCODE;
	else
		begin
			if(UpdateIR)
				JTAG_IR <= JTAG_SIR;
		end
end

//TDO is changing on the falling edge of TCK
always @ (negedge TCK)
begin
	if(ShiftIR)
		TDOInstruction <= JTAG_SIR[0];
end
	
/**********************************************************************************
*																																									*
*		End: JTAG_SIR																																	*
*		End: JTAG_IR																																	*
*																																									*
**********************************************************************************/


/**********************************************************************************
*																																									*
*		JTAG_SDR:	JTAG Shift Data Register: Data shifted in and out										*
*		JTAG_DR:	JTAG Data Register: Updated on UpdateDR															*
*																																									*
*		Data that is shifted out can be a chip ID or a requested data (register value,*
*		memory value, etc.																														*
*																																									*
**********************************************************************************/
wire [32:0] IDCodeValue = 33'b011000011110000111100001111000011; // ID value (constant 0x0c3c3c3c3). IDCODE is 32-bit long, so the MSB is not used
wire [32:0] DataValue   = 33'b101001100011100001111000111001101; // This should be data from the core. For now a constant value 0x14c70f1cd is used
wire [32:0] RequestedData = (JTAG_IR==IDCODE)? IDCodeValue : DataValue;	// This is to be expanded with number of user registers

reg [32:0]JTAG_SDR;	// Register used for shifting in and out
reg [32:0]JTAG_DR;		// Data register
reg TDOData;

always @ (posedge TCK)
begin
	if(CaptureDR)
		JTAG_SDR <= RequestedData;			// DataResponse contains data requested in previous cycle
	else
		begin
			if(ShiftDR)
				begin
					JTAG_SDR <= JTAG_SDR >> 1;
					JTAG_SDR[32] <= TDI;
				end
		end
end

// Updating JTAG_DR (Data Register)
always @ (posedge TCK)
begin
	if(UpdateDR)
		JTAG_DR <= JTAG_SDR;
end

//TDO is changing on the falling edge of TCK
always @ (negedge TCK)
begin
	if(ShiftDR)
		TDOData <= JTAG_SDR[0];
end

/**********************************************************************************
*																																									*
*		End: JTAG_SDR																																	*
*		End: JTAG_DR																																	*
*																																									*
**********************************************************************************/



/**********************************************************************************
*																																									*
*		Bypass logic																																	*
*																																									*
**********************************************************************************/
reg BypassRegister;
reg TDOBypassed;

always @ (posedge TCK)
begin
	if(ShiftDR)
		BypassRegister<=TDI;
end

always @ (negedge TCK)
begin
		TDOBypassed<=BypassRegister;
end
/**********************************************************************************
*																																									*
*		End: Bypass logic																															*
*																																									*
**********************************************************************************/



/**********************************************************************************
*																																									*
*		Boundary Scan Logic																														*
*																																									*
**********************************************************************************/
wire [`BSLength-1:0]ExitFromBSCell;


wire [3:0]ToOutputEnable;
wire [1:0]BidirectionalBuffered;

wire [5:0]FromCore = 6'h0;   			// This are signals that core send to output (or bidirectional) pins. We have no core, so they are all zero.
wire [3:0]ControlPIN = 4'h0;			// Core control signals. Since no core is used, they are fixed to zero.

// buffers
assign BidirectionalBuffered[1:0] = BidirectionalPin[1:0];								// Inputs of bidirectional signals should be buffered (as seen below)
//IBUF buffer0 (.I(BidirectionalPin[0]), .O(BidirectionalBuffered[0]));
//IBUF buffer1 (.I(BidirectionalPin[1]), .O(BidirectionalBuffered[1]));

wire ExtTestEnabled = (JTAG_IR==EXTEST) | (JTAG_IR==SAMPLE_PRELOAD);


// BOUNDARY SCAN REGISTER
// closest to TDO
InputCell BS0     ( .InputPin(InputPin[0]),              .FromPreviousBSCell(ExitFromBSCell[12]), .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[`BSLength-1]));
InputCell BS1     ( .InputPin(InputPin[1]),              .FromPreviousBSCell(ExitFromBSCell[11]), .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[12]));

OutputCell BS2    ( .FromCore(FromCore[0]),              .FromPreviousBSCell(ExitFromBSCell[10]), .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[11]), .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .FromOutputEnable(ToOutputEnable[0]), .TristatedPin(Output3Pin[0]));
ControlCell BS3   ( .OutputControl(ControlPIN[0]),       .FromPreviousBSCell(ExitFromBSCell[9]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[10]), .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .ToOutputEnable(ToOutputEnable[0]));
                                                                                                                                                                                          
OutputCell BS4    ( .FromCore(FromCore[1]),              .FromPreviousBSCell(ExitFromBSCell[8]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[9]),  .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .FromOutputEnable(ToOutputEnable[1]), .TristatedPin(Output3Pin[1]));
ControlCell BS5   ( .OutputControl(ControlPIN[1]),       .FromPreviousBSCell(ExitFromBSCell[7]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[8]),  .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .ToOutputEnable(ToOutputEnable[1]));
                                                                                                                                                                                          
InputCell BS6     ( .InputPin(BidirectionalBuffered[0]), .FromPreviousBSCell(ExitFromBSCell[6]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[7]));
OutputCell BS7    ( .FromCore(FromCore[2]),              .FromPreviousBSCell(ExitFromBSCell[5]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[6]),  .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .FromOutputEnable(ToOutputEnable[2]), .TristatedPin(BidirectionalPin[0]));
ControlCell BS8   ( .OutputControl(ControlPIN[2]),       .FromPreviousBSCell(ExitFromBSCell[4]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[5]),  .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .ToOutputEnable(ToOutputEnable[2]));
                                                                                                                                                                                          
InputCell BS9     ( .InputPin(BidirectionalBuffered[1]), .FromPreviousBSCell(ExitFromBSCell[3]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[4]));
OutputCell BS10   ( .FromCore(FromCore[3]),              .FromPreviousBSCell(ExitFromBSCell[2]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[3]),  .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .FromOutputEnable(ToOutputEnable[3]), .TristatedPin(BidirectionalPin[1]));
ControlCell BS11  ( .OutputControl(ControlPIN[3]),       .FromPreviousBSCell(ExitFromBSCell[1]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[2]),  .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .ToOutputEnable(ToOutputEnable[3]));
                                                                                                                                                                                          
OutputCell BS12   ( .FromCore(FromCore[4]),              .FromPreviousBSCell(ExitFromBSCell[0]),  .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[1]),  .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .FromOutputEnable(vcc),               .TristatedPin(Output2Pin[0]));
OutputCell BS13   ( .FromCore(FromCore[5]),              .FromPreviousBSCell(TDI),                .CaptureDR(CaptureDR), .ShiftDR(ShiftDR), .TCK(TCK), .ToNextBSCell(ExitFromBSCell[0]),  .UpdateDR(UpdateDR), .extest(ExtTestEnabled), .FromOutputEnable(vcc),               .TristatedPin(Output2Pin[1]));
// closest to TDI


/**********************************************************************************
*																																									*
*		End: Boundary Scan Logic																											*
*																																									*
**********************************************************************************/





/**********************************************************************************
*																																									*
*		Multiplexing TDO and Tristate control																					*
*																																									*
**********************************************************************************/
wire TDOShifted;
assign TDOShifted = (ShiftIR | Exit1IR)? TDOInstruction : TDOData;

reg TDOMuxed;


// This multiplexing can be expanded with number of user registers
always @ (JTAG_IR or TDOShifted or ExitFromBSCell or TDOBypassed)
begin
	case(JTAG_IR)
		IDCODE: // Reading ID code
			begin
				TDOMuxed<=TDOShifted;
			end
		SAMPLE_PRELOAD:	// Sampling/Preloading
			begin
				TDOMuxed<=ExitFromBSCell[`BSLength-1];
			end
		EXTEST:	// External test
			begin
				TDOMuxed<=ExitFromBSCell[`BSLength-1];
			end
		default:	// BYPASS instruction
			begin
				TDOMuxed<=TDOBypassed;
			end
	endcase
end



// Tristate control for P_TDO pin
assign P_TDO = (ShiftIR | ShiftDR | Exit1IR | Exit1DR)? TDOMuxed : 1'bz;


/**********************************************************************************
*																																									*
*		End:	Multiplexing TDO and Tristate control																		*
*																																									*
**********************************************************************************/






// Test Signals (can be deleted)

assign TestSignal[0] = CaptureDR;
assign TestSignal[1] = RunTestIdle;
assign TestSignal[2] = ShiftDR;
assign TestSignal[3] = UpdateDR;

assign TestSignal[4] = JTAG_IR[0];
assign TestSignal[5] = JTAG_IR[1];



endmodule	// TAP
