// Design:           DDR2 PHY DLL behavioral model
// Revision:         1.4
// Date:             2017-08-15
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2017-02-02 A.Kornukhin: initial release
//                   1.1 2017-02-20 A.Kornukhin: dfi_rdlvl_gate_en added to block
//                       DQS_90 in gate training mode
//                   1.2 2017-06-24 A.Kornukhin: re-written to avoid usage of
//                       frequency specification from testbench
//                   1.3 2017-08-01 A.Kornukhin: lock assertion during bypass added
//                   1.4 2017-08-15 A.Kornukhin: MEPHI model added; DQS_n logic added

// TODO: it can be beneficial to have different training and settings for DQS and DQS_n delay lines
//       this can be implemented in next release if current one will show issues...
// Q: what if make DLL as RTL with only DELAY lines as macro?
// A: this will lowering level of abstraction, while task is to create higher level PHY macro...

// Q: simulation model can be single for all modes... while synthesis can use LIB_CELL
//    thus model can be placed into DDR2_PHY_DLL module
//        and this module used everywhere here as a hard macro
//    -- on the other hand IOs 

`timescale 1ps/10fs

module ehl_ddr_phy_dll
#(
   parameter TECHNOLOGY = 0 // 0 - simulation model; 1 - TSMC 90 nm; 2 - TSMC 90 nm 3XTM; 3 - Mikron 90 nm;
)
(
   input ref_clk,
   input reset_n,
   input dqs,
   input dqs_n,
   input dqs_gate,
   output clk_0,
   output clk_90,
   output clk_180,
   output clk_270,
   output clk_2x,
   output dqs_90,
   output dqs_n_90,
   output locked,
   input [2:0] dfi_rdlvl_delay,
   input [2:0] dfi_rdlvl_delay_n,
   input [2:0] dfi_rdlvl_gate_delay,
   input dfi_rdlvl_gate_en,
   output dfi_rdlvl_resp,
   input hf,
   input bypass
);
   if(TECHNOLOGY == 0)
   begin : dll_sim
`ifndef SYNTHESIS
      `include "dll_func_inc.v"
`endif
   end
   else if(TECHNOLOGY == 1 || TECHNOLOGY == 2)
   begin : dll_tsmc_90
      DDR2_PHY_DLL dll_inst
      (
         .clk_0                ( clk_0                ),
         .clk_2x               ( clk_2x               ),
         .clk_90               ( clk_90               ),
         .clk_180              ( clk_180              ),
         .clk_270              ( clk_270              ),
         .dfi_rdlvl_resp       ( dfi_rdlvl_resp       ),
         .dqs_90               ( dqs_90               ),
         .dqs_n_90             ( dqs_n_90             ),
         .locked               ( locked               ),
         .dfi_rdlvl_delay      ( dfi_rdlvl_delay      ),
/*         .dfi_rdlvl_delay_n    ( dfi_rdlvl_delay_n    ),*/
         .dfi_rdlvl_gate_delay ( dfi_rdlvl_gate_delay ),
         .dfi_rdlvl_gate_en    ( dfi_rdlvl_gate_en    ),
         .dqs                  ( dqs                  ),
         .dqs_gate             ( dqs_gate             ),
         .dqs_n                ( dqs_n                ),
         .bypass               ( bypass               ),
         .hf                   ( hf                   ),
         .ref_clk              ( ref_clk              ),
         .reset_n              ( reset_n              )
      );
// Note: test SNPS DLL for timings through DLL
//      MSD_MSDLL_DDR dll_inst
//      (
//         .rstb       ( reset_n  ),
//         .srstb      ( reset_n  ),
//         .clk_in     ( ref_clk  ),
//         .dqs        ( dqs      ),
//         .dqsb       ( dqs_n    ),
//         .bypass     ( bypass   ),
//         .dll_ctrl   ( 52'h0    ),
//         .clk_0      ( clk_0    ),
//         .cclk_0     (          ),
//         .clk_90     ( clk_90   ),
//         .clk_180    ( clk_180  ),
//         .clk_270    ( clk_270  ),
//         .dqs_90     ( dqs_90   ),
//         .dqsb_90    ( dqs_n_90 ),
//         .test_out_d (          ),
//         .test_out_a (          ),
//         .MVDD       ( 1'b1     ),
//         .MVSS       ( 1'b0     )
//      );
   end
   else if(TECHNOLOGY == 3)
   begin : dll_mikron_90
   end

endmodule
