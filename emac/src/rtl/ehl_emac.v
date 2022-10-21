// Design:           Ethernet MAC Core
// Revision:         1.0
// Date:             2017-06-27
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2017-06-27 A.Kornukhin: Initial release
// Reference:        [1] IEEE 802.3-2005

// TODO: required features
//       1. Flow Control
//       2. VLAN tags, stacked VLAN
//       3. 1588 support
//       4. TCP/IP wrapper
//       5. AXI slave for tx data - different queue
//          AXI master for rx data - different queue
//       6. 10/100/1000[/10G] MII, GMII ... RMII, RGMII (as MII-like), SGMII wrappers
//       7. PCS(GMII->TBI), PMA!?
//       8. external FIFO interface for emergency transfers
// Q: external FIFO ... sent data to that FIFO, and this FIFO can resend data according to specified queue descriptors...

// TODO: add register that defines width of output interface, i.e. 4, 8, 32/64
//       so setting this register will allow to support GMII, RGMII=MII modes

// todo: so far only 10M/100M and 1G configurations are supported; 10G configuration will be in development after earlier will be completed
// todo: generate APB error if aligned transfer, i.e. paddr[1:0]!=0

module ehl_emac
#(
   parameter CDC_SYNC_STAGE = 3,        // number of clock-domain-crossing stages
   DATA_WIDTH = 32,                     // width of write buffer RAM
   TECHNOLOGY = 0,
   parameter [0:0] TX_ENA = 1,          // enable transmitter
   TX_STAT_ENA = 1,                     // enable transmitter statistics registers
   RX_ENA = 1,                          // enable receiver
   RX_STAT_ENA = 1,                     // enable receiver statistics registers
   MDIO_ENA = 1,                        // enable MIIM core
   FC_ENA = 1,                          // enable Flow Control
   SYNCHRONIZE_RESETS = 0,              // enable reset synchronizers
// TODO: 64bit address support - to avoid 64B descriptors...
   parameter [47:0] DEFAULT_MAC = 48'h0 // default value of core MAC address
)
(
   input         test_mode, // TODO: spec
// Configuration interface
   input         clk,
                 reset_n,
   input [31:0]  addr,
   input         wr,
   input         rd,
   input [31:0]  wdata,
   output        ready,
   output        err,
   output [31:0] rdata,
   output        irq,
// DMA interface
   input                   dma_clk,
   output                  dma_rd,
   output                  dma_wr,
   output [/*32+*/31:0]    dma_waddr,
   output [/*32+*/31:0]    dma_raddr,
   input  [DATA_WIDTH-1:0] dma_rdata,
   output [DATA_WIDTH-1:0] dma_wdata,
   input                   dma_rdy,
//===================================
// 7) Internal RAM
// Q: place RAM outside this core to allow user use it's own modules...
// use registered DPRAM here, to allow FPGA to use MACROs
//===================================
// Transmit MII
   input         tx_clk,
   output [7:0]  txd, // todo: XGMII SDR/DDR mode too...
   output        tx_er,
   output        tx_en,
   input         col,
                 crs,
// Receive MII
   input         rx_clk,
                 rx_dv,
                 rx_er,
   input [7:0]   rxd,
// MII Management interface
   input         mdi,
   output        mdo,
                 mdo_en,
                 mdc
);
//===================================
// 1) Reset synchronizers
//===================================
   wire reset_n_sync;
   wire tx_reset_n;
   wire rx_reset_n;
   wire dma_reset_n;

   if(SYNCHRONIZE_RESETS)
   begin : sync_reset
      ehl_reset_sync
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      ) apb_reset_sync
      (
         .clk       ( clk          ),
         .res_n     ( reset_n      ),
         .res_out_n ( reset_n_sync ),
         .test_mode
      );
      ehl_reset_sync
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      )  tx_reset_sync
      (
         .clk       ( tx_clk     ),
         .res_n     ( reset_n    ),
         .res_out_n ( tx_reset_n ),
         .test_mode
      );
      ehl_reset_sync
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      )  rx_reset_sync
      (
         .clk       ( rx_clk     ),
         .res_n     ( reset_n    ),
         .res_out_n ( rx_reset_n ),
         .test_mode
      );
      ehl_reset_sync
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      )  dma_reset_sync
      (
         .clk       ( dma_clk     ),
         .res_n     ( reset_n     ),
         .res_out_n ( dma_reset_n ),
         .test_mode
      );
   end
   else
   begin : bypass_reset
      assign reset_n_sync = reset_n;
      assign tx_reset_n   = reset_n;
      assign rx_reset_n   = reset_n;
      assign dma_reset_n  = reset_n;
   end
