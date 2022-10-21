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
   CDC_SYNC_STAGE = 2
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
   output reg                 gt_req,  // request to FSM to start training
   output reg                 det_req, // request to FSM to start training
   input [3:0] trng_ranks,
   output reg [3:0] enable_rank_trng,
   output                     train_mode,
   output reg                 rgt,
   output reg                 rdet,
   input                      trng_done, trng_run_done,
   input [SDRAM_BYTE_COUNT-1:0]            dfi_rdlvl_resp,
   input [SDRAM_BYTE_COUNT-1:0] err_gt_first_one,
   input [SDRAM_BYTE_COUNT-1:0] err_gt_no_zeroes,
   input [SDRAM_BYTE_COUNT-1:0] err_gt_no_ones,
   output [3*SDRAM_BYTE_COUNT*4-1:0] dfi_rdlvl_delay,
   output [3*SDRAM_BYTE_COUNT*4-1:0] dfi_rdlvl_delay_n,
   output [4*SDRAM_BYTE_COUNT*4-1:0] dfi_rdlvl_gate_delay,
   input [2*SDRAM_BYTE_COUNT-1:0]    dfi_rddata_valid,
   input [3*SDRAM_BYTE_COUNT-1:0] det_coef,
   input [4*SDRAM_BYTE_COUNT-1:0] gt_coef,
   input [2:0] cur_coef_det,
   input [3:0] cur_coef_gt,
input gt_request, det_request,


   output reg                 pwd, // TODO: resync to PHY clock synchronous control signals
   input [SDRAM_BYTE_COUNT:0] dll_locked,
   output reg                 dll_bypass,
   output reg                 dll_reset_n,
//   output reg                 read_deskew,
   output reg                 dm_off_state,
   output reg                 enable_dqs,
   output reg [1:0]           odt,
   output reg                 turn_off_inactive_io,
   output reg                 wr_1tck_preamble,
   output reg                 hf,
   output reg                 ddr4_mode,
   output reg                 ddr2_mode
);
   assign dfi_rdlvl_delay_n = dfi_rdlvl_delay;
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
      .ADR_WIDTH  ( 32         ), // TODO: reduce
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

   wire [31:0] csr [15:0];

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
   assign ctrl_rdata = csr[ctrl_addr[5:2]];
