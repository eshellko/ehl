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
// test connectivity
// Note: test bits connectivity order can be changed based on IO placement, alternatively order of input connections can be changed with indexes preserved
// Note: for DIFFERENTIAL PADS test_oe, loopback, and test_dv are scalars - so only lowest bit is used internally
   input                                   test_mode,
   input [RANK_CNT*3+RAM_WIDTH/8*11+23:0]  test_di,
   output [RANK_CNT*3+RAM_WIDTH/8*11+23:0] test_do,
   input [RANK_CNT*3+RAM_WIDTH/8*11+23:0]  test_dv,
   input [RANK_CNT*3+RAM_WIDTH/8*11+23:0]  test_oe,
   input [RANK_CNT*3+RAM_WIDTH/8*11+23:0]  loopback
);
// IO order in test chain:
//  1                                          :  0                                       sdram_ck/sdram_ck_n
//                                                2                                       sdram_we_n
//                                                3                                       sdram_ras_n
//                                                4                                       sdram_cas_n
//  7                                          :  5                                       sdram_ba
// 23                                          :  8                                       sdram_a
// 24+RANK_CNT-1                               : 24                                       sdram_cke
// 24+2*RANK_CNT-1                             : 24+RANK_CNT                              sdram_cs_n
// 24+3*RANK_CNT-1                             : 24+2*RANK_CNT                            sdram_odt
// 24+3*RANK_CNT+RAM_WIDTH/8-1               : 24+3*RANK_CNT                            sdram_dm
// 24+3*RANK_CNT+RAM_WIDTH/8+RAM_WIDTH-1   : 24+3*RANK_CNT+RAM_WIDTH/8              sdram_dq
// 24+3*RANK_CNT+3*RAM_WIDTH/8+RAM_WIDTH-1 : 24+3*RANK_CNT+RAM_WIDTH/8+RAM_WIDTH  sdram_dqs/sdram_dqs_n

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
   genvar gen_k;