//===================================
// CSRs read
// 0 - CSRs
// 1 - MIIM
// 2 - TX
// 3 - RX
// 4 - FC
//===================================
   wire [31:0] csr_rdata [4:0]; // TODO: set valid number of sources
   wire [4:0]  csr_rdy; // TODO: set valid number of sources

   assign ready = &csr_rdy; // TODO:
   assign rdata = csr_rdata[0] | csr_rdata[1] | csr_rdata[2] | csr_rdata[3] | csr_rdata[4];
//(addr[11:8]==3) ? csr_rdata[1] : csr_rdata[0]; // TODO:
//===================================
// 1) control and status registers (assumed pseudo-static)
//===================================
   wire [47:0] mac_addr;
   wire [47:0] mcasta, mcastm;
   wire [14:0] maxlr;
   wire [9:0]  minlr;
   wire fc_enable;
   wire [1:0] speed_mode;
   wire duplex_mode;
   wire [5:0] ifg;
   wire [4:0] attlim;
   wire mac_ena;
   wire broad_ena;
   wire rx_enable;
   wire tx_enable;
   wire [31:0] txbdptr;
   wire [31:0] rxbdptr;
   wire txdma_start;
   wire [31:0] txdmactrl;
   wire [31:0] rxdmactrl;
   wire reset_rx_stat;
   wire reset_tx_stat;

   wire irq_miim, irq_txbddone, irq_rxbddone;
   wire irq_txbddone$ctrl, irq_rxbddone$ctrl;
   ehl_cdc_pulse
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) irq_sync[1:0]
   (
      .src_clk     ( dma_clk           ),
      .src_reset_n ( dma_reset_n       ),
      .src         ( {irq_txbddone, irq_rxbddone}      ),
      .dst_clk     ( clk               ),
      .dst_reset_n ( reset_n           ),
      .dst         ( {irq_txbddone$ctrl, irq_rxbddone$ctrl} )
   );

   wire txdma_active;
   wire txdma_active$ctrl;
   ehl_cdc
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .WIDTH      ( 1              ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) txdmact_sync_inst
   (
      .clk     ( clk               ),
      .reset_n ( reset_n           ),
      .din     ( txdma_active      ),
      .dout    ( txdma_active$ctrl )
   );
   wire txdma_wait;
   wire txdma_wait$ctrl;
   ehl_cdc
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .WIDTH      ( 1              ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) txdmwait_sync_inst
   (
      .clk     ( clk             ),
      .reset_n ( reset_n         ),
      .din     ( txdma_wait      ),
      .dout    ( txdma_wait$ctrl )
   );

   ehl_emac_csr
   #(
      .DEFAULT_MAC ( DEFAULT_MAC )
   ) csr_inst
   (
      .clk,
      .reset_n          ( reset_n_sync     ),
      .wr,
      .addr             ( addr[11:0]       ),
      .wdata,
      .rdata            ( csr_rdata[0]     ),
      .rdy              ( csr_rdy[0]       ),
// Control registers
      .tx_enable        ( tx_enable        ),
      .rx_enable        ( rx_enable        ),
      .mac_addr,
      .maxlr,
      .minlr,
      .duplex_mode      ( duplex_mode      ),
      .mcasta,
      .mcastm,
      .broad_ena,
      .txbdptr,
      .rxbdptr,
      .txdmactrl,
      .rxdmactrl,
      .txdma_start,
      .reset_tx_stat,
      .reset_rx_stat,
      .attlim,
      .ifg,
      .irq_miim,
      .irq_txbddone     ( irq_txbddone$ctrl ),
      .irq_rxbddone     ( irq_rxbddone$ctrl ),
      .txdma_active     ( txdma_active$ctrl ),
      .txdma_wait       ( txdma_wait$ctrl   ),
// todo: program MSB 64-bits of Rx/Tx buffers - they should point to single 32-bit location, i.e. descriptors placed into single 4GB area...
      .fc_enable,
      .speed_mode       ( speed_mode       ),
      .mac_ena
   );

   wire rx_enable$rx;
   ehl_cdc
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .WIDTH      ( 1              ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) rxen_sync_inst
   (
      .clk     ( rx_clk          ),
      .reset_n ( rx_reset_n ),
      .din     ( rx_enable       ),
      .dout    ( rx_enable$rx    )
   );
   wire rx_enable$dma;
   ehl_cdc
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .WIDTH      ( 1              ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) rxen_sync2_inst
   (
      .clk     ( dma_clk          ),
      .reset_n ( dma_reset_n   ),
      .din     ( rx_enable     ),
      .dout    ( rx_enable$dma    )
   );

   wire tx_enable$tx;
   ehl_cdc
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .WIDTH      ( 1              ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) txen_sync_inst
   (
      .clk     ( tx_clk          ),
      .reset_n ( tx_reset_n ),
      .din     ( tx_enable       ),
      .dout    ( tx_enable$tx    )
   );
   wire tx_enable$dma;
   ehl_cdc
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .WIDTH      ( 1              ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) txen_sync2_inst
   (
      .clk     ( dma_clk          ),
      .reset_n ( dma_reset_n ),
      .din     ( tx_enable        ),
      .dout    ( tx_enable$dma    )
   );
