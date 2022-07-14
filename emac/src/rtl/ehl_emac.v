// Design:           Ethernet MAC Core
// Revision:         1.0
// Date:             2017-06-27
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2017-06-27 A.Kornukhin: Initial release
// Reference:        [1] IEEE 802.3-2005

// todo: required features
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
   TX_DESCR_COUNT = 32,                 // number of Transmit Descriptors
   RX_DESCR_COUNT = 32,                 // number of receive descriptors (4, 8, 16, 32...)
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
// TODO: use it... resync to required domain...
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

// Generic Data interface (AXI assumed as wrapper around this core so far) - VALID required!!!
   // there are 2 configurations:
   //  1. legacy support - core reads data from RAM (dual-port RAM) using TxDescr
   //  2. new            - core became master, and requests converted to AXI transactions
   // in both cases data read into FIFO and then processed by the core
   input         w_clk,  // clock for write buffer
   w_reset_n,
   output        w_rd,   // read request
   output [32+31:0] w_addr, // address for memory
   input [DATA_WIDTH-1:0]  w_data, // data from buffer
//===================================
// 7) Internal RAM
// Q: place RAM outside this core to allow user use it's own modules...
// use registered DPRAM here, to allow FPGA to use MACROs
//===================================
// Transmit MII
   input         tx_clk,
                 tx_reset_n,
   output [7:0]  txd, // todo: XGMII SDR/DDR mode too...
   output        tx_er,
   output        tx_en,
   input         col,
                 crs,
// Receive MII
   input         rx_clk,
                 rx_reset_n,
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
// configuration interface split requests to sub-cores:
// - MIIM (same clock)
// - Rx (Q: clock required!? with some kind of timeout and err response on expiration - deadlock defend)
// - Tx (Q: clock required!?)
// - Flow Control
//===================================

















//===================================
// 0) Reset synchronizers
//===================================
   wire presetn_sync;
   wire tx_reset_n_sync;
   wire rx_reset_n_sync;
   wire w_reset_n_sync;

   if(SYNCHRONIZE_RESETS)
   begin : sync_reset
      ehl_reset_sync apb_reset_sync
      (
         .clk       ( pclk         ),
         .res_n     ( presetn      ),
         .res_out_n ( presetn_sync )
      );
      ehl_reset_sync tx_reset_sync
      (
         .clk       ( tx_clk          ),
         .res_n     ( tx_reset_n      ),
         .res_out_n ( tx_reset_n_sync )
      );
      ehl_reset_sync rx_reset_sync
      (
         .clk       ( rx_clk          ),
         .res_n     ( rx_reset_n      ),
         .res_out_n ( rx_reset_n_sync )
      );
      ehl_reset_sync w_reset_sync
      (
         .clk       ( w_clk          ),
         .res_n     ( w_reset_n      ),
         .res_out_n ( w_reset_n_sync )
      );
   end
   else
   begin : bypass_reset
      assign presetn_sync    = presetn;
      assign tx_reset_n_sync = tx_reset_n;
      assign rx_reset_n_sync = rx_reset_n;
      assign w_reset_n_sync  = w_reset_n;
   end