//=========================
// CKE
//=========================
   for(gen_k=0; gen_k<RANK_CNT;gen_k=gen_k+1)
   begin : rank_loop
      ehl_ddr_sstl_pad
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      ) io_cke_inst (
`ifdef __io_spice__
         .vdd       ( vdd                 ),
         .gnd       ( gnd                 ),
         .pvdd      ( pvdd                ),
         .pgnd      ( pgnd                ),
`endif
         .oe        ( sdram_cke_oe[gen_k] ),
         .dat       ( sdram_cke_di[gen_k] ),
         .pad       ( sdram_cke[gen_k]    ),
         .y         (                     ),
         .vref      ( vref_wire           ),
         .odt       ( 2'b00               ),
         .pwd       ( 1'b0                ), // Note: CKE is not turned OFF, as its' value must be provided even in Self-Refresh
         .test_oe   ( test_oe[24+gen_k]   ),
         .test_di   ( test_di[24+gen_k]   ),
         .test_mode ( test_mode           ),
         .loopback  ( loopback[24+gen_k]  ),
         .test_dv   ( test_dv[24+gen_k]   ),
         .test_do   ( test_do[24+gen_k]   )
      );
//=========================
// CS_n
//=========================
      ehl_ddr_sstl_pad
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      ) io_cs_n_inst (
`ifdef __io_spice__
         .vdd       ( vdd                         ),
         .gnd       ( gnd                         ),
         .pvdd      ( pvdd                        ),
         .pgnd      ( pgnd                        ),
`endif
         .oe        ( sdram_cs_n_oe[gen_k]        ),
         .dat       ( sdram_cs_n_di[gen_k]        ),
         .pad       ( sdram_cs_n[gen_k]           ),
         .y         (                             ),
         .vref      ( vref_wire                   ),
         .odt       ( 2'b00                       ),
         .pwd       ( pwd                         ),
         .test_oe   ( test_oe[24+RANK_CNT+gen_k]  ),
         .test_di   ( test_di[24+RANK_CNT+gen_k]  ),
         .test_mode ( test_mode                   ),
         .loopback  ( loopback[24+RANK_CNT+gen_k] ),
         .test_dv   ( test_dv[24+RANK_CNT+gen_k]  ),
         .test_do   ( test_do[24+RANK_CNT+gen_k]  )
      );
//=========================
// ODT
//=========================
      ehl_ddr_sstl_pad
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      ) io_odt_inst (
`ifdef __io_spice__
         .vdd       ( vdd                           ),
         .gnd       ( gnd                           ),
         .pvdd      ( pvdd                          ),
         .pgnd      ( pgnd                          ),
`endif
         .oe        ( sdram_odt_oe[gen_k]           ),
         .dat       ( sdram_odt_di[gen_k]           ),
         .pad       ( sdram_odt[gen_k]              ),
         .y         (                               ),
         .vref      ( vref_wire                     ),
         .odt       ( 2'b00                         ),
         .pwd       ( pwd                           ),
         .test_oe   ( test_oe[24+2*RANK_CNT+gen_k]  ),
         .test_di   ( test_di[24+2*RANK_CNT+gen_k]  ),
         .test_mode ( test_mode                     ),
         .loopback  ( loopback[24+2*RANK_CNT+gen_k] ),
         .test_dv   ( test_dv[24+2*RANK_CNT+gen_k]  ),
         .test_do   ( test_do[24+2*RANK_CNT+gen_k]  )
      );
   end
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
   ehl_ddr_sstl_pad io_act_n_inst ( // TODO: add another STD pins -- bind them into test chain...
      .oe        ( sdram_act_n_oe ),
      .dat       ( sdram_act_n_di ),
      .pad       ( sdram_act_n    ),
      .y         (                )
   );
   genvar gen_cid;
   for(gen_cid=0; gen_cid<3; gen_cid=gen_cid+1)
   begin : cid_io_loop
//=========================
// CID
//=========================
      ehl_ddr_sstl_pad io_cid_inst ( // TODO: add another STD pins
         .oe  ( sdram_cid_oe[gen_cid] ),
         .dat ( sdram_cid_di[gen_cid] ),
         .pad ( sdram_cid[gen_cid]    ),
         .y   (                       )
      );
   end
   genvar gen_g;
   for(gen_g=0; gen_g<2; gen_g=gen_g+1)
   begin : bank_group_io_loop
//=========================
// BG
//=========================
      ehl_ddr_sstl_pad io_bg_inst ( // TODO: add another STD pins
         .oe        ( sdram_bg_oe[gen_g] ),
         .dat       ( sdram_bg_di[gen_g] ),
         .pad       ( sdram_bg[gen_g]    ),
         .y         (                    )
      );
   end
//=========================
// PAR
//=========================
   ehl_ddr_sstl_pad io_par_inst ( // TODO: add another STD pins
      .oe        ( sdram_par_oe ),
      .dat       ( sdram_par_di ),
      .pad       ( sdram_par    ),
      .y         (              )
   );
   genvar gen_b;
   for(gen_b=0; gen_b<3; gen_b=gen_b+1)
   begin : bank_io_loop
//=========================
// BA
//=========================
      ehl_ddr_sstl_pad
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      ) io_ba_inst (
`ifdef __io_spice__
         .vdd       ( vdd                ),
         .gnd       ( gnd                ),
         .pvdd      ( pvdd               ),
         .pgnd      ( pgnd               ),
`endif
         .oe        ( sdram_ba_oe[gen_b] ),
         .dat       ( sdram_ba_di[gen_b] ),
         .pad       ( sdram_ba[gen_b]    ),
         .y         (                    ),
         .vref      ( vref_wire          ),
         .odt       ( 2'b00              ),
         .pwd       ( pwd                ),
         .test_oe   ( test_oe[5+gen_b]   ),
         .test_di   ( test_di[5+gen_b]   ),
         .test_mode ( test_mode          ),
         .loopback  ( loopback[5+gen_b]  ),
         .test_dv   ( test_dv[5+gen_b]   ),
         .test_do   ( test_do[5+gen_b]   )
      );
   end
   genvar gen_a;
   for(gen_a=0; gen_a<16; gen_a=gen_a+1)
   begin : addr_io_loop
//=========================
// A
//=========================
      ehl_ddr_sstl_pad
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      ) io_a_inst (
`ifdef __io_spice__
         .vdd       ( vdd               ),
         .gnd       ( gnd               ),
         .pvdd      ( pvdd              ),
         .pgnd      ( pgnd              ),
`endif
         .oe        ( sdram_a_oe[gen_a] ),
         .dat       ( sdram_a_di[gen_a] ),
         .pad       ( sdram_a[gen_a]    ),
         .y         (                   ),
         .vref      ( vref_wire         ),
         .odt       ( 2'b00             ),
         .pwd       ( pwd               ),
         .test_oe   ( test_oe[8+gen_a]  ),
         .test_di   ( test_di[8+gen_a]  ),
         .test_mode ( test_mode         ),
         .loopback  ( loopback[8+gen_a] ),
         .test_dv   ( test_dv[8+gen_a]  ),
         .test_do   ( test_do[8+gen_a]  )
      );
   end
   genvar gen_i, gen_j;
   for(gen_i=0; gen_i<(RAM_WIDTH>>3); gen_i=gen_i+1)
   begin : io_loop
//=========================
// DM
// Note: DM can be placed into 3-state, or keep "0" during inactive cycles
//       Q: will "0" give less power?
`define __inactive_dm_dc__
//=========================
      ehl_ddr_sstl_pad
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      ) io_dm_inst (
`ifdef __io_spice__
         .vdd       ( vdd                           ),
         .gnd       ( gnd                           ),
         .pvdd      ( pvdd                          ),
         .pgnd      ( pgnd                          ),
`endif
`ifdef __inactive_dm_dc__
         .oe        ( 1'b1                          ),
`else
         .oe        ( sdram_dm_oe[gen_i]            ),
`endif
         .dat       ( sdram_dm_di[gen_i]            ),
         .pad       ( sdram_dm[gen_i]               ),
         .y         (                               ),
         .vref      ( vref_wire                     ),
         .odt       ( odt                           ),
         .pwd       ( pwd                           ),
         .test_oe   ( test_oe[24+3*RANK_CNT+gen_i]  ),
         .test_di   ( test_di[24+3*RANK_CNT+gen_i]  ),
         .test_mode ( test_mode                     ),
         .loopback  ( loopback[24+3*RANK_CNT+gen_i] ),
         .test_dv   ( test_dv[24+3*RANK_CNT+gen_i]  ),
         .test_do   ( test_do[24+3*RANK_CNT+gen_i]  )
      );
      for(gen_j=0; gen_j<8; gen_j=gen_j+1)
      begin : bit_loop
//=========================
// DQ
//=========================
         localparam IDX_DQ_LO = 24+3*RANK_CNT+RAM_WIDTH/8+gen_i*8+gen_j;
         ehl_ddr_sstl_pad
         #(
            .TECHNOLOGY ( TECHNOLOGY ),
            .SIM_DELAY  ( 0          ) // ( gen_j < 8 ? 2800 : 1100 )
         ) io_dq_inst (
`ifdef __io_spice__
            .vdd       ( vdd                        ),
            .gnd       ( gnd                        ),
            .pvdd      ( pvdd                       ),
            .pgnd      ( pgnd                       ),
`endif
            .oe        ( sdram_dq_oe[gen_i*8+gen_j] ),
            .dat       ( sdram_dq_di[gen_i*8+gen_j] ),
            .pad       ( sdram_dq[gen_i*8+gen_j]    ),
            .y         ( sdram_dq_do[gen_i*8+gen_j] ),
            .vref      ( vref_wire                  ),
            .odt       ( odt                        ),
            .pwd       ( pwd                        ),
            .test_oe   ( test_oe[IDX_DQ_LO]         ),
            .test_di   ( test_di[IDX_DQ_LO]         ),
            .test_mode ( test_mode                  ),
            .loopback  ( loopback[IDX_DQ_LO]        ),
            .test_dv   ( test_dv[IDX_DQ_LO]         ),
            .test_do   ( test_do[IDX_DQ_LO]         )
         );
      end
//=========================
// DQS
//=========================
      localparam IDX_DQS_LO = 24+3*RANK_CNT+RAM_WIDTH/8+RAM_WIDTH+gen_i*2;
      ehl_ddr_sstl_dpad
      #(
         .TECHNOLOGY  ( TECHNOLOGY ),
         .SIM_DELAY_M ( 0          ), // ( gen_i ? 2800 : 1100 ),
         .SIM_DELAY_P ( 0          ) // ( gen_i ? 2800 : 1100 )
      ) io_dqs_inst (
`ifdef __io_spice__
         .vdd       ( vdd                    ),
         .gnd       ( gnd                    ),
         .pvdd      ( pvdd                   ),
         .pgnd      ( pgnd                   ),
`endif
         .oe        ( sdram_dqs_oe[gen_i]    ),
         .datp      ( sdram_dqs_di[gen_i]    ),
         .padp      ( sdram_dqs[gen_i]       ),
         .vref      ( vref_wire              ),
         .diff      ( ~enable_dqs            ),
         .datm      ( sdram_dqs_n_di[gen_i]  ),
         .padm      ( sdram_dqs_n[gen_i]     ),
         .yp        ( sdram_dqs_do[gen_i]    ),
         .ym        ( sdram_dqs_n_do[gen_i]  ),
         .odt       ( odt                    ),
         .pwd       ( pwd                    ),
         .test_oe   ( test_oe[IDX_DQS_LO]    ), // Note: test_oe[IDX_DQS_LO+1] unused
         .test_di   ( test_di[IDX_DQS_LO+:2] ),
         .test_mode ( test_mode              ),
         .loopback  ( loopback[IDX_DQS_LO]   ), // Note: loopback[IDX_DQS_LO+1] unused
         .test_dv   ( test_dv[IDX_DQS_LO]    ), // Note: test_dv[IDX_DQS_LO+1] unused
         .test_do   ( test_do[IDX_DQS_LO+:2] )
      );
   end
//=========================
// VREF
//=========================
   genvar gen_v;
   for(gen_v = 0; gen_v < VREF_CNT; gen_v = gen_v + 1)
   begin : vref_loop
      ehl_vref_sstl_pad
      #(
         .TECHNOLOGY ( TECHNOLOGY )
      ) vref_inst (
         .vref ( vref_wire ),
         .pwd  ( pwd       ),
         .apad ( vref      )
      );
   end

endmodule