//===================================
// 3) Media Independent Interface Management (MIIM)
//===================================
   wire [15:0] mdr;
   wire [26:0] mcr;

   if(MDIO_ENA)
   begin : mdio
      ehl_eth_miim
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      ) miim_inst
      (
         .clk       ( clk                        ),
         .reset_n   ( reset_n_sync               ),
         .test_mode ( test_mode                  ),
         .din       ( wdata                      ),
         .mdi       ( mdi                        ),
         .mdo       ( mdo                        ),
         .mdo_en    ( mdo_en                     ),
         .mdc       ( mdc                        ),
         .interrupt ( irq_miim                   ),
         .write_mcr ( wr & addr[11:0] == 12'h300 ),
         .write_mdr ( wr & addr[11:0] == 12'h304 ),
         .mdr       ( mdr                        ),
         .mcr       ( mcr                        )
      );
      assign csr_rdy[1]   = 1'b1;
      assign csr_rdata[1] = (addr==12'h300) ? {5'h0, mcr} : (addr==12'h304) ? {16'h0, mdr} : 32'h0;
   end
   else
   begin : no_mdio
      assign mdr    = 16'h0;
      assign mcr    = 27'h7fe_0000;
      assign mdo    = 1'b1;
      assign mdo_en = 1'b0;
      assign mdc    = 1'b0;
      assign csr_rdy[1]   = 1'b1;
      assign csr_rdata[1] = 32'h0;
      assign irq_miim = 1'b0;
   end
//===================================
// 4) Receiver Core
//===================================
   wire        fc_received;
   wire [15:0] fc_rx_value;
   wire [5:0]  fcllr, fchlr;

   wire        rxfifo_wr;
   wire        rxfifo_sop;
   wire        rxfifo_eop;
   wire [31:0] rxfifo_wdata;
   wire        rxfifo_ok;

   if(RX_ENA)
   begin : rx
      ehl_emac_rx
      #(
         .CDC_SYNC_STAGE ( CDC_SYNC_STAGE ),
         .DATA_WIDTH     ( DATA_WIDTH     ),
         .RX_STAT_ENA    ( RX_STAT_ENA    )
      ) rx_inst
      (
         .clk,
         .reset_n          ( reset_n_sync     ),
         .wr,
         .addr             ( addr[11:0]       ),
         .wdata,
         .rdata            ( csr_rdata[3]     ),
         .rdy              ( csr_rdy[3]       ),
// Settings
         .mac_addr         ( mac_addr         ),
         .minlr            ( minlr            ),
         .maxlr            ( maxlr            ),
         .rx_enable        ( rx_enable$rx     ),
         .speed_mode       ( speed_mode       ), // [CDC] - assumed static
         .mcasta,
         .mcastm,
         .mac_ena,
         .broad_ena,
         .reset_stat       ( reset_rx_stat    ), // TODO: resync...
// RX
         .rx_clk           ( rx_clk           ),
         .rx_reset_n       ( rx_reset_n       ),
         .rx_er            ( rx_er            ),
         .rx_dv            ( rx_dv            ),
         .rxd              ( rxd              ),

         .rxfifo_wr,
         .rxfifo_sop,
         .rxfifo_eop,
         .rxfifo_wdata,
         .rxfifo_ok,
`ifdef __NONE__
// Flow control
         .fcllr            ( fcllr            ),
         .fchlr            ( fchlr            ),
         .fc_rx_value      ( fc_rx_value      ),
         .fc_received      ( fc_received      ),
`endif
         .fc_enable
      );
   end
   else
   begin : no_rx
      assign csr_rdy[3] = 1'b1;
      assign csr_rdata[3] = 32'h0;
   end
//===================================
// 5) Transmitter Core
//===================================
   wire txfifo_wr;
   wire [31:0] txfifo_wdata;
   wire txfifo_full;
   wire txfifo_empty;
   wire [15:0] txfifo_length;
   wire txfifo_af;

   wire fc_transmit;
   wire [15:0] fc_tx_value;
   wire [15:0] fcvr;
   wire tx_req_pulse, tx_req_pulse0;
   wire w_rd_fc;
   wire [31:0] w_addr_fc;
   wire [DATA_WIDTH-1:0] w_data_fc;
   wire tx_inhibit;

   wire tx_resp_empty;
   wire [6:0] tx_resp_out;
   wire tx_resp_rd;
   wire tx_resp_done;

   if(TX_ENA)
   begin : tx
      ehl_emac_tx
      #(
         .CDC_SYNC_STAGE ( CDC_SYNC_STAGE ),
         .DATA_WIDTH     ( DATA_WIDTH     ),
         .TX_STAT_ENA    ( TX_STAT_ENA    ),
         .TECHNOLOGY     ( TECHNOLOGY     )
      ) tx_inst
      (
         .clk,
         .reset_n       ( reset_n_sync        ),
         .wr,
         .addr          ( addr[11:0]          ),
         .wdata,
         .rdata         ( csr_rdata[2]        ),
         .rdy           ( csr_rdy[2]          ),
// Settings
         .reset_stat    ( reset_tx_stat   ),
         .mac_addr      ( mac_addr            ),
         .minlr         ( minlr               ),
         .maxlr         ( maxlr               ),
         .tx_enable     ( tx_enable$tx        ),
         .speed_mode    ( speed_mode          ), // [CDC] - assumed static
         .ifg,
         .duplex_mode   ( duplex_mode         ), // Note: [CDC] signals must be static when turn design on - TODO: add synchronizer...
         .attlim,
// TX
         .tx_clk        ( tx_clk              ),
         .tx_reset_n    ( tx_reset_n     ),
         .tx_en         ( tx_en               ),
         .tx_er         ( tx_er               ),
         .txd           ( txd                 ),
         .crs           ( crs                 ),
         .col           ( col                 ),
// Frame buffer interface
         .dma_clk,
         .dma_reset_n,
         .txfifo_wr,
         .txfifo_wdata,
         .txfifo_full,
         .txfifo_empty,
         .txfifo_length,
         .txfifo_af,


         .tx_resp_empty,
         .tx_resp_out,
         .tx_resp_rd,
         .tx_resp_done

`ifdef __NONE__
         .w_data_fc     ( w_data_fc           ),
         .w_rd_fc       ( w_rd_fc             ),
         .w_addr_fc     ( w_addr_fc           ),
// Flow control
         .fcvr          ( fcvr                ),
         .tx_req_pulse  ( tx_req_pulse        ),
         .tx_req_pulse0 ( tx_req_pulse0       ),
         .tx_inhibit    ( tx_inhibit          )
`endif
      );
   end
   else
   begin : no_tx
      assign csr_rdy[2] = 1'b1;
      assign csr_rdata[2] = 32'h0;
   end