//============================
// 0x00: DLL_CTRL
//============================
   wire [9:0] dll_locked_bus;
   assign dll_locked_bus[0]   = dll_locked[SDRAM_BYTE_COUNT]; // TODO: ECC_ENA placed in MSB - rewrite register description!!!!
   assign dll_locked_bus[9:1] = dll_locked[SDRAM_BYTE_COUNT-1:0]; // Npte: extended for all configurations

   assign csr[0] = {
      16'h0,
      ~dll_reset_n,
      3'h0,
      hf,
      dll_bypass,
      dll_locked_bus
   };

   always@(posedge pclk or negedge presetn)
   if(!presetn)
   begin
      dll_bypass  <= 1'b1; // Note: this signal controls mctrl_clk itself...
      hf          <= 1'b0;
      dll_reset_n <= 1'b0;
   end
   else if(ctrl_wr & ctrl_addr == 32'h0)
   begin
      dll_bypass  <= ctrl_wdata[10];
      hf          <= ctrl_wdata[11];
      dll_reset_n <= ~ctrl_wdata[15];
   end
//============================
// 0x04: IO_CTRL
//============================
   assign csr[1] = {25'h0,
      dm_off_state,
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
      dm_off_state         <= 1'b0;
   end
   else if(ctrl_wr & ctrl_addr == 32'h4)
   begin
      pwd                  <= ctrl_wdata[0];
      turn_off_inactive_io <= ctrl_wdata[1];
      enable_dqs           <= ctrl_wdata[2];
      odt                  <= ctrl_wdata[4:3];
      wr_1tck_preamble     <= ctrl_wdata[5];
      dm_off_state         <= ctrl_wdata[6];
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
// 0x0C:
//============================
   assign csr[3] = 32'h0;
//============================
// 0x10: TRNG_CTRL
//============================
   reg mgt;
   assign train_mode = mgt | rgt | rdet; // TODO: resync
   wire trng_done$pclk;

   always@(posedge pclk or negedge presetn)
   if(!presetn)
   begin
      enable_rank_trng <= 4'b1;
      mgt  <= 1'b0;
      rgt  <= 1'b0;
      rdet <= 1'b0;
   end
   else if(ctrl_wr & ctrl_addr == 32'h10)
   begin
      enable_rank_trng <= ctrl_wdata[6:3];
      mgt  <= ctrl_wdata[2];
      rgt  <= ctrl_wdata[1];
      rdet <= ctrl_wdata[0];
   end
   else if(trng_done$pclk)
   begin
      mgt  <= 0;
      rgt  <= 0;
      rdet <= 0;
   end

   assign csr[4] = {25'h0, enable_rank_trng, mgt, rgt, rdet};
/*
   output reg                        mgt_req,
   output reg                        update_gt,
   output reg                        update_det,
*/

   ehl_cdc_pulse
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) det_p_inst
   (
      .src_clk     ( pclk      ),
      .src_reset_n ( presetn   ),
      .src         ( ctrl_wr && ctrl_addr == 32'h10 && ctrl_wdata[0] ),
      .dst_clk     ( mctrl_clk ),
      .dst_reset_n ( presetn   ), // !!!
      .dst         ( det_req    )
   );
   ehl_cdc_pulse
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) gt_p_inst
   (
      .src_clk     ( pclk      ),
      .src_reset_n ( presetn   ),
      .src         ( ctrl_wr && ctrl_addr == 32'h10 && ctrl_wdata[1] ),
      .dst_clk     ( mctrl_clk ),
      .dst_reset_n ( presetn   ), // !!!
      .dst         ( gt_req    )
   );
   ehl_cdc_pulse
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) done_p_inst
   (
      .src_clk     ( mctrl_clk      ),
      .src_reset_n ( presetn   ), // !!!
      .src         ( trng_done ),
      .dst_clk     ( pclk ),
      .dst_reset_n ( presetn   ),
      .dst         ( trng_done$pclk )
   );

//============================
// 0x14:
//============================
   assign csr[5] = 32'h0;
//============================
// 0x18: MODE
//============================
   assign csr[6] = {29'h0, ddr2_mode, 1'b0, ddr4_mode};

   always@(posedge pclk or negedge presetn)
   if(!presetn)
   begin
      ddr4_mode <= 1'b0;
      ddr2_mode <= 1'b1;
   end
   else if(ctrl_wr & ctrl_addr == 32'h18)
   begin
      ddr4_mode <= ctrl_wdata[0];
      ddr2_mode <= ctrl_wdata[2];
   end
//============================
//============================
// 0x1C - 0x3C: TRNG_BYTE
//============================
   wire [1:0] cs_n_trng =
      trng_ranks[0] ? 2'd0 :
      trng_ranks[1] ? 2'd1 :
      trng_ranks[2] ? 2'd2 :
      trng_ranks[3] ? 2'd3 : 2'd0;

   reg det_request_delay;
   always@(posedge mctrl_clk or negedge reset_n)
   if(!reset_n)
      det_request_delay <= 1'b0;
   else
      det_request_delay <= det_request;
   reg gt_request_delay;
   always@(posedge mctrl_clk or negedge reset_n)
   if(!reset_n)
      gt_request_delay <= 1'b0;
   else
      gt_request_delay <= gt_request;

   wire det_r0_complete = rdet & trng_run_done & (cs_n_trng==0);
   wire det_r1_complete = rdet & trng_run_done & (cs_n_trng==1);
   wire det_r2_complete = rdet & trng_run_done & (cs_n_trng==2);
   wire det_r3_complete = rdet & trng_run_done & (cs_n_trng==3);

   wire gt_r0_complete = rgt & trng_run_done & (cs_n_trng==0);
   wire gt_r1_complete = rgt & trng_run_done & (cs_n_trng==1);
   wire gt_r2_complete = rgt & trng_run_done & (cs_n_trng==2);
   wire gt_r3_complete = rgt & trng_run_done & (cs_n_trng==3);

   genvar gen_i;
   for(gen_i = 0; gen_i < SDRAM_BYTE_COUNT; gen_i = gen_i + 1)
   begin : trng_ctrl
      wire drv = 1'b0; // unsupported
      wire csr_wr;
      ehl_cdc_pulse
      #(
         .SYNC_STAGE ( CDC_SYNC_STAGE ),
         .TECHNOLOGY ( TECHNOLOGY     )
      ) apb_wr_inst
      (
         .src_clk     ( pclk      ),
         .src_reset_n ( presetn   ),
         .src         ( ctrl_wr && ctrl_addr == (32'h1C + 4*gen_i)),
         .dst_clk     ( mctrl_clk ),
         .dst_reset_n ( presetn   ), // !!!
         .dst         ( csr_wr    )
      );

      wire [15:0] byte_rdlvl_gate_delay;
      wire [11:0] byte_rdlvl_delay;
      // Note: data provided as {Bx_R3, Bx_R2, Bx_R1, Bx_R0}, while externally it is used as {{B3_R1, B2_R1, B1_R1... B1_R0, B0_R0}
      assign dfi_rdlvl_gate_delay[gen_i*16+:16] = byte_rdlvl_gate_delay;
      assign dfi_rdlvl_delay[gen_i*12+:12]      = byte_rdlvl_delay;
/*
      always@(posedge mctrl_clk or negedge reset_n)
      if(!reset_n)
         drv <= 1'b0;
      else if(ahb_request_wr)
      begin
         if(ctrl_addr_cpt==REG_DDR_BYTE0) drv <= 1'b0; // Note: clear on write functionality
      end
      else if(~|dfi_rddata_valid_delay && (|dfi_rddata_valid ^ &dfi_rddata_valid))
         drv <= dfi_rddata_valid[gen_i];
*/
      assign csr[7 + gen_i] = {
         dfi_rdlvl_resp[gen_i],
         drv,
         err_gt_first_one[gen_i] ? 2'b01 : err_gt_no_zeroes[gen_i] ? 2'b10 : err_gt_no_ones[gen_i] ? 2'b11 : 2'b00,
         dfi_rdlvl_delay[gen_i*12+9+:3],
         dfi_rdlvl_delay[gen_i*12+6+:3],
         dfi_rdlvl_delay[gen_i*12+3+:3],
         dfi_rdlvl_delay[gen_i*12+0+:3],
         dfi_rdlvl_gate_delay[gen_i*16+12+:4],
         dfi_rdlvl_gate_delay[gen_i*16+8+:4],
         dfi_rdlvl_gate_delay[gen_i*16+4+:4],
         dfi_rdlvl_gate_delay[gen_i*16+0+:4]
      };
      ehl_ddr_trng_byte
      #(
         .RANK_CNT ( RANK_CNT )
      )
      b_inst
      (
         .mctrl_clk         ( mctrl_clk             ),
         .reset_n           ( reset_n               ),
         .det_r0_complete   ( det_r0_complete       ),
         .det_r1_complete   ( det_r1_complete       ),
         .det_r2_complete   ( det_r2_complete       ),
         .det_r3_complete   ( det_r3_complete       ),
         .gt_r0_complete    ( gt_r0_complete        ),
         .gt_r1_complete    ( gt_r1_complete        ),
         .gt_r2_complete    ( gt_r2_complete        ),
         .gt_r3_complete    ( gt_r3_complete        ),
         .det_request_delay ( det_request_delay     ),
         .gt_request_delay  ( gt_request_delay      ),
         .sw_write          ( csr_wr                ),
         .cur_cs_n_trng     ( cs_n_trng             ),
         .det_coef          ( det_coef[gen_i*3+:3]  ),
         .cur_coef_det      ( cur_coef_det          ),
         .gt_coef           ( gt_coef[gen_i*4+:4]   ),
         .cur_coef_gt       ( cur_coef_gt           ),
         .sw_data           ( ctrl_wdata[27:0]      ), // Note: data must be stable as per APB
         .rdlvl_gate_delay  ( byte_rdlvl_gate_delay ),
         .rdlvl_delay       ( byte_rdlvl_delay      )
      );
   end
   genvar gen_j;
   for(gen_j = SDRAM_BYTE_COUNT; gen_j < 9; gen_j = gen_j + 1)
   begin : no_trng_ctrl
      assign csr[7 + gen_j] = 32'h0;
   end

endmodule
