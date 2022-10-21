// Design:           DDR4/3/2 PHY IO cells behavioral Library
// Revision:         1.1
// Date:             2020-07-25
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2017-02-02 A.Kornukhin: initial release
//                   1.1 2020-07-25 A.Kornukhin: 'SDRAM_WIDTH' renamed to 'RAM_WIDTH' due to issues with simulators
//                       that redefines parameters by name rather than actual connection

// TODO: add retention cells on CKE (JESD79-2F 3.10 / JESD79-3F 4.16), RESET_N (JESD79-3F 4.16)
//       as reset_n driver externally with CMOS, it will not be powered down here

module ehl_sstl
#(
   parameter RAM_WIDTH = 32,
   RANK_CNT = 4,
   TECHNOLOGY = 0,
   VREF_CNT = 2
)
(
   input                                   sdram_ck_di,
                                           sdram_ck_oe,
   output                                  sdram_ck,
   input                                   sdram_ck_n_di,
   output                                  sdram_ck_n,

   input [RANK_CNT-1:0]                    sdram_cke_di,
                                           sdram_cke_oe,
   output [RANK_CNT-1:0]                   sdram_cke,

   input [RANK_CNT-1:0]                    sdram_cs_n_di,
                                           sdram_cs_n_oe,
   output [RANK_CNT-1:0]                   sdram_cs_n,

   input                                   sdram_we_n_di,
                                           sdram_we_n_oe,
   output                                  sdram_we_n,

   input                                   sdram_ras_n_di,
                                           sdram_ras_n_oe,
   output                                  sdram_ras_n,

   input                                   sdram_cas_n_di,
                                           sdram_cas_n_oe,
   output                                  sdram_cas_n,

   input                                   sdram_act_n_di,
                                           sdram_act_n_oe,
   output                                  sdram_act_n,

   input [2:0]                             sdram_cid_di,
                                           sdram_cid_oe,
   output [2:0]                            sdram_cid,

   input [1:0]                             sdram_bg_di,
                                           sdram_bg_oe,
   output [1:0]                            sdram_bg,

   input                                   sdram_par_di,
                                           sdram_par_oe,
   output                                  sdram_par,

   input [2:0]                             sdram_ba_di,
                                           sdram_ba_oe,
   output [2:0]                            sdram_ba,

   input [15:0]                            sdram_a_di,
                                           sdram_a_oe,
   output [15:0]                           sdram_a,

   input [RANK_CNT-1:0]                    sdram_odt_di,
                                           sdram_odt_oe,
   output [RANK_CNT-1:0]                   sdram_odt,

   input [RAM_WIDTH / 8-1:0]               sdram_dm_di,
                                           sdram_dm_oe,
   output [RAM_WIDTH / 8-1:0]              sdram_dm,

   input [RAM_WIDTH / 8-1:0]               sdram_dqs_di,
                                           sdram_dqs_oe,
   output [RAM_WIDTH / 8-1:0]              sdram_dqs_do,
   inout [RAM_WIDTH / 8-1:0]               sdram_dqs,

   input [RAM_WIDTH / 8-1:0]               sdram_dqs_n_di,
   output [RAM_WIDTH / 8-1:0]              sdram_dqs_n_do,
   inout [RAM_WIDTH / 8-1:0]               sdram_dqs_n,

   input [RAM_WIDTH-1:0]                   sdram_dq_di,
                                           sdram_dq_oe,
   output [RAM_WIDTH-1:0]                  sdram_dq_do,
   inout [RAM_WIDTH-1:0]                   sdram_dq,

   inout                                   vref,

`ifdef __io_spice__
   input                                   vdd,
                                           gnd,
                                           pvdd,
                                           pgnd,
`endif
   input                                   pwd,
   input                                   enable_dqs,
   input [1:0]                             odt,
   input                                   dm_off_state,
// test connectivity
// Note: test bits connectivity order can be changed based on IO placement, alternatively order of input connections can be changed with indexes preserved
// Note: for DIFFERENTIAL PADS test_oe, loopback, and test_dv are scalars - so only lowest bit is used internally
   input                                   test_mode,
   input [RANK_CNT*3+RAM_WIDTH/8*11+30:0]  test_di,
   output [RANK_CNT*3+RAM_WIDTH/8*11+30:0] test_do,
   input [RANK_CNT*3+RAM_WIDTH/8*11+30:0]  test_dv,
   input [RANK_CNT*3+RAM_WIDTH/8*11+30:0]  test_oe,
   input [RANK_CNT*3+RAM_WIDTH/8*11+30:0]  loopback
);
// IO order in test chain map:
//  1                                          :  0                                       sdram_ck/sdram_ck_n
//                                                2                                       sdram_we_n
//                                                3                                       sdram_ras_n
//                                                4                                       sdram_cas_n
//  7                                          :  5                                       sdram_ba
// 23                                          :  8                                       sdram_a
// 24+RANK_CNT-1                               : 24                                       sdram_cke
// 24+2*RANK_CNT-1                             : 24+RANK_CNT                              sdram_cs_n
// 24+3*RANK_CNT-1                             : 24+2*RANK_CNT                            sdram_odt
// 24+3*RANK_CNT+RAM_WIDTH/8-1                 : 24+3*RANK_CNT                            sdram_dm
// 24+3*RANK_CNT+RAM_WIDTH/8+RAM_WIDTH-1       : 24+3*RANK_CNT+RAM_WIDTH/8                sdram_dq
// 24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH-1     : 24+3*RANK_CNT+RAM_WIDTH/8+RAM_WIDTH      sdram_dqs/sdram_dqs_n
//                                               24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH    sdram_act_n
// 24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+1     : 24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+3  sdram_cid
// 24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+4     : 24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+5  sdram_bg
//                                               24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+6  sdram_par
   tri vref_wire;
