//////////////////////////////////////////////////////////////////////
////                                                              ////
////  tap_top.v                                                   ////
////                                                              ////
////                                                              ////
////  This file is part of the JTAG Test Access Port (TAP)        ////
////  http://www.opencores.org/projects/jtag/                     ////
////                                                              ////
////  Author(s):                                                  ////
////       Igor Mohor (igorm@opencores.org)                       ////
////                                                              ////
////                                                              ////
////  All additional information is avaliable in the README.txt   ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 - 2003 Authors                            ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.10  2003/10/23 18:08:01  mohor
// MBIST chain connection fixed.
//
// Revision 1.9  2003/10/23 16:17:02  mohor
// CRC logic changed.
//
// Revision 1.8  2003/10/21 09:48:31  simons
// Mbist support added.
//
// Revision 1.7  2002/11/06 14:30:10  mohor
// Trst active high. Inverted on higher layer.
//
// Revision 1.6  2002/04/22 12:55:56  mohor
// tdo_padoen_o changed to tdo_padoe_o. Signal is active high.
//
// Revision 1.5  2002/03/26 14:23:38  mohor
// Signal tdo_padoe_o changed back to tdo_padoen_o.
//
// Revision 1.4  2002/03/25 13:16:15  mohor
// tdo_padoen_o changed to tdo_padoe_o. Signal was always active high, just
// not named correctly.
//
// Revision 1.3  2002/03/12 14:30:05  mohor
// Few outputs for boundary scan chain added.
//
// Revision 1.2  2002/03/12 10:31:53  mohor
// tap_top and dbg_top modules are put into two separate modules. tap_top
// contains only tap state machine and related logic. dbg_top contains all
// logic necessery for debugging.
//
// Revision 1.1  2002/03/08 15:28:16  mohor
// Structure changed. Hooks for jtag chain added.
//
//
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "tap_defines.v"

// Top module
module tap_top(
                // JTAG pads
                tms_pad_i, 
                tck_pad_i, 
                trst_pad_i, 
                tdi_pad_i, 
                tdo_pad_o, 
                tdo_padoe_o,

                // TAP states
                shift_dr_o,
                pause_dr_o, 
                update_dr_o,
                
                // Select signals for boundary scan or mbist
                extest_select_o, 
                sample_preload_select_o,
                mbist_select_o,
                debug_select_o,
                
                // TDO signal that is connected to TDI of sub-modules.
                tdo_o, 
                
                // TDI signals from sub-modules
                debug_tdi_i,    // from debug module
                bs_chain_tdi_i, // from Boundary Scan Chain
                mbist_tdi_i     // from Mbist Chain
              );


// JTAG pins
input   tms_pad_i;      // JTAG test mode select pad
input   tck_pad_i;      // JTAG test clock pad
input   trst_pad_i;     // JTAG test reset pad
input   tdi_pad_i;      // JTAG test data input pad
output  tdo_pad_o;      // JTAG test data output pad
output  tdo_padoe_o;    // Output enable for JTAG test data output pad 

// TAP states
output  shift_dr_o;
output  pause_dr_o;
output  update_dr_o;

// Select signals for boundary scan or mbist
output  extest_select_o;
output  sample_preload_select_o;
output  mbist_select_o;
output  debug_select_o;

// TDO signal that is connected to TDI of sub-modules.
output  tdo_o;

// TDI signals from sub-modules
input   debug_tdi_i;    // from debug module
input   bs_chain_tdi_i; // from Boundary Scan Chain
input   mbist_tdi_i;    // from Mbist Chain

// Registers
reg     test_logic_reset;
reg     run_test_idle;
reg     select_dr_scan;
reg     capture_dr;
reg     shift_dr;
reg     exit1_dr;
reg     pause_dr;
reg     exit2_dr;
reg     update_dr;
reg     select_ir_scan;
reg     capture_ir;
reg     shift_ir;
reg     exit1_ir;
reg     pause_ir;
reg     exit2_ir;
reg     update_ir;
reg     extest_select;
reg     sample_preload_select;
reg     idcode_select;
reg     mbist_select;
reg     debug_select;
reg     bypass_select;
reg     tdo_pad_o;
reg     tdo_padoe_o;


assign tdo_o = tdi_pad_i;
assign shift_dr_o = shift_dr;
assign pause_dr_o = pause_dr;
assign update_dr_o = update_dr;

assign extest_select_o = extest_select;
assign sample_preload_select_o = sample_preload_select;
assign mbist_select_o = mbist_select;
assign debug_select_o = debug_select;

/**********************************************************************************
*                                                                                 *
*   TAP State Machine: Fully JTAG compliant                                       *
*                                                                                 *
**********************************************************************************/

// test_logic_reset state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    test_logic_reset<=#1 1'b1;
  else
    begin
      if(tms_pad_i & (test_logic_reset | select_ir_scan))
        test_logic_reset<=#1 1'b1;
      else
        test_logic_reset<=#1 1'b0;
    end
end