//===================================
// 1) APB configuration port
//===================================
   wire [29:0] apb_addr;
   wire apb_wr;
   wire apb_rd;
   wire [31:0] apb_wdata;
   wire [31:0] apb_rdata;
   wire apb_ready;
   wire apb_setup_state = 1'b0; // TODO: logic is not supported by apb2generic any more, rewrite it using other way

   ehl_apb2generic
   #(
      .DATA_WIDTH ( 32 ),
      .ADR_WIDTH  ( 30 )
   ) apb_inst
   (
// AMBA APB interface
      .pclk    ( pclk         ),
      .presetn ( presetn_sync ),
      .paddr   ( paddr[31:2]  ),
      .pwrite  ( pwrite       ),
      .psel    ( psel         ),
      .penable ( penable      ),
      .pwdata  ( pwdata       ),
      .pready  ( pready       ),
      .pslverr ( pslverr      ),
      .prdata  ( prdata       ),
// Generic interface
// TODO:
//      .setup_state ( apb_setup_state ),
      .adr     ( apb_addr     ),
      .wr      ( apb_wr       ),
      .rd      ( apb_rd       ),
      .wdata   ( apb_wdata    ),
      .rdata   ( apb_rdata    ),
      .ready   ( apb_ready    )
   );
   wire [31:0] apb_rdata_vector [4:0];
   wire [4:0] apb_ready_vector;
   // Note: during SETUP state non-always-ready devices will drive READY signal low
   reg pull_ready;
   always@(posedge pclk or negedge presetn_sync)
   if(!presetn_sync)
      pull_ready <= 1'b1;
   else
      pull_ready <= ~(apb_setup_state & apb_addr[7]==1'b0);

   assign apb_ready = ~(apb_setup_state & apb_addr[7]==1'b0) & pull_ready &
      (apb_ready_vector[0] & apb_ready_vector[1] & apb_ready_vector[2] & apb_ready_vector[3] & apb_ready_vector[4]);

   assign apb_rdata =
      apb_addr[8:6] == 3'b000 ? apb_rdata_vector[0] :
      apb_addr[8:6] == 3'b001 ? apb_rdata_vector[1] :
      apb_addr[8:6] == 3'b010 ? apb_rdata_vector[2] :
      apb_addr[8:6] == 3'b010 ? apb_rdata_vector[3] :
      apb_addr[8:6] == 3'b100 ? apb_rdata_vector[4] :
      apb_addr[8:6] == 3'b101 ? apb_rdata_vector[4] : // Q: also [4]!?
      1'b1; // todo: PSLVERR
//===================================
// 2) APB domain registers (assumed pseudo-static)
//===================================
   wire [47:0] mac_addr;
   wire [47:0] multicast_addr;
   wire [14:0] maxlr;
   wire [9:0]  minlr;
   wire fc_enable;
   wire [1:0] speed_mode;
   wire duplex_mode;
   wire [5:0] ifg;
   wire [4:0] attlim;
   wire mac_ena;
   wire mult_ena;
   wire broad_ena;
   wire [31:0] tx_desc_addr_msb, rx_desc_addr_msb;

   ehl_emac_regs
   #(
      .DEFAULT_MAC ( DEFAULT_MAC )
   ) apb_regs_inst
   (
// APB
      .pclk             ( pclk                ),
      .presetn          ( presetn_sync        ),
      .paddr            ( paddr               ),
      .pwrite           ( pwrite              ),
      .psel             ( psel                ),
      .penable          ( penable             ),
      .pwdata           ( pwdata              ),
      .pready           ( apb_ready_vector[2] ),
      .pslverr          (                     ), // todo: use it...
      .prdata           ( apb_rdata_vector[2] ),
// Control registers
// todo: program MSB 64-bits of Rx/Tx buffers - they should point to single 32-bit location, i.e. descriptors placed into single 4GB area...
      .mac_addr         ( mac_addr            ),
      .muclticast_addr  ( multicast_addr      ),
      .maxlr            ( maxlr               ),
      .minlr            ( minlr               ),
      .fc_enable        ( fc_enable           ),
      .speed_mode       ( speed_mode          ),
      .duplex_mode      ( duplex_mode         ),
      .ifg              ( ifg                 ),
      .attlim           ( attlim              ),
      .mac_ena          ( mac_ena             ),
      .mult_ena         ( mult_ena            ),
      .broad_ena        ( broad_ena           ),
      .tx_desc_addr_msb ( tx_desc_addr_msb    ),
      .rx_desc_addr_msb ( rx_desc_addr_msb    ) // todo: use it for receive buffer
   );
//===================================
// 3) Media Independent Interface Management (MIIM)
// Note: another APB slave - 4th to allow self-changing register bits
//===================================
   wire [15:0] mdr;
   wire [27:0] mcr;
   assign apb_ready_vector[3] = 1'b1;
   assign apb_rdata_vector[3] = apb_addr[0] ? {16'h0, mdr} : {4'h0, mcr};

   if(MDIO_ENA)
   begin : mdio
      ehl_eth_miim miim_inst
      (
         .clk       ( pclk                                      ),
         .reset_n   ( presetn_sync                              ),
         .din       ( apb_wdata                                 ),
         .mdi       ( mdi                                       ),
         .mdo       ( mdo                                       ),
         .mdo_en    ( mdo_en                                    ),
         .mdc       ( mdc                                       ),
         .interrupt (                                           ),
         .write_mcr ( apb_wr & apb_addr[7:0]=={2'b11,6'b000000} ),
         .write_mdr ( apb_wr & apb_addr[7:0]=={2'b11,6'b000001} ),
         .mdr       (                                           ),
         .mcr       (                                           ),
         .clock_ena (                                           )
      );
   end
   else
   begin : no_mdio
      assign mdr = 16'h0;
      assign mcr = 28'hffe_0000;
      assign mdo = 1'b1;
      assign mdo_en = 1'b0;
      assign mdc = 1'b0;
   end
//===================================
// 4) Receiver Core
//===================================
   wire fc_received;
   wire [15:0] fc_rx_value;
   wire [5:0] fcllr, fchlr;
   wire [31:0] rx_buffer_status;
   if(RX_ENA)
   begin : rx
      ehl_emac_rx
      #(
         .CDC_SYNC_STAGE ( CDC_SYNC_STAGE ),
         .DATA_WIDTH     ( DATA_WIDTH     ),
         .RX_STAT_ENA    ( RX_STAT_ENA    ),
         .RX_DESCR_COUNT ( RX_DESCR_COUNT )
      ) rx_inst
      (
// APB
         .pclk             ( pclk                ),
         .presetn          ( presetn_sync        ),
         .pready           ( apb_ready_vector[1] ),
         .prdata           ( apb_rdata_vector[1] ),
         .apb_addr         ( {2'h0, apb_addr}    ),
         .apb_wr           ( apb_wr              ),
         .apb_rd           ( apb_rd              ),
         .apb_wdata        ( apb_wdata           ),
// Settings
         .speed_mode       ( speed_mode          ),
         .mac_addr         ( mac_addr            ),
         .multicast_addr   ( multicast_addr      ),
         .minlr            ( minlr               ),
         .maxlr            ( maxlr               ),
         .mac_ena          ( mac_ena             ),
         .mult_ena         ( mult_ena            ),
         .broad_ena        ( broad_ena           ),
// RX
         .rx_clk           ( rx_clk              ),
         .rx_reset_n       ( rx_reset_n_sync     ),
         .rx_er            ( rx_er               ),
         .rx_dv            ( rx_dv               ),
         .rxd              ( rxd                 ),
// Flow control
         .fcllr            ( fcllr               ),
         .fchlr            ( fchlr               ),
         .rx_buffer_status ( rx_buffer_status    ),
         .fc_rx_value      ( fc_rx_value         ),
         .fc_received      ( fc_received         ),
         .fc_enable        ( fc_enable           )
      );
   end
   else
   begin : no_rx
      assign apb_ready_vector[1] = 1'b1;
      assign apb_rdata_vector[1] = 32'h0;
   end
//===================================
// 5) Transmitter Core
//===================================
   wire fc_transmit;
   wire [15:0] fc_tx_value;
   wire [15:0] fcvr;
   wire tx_req_pulse, tx_req_pulse0;
   wire w_rd_fc;
   wire [31:0] w_addr_fc;
   wire [DATA_WIDTH-1:0] w_data_fc;
   wire tx_inhibit;
   if(TX_ENA)
   begin : tx
      ehl_emac_tx
      #(
         .CDC_SYNC_STAGE ( CDC_SYNC_STAGE ),
         .DATA_WIDTH     ( DATA_WIDTH     ),
         .TX_DESCR_COUNT ( TX_DESCR_COUNT ),
         .TX_STAT_ENA    ( TX_STAT_ENA    )
      ) tx_inst
      (
// APB
         .pclk          ( pclk                ),
         .presetn       ( presetn_sync        ),
         .pready        ( apb_ready_vector[0] ),
         .prdata        ( apb_rdata_vector[0] ),
         .apb_addr      ( {2'h0, apb_addr}    ),
         .apb_wr        ( apb_wr              ),
         .apb_rd        ( apb_rd              ),
         .apb_wdata     ( apb_wdata           ),
// Tx DESC
         .pready_td     ( apb_ready_vector[4] ), // Note: so far TxDesc mapped into separate area and separate controller
         .prdata_td     ( apb_rdata_vector[4] ),
// Settings
         .speed_mode    ( speed_mode          ),
         .minlr         ( minlr               ),
         .maxlr         ( maxlr               ),
         .ifg           ( ifg                 ),
         .duplex_mode   ( duplex_mode         ),
         .attlim        ( attlim              ),
         .mac_addr      ( mac_addr            ),
// TX
         .tx_clk        ( tx_clk              ),
         .tx_reset_n    ( tx_reset_n_sync     ),
         .tx_en         ( tx_en               ),
         .tx_er         ( tx_er               ),
         .txd           ( txd                 ),
         .crs           ( crs                 ),
         .col           ( col                 ),
// Frame buffer interface
         .w_clk         ( w_clk               ),
         .w_reset_n     ( w_reset_n_sync      ),
         .w_rd          ( w_rd                ),
         .w_addr        ( w_addr[31:0]        ),
         .w_data        ( w_data              ),
         .w_data_fc     ( w_data_fc           ),
         .w_rd_fc       ( w_rd_fc             ),
         .w_addr_fc     ( w_addr_fc           ),
// Flow control
         .fcvr          ( fcvr                ),
         .tx_req_pulse  ( tx_req_pulse        ),
         .tx_req_pulse0 ( tx_req_pulse0       ),
         .tx_inhibit    ( tx_inhibit          )
      );
      assign w_addr[63:32] = tx_desc_addr_msb;
   end
   else
   begin : no_tx
      assign apb_ready_vector[0] = 1'b1;
      assign apb_rdata_vector[0] = 32'h0;
      assign w_rd = 1'b0;
      assign w_addr = 64'h0;
   end
//===================================
// 6) Flow Control Core
//===================================
   if(FC_ENA)
   begin : fc
      ehl_emac_fc
      #(
         .RX_DESCR_COUNT ( RX_DESCR_COUNT ),
         .DATA_WIDTH     ( DATA_WIDTH     )
      ) fc_inst
      (
         .fc_enable        ( fc_enable        ),
         .duplex_mode      ( duplex_mode      ),
         .speed_mode       ( speed_mode       ),
      // receive domain
         .rx_clk           ( rx_clk           ),
         .rx_reset_n       ( rx_reset_n_sync  ),
         .fc_received      ( fc_received      ),
         .fc_rx_value      ( fc_rx_value      ),
         .fcllr            ( fcllr            ),
         .fchlr            ( fchlr            ),
         .rx_buffer_status ( rx_buffer_status ),
      // transmit domain
         .tx_clk           ( tx_clk           ),
         .tx_reset_n       ( tx_reset_n_sync  ),
         .fc_transmit      ( fc_transmit      ),
         .fc_tx_value      ( fc_tx_value      ),
         .fcvr             ( fcvr             ), // Q: what for this register made? for Upper bound only? as lower should be 0-filled automatically
         .tx_inhibit       ( tx_inhibit       ),
         .tx_req_pulse     ( tx_req_pulse     ),
         .tx_req_pulse0    ( tx_req_pulse0    ),
      // ROM
         .w_clk            ( w_clk            ),
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

endmodule