//===================================
// 6) Flow Control Core
//===================================
assign csr_rdata [4] = 0;
assign csr_rdy[4] = 1;
   if(FC_ENA)
   begin : fc
      ehl_emac_fc
      #(
         .DATA_WIDTH     ( DATA_WIDTH     ),
         .CDC_SYNC_STAGE ( CDC_SYNC_STAGE ),
         .TECHNOLOGY     ( TECHNOLOGY     )
      ) fc_inst
      (
         .fc_enable,
         .duplex_mode      ( duplex_mode      ),
         .speed_mode       ( speed_mode       ), // [CDC] - assumed static
      // receive domain
         .rx_clk           ( rx_clk           ),
         .rx_reset_n       ( rx_reset_n  ),
         .fc_received      ( fc_received      ),
         .fc_rx_value      ( fc_rx_value      ),
         .fcllr            ( fcllr            ),
         .fchlr            ( fchlr            ),
         .rx_buffer_status ( 32'h0 ), // TODO:
      // transmit domain
         .tx_clk           ( tx_clk           ),
         .tx_reset_n       ( tx_reset_n  ),
         .fc_transmit      ( fc_transmit      ),
         .fc_tx_value      ( fc_tx_value      ),
         .fcvr             ( fcvr             ), // Q: what for this register made? for Upper bound only? as lower should be 0-filled automatically
         .tx_inhibit       ( tx_inhibit       ),
         .tx_req_pulse     ( tx_req_pulse     ),
         .tx_req_pulse0    ( tx_req_pulse0    ),
      // ROM
         .w_clk            ( clk              ), // TODO: use valid clock
         .w_rd_fc          ( w_rd_fc          ),
         .w_addr_fc        ( w_addr_fc        ),
         .w_data_fc        ( w_data_fc        )
      );
   end
   else
   begin : no_fc
      assign fc_transmit = 1'b0;
      assign fc_tx_value = 16'h0;
      //fc_received;
      //fc_rx_value;
   end
//===================================
// 7) DMA
// TODO: place under associated Rx/Tx generate scopes
//===================================
   wire [7:0] a_dma_rdy;
   wire [3:0] a_dma_rd;
   wire [3:0] a_dma_wr;
   wire [31:0] a_dma_wdata[3:0];
   wire [31:0] a_dma_waddr[3:0];
   wire [31:0] a_dma_raddr[3:0];

   wire        tx_q_read;
//    wire [31:0] tx_q_flags;
   wire [31:0] tx_q_buf_ptr;
   wire [15:0] tx_q_buf_size;
   wire        tx_q_empty;
   wire        bd_updated;
   wire txdma_start$dma;

   ehl_cdc_pulse
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) txdma_sync
   (
      .src_clk     ( clk             ),
      .src_reset_n ( reset_n         ),
      .src         ( txdma_start     ),
      .dst_clk     ( dma_clk         ),
      .dst_reset_n ( dma_reset_n     ),
      .dst         ( txdma_start$dma )
   );

   ehl_emac_txdma_mngr dma_tx_mngr_inst
   (
      .clk            ( dma_clk        ),
      .reset_n        ( dma_reset_n    ),

      .wr             ( a_dma_wr[0]    ),
      .rd             ( a_dma_rd[0]    ),
      .waddr          ( a_dma_waddr[0] ),
      .raddr          ( a_dma_raddr[0] ),
      .wdata          ( a_dma_wdata[0] ),
      .rdata          ( dma_rdata      ),
      .rdy_wr         ( a_dma_rdy[1]   ), // read and write has independent READY
      .rdy            ( a_dma_rdy[0]   ),

      .txbdptr,
      .txdmactrl,
      .txdma_start    ( txdma_start$dma ),

      .tx_enable      ( tx_enable$dma  ),
      .dma_active     ( txdma_active  ),
      .dma_wait       ( txdma_wait    ),
      .irq_txbddone,

      .queue_rd       ( tx_q_read      ),
//       .queue_flags    ( tx_q_flags     ),
      .queue_buf_ptr  ( tx_q_buf_ptr   ),
      .queue_buf_size ( tx_q_buf_size  ),
      .queue_empty    ( tx_q_empty     ),

      .bd_updated,
      .tx_resp_empty,
      .tx_resp_out,
      .tx_resp_done
   );
   assign tx_resp_rd = a_dma_wr[0];

   assign a_dma_waddr[1] = 32'h0;
   assign a_dma_wdata[1] = 32'h0;
   ehl_emac_txdma dma_tx_inst
   (
      .clk            ( dma_clk        ),
      .reset_n        ( dma_reset_n    ),
      .rd             ( a_dma_rd[1]    ),
      .raddr          ( a_dma_raddr[1] ),
      .rdata          ( dma_rdata      ),
      .rdy            ( a_dma_rdy[2]   ),

      .queue_rd       ( tx_q_read      ),
//       .queue_flags    ( tx_q_flags     ),
      .queue_buf_ptr  ( tx_q_buf_ptr   ),
      .queue_buf_size ( tx_q_buf_size  ),
      .queue_empty    ( tx_q_empty     ),

      .bd_updated,

      .txfifo_wr,
      .txfifo_wdata,
      .txfifo_full,
      .txfifo_empty,
      .txfifo_af,
      .txfifo_length
   );

   wire [31:0] rx_q_buf_ptr;
   wire [15:0] rx_q_buf_size;
   wire        rx_q_empty;
   wire        rx_q_read;

   ehl_emac_rxdma_mngr dma_rx_mngr_inst
   (
      .clk            ( dma_clk        ),
      .reset_n        ( dma_reset_n    ),
      .rxbdptr,
      .rxdmactrl,
      .rx_enable      ( rx_enable$dma  ),
      .irq_rxbddone,

      .wr             ( a_dma_wr[2]    ),
      .rd             ( a_dma_rd[2]    ),
      .waddr          ( a_dma_waddr[2] ),
      .raddr          ( a_dma_raddr[2] ),
      .wdata          ( a_dma_wdata[2] ),
      .rdata          ( dma_rdata      ),
      .rdy_wr         ( a_dma_rdy[5]   ), // read and write has independent READY
      .rdy            ( a_dma_rdy[4]   ),

/*
      .rd             ( a_dma_rd[1]    ),
      .raddr          ( a_dma_raddr[1] ),
      .rdata          ( dma_rdata      ),
      .rdy            ( a_dma_rdy[2]   ),
*/
      .queue_rd       ( rx_q_read      ),
//       .queue_flags    ( tx_q_flags     ),
      .queue_buf_ptr  ( rx_q_buf_ptr   ),
      .queue_buf_size ( rx_q_buf_size  ),
      .queue_empty    ( rx_q_empty     )/*,

      .bd_updated,

      .txfifo_wr,
      .txfifo_wdata,
      .txfifo_full,
      .txfifo_empty,
      .txfifo_af,
      .txfifo_length
*/
   );

   assign a_dma_raddr[3] = 0;

   ehl_emac_rxdma
   #(
      .SYNC_STAGE ( CDC_SYNC_STAGE ),
      .TECHNOLOGY ( TECHNOLOGY     )
   ) dma_rx_inst
   (
      .clk            ( dma_clk        ),
      .reset_n        ( dma_reset_n    ),

      .wr             ( a_dma_wr[3]    ),
//       .rd             ( a_dma_rd[3]    ),
      .waddr          ( a_dma_waddr[3] ),
//       .raddr          ( a_dma_raddr[3] ),
      .wdata          ( a_dma_wdata[3] ),
      .rdy            ( a_dma_rdy[7]   ),

      .rx_enable      ( rx_enable$dma  ),

      .queue_rd       ( rx_q_read      ),
//       .queue_flags    ( tx_q_flags     ),
      .queue_buf_ptr  ( rx_q_buf_ptr   ),
      .queue_buf_size ( rx_q_buf_size  ),
      .queue_empty    ( rx_q_empty     ),
//   input             bd_updated,

      .rx_clk,
      .rx_reset_n,
      .rxfifo_wr,
      .rxfifo_sop,
      .rxfifo_eop,
      .rxfifo_wdata,
      .rxfifo_ok
/*
      .rd             ( a_dma_rd[1]    ),
      .raddr          ( a_dma_raddr[1] ),
      .rdata          ( dma_rdata      ),
      .rdy            ( a_dma_rdy[2]   ),

      .queue_rd       ( tx_q_read      ),
//       .queue_flags    ( tx_q_flags     ),
      .queue_buf_ptr  ( tx_q_buf_ptr   ),
      .queue_buf_size ( tx_q_buf_size  ),
      .queue_empty    ( tx_q_empty     ),

      .bd_updated,

      .txfifo_wr,
      .txfifo_wdata,
      .txfifo_full,
      .txfifo_empty,
      .txfifo_af,
      .txfifo_length
*/
   );