// run_test_idle state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    run_test_idle<=#1 1'b0;
  else
  if(~tms_pad_i & (test_logic_reset | run_test_idle | update_dr | update_ir))
    run_test_idle<=#1 1'b1;
  else
    run_test_idle<=#1 1'b0;
end

// select_dr_scan state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    select_dr_scan<=#1 1'b0;
  else
  if(tms_pad_i & (run_test_idle | update_dr | update_ir))
    select_dr_scan<=#1 1'b1;
  else
    select_dr_scan<=#1 1'b0;
end

// capture_dr state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    capture_dr<=#1 1'b0;
  else
  if(~tms_pad_i & select_dr_scan)
    capture_dr<=#1 1'b1;
  else
    capture_dr<=#1 1'b0;
end

// shift_dr state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    shift_dr<=#1 1'b0;
  else
  if(~tms_pad_i & (capture_dr | shift_dr | exit2_dr))
    shift_dr<=#1 1'b1;
  else
    shift_dr<=#1 1'b0;
end

// exit1_dr state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    exit1_dr<=#1 1'b0;
  else
  if(tms_pad_i & (capture_dr | shift_dr))
    exit1_dr<=#1 1'b1;
  else
    exit1_dr<=#1 1'b0;
end

// pause_dr state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    pause_dr<=#1 1'b0;
  else
  if(~tms_pad_i & (exit1_dr | pause_dr))
    pause_dr<=#1 1'b1;
  else
    pause_dr<=#1 1'b0;
end

// exit2_dr state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    exit2_dr<=#1 1'b0;
  else
  if(tms_pad_i & pause_dr)
    exit2_dr<=#1 1'b1;
  else
    exit2_dr<=#1 1'b0;
end

// update_dr state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    update_dr<=#1 1'b0;
  else
  if(tms_pad_i & (exit1_dr | exit2_dr))
    update_dr<=#1 1'b1;
  else
    update_dr<=#1 1'b0;
end

// select_ir_scan state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    select_ir_scan<=#1 1'b0;
  else
  if(tms_pad_i & select_dr_scan)
    select_ir_scan<=#1 1'b1;
  else
    select_ir_scan<=#1 1'b0;
end

// capture_ir state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    capture_ir<=#1 1'b0;
  else
  if(~tms_pad_i & select_ir_scan)
    capture_ir<=#1 1'b1;
  else
    capture_ir<=#1 1'b0;
end

// shift_ir state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    shift_ir<=#1 1'b0;
  else
  if(~tms_pad_i & (capture_ir | shift_ir | exit2_ir))
    shift_ir<=#1 1'b1;
  else
    shift_ir<=#1 1'b0;
end

// exit1_ir state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    exit1_ir<=#1 1'b0;
  else
  if(tms_pad_i & (capture_ir | shift_ir))
    exit1_ir<=#1 1'b1;
  else
    exit1_ir<=#1 1'b0;
end

// pause_ir state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    pause_ir<=#1 1'b0;
  else
  if(~tms_pad_i & (exit1_ir | pause_ir))
    pause_ir<=#1 1'b1;
  else
    pause_ir<=#1 1'b0;
end

// exit2_ir state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    exit2_ir<=#1 1'b0;
  else
  if(tms_pad_i & pause_ir)
    exit2_ir<=#1 1'b1;
  else
    exit2_ir<=#1 1'b0;
end

// update_ir state
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    update_ir<=#1 1'b0;
  else
  if(tms_pad_i & (exit1_ir | exit2_ir))
    update_ir<=#1 1'b1;
  else
    update_ir<=#1 1'b0;
end

/**********************************************************************************
*                                                                                 *
*   End: TAP State Machine                                                        *
*                                                                                 *
**********************************************************************************/



/**********************************************************************************
*                                                                                 *
*   jtag_ir:  JTAG Instruction Register                                           *
*                                                                                 *
**********************************************************************************/
reg [`IR_LENGTH-1:0]  jtag_ir;          // Instruction register
reg [`IR_LENGTH-1:0]  latched_jtag_ir;
reg                   instruction_tdo;

always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    jtag_ir[`IR_LENGTH-1:0] <= #1 `IR_LENGTH'b0;
  else
  if(capture_ir)
    jtag_ir <= #1 4'b0101;          // This value is fixed for easier fault detection
  else
  if(shift_ir)
    jtag_ir[`IR_LENGTH-1:0] <= #1 {tdi_pad_i, jtag_ir[`IR_LENGTH-1:1]};
end

always @ (negedge tck_pad_i)
begin
  instruction_tdo <= #1 jtag_ir[0];
end
/**********************************************************************************
*                                                                                 *
*   End: jtag_ir                                                                  *
*                                                                                 *
**********************************************************************************/


/**********************************************************************************
*                                                                                 *
*   jtag_dr:  JTAG Data Register                                                  *
*                                                                                 *
**********************************************************************************/
reg [`DR_LENGTH-1:0]  jtag_dr;          // Data register
reg [`DR_LENGTH-1:0]  latched_jtag_dr;
reg                   data_tdo;

