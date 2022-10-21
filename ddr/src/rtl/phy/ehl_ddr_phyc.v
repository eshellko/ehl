// Design:           DDR2 PHY Command Lane Core
// Revision:         1.3
// Date:             2018-11-28
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2017-02-02 A.Kornukhin: initial release
//                   1.1 2017-02-15 A.Kornukhin: removed implementation with additional delay cycle on data path
//                   1.2 2018-02-07 A.Kornukhin: HDR mode added dram_clk_disable added
//                   1.3 2018-11-28 A.Kornukhin: Added 'cmd_oe' - allow to turn off output drivers, when bus inactive

module ehl_ddr_phyc
#(
   parameter RANK_CNT = 4,
             DLL_TECHNOLOGY = 0,
             TECHNOLOGY = 0
)
(
   input                     ref_clk,
   output                    mctrl_clk,
   output                    locked,
   input                     reset_n,
   input [RANK_CNT-1:0]      dfi_cke,
   input [RANK_CNT-1:0]      dfi_cs_n,
   input                     dfi_we_n,
   input                     dfi_ras_n,
   input                     dfi_cas_n,
   input                     dfi_act_n,
   input [2:0]               dfi_cid,
   input [1:0]               dfi_bg,
   input                     dfi_par,
   input [2:0]               dfi_bank,
   input [15:0]              dfi_address,
   input [RANK_CNT-1:0]      dfi_odt,
   input                     dfi_dram_clk_disable,
   output                    sdram_ck,
   output                    sdram_ck_n,
   output reg [RANK_CNT-1:0] sdram_cke,
   output reg [RANK_CNT-1:0] sdram_cs_n,
   output reg                sdram_we_n,
   output reg                sdram_ras_n,
   output reg                sdram_cas_n,
   output reg                sdram_act_n,
   output reg [2:0]          sdram_cid,
   output reg [1:0]          sdram_bg,
   output reg                sdram_par,
   output reg [2:0]          sdram_ba,
   output reg [15:0]         sdram_a,
   output reg [RANK_CNT-1:0] sdram_odt,
   input                     turn_off_inactive_io,
   output reg                cmd_oe, // Note: this register used to disable output-driver for command signals when inactive (to reduce power) Q: probably drive it earlier to allow driver ON
   input                     hf,
   input                     dll_bypass,
   input                     dll_reset_n,
   input                     dft_test_mode_n,
                             dft_test_clock
);
   wire clk_0, clk_270, clk_180, clk_90;
   wire test_clk_0, test_clk_180;
   assign mctrl_clk = test_clk_0;

