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
   wire test_clk_0, test_clk_270, test_clk_180, test_clk_90;
   assign mctrl_clk = test_clk_0;

// Note: clocks are split into 2 sub-chains to have similar fanout loads for 90 and 270 clocks
   wire clk_90_buf_a;
   wire clk_270_buf_a;
   wire clk_90_buf_b;
   wire clk_270_buf_b;

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
   reg [RANK_CNT-1:0] rsdram_cke;
   reg [RANK_CNT-1:0] rsdram_cs_n;
   reg rsdram_we_n;
   reg rsdram_ras_n;
   reg rsdram_cas_n;
   reg rsdram_act_n;
   reg [2:0] rsdram_cid;
   reg [1:0] rsdram_bg;
   reg rsdram_par;
   reg [2:0] rsdram_ba;
   reg [15:0] rsdram_a;
   reg [RANK_CNT-1:0] rsdram_odt;

   reg rcmd_oe;
// Note: as clock will not be generated after reset (until DLL stabilized) data will not be initialized
   always@(posedge test_clk_180 or negedge reset_n)
   if(!reset_n)
   begin
      rsdram_cs_n  <= {RANK_CNT{1'b1}};
      rsdram_cke   <= {RANK_CNT{1'b0}};
      rcmd_oe      <= 1'b0;
      // Note: no need to clear addresses here, as they are not cleared in memory controller
      rsdram_ba    <= 3'hx;
      rsdram_a     <= 16'hxxxx;
      // Note: no need to clear intermediate flops, as they will be written upon reset, and will not be read upon reset
      rsdram_we_n  <= 1'bx;
      rsdram_ras_n <= 1'bx;
      rsdram_cas_n <= 1'bx;
      rsdram_act_n <= 1'bx;
      rsdram_cid   <= 3'hx;
      rsdram_bg    <= 2'hx;
      rsdram_par   <= 1'bx;
      rsdram_odt   <= {RANK_CNT{1'bx}};
   end
   else
   begin
      rsdram_cs_n  <= dfi_cs_n;
      rsdram_cke   <= dfi_cke;
      // Note: software control over this feature
      rcmd_oe      <= turn_off_inactive_io ? ~&dfi_cs_n : 1'b1;

      rsdram_ba    <= dfi_bank;
      rsdram_a     <= dfi_address;

      rsdram_we_n  <= dfi_we_n;
      rsdram_ras_n <= dfi_ras_n;
      rsdram_cas_n <= dfi_cas_n;
      rsdram_act_n <= dfi_act_n;
      rsdram_cid   <= dfi_cid;
      rsdram_bg    <= dfi_bg;
      rsdram_par   <= dfi_par;
      rsdram_odt   <= dfi_odt;
   end
//=====================
// Stage 2. Re-capture 180 to 90
//=====================
   reg [RANK_CNT-1:0] rsdram_cke2;
   reg [RANK_CNT-1:0] rsdram_cs_n2;
   reg rsdram_we_n2;
   reg rsdram_ras_n2;
   reg rsdram_cas_n2;
   reg rsdram_act_n2;
   reg [2:0] rsdram_cid_n2;
   reg [1:0] rsdram_bg2;
   reg rsdram_par2;
   reg [2:0] rsdram_ba2;
   reg [15:0] rsdram_a2;
   reg [RANK_CNT-1:0] rsdram_odt2;
   reg rcmd_oe2;

// Note: 'sdram_ck[_n]' is driven by clk_270[90]
//       clk_90 also used internally to drive datapath.
//       This leads to extra delay in clock tree of clk_90 relative to clk_270.
//       To reduce clock tree impact, 'a' clocks used internally, and 'b' clocks used to drive IO

   always@(negedge test_clk_270_a or negedge reset_n) // Note: balance clock fanout
   if(!reset_n)
   begin
      rsdram_cke2   <= {RANK_CNT{1'b0}};
      rsdram_cs_n2  <= {RANK_CNT{1'b1}};
      rsdram_we_n2  <= 1'b1;
      rsdram_ras_n2 <= 1'b1;
      rsdram_cas_n2 <= 1'b1;
      rsdram_act_n2 <= 1'b1;
      rsdram_cid_n2 <= 3'h7;
      rsdram_bg2    <= 2'b0;
      rsdram_par2   <= 1'b0;
      rsdram_odt2   <= {RANK_CNT{1'b0}};
      rcmd_oe2      <= 1'b0;
      rsdram_ba2    <= 3'hx;
      rsdram_a2     <= 16'hx;
   end
   else
   begin
      rsdram_cke2   <= rsdram_cke;
      rsdram_cs_n2  <= rsdram_cs_n;
      rsdram_we_n2  <= rsdram_we_n;
      rsdram_ras_n2 <= rsdram_ras_n;
      rsdram_cas_n2 <= rsdram_cas_n;
      rsdram_act_n2 <= rsdram_act_n;
      rsdram_cid_n2 <= rsdram_cid;
      rsdram_bg2    <= rsdram_bg;
      rsdram_par2   <= rsdram_par;
      rsdram_odt2   <= rsdram_odt;
      rcmd_oe2      <= rcmd_oe;
      rsdram_ba2    <= rsdram_ba;
      rsdram_a2     <= rsdram_a;
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
      sdram_bg    <= 2'b0;// TODO: balance clock fanout for new DDR4 signals

      sdram_par   <= 1'b0;
      sdram_odt   <= {RANK_CNT{1'b0}};
      cmd_oe      <= 1'b0;
      sdram_ba    <= 3'hx;
      sdram_a     <= 16'hx;
   end
   else
   begin
      sdram_cke   <= rsdram_cke2;
      sdram_cs_n  <= rsdram_cs_n2;
      sdram_we_n  <= rsdram_we_n2;
      sdram_ras_n <= rsdram_ras_n2;
      sdram_cas_n <= rsdram_cas_n2;
      sdram_act_n <= rsdram_act_n2;
      sdram_cid   <= rsdram_cid_n2;
      sdram_bg    <= rsdram_bg2;
      sdram_par   <= rsdram_par2;
      sdram_odt   <= rsdram_odt2;
      cmd_oe      <= rcmd_oe2;
      sdram_ba    <= rsdram_ba2;
      sdram_a     <= rsdram_a2;
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