always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    jtag_dr[`DR_LENGTH-1:0] <= #1 `DR_LENGTH'b0;
  else
  if(capture_dr)
    jtag_dr <= #1 4'b0101;          // This value is fixed for easier fault detection
  else
  if(shift_dr)
    jtag_dr[`DR_LENGTH-1:0] <= #1 {tdi_pad_i, jtag_dr[`DR_LENGTH-1:1]};
end

always @ (negedge tck_pad_i)
begin
  data_tdo <= #1 jtag_dr[0];
end
/**********************************************************************************
*                                                                                 *
*   End: jtag_dr                                                                  *
*                                                                                 *
**********************************************************************************/


/**********************************************************************************
*                                                                                 *
*   idcode logic                                                                  *
*                                                                                 *
**********************************************************************************/
reg [31:0] idcode_reg;
reg        idcode_tdo;

always @ (posedge tck_pad_i)
begin
  if(idcode_select & shift_dr)
    idcode_reg <= #1 {tdi_pad_i, idcode_reg[31:1]};
  else
    idcode_reg <= #1 `IDCODE_VALUE;
end

always @ (negedge tck_pad_i)
begin
    idcode_tdo <= #1 idcode_reg;
end
/**********************************************************************************
*                                                                                 *
*   End: idcode logic                                                             *
*                                                                                 *
**********************************************************************************/


/**********************************************************************************
*                                                                                 *
*   Bypass logic                                                                  *
*                                                                                 *
**********************************************************************************/
reg  bypassed_tdo;
reg  bypass_reg;

always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if (trst_pad_i)
    bypass_reg<=#1 1'b0;
  else if(shift_dr)
    bypass_reg<=#1 tdi_pad_i;
end

always @ (negedge tck_pad_i)
begin
  bypassed_tdo <=#1 bypass_reg;
end
/**********************************************************************************
*                                                                                 *
*   End: Bypass logic                                                             *
*                                                                                 *
**********************************************************************************/


/**********************************************************************************
*                                                                                 *
*   Activating Instructions                                                       *
*                                                                                 *
**********************************************************************************/
// Updating jtag_ir (Instruction Register)
always @ (posedge tck_pad_i or posedge trst_pad_i)
begin
  if(trst_pad_i)
    latched_jtag_ir <=#1 `IDCODE;   // IDCODE selected after reset
  else
  if(update_ir)
    latched_jtag_ir <=#1 jtag_ir;
end

/**********************************************************************************
*                                                                                 *
*   End: Activating Instructions                                                  *
*                                                                                 *
**********************************************************************************/


// Updating jtag_ir (Instruction Register)
always @ (latched_jtag_ir)
begin
  extest_select           = 1'b0;
  sample_preload_select   = 1'b0;
  idcode_select           = 1'b0;
  mbist_select            = 1'b0;
  debug_select            = 1'b0;
  bypass_select           = 1'b0;

  case(latched_jtag_ir)    /* synthesis parallel_case */ 
    `EXTEST:            extest_select           = 1'b1;    // External test
    `SAMPLE_PRELOAD:    sample_preload_select   = 1'b1;    // Sample preload
    `IDCODE:            idcode_select           = 1'b1;    // ID Code
    `MBIST:             mbist_select            = 1'b1;    // Mbist test
    `DEBUG:             debug_select            = 1'b1;    // Debug
    `BYPASS:            bypass_select           = 1'b1;    // BYPASS
    default:            bypass_select           = 1'b1;    // BYPASS
  endcase
end



/**********************************************************************************
*                                                                                 *
*   Multiplexing TDO data                                                         *
*                                                                                 *
**********************************************************************************/

always @ (shift_ir or exit1_ir or instruction_tdo or latched_jtag_ir or idcode_tdo or
          debug_tdi_i or bs_chain_tdi_i or mbist_tdi_i or 
          bypassed_tdo)
begin
  if(shift_ir)
    tdo_pad_o <=#1 instruction_tdo;
  else
    begin
      case(latched_jtag_ir)    // synthesis parallel_case
        `IDCODE:            tdo_pad_o = idcode_tdo;       // Reading ID code
        `DEBUG:             tdo_pad_o = debug_tdi_i;      // Debug
        `SAMPLE_PRELOAD:    tdo_pad_o = bs_chain_tdi_i;   // Sampling/Preloading
        `EXTEST:            tdo_pad_o = bs_chain_tdi_i;   // External test
        `MBIST:             tdo_pad_o = mbist_tdi_i;      // Mbist test
        default:            tdo_pad_o = bypassed_tdo;     // BYPASS instruction
      endcase
    end
end


// Tristate control for tdo_pad_o pin
always @ (negedge tck_pad_i)
begin
  tdo_padoe_o <= #1 shift_ir | shift_dr | (pause_dr & debug_select);
end
/**********************************************************************************
*                                                                                 *
*   End: Multiplexing TDO data                                                    *
*                                                                                 *
**********************************************************************************/




endmodule