// Note: clocks are split into 2 sub-chains to have similar fanout loads for 90 and 270 clocks
   ehl_clock_mux #( .TECHNOLOGY ( TECHNOLOGY ) ) mux_0   ( .clk_0(dft_test_clock), .clk_1(clk_0),   .sel(dft_test_mode_n), .clk_out (test_clk_0));
   ehl_clock_mux #( .TECHNOLOGY ( TECHNOLOGY ) ) mux_90  ( .clk_0(dft_test_clock), .clk_1(clk_90),  .sel(dft_test_mode_n), .clk_out (clk_90_buf));
   ehl_clock_mux #( .TECHNOLOGY ( TECHNOLOGY ) ) mux_180 ( .clk_0(dft_test_clock), .clk_1(clk_180), .sel(dft_test_mode_n), .clk_out (test_clk_180));
   ehl_clock_mux #( .TECHNOLOGY ( TECHNOLOGY ) ) mux_270 ( .clk_0(dft_test_clock), .clk_1(clk_270), .sel(dft_test_mode_n), .clk_out (clk_270_buf));

   // buffer after DFT mux
   ehl_buf #(.TECHNOLOGY(TECHNOLOGY)) buf_a_90_inst  (.data_i(clk_90_buf),.data_o(test_clk_90_a));
   ehl_buf #(.TECHNOLOGY(TECHNOLOGY)) buf_a_270_inst (.data_i(clk_270_buf),.data_o(test_clk_270_a));
   ehl_buf #(.TECHNOLOGY(TECHNOLOGY)) buf_b_90_inst  (.data_i(clk_90_buf),.data_o(test_clk_90_b));
   ehl_buf #(.TECHNOLOGY(TECHNOLOGY)) buf_b_270_inst (.data_i(clk_270_buf),.data_o(test_clk_270_b));

   ehl_ddr_phy_dll
   #(
      .TECHNOLOGY ( DLL_TECHNOLOGY )
   ) dll_inst
   (
      .ref_clk              ( ref_clk     ),
      .reset_n              ( dll_reset_n ),
      .dqs                  ( 1'b0        ),//x
      .dqs_n                ( 1'b1        ),//x
      .dfi_rdlvl_delay      ( 3'b0        ),//x
      .dfi_rdlvl_delay_n    ( 3'b0        ),//x
      .dfi_rdlvl_gate_delay ( 3'b0        ),//x
      .dfi_rdlvl_gate_en    ( 1'b0        ),
      .dqs_gate             ( 1'b0        ),//x
      .clk_0                ( clk_0       ),
      .clk_90               ( clk_90      ),
      .clk_180              ( clk_180     ),
      .clk_270              ( clk_270     ),
      .clk_2x               (             ),
      .dqs_90               (             ),
      .dqs_n_90             (             ),
      .locked               ( locked      ),
      .hf                   ( hf          ),
      .dfi_rdlvl_resp       (             ),
      .bypass               ( dll_bypass  )
   );
//=====================
// Stage 1. Re-capture from 0 to 180
//=====================
   localparam DFI_WIDTH = 3*RANK_CNT+29;
   wire [DFI_WIDTH-1:0] dfi_in = {dfi_cke, dfi_cs_n, dfi_odt,
      dfi_we_n, dfi_ras_n, dfi_cas_n,
      dfi_act_n, dfi_cid, dfi_bg, dfi_par,
      dfi_bank, dfi_address};
   reg [DFI_WIDTH-1:0] rsdram;
   // Note: some signals require initial values while others not (order as per 'dfi_in'
   localparam [DFI_WIDTH-1:0] RSDRAM_INIT = {{RANK_CNT{1'b0}}, {RANK_CNT{1'b1}}, {RANK_CNT{1'bx}}, 29'hx};

   reg rcmd_oe;
// Note: as clock will not be generated after reset (until DLL stabilized) data will not be initialized
   always@(posedge test_clk_180 or negedge reset_n)
   if(!reset_n)
   begin
      rsdram  <= RSDRAM_INIT;
      rcmd_oe <= 1'b0;
   end
   else
   begin
      rsdram  <= dfi_in;
      // Note: software control over this feature
      rcmd_oe <= turn_off_inactive_io ? ~&dfi_cs_n : 1'b1;
   end
//=====================
// Stage 2. Re-capture 180 to 90
//=====================
   localparam [DFI_WIDTH-1:0] RSDRAM2_INIT = {{RANK_CNT{1'b0}}, {RANK_CNT{1'b1}}, {RANK_CNT{1'b0}}, 1'b1, 1'b1, 1'b1, 1'b1, 3'h7, 2'h0, 1'b0, 3'hx, 16'hx};
   reg [DFI_WIDTH-1:0] rsdram2;
   reg rcmd_oe2;

// Note: 'sdram_ck[_n]' is driven by clk_270[90]
//       clk_90 also used internally to drive datapath.
//       This leads to extra delay in clock tree of clk_90 relative to clk_270.
//       To reduce clock tree impact, 'a' clocks used internally, and 'b' clocks used to drive IO
   always@(negedge test_clk_270_a or negedge reset_n) // Note: balance clock fanout
   if(!reset_n)
   begin
      rcmd_oe2 <= 1'b0;
      rsdram2  <= RSDRAM2_INIT;
   end
   else
   begin
      rsdram2  <= rsdram;
      rcmd_oe2 <= rcmd_oe;
   end
//=====================
// Stage 3. Delay single cycle at 90
//=====================
   always@(posedge test_clk_90_a or negedge reset_n)
   if(!reset_n)
   begin
      sdram_cke   <= {RANK_CNT{1'b0}};
      sdram_cs_n  <= {RANK_CNT{1'b1}};
      sdram_we_n  <= 1'b1;
      sdram_ras_n <= 1'b1;
      sdram_cas_n <= 1'b1;
      sdram_act_n <= 1'b1;
      sdram_cid   <= 3'h7;
      sdram_bg    <= 2'b0;
      sdram_par   <= 1'b0;
      sdram_odt   <= {RANK_CNT{1'b0}};
      sdram_ba    <= 3'hx;
      sdram_a     <= 16'hx;
      cmd_oe      <= 1'b0;
   end
   else
   begin
      sdram_cke   <= rsdram2[29+2*RANK_CNT+:RANK_CNT];
      sdram_cs_n  <= rsdram2[29+RANK_CNT+:RANK_CNT];
      sdram_odt   <= rsdram2[29+:RANK_CNT];
      sdram_we_n  <= rsdram2[28];
      sdram_ras_n <= rsdram2[27];
      sdram_cas_n <= rsdram2[26];
      sdram_act_n <= rsdram2[25];
      sdram_cid   <= rsdram2[24:22];
      sdram_bg    <= rsdram2[21:20];
      sdram_par   <= rsdram2[19];
      sdram_ba    <= rsdram2[18:16];
      sdram_a     <= rsdram2[15:0];
      cmd_oe      <= rcmd_oe2;
   end

   // Number of memory cycles after clock is disabled/enabled before it is applied to outputs (to compensate command line delay)
   // Clock enabled ASAP as per JESD79-2F 3.10 "clock must be stable prior to CKE going back HIGH"
   localparam DRAM_CLK_XABLE = 3; // do not modify this value

   reg [DRAM_CLK_XABLE:0] dfi_dram_clk_disable_resync;
   always@(posedge clk_0) // half_period delay to resync (a.k.a. tdram_clk_disable/tdram_clk_enable)
      dfi_dram_clk_disable_resync <= {dfi_dram_clk_disable_resync[DRAM_CLK_XABLE-1:0], dfi_dram_clk_disable};
   // Note: output clocks toggles at 90 and 270
   //       while gate for them at 0
   //       thus 1/4 period guard interval present
   //       inactive value for sdram_ck is 1, for sdram_ck_n is 0
   // Note: command line can be disabled externally to meet HDR timing and other delays
   //       to compensate this DRAM_CLK_XABLE delay introduced to turn OFF clock when external device is in SELF REFRESH
   //       and also delay introduced to turn ON clock when external device enabled with CKE
   //              ___     ___     ___
   // clk_0    ___/   \___/   \___/   \___
   //          _     ___     ___     ___
   // clk_90    \___/   \___/   \___/   \___      CK_n
   //            ___     ___     ___     ___
   // clk_270  _/   \___/   \___/   \___/   \___  CK
   //               _______________
   // cdis     ___//               \\________
   //          _                     ___
   // CK_n      \___________________/   \___
   //            ___________________     ___
   // CK       _/                   \___/   \___
   //

// Note: it is highly possible that there will be timing violation on clock gating setup check
//       'dfi_dram_clk_disable_resync' and 'test_clk'
//       problem is that 'clk_0' (source clock) has high fanout, and thus clock tree latency
//       on the other hand test_clk is short and came to clock_gating gate earlier
// Note: this functionality activated upon Self-Refrech mode when there is no clock used internally by SDRAM device,
//       and any toggles on that clock are acceptable (TODO: write false_path SDC for this path)
// Fix: macro model should be used during CTS on LSB of 'dfi_dram_clk_disable_resync' which should allow
//      this FF to have CTS delay smaller than others (this should be done by default with useful skew - todo: statement need to be checked)
   assign sdram_ck   = dfi_dram_clk_disable_resync[DRAM_CLK_XABLE] | test_clk_270_b;
   assign sdram_ck_n = ~dfi_dram_clk_disable_resync[DRAM_CLK_XABLE] & test_clk_90_b;

endmodule