//=========================
// CK
//=========================
   ehl_ddr_sstl_dpad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_ck_inst (
`ifdef __io_spice__
      .vdd       ( vdd           ),
      .gnd       ( gnd           ),
      .pvdd      ( pvdd          ),
      .pgnd      ( pgnd          ),
`endif
      .oe        ( sdram_ck_oe   ),
      .datp      ( sdram_ck_di   ),
      .padp      ( sdram_ck      ),
      .vref      ( vref_wire     ),
      .diff      ( 1'b0          ), // Note: this is output only PAD. there is no need in DIFF mode.
      .datm      ( sdram_ck_n_di ),
      .padm      ( sdram_ck_n    ),
      .yp        (               ),
      .ym        (               ),
      .odt       ( 2'b00         ),
      .pwd       ( pwd           ),
      .test_oe   ( test_oe[0]    ), // Note test_oe[1] unused
      .test_di   ( test_di[1:0]  ),
      .test_mode ( test_mode     ),
      .loopback  ( loopback[0]   ), // Note: loopback[1] unused
      .test_dv   ( test_dv[0]    ), // Note: test_dv[1] unused
      .test_do   ( test_do[1:0]  )
   );
//=========================
// CKE
//=========================
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_cke_inst [RANK_CNT-1:0] (
`ifdef __io_spice__
      .vdd       ( vdd                      ),
      .gnd       ( gnd                      ),
      .pvdd      ( pvdd                     ),
      .pgnd      ( pgnd                     ),
`endif
      .oe        ( sdram_cke_oe             ),
      .dat       ( sdram_cke_di             ),
      .pad       ( sdram_cke                ),
      .y         (                          ),
      .vref      ( vref_wire                ),
      .odt       ( 2'b00                    ),
      .pwd       ( 1'b0                     ), // Note: CKE is not turned OFF, as its' value must be provided even in Self-Refresh
      .test_oe   ( test_oe[23+RANK_CNT:24]  ),
      .test_di   ( test_di[23+RANK_CNT:24]  ),
      .test_mode ( test_mode                ),
      .loopback  ( loopback[23+RANK_CNT:24] ),
      .test_dv   ( test_dv[23+RANK_CNT:24]  ),
      .test_do   ( test_do[23+RANK_CNT:24]  )
   );
//=========================
// CS_n
//=========================
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_cs_n_inst [RANK_CNT-1:0] (
`ifdef __io_spice__
      .vdd       ( vdd                                 ),
      .gnd       ( gnd                                 ),
      .pvdd      ( pvdd                                ),
      .pgnd      ( pgnd                                ),
`endif
      .oe        ( sdram_cs_n_oe                       ),
      .dat       ( sdram_cs_n_di                       ),
      .pad       ( sdram_cs_n                          ),
      .y         (                                     ),
      .vref      ( vref_wire                           ),
      .odt       ( 2'b00                               ),
      .pwd       ( pwd                                 ),
      .test_oe   ( test_oe[23+2*RANK_CNT:24+RANK_CNT]  ),
      .test_di   ( test_di[23+2*RANK_CNT:24+RANK_CNT]  ),
      .test_mode ( test_mode                           ),
      .loopback  ( loopback[23+2*RANK_CNT:24+RANK_CNT] ),
      .test_dv   ( test_dv[23+2*RANK_CNT:24+RANK_CNT]  ),
      .test_do   ( test_do[23+2*RANK_CNT:24+RANK_CNT]  )
   );
//=========================
// ODT
//=========================
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_odt_inst [RANK_CNT-1:0] (
`ifdef __io_spice__
      .vdd       ( vdd                                   ),
      .gnd       ( gnd                                   ),
      .pvdd      ( pvdd                                  ),
      .pgnd      ( pgnd                                  ),
`endif
      .oe        ( sdram_odt_oe                          ),
      .dat       ( sdram_odt_di                          ),
      .pad       ( sdram_odt                             ),
      .y         (                                       ),
      .vref      ( vref_wire                             ),
      .odt       ( 2'b00                                 ),
      .pwd       ( pwd                                   ),
      .test_oe   ( test_oe[23+3*RANK_CNT:24+2*RANK_CNT]  ),
      .test_di   ( test_di[23+3*RANK_CNT:24+2*RANK_CNT]  ),
      .test_mode ( test_mode                             ),
      .loopback  ( loopback[23+3*RANK_CNT:24+2*RANK_CNT] ),
      .test_dv   ( test_dv[23+3*RANK_CNT:24+2*RANK_CNT]  ),
      .test_do   ( test_do[23+3*RANK_CNT:24+2*RANK_CNT]  )
   );
//=========================
// WE_n
//=========================
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_we_n_inst (
`ifdef __io_spice__
      .vdd       ( vdd           ),
      .gnd       ( gnd           ),
      .pvdd      ( pvdd          ),
      .pgnd      ( pgnd          ),
`endif
      .oe        ( sdram_we_n_oe ),
      .dat       ( sdram_we_n_di ),
      .pad       ( sdram_we_n    ),
      .y         (               ),
      .vref      ( vref_wire     ),
      .odt       ( 2'b00         ),
      .pwd       ( pwd           ),
      .test_oe   ( test_oe[2]    ),
      .test_di   ( test_di[2]    ),
      .test_mode ( test_mode     ),
      .loopback  ( loopback[2]   ),
      .test_dv   ( test_dv[2]    ),
      .test_do   ( test_do[2]    )
   );
//=========================
// RAS_n
//=========================
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_ras_n_inst (
`ifdef __io_spice__
      .vdd       ( vdd            ),
      .gnd       ( gnd            ),
      .pvdd      ( pvdd           ),
      .pgnd      ( pgnd           ),
`endif
      .oe        ( sdram_ras_n_oe ),
      .dat       ( sdram_ras_n_di ),
      .pad       ( sdram_ras_n    ),
      .y         (                ),
      .vref      ( vref_wire      ),
      .odt       ( 2'b00          ),
      .pwd       ( pwd            ),
      .test_oe   ( test_oe[3]     ),
      .test_di   ( test_di[3]     ),
      .test_mode ( test_mode      ),
      .loopback  ( loopback[3]    ),
      .test_dv   ( test_dv[3]     ),
      .test_do   ( test_do[3]     )
   );
//=========================
// CAS_n
//=========================
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_cas_n_inst (
`ifdef __io_spice__
      .vdd       ( vdd            ),
      .gnd       ( gnd            ),
      .pvdd      ( pvdd           ),
      .pgnd      ( pgnd           ),
`endif
      .oe        ( sdram_cas_n_oe ),
      .dat       ( sdram_cas_n_di ),
      .pad       ( sdram_cas_n    ),
      .y         (                ),
      .vref      ( vref_wire      ),
      .odt       ( 2'b00          ),
      .pwd       ( pwd            ),
      .test_oe   ( test_oe[4]     ),
      .test_di   ( test_di[4]     ),
      .test_mode ( test_mode      ),
      .loopback  ( loopback[4]    ),
      .test_dv   ( test_dv[4]     ),
      .test_do   ( test_do[4]     )
   );
//=========================
// ACT_n
//=========================
   ehl_ddr_sstl_pad io_act_n_inst (
      .oe        ( sdram_act_n_oe                                  ),
      .dat       ( sdram_act_n_di                                  ),
      .pad       ( sdram_act_n                                     ),
      .y         (                                                 ),
      .vref      ( vref_wire                                       ),
      .odt       ( 2'b00                                           ),
      .pwd       ( pwd                                             ),
      .test_oe   ( test_oe[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH]  ),
      .test_di   ( test_di[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH]  ),
      .test_mode ( test_mode                                       ),
      .loopback  ( loopback[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH] ),
      .test_dv   ( test_dv[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH]  ),
      .test_do   ( test_do[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH]  )
   );
//=========================
// CID
//=========================
   localparam CID_IDX = 24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+1;
   ehl_ddr_sstl_pad io_cid_inst[2:0]
   (
      .oe        ( sdram_cid_oe                ),
      .dat       ( sdram_cid_di                ),
      .pad       ( sdram_cid                   ),
      .y         (                             ),
      .vref      ( vref_wire                   ),
      .odt       ( 2'b00                       ),
      .pwd       ( pwd                         ),
      .test_oe   ( test_oe[CID_IDX+2:CID_IDX]  ),
      .test_di   ( test_di[CID_IDX+2:CID_IDX]  ),
      .test_mode ( test_mode                   ),
      .loopback  ( loopback[CID_IDX+2:CID_IDX] ),
      .test_dv   ( test_dv[CID_IDX+2:CID_IDX]  ),
      .test_do   ( test_do[CID_IDX+2:CID_IDX]  )
   );
//=========================
// BG
//=========================
   localparam BG_IDX = 24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+4;
   ehl_ddr_sstl_pad io_bg_inst[1:0]
   (
      .oe        ( sdram_bg_oe               ),
      .dat       ( sdram_bg_di               ),
      .pad       ( sdram_bg                  ),
      .y         (                           ),
      .vref      ( vref_wire                 ),
      .odt       ( 2'b00                     ),
      .pwd       ( pwd                       ),
      .test_oe   ( test_oe[BG_IDX+1:BG_IDX]  ),
      .test_di   ( test_di[BG_IDX+1:BG_IDX]  ),
      .test_mode ( test_mode                 ),
      .loopback  ( loopback[BG_IDX+1:BG_IDX] ),
      .test_dv   ( test_dv[BG_IDX+1:BG_IDX]  ),
      .test_do   ( test_do[BG_IDX+1:BG_IDX]  )
   );
//=========================
// PAR
//=========================
   ehl_ddr_sstl_pad io_par_inst (
      .oe        ( sdram_par_oe                                      ),
      .dat       ( sdram_par_di                                      ),
      .pad       ( sdram_par                                         ),
      .y         (                                                   ),
      .vref      ( vref_wire                                         ),
      .odt       ( 2'b00                                             ),
      .pwd       ( pwd                                               ),
      .test_oe   ( test_oe[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+6]  ),
      .test_di   ( test_di[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+6]  ),
      .test_mode ( test_mode                                         ),
      .loopback  ( loopback[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+6] ),
      .test_dv   ( test_dv[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+6]  ),
      .test_do   ( test_do[24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH+6]  )
   );
//=========================
// BA
//=========================
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_ba_inst[2:0] (
`ifdef __io_spice__
      .vdd       ( vdd           ),
      .gnd       ( gnd           ),
      .pvdd      ( pvdd          ),
      .pgnd      ( pgnd          ),
`endif
      .oe        ( sdram_ba_oe   ),
      .dat       ( sdram_ba_di   ),
      .pad       ( sdram_ba      ),
      .y         (               ),
      .vref      ( vref_wire     ),
      .odt       ( 2'b00         ),
      .pwd       ( pwd           ),
      .test_oe   ( test_oe[7:5]  ),
      .test_di   ( test_di[7:5]  ),
      .test_mode ( test_mode     ),
      .loopback  ( loopback[7:5] ),
      .test_dv   ( test_dv[7:5]  ),
      .test_do   ( test_do[7:5]  )
   );
//=========================
// A
//=========================
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_a_inst [15:0] (
`ifdef __io_spice__
      .vdd       ( vdd            ),
      .gnd       ( gnd            ),
      .pvdd      ( pvdd           ),
      .pgnd      ( pgnd           ),
`endif
      .oe        ( sdram_a_oe     ),
      .dat       ( sdram_a_di     ),
      .pad       ( sdram_a        ),
      .y         (                ),
      .vref      ( vref_wire      ),
      .odt       ( 2'b00          ),
      .pwd       ( pwd            ),
      .test_oe   ( test_oe[23:8]  ),
      .test_di   ( test_di[23:8]  ),
      .test_mode ( test_mode      ),
      .loopback  ( loopback[23:8] ),
      .test_dv   ( test_dv[23:8]  ),
      .test_do   ( test_do[23:8]  )
   );
//=========================
// DM
// Note: DM can be placed into 3-state, or keep "0" during inactive cycles
//=========================
   localparam DM_IDX = 24+3*RANK_CNT;
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) io_dm_inst[RAM_WIDTH/8-1:0] (
`ifdef __io_spice__
      .vdd       ( vdd                                        ),
      .gnd       ( gnd                                        ),
      .pvdd      ( pvdd                                       ),
      .pgnd      ( pgnd                                       ),
`endif
      .oe        ( sdram_dm_oe | ~{RAM_WIDTH/8{dm_off_state}} ),
      .dat       ( sdram_dm_di                                ),
      .pad       ( sdram_dm                                   ),
      .y         (                                            ),
      .vref      ( vref_wire                                  ),
      .odt       ( odt                                        ),
      .pwd       ( pwd                                        ),
      .test_oe   ( test_oe[DM_IDX+:RAM_WIDTH/8]               ),
      .test_di   ( test_di[DM_IDX+:RAM_WIDTH/8]               ),
      .test_mode ( test_mode                                  ),
      .loopback  ( loopback[DM_IDX+:RAM_WIDTH/8]              ),
      .test_dv   ( test_dv[DM_IDX+:RAM_WIDTH/8]               ),
      .test_do   ( test_do[DM_IDX+:RAM_WIDTH/8]               )
   );
//=========================
// DQ
//=========================
   localparam DQ_IDX = 24+3*RANK_CNT+RAM_WIDTH/8;
   ehl_ddr_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY ),
      .SIM_DELAY  ( 0          )
   ) io_dq_inst [RAM_WIDTH-1:0] (
`ifdef __io_spice__
      .vdd       ( vdd                        ),
      .gnd       ( gnd                        ),
      .pvdd      ( pvdd                       ),
      .pgnd      ( pgnd                       ),
`endif
      .oe        ( sdram_dq_oe                 ),
      .dat       ( sdram_dq_di                 ),
      .pad       ( sdram_dq                    ),
      .y         ( sdram_dq_do                 ),
      .vref      ( vref_wire                   ),
      .odt       ( odt                         ),
      .pwd       ( pwd                         ),
      .test_oe   ( test_oe[DQ_IDX+:RAM_WIDTH]  ),
      .test_di   ( test_di[DQ_IDX+:RAM_WIDTH]  ),
      .test_mode ( test_mode                   ),
      .loopback  ( loopback[DQ_IDX+:RAM_WIDTH] ),
      .test_dv   ( test_dv[DQ_IDX+:RAM_WIDTH]  ),
      .test_do   ( test_do[DQ_IDX+:RAM_WIDTH]  )
   );
//=========================
// DQS
//=========================
   wire [RAM_WIDTH/8-1:0] dqs_oe, dqs_lb, dqs_dv;
   localparam DQS_IDX = 24+3*RANK_CNT+RAM_WIDTH/8+RAM_WIDTH;
   ehl_ddr_sstl_dpad
   #(
      .TECHNOLOGY  ( TECHNOLOGY ),
      .SIM_DELAY_M ( 0          ), // ( gen_i ? 2800 : 1100 ),
      .SIM_DELAY_P ( 0          )  // ( gen_i ? 2800 : 1100 )
   ) io_dqs_inst [RAM_WIDTH/8-1:0] (
`ifdef __io_spice__
      .vdd       ( vdd                           ),
      .gnd       ( gnd                           ),
      .pvdd      ( pvdd                          ),
      .pgnd      ( pgnd                          ),
`endif
      .oe        ( sdram_dqs_oe                  ),
      .datp      ( sdram_dqs_di                  ),
      .padp      ( sdram_dqs                     ),
      .vref      ( vref_wire                     ),
      .diff      ( ~enable_dqs                   ),
      .datm      ( sdram_dqs_n_di                ),
      .padm      ( sdram_dqs_n                   ),
      .yp        ( sdram_dqs_do                  ),
      .ym        ( sdram_dqs_n_do                ),
      .odt       ( odt                           ),
      .pwd       ( pwd                           ),
      .test_oe   ( dqs_oe                        ), // Note: every other test_oe[+1] is unused
      .test_di   ( test_di[DQS_IDX+:RAM_WIDTH/4] ), // Q: how to test with 2 different inputs? i.e. why we need 2 same outputs to be driven?
      .test_mode ( test_mode                     ),
      .loopback  ( dqs_lb                        ), // Note: every other loopback[+1] is unused
      .test_dv   ( dqs_dv                        ), // Note: every other test_dv[+1] is unused
      .test_do   ( test_do[DQS_IDX+:RAM_WIDTH/4] )
   );
   genvar gen_i;
   for(gen_i =0; gen_i < RAM_WIDTH/8; gen_i = gen_i + 1)
   begin : remap
      assign dqs_oe[gen_i] = test_oe[DQS_IDX+2*gen_i];
      assign dqs_lb[gen_i] = loopback[DQS_IDX+2*gen_i];
      assign dqs_dv[gen_i] = test_dv[DQS_IDX+2*gen_i];
      // Note: unused inputs test_oe[DQS_IDX+2*gen_i+1], loopback[DQS_IDX+2*gen_i+1], test_dv[DQS_IDX+2*gen_i+1]
   end
//=========================
// VREF
//=========================
   ehl_vref_sstl_pad
   #(
      .TECHNOLOGY ( TECHNOLOGY )
   ) vref_inst [VREF_CNT-1:0] (
      .vref ( vref_wire ),
      .pwd  ( pwd       ),
      .apad ( vref      )
   );

endmodule
