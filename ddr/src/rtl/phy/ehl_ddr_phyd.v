// Design:           DDR2 PHY Byte Lane Core
// Revision:         1.1
// Date:             2018-04-05
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2017-02-02 A.Kornukhin: initial release
//                   1.1 2018-04-05 A.Kornukhin: dfi_rdlvl_gate_delay extended to 4 bits
//                       MSB used to delay dfi_rddata_en 1 cycle

module ehl_ddr_phyd
#(
   parameter DLL_TECHNOLOGY = 0,
   CDC_TECHNOLOGY = 0,
   TECHNOLOGY = 0
)
(
   input         ref_clk,
   input         reset_n,
   input [1:0]   dfi_wrdata_mask,
   input [15:0]  dfi_wrdata,
   output [15:0] dfi_rddata,
   output        dfi_rddata_valid,
   input         dfi_rddata_en,
   input         dfi_wrdata_en,
   input         sdram_dqs_in,
   input         sdram_dqs_n_in,
   input [7:0]   sdram_dq_in,
   output        sdram_dm,
   output        sdram_dqs_out,
   output        sdram_dqs_n_out,
   output [7:0]  sdram_dq_out,
   output        locked,
   input [2:0]   dfi_rdlvl_delay,
   input [2:0]   dfi_rdlvl_delay_n,
   input [3:0]   dfi_rdlvl_gate_delay,
   input         dfi_rdlvl_gate_en,
   output        dqs_oe,
   output        dq_oe,
   output        dfi_rdlvl_resp,
   input         hf,
   input         wr_1tck_preamble,
   input         ddr4_mode,
   input         ddr2_mode,
   input         dll_bypass,
   input         dll_reset_n,
   input         dft_test_mode_n,
                 dft_test_clock
);
   wire clk_0;
   wire clk_2x;
   wire dqs_90, dqs_n_90;
   wire test_clk_0, test_clk_2x, test_dqs_90, test_dqs_n_90;
   ehl_clock_mux #( .TECHNOLOGY ( TECHNOLOGY ) ) mux_0    ( .clk_0(dft_test_clock), .clk_1(clk_0),    .sel(dft_test_mode_n), .clk_out (test_clk_0));
   ehl_clock_mux #( .TECHNOLOGY ( TECHNOLOGY ) ) mux_2x   ( .clk_0(dft_test_clock), .clk_1(clk_2x),   .sel(dft_test_mode_n), .clk_out (test_clk_2x));
   ehl_clock_mux #( .TECHNOLOGY ( TECHNOLOGY ) ) mux_s90  ( .clk_0(dft_test_clock), .clk_1(dqs_90),   .sel(dft_test_mode_n), .clk_out (test_dqs_90));
   ehl_clock_mux #( .TECHNOLOGY ( TECHNOLOGY ) ) mux_sn90 ( .clk_0(dft_test_clock), .clk_1(dqs_n_90), .sel(dft_test_mode_n), .clk_out (test_dqs_n_90));

   // Note: as DQS_n latest bit has small margin DQS_n_90 shifted 1 step left
   // todo: make this value programmable, as otherwise incorrect value possible without ability to change it manually
   // todo: this feature is not implemented in DLL yet...
//   wire [2:0] dfi_rdlvl_delay_n = dfi_rdlvl_delay /*? dfi_rdlvl_delay - 1'b1 : dfi_rdlvl_delay*/;

   reg dqs_gate_delay;
   always@(posedge test_clk_0 or negedge reset_n)
   if(!reset_n)
      dqs_gate_delay <= 1'b0;
   else
      dqs_gate_delay <= dfi_rddata_en;
   wire dqs_gate = dfi_rdlvl_gate_delay[3] ? dqs_gate_delay : dfi_rddata_en;

   ehl_ddr_phy_dll
   #(
      .TECHNOLOGY ( DLL_TECHNOLOGY )
   ) dll_inst
   (
      .ref_clk              ( ref_clk                   ),
      .reset_n              ( dll_reset_n               ),
      .dqs                  ( sdram_dqs_in              ),
      .dqs_n                ( sdram_dqs_n_in            ),
      .dqs_gate             ( dqs_gate                  ),
      .clk_0                ( clk_0                     ),
      .clk_90               (                           ),
      .clk_180              (                           ),
      .clk_270              (                           ),
      .clk_2x               ( clk_2x                    ),
      .dqs_90               ( dqs_90                    ),
      .dqs_n_90             ( dqs_n_90                  ),
      .locked               ( locked                    ),
      .dfi_rdlvl_delay      ( dfi_rdlvl_delay           ),
      .dfi_rdlvl_delay_n    ( dfi_rdlvl_delay_n         ),
      .dfi_rdlvl_gate_delay ( dfi_rdlvl_gate_delay[2:0] ),
      .dfi_rdlvl_gate_en    ( dfi_rdlvl_gate_en         ),
      .hf                   ( hf                        ),
      .dfi_rdlvl_resp       ( dfi_rdlvl_resp            ),
      .bypass               ( dll_bypass                )
   );

   ehl_ddr_phy_rx
   #(
      .CDC_TECHNOLOGY ( CDC_TECHNOLOGY )
   ) read_inst
   (
      .reset_n    ( reset_n          ),
      .dqs_90     ( test_dqs_90      ),
      .dqs_n_90   ( test_dqs_n_90    ),
      .dq         ( sdram_dq_in      ),
      .clk_0      ( test_clk_0       ),
      .data_valid ( dfi_rddata_valid ),
      .data_out   ( dfi_rddata       )
   );

   ehl_ddr_phy_tx write_inst
   (
      .clk_0            ( test_clk_0       ),
      .reset_n          ( reset_n          ),
      .clk_2x           ( test_clk_2x      ),
      .data_in          ( dfi_wrdata       ),
      .data_mask        ( dfi_wrdata_mask  ),
      .write_ena        ( dfi_wrdata_en    ),
      .wr_1tck_preamble ( wr_1tck_preamble ),
      .ddr4_mode        ( ddr4_mode        ),
      .ddr2_mode        ( ddr2_mode        ),
      .dq               ( sdram_dq_out     ),
      .dm               ( sdram_dm         ),
      .dqs              ( sdram_dqs_out    ),
      .dqs_n            ( sdram_dqs_n_out  ),
      .dqs_oe           ( dqs_oe           ),
      .dq_oe            ( dq_oe            )
   );

endmodule
