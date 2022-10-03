// Design:           DDR2 PHY IP Core Control & Status registers
// Revision:         1.0
// Date:             2019-06-27
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2019-06-27 A.Kornukhin: initial release

module ehl_ddr_phy_csr
#(
   parameter SDRAM_BYTE_COUNT = 4,
   RANK_CNT = 4,
   TECHNOLOGY = 0,
   CDC_SYNC_STAGE = 2,
   parameter [0:0] HDR_MODE = 1'b0
)
(
// Clocking
   input                      mctrl_clk,
   input                      reset_n,
// AHB
   input                      pclk,
   input                      presetn,
   input  [31:0]              paddr,
   input                      penable,
   input                      pwrite,
   input  [31:0]              pwdata,
   input                      psel,
   output [31:0]              prdata,
   output                     pready,
// Registers
   output reg                 pwd, // TODO: resync to PHY clock synchronous control signals
   input [SDRAM_BYTE_COUNT:0] dll_locked,
   output reg                 dll_bypass,
//   output reg                 read_deskew,
   output reg                 enable_dqs,
   output reg [1:0]           odt,
   output reg                 turn_off_inactive_io,
   output reg                 wr_1tck_preamble,
   output reg                 hf,
   output reg                 ddr4_mode,
   output reg                 ddr2_mode
);
//============================
// AHB frontend
//============================
   wire ctrl_rd;
   wire ctrl_ready;
   wire ctrl_wr;
   wire [31:0] ctrl_addr;
   wire [31:0] ctrl_wdata;
   wire [31:0] ctrl_rdata;
   ehl_apb2generic
   #(
      .DATA_WIDTH ( 32         ),
      .ADR_WIDTH  ( 32         ), // TODO: reduce?!
      .PIPE_RESP  ( 0          ),
      .PIPE_CMD   ( 0          ),
      .TECHNOLOGY ( TECHNOLOGY )
   ) apb_inst
   (
      .pclk      ( pclk       ),
      .presetn   ( presetn    ),
      .paddr     ( paddr      ),
      .penable   ( penable    ),
      .pwrite    ( pwrite     ),
      .pwdata    ( pwdata     ),
      .psel      ( psel       ),
      .prdata    ( prdata     ),
      .pready    ( pready     ),
      .pslverr   (            ), // Note: no error response supported
      .adr       ( ctrl_addr  ),
      .wr        ( ctrl_wr    ),
      .rd        ( ctrl_rd    ),
      .err       ( 1'b0       ),
      .wdata     ( ctrl_wdata ),
      .rdata     ( ctrl_rdata ),
      .ready     ( ctrl_ready ),
      .test_mode ( 1'b0       ), // TODO: drive
      .clk_gated (            )
   );
   assign ctrl_ready = 1'b1;
//============================
// registers access
//============================
   wire [4:0]  ctrl_addr_cpt;
   wire [31:0] ctrl_wdata_cpt;
   wire ahb_request_wr, ahb_request_rd;
   assign ctrl_addr_cpt[1:0] = 2'h0;

   wire [31:0] csr [7:0];

/*   ehl_ahb2core_sync
   #(
      .CDC_SYNC_STAGE ( CDC_SYNC_STAGE ),
      .REG_NUM        ( 8              )
   ) bus_sync_inst
   (
      .hclk           ( pclk               ),
      .hresetn        ( presetn            ),
      .ctrl_addr      ( ctrl_addr[4:2]     ),
      .ctrl_wr        ( ctrl_wr            ),
      .ctrl_rd        ( ctrl_rd            ),
      .ctrl_wdata     ( ctrl_wdata         ),
      .ctrl_rdata     ( ctrl_rdata         ),
      .ctrl_ready     ( ctrl_ready         ),
// Core interface
      .core_clk       ( mctrl_clk          ),
      .reset_n        ( reset_n            ),
      .ctrl_addr_cpt  ( ctrl_addr_cpt[4:2] ),
      .ctrl_wdata_cpt ( ctrl_wdata_cpt     ),
      .ahb_request_wr ( ahb_request_wr     ),
      .ahb_request_rd ( ahb_request_rd     ),
// Registers interface
      .reg_vector     ( {csr[7],
                         csr[6],
                         csr[5],
                         csr[4],
                         csr[3],
                         csr[2],
                         csr[1],
                         csr[0]}           )
   );*/
//============================
// Registers content
//============================
   assign ctrl_rdata = csr[ctrl_addr[4:2]];
//============================
// 0x00: DLL_CTRL
//============================
   wire [9:0] dll_locked_bus;
   assign dll_locked_bus[0]   = dll_locked[SDRAM_BYTE_COUNT]; // TODO: ECC_ENA placed in MSB - rewrite register description!!!!
   assign dll_locked_bus[9:1] = dll_locked[SDRAM_BYTE_COUNT-1:0]; // Npte: extended for all configurations

   assign csr[0] = {
      20'h0,
      hf,
      dll_bypass,
      dll_locked_bus
   };

   always@(posedge pclk or negedge presetn)
   if(!presetn)
   begin
      dll_bypass  <= 1'b1; // Note: this signal controls mctrl_clk itself...
      hf          <= 1'b0;
   end
   else if(ctrl_wr & ctrl_addr == 32'h0)
   begin
      dll_bypass  <= ctrl_wdata[10];
      hf          <= ctrl_wdata[11];
   end
//============================
// 0x04: IO_CTRL
//============================
   assign csr[1] = {26'h0,
      wr_1tck_preamble,
      odt,
      enable_dqs,
      turn_off_inactive_io,
      pwd};

   always@(posedge pclk or negedge presetn)
   if(!presetn)
   begin
      pwd                  <= 1'b0; // TODO: turn OFF by default
      turn_off_inactive_io <= 1'b0;
      enable_dqs           <= 1'b0;
      odt                  <= 2'd0;
      wr_1tck_preamble     <= 1'b0;
   end
   else if(ctrl_wr & ctrl_addr == 32'h4)
   begin
      pwd                  <= ctrl_wdata[0];
      turn_off_inactive_io <= ctrl_wdata[1];
      enable_dqs           <= ctrl_wdata[2];
      odt                  <= ctrl_wdata[4:3];
      wr_1tck_preamble     <= ctrl_wdata[5];
   end
//============================
// 0x08: CTRL
//============================
  assign csr[2] = 32'h0;
/*   assign csr[2] = {31'h0, read_deskew};

   always@(posedge pclk or negedge presetn)
   if(!presetn)
      read_deskew <= 1'b0;
   else if(ctrl_wr & ctrl_addr == 32'h8)
      read_deskew <= ctrl_wdata[0];*/
//============================
// 0x0C: TRNG_CTRL
//============================
/*
   reg [3:0] enable_rank_trng;
   assign csr[3] = {28'h0, enable_rank_trng};

   always@(posedge pclk or negedge presetn)
   if(!presetn)
      enable_rank_trng <= 4'b0;
   else if(ctrl_wr & ctrl_addr == 32'hC)
      enable_rank_trng <= ctrl_wdata[3:0];
*/
   assign csr[3] = 32'h0;
/*
   output reg                        mgt_req,
   output reg                        update_gt,
   output reg                        update_det,
   input                             training_done,
   output reg                        gt_in_progress_sw,
   input [3:0]                       gt_coef_0, gt_coef_1, gt_coef_2, gt_coef_3, gt_coef_4,
   input [3:0]                       gt_coef_5, gt_coef_6, gt_coef_7, gt_coef_8,
   input [2:0]                       det_coef_0, det_coef_1, det_coef_2, det_coef_3, det_coef_4,
   input [2:0]                       det_coef_5, det_coef_6, det_coef_7, det_coef_8,
*/
//============================
// 0x10:
//============================
   assign csr[4] = 32'h0;
//============================
// 0x14:
//============================
   assign csr[5] = 32'h0;
//============================
// 0x18:
//============================
   assign csr[6] = 32'h0;
//============================
// 0x1C: MODE
//============================
   assign csr[7] = {29'h0, ddr2_mode, 1'b0, ddr4_mode};

   always@(posedge pclk or negedge presetn)
   if(!presetn)
   begin
      ddr4_mode <= 1'b0;
      ddr2_mode <= 1'b1;
   end
   else if(ctrl_wr & ctrl_addr == 32'h1C)
   begin
      ddr4_mode <= ctrl_wdata[0];
      ddr2_mode <= ctrl_wdata[2];
   end
//============================
//============================
//============================

// TODO: move training engine here

endmodule