//===================================
// 11) DMA arbiter to external RAM
// 0 - DMA Tx Mngr Rd
// 1 - DMA Tx Mngr Wr
// 2 - DMA Tx Rd
// 3 - DMA Tx Wr
// 4 - DMA Rx Mngr Rd
// 5 - DMA Rx Mngr Wr
// 6 - DMA Rx Rd
// 7 - DMA Rx Wr
//===================================
// Q: independent READ and WRITE for AXI interface, as bandwidth falls by x2 otherwise...
//    they can be muxed at upper level - where AHB (half-duplex), or AXI (full duplex) will be used
   wire [8:0] dma_ack;
   wire [8:0] dma_grant;
   wire [8:0] dma_req = {1'b0/*TODO: add*/, a_dma_wr[3], 1'b0, a_dma_wr[2], a_dma_rd[2], 1'b0, a_dma_rd[1], a_dma_wr[0], a_dma_rd[0]};
   wire [8:0] dma_done = dma_rdy ? dma_ack : 9'h0;

   ehl_arbiter
   #(
      .WIDTH      ( 8+1  ),
      .SECOND_REQ ( 1'b0 )
   ) arb_inst
   (
      .clk              ( dma_clk     ),
      .reset_n          ( dma_reset_n ),
      .req              ( dma_req     ),
      .done             ( dma_done    ),
      .ack              ( dma_ack     ),
      .grant            ( dma_grant   ),
      .arbitration_type ( 1'b0        ),
      .empty            (             )
   );

   assign dma_rd = dma_grant[0] | dma_grant[2] | dma_grant[4] | dma_grant[6];
   assign dma_wr = dma_grant[1] | dma_grant[3] | dma_grant[5] | dma_grant[7];

   assign dma_waddr = dma_grant[1] ? a_dma_waddr[0] : dma_grant[3] ? a_dma_waddr[1] : dma_grant[5] ? a_dma_waddr[2] : a_dma_waddr[3];
   assign dma_raddr = dma_grant[0] ? a_dma_raddr[0] : dma_grant[2] ? a_dma_raddr[1] : dma_grant[4] ? a_dma_raddr[2] : a_dma_raddr[3];
   assign dma_wdata = dma_grant[1] ? a_dma_wdata[0] : dma_grant[3] ? a_dma_wdata[1] : dma_grant[5] ? a_dma_wdata[2] : a_dma_wdata[3];

   assign a_dma_rdy = dma_rdy ? dma_ack : 9'h0;

endmodule
