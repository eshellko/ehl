// Design:           AHB matrix
// Revision:         1.0
// Date:             2022-09-29
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-09-29 A.Kornukhin: initial release

module ehl_ahb_matrix
#(
   parameter SNUM = 8,
   MNUM = 8,
// Slave configuration
   SLV0_BASE  = 32'h00000000,
   SLV0_MASK  = 32'h00000000,
   SLV1_BASE  = 32'h00000000,
   SLV1_MASK  = 32'h00000000,
   SLV2_BASE  = 32'h00000000,
   SLV2_MASK  = 32'h00000000,
   SLV3_BASE  = 32'h00000000,
   SLV3_MASK  = 32'h00000000,
   SLV4_BASE  = 32'h00000000,
   SLV4_MASK  = 32'h00000000,
   SLV5_BASE  = 32'h00000000,
   SLV5_MASK  = 32'h00000000,
   SLV6_BASE  = 32'h00000000,
   SLV6_MASK  = 32'h00000000,
   SLV7_BASE  = 32'h00000000,
   SLV7_MASK  = 32'h00000000,
   SLV8_BASE  = 32'h00000000,
   SLV8_MASK  = 32'h00000000,
   SLV9_BASE  = 32'h00000000,
   SLV9_MASK  = 32'h00000000,
   SLV10_BASE = 32'h00000000,
   SLV10_MASK = 32'h00000000,
   SLV11_BASE = 32'h00000000,
   SLV11_MASK = 32'h00000000,
   SLV12_BASE = 32'h00000000,
   SLV12_MASK = 32'h00000000,
   SLV13_BASE = 32'h00000000,
   SLV13_MASK = 32'h00000000,
   SLV14_BASE = 32'h00000000,
   SLV14_MASK = 32'h00000000,
   SLV15_BASE = 32'h00000000,
   SLV15_MASK = 32'h00000000,
// Remapped Slave configuration
   RSLV0_BASE  = 32'h00000000,
   RSLV0_MASK  = 32'h00000000,
   RSLV1_BASE  = 32'h00000000,
   RSLV1_MASK  = 32'h00000000,
   RSLV2_BASE  = 32'h00000000,
   RSLV2_MASK  = 32'h00000000,
   RSLV3_BASE  = 32'h00000000,
   RSLV3_MASK  = 32'h00000000,
   RSLV4_BASE  = 32'h00000000,
   RSLV4_MASK  = 32'h00000000,
   RSLV5_BASE  = 32'h00000000,
   RSLV5_MASK  = 32'h00000000,
   RSLV6_BASE  = 32'h00000000,
   RSLV6_MASK  = 32'h00000000,
   RSLV7_BASE  = 32'h00000000,
   RSLV7_MASK  = 32'h00000000,
   RSLV8_BASE  = 32'h00000000,
   RSLV8_MASK  = 32'h00000000,
   RSLV9_BASE  = 32'h00000000,
   RSLV9_MASK  = 32'h00000000,
   RSLV10_BASE = 32'h00000000,
   RSLV10_MASK = 32'h00000000,
   RSLV11_BASE = 32'h00000000,
   RSLV11_MASK = 32'h00000000,
   RSLV12_BASE = 32'h00000000,
   RSLV12_MASK = 32'h00000000,
   RSLV13_BASE = 32'h00000000,
   RSLV13_MASK = 32'h00000000,
   RSLV14_BASE = 32'h00000000,
   RSLV14_MASK = 32'h00000000,
   RSLV15_BASE = 32'h00000000,
   RSLV15_MASK = 32'h00000000
)
(
   input wire                 hclk, hresetn,
// Inputs from master
   input wire [MNUM*32-1:0]   im_haddr,
   input wire [MNUM*2-1:0]    im_htrans,
   input wire [MNUM-1:0]      im_hwrite,
   input wire [MNUM*3-1:0]    im_hsize, im_hburst,
   input wire [MNUM*4-1:0]    im_hprot,
   input wire [MNUM*32-1:0]   im_hwdata,
   input wire [MNUM*SNUM-1:0] im_route, // allows (1) master to access selected slave - should be static (or modified when IDLE with gap)
   input wire                 remap, // 1 of 2 mapping modes: 0 - SLVx, 1 - RSLVx
// Outputs to masters
   output wire [MNUM*32-1:0]  om_hrdata,
   output wire [MNUM-1:0]     om_hready,
   output wire [MNUM*2-1:0]   om_hresp,
// Inputs to Slaves
   output wire [SNUM*32-1:0]  os_haddr,
   output wire [SNUM*2-1:0]   os_htrans,
   output wire [SNUM-1:0]     os_hwrite,
   output wire [SNUM*3-1:0]   os_hsize, os_hburst,
   output wire [SNUM*4-1:0]   os_hprot,
   output wire [SNUM*32-1:0]  os_hwdata,
   output wire [SNUM-1:0]     os_hsel,
// Outputs from Slaves
   input wire [SNUM*32-1:0]   is_hrdata,
   input wire [SNUM-1:0]      is_hready,
   input wire [SNUM*2-1:0]    is_hresp
);
   wire [1:0]  dflt_htrans;
   wire        dflt_hsel;
   wire        dflt_hready;
   wire [1:0]  dflt_hresp;
   wire [31:0] dflt_hrdata;

   wire [(SNUM+1)*32-1:0] s_haddr;
   assign os_haddr = s_haddr[SNUM*32-1:0]; // Note: signal not used by default slave
   wire [(SNUM+1)*2-1:0]  s_htrans;
   assign {dflt_htrans, os_htrans} = s_htrans;
   wire [(SNUM+1)-1:0]    s_hwrite;
   assign os_hwrite = s_hwrite[SNUM-1:0]; // Note: signal not used by default slave
   wire [(SNUM+1)*3-1:0]  s_hsize;
   assign os_hsize = s_hsize[SNUM*3-1:0]; // Note: signal not used by default slave
   wire [(SNUM+1)*3-1:0]  s_hburst;
   assign os_hburst = s_hburst[SNUM*3-1:0]; // Note: signal not used by default slave
   wire [(SNUM+1)*4-1:0]  s_hprot;
   assign os_hprot = s_hprot[SNUM*4-1:0]; // Note: signal not used by default slave
   wire [(SNUM+1)*32-1:0] s_hwdata;
   assign os_hwdata = s_hwdata[SNUM*32-1:0]; // Note: signal not used by default slave
   wire [(SNUM+1)-1:0]    s_hsel;
   assign {dflt_hsel, os_hsel} = s_hsel;

   wire [(SNUM+1)*32-1:0] s_hrdata = {dflt_hrdata, is_hrdata};
   wire [(SNUM+1)-1:0]    s_hready = {dflt_hready, is_hready};
   wire [(SNUM+1)*2-1:0]  s_hresp  = {dflt_hresp,  is_hresp};

   genvar gen_i, gen_o;
//============================================
// Input stage
//============================================
   // matrix of 'htrans'. Every master copies it's 'htrans'
   // to all slaves, but ties low incative htrans
   wire [(SNUM+1)*2-1:0] mst_htrans [2*MNUM-1:0];
   wire [2*MNUM-1:0]     slv_htrans [(SNUM+1)*2-1:0];

   wire [(SNUM+1)*32-1:0] int_hrdata;
   wire [(SNUM+1)*2-1:0]  int_hresp;

   wire [MNUM-1:0]       slv_hready [(SNUM+1)*1-1:0];
   wire [(SNUM+1)*1-1:0] mst_hready [MNUM-1:0];

   genvar gen_j;
   for(gen_i = 0; gen_i < MNUM; gen_i = gen_i + 1)
   begin : instage
      ehl_ahb_matrix_in
      #(
         .SNUM        ( SNUM        ),
         .SLV0_BASE   ( SLV0_BASE   ),
         .SLV0_MASK   ( SLV0_MASK   ),
         .SLV1_BASE   ( SLV1_BASE   ),
         .SLV1_MASK   ( SLV1_MASK   ),
         .SLV2_BASE   ( SLV2_BASE   ),
         .SLV2_MASK   ( SLV2_MASK   ),
         .SLV3_BASE   ( SLV3_BASE   ),
         .SLV3_MASK   ( SLV3_MASK   ),
         .SLV4_BASE   ( SLV4_BASE   ),
         .SLV4_MASK   ( SLV4_MASK   ),
         .SLV5_BASE   ( SLV5_BASE   ),
         .SLV5_MASK   ( SLV5_MASK   ),
         .SLV6_BASE   ( SLV6_BASE   ),
         .SLV6_MASK   ( SLV6_MASK   ),
         .SLV7_BASE   ( SLV7_BASE   ),
         .SLV7_MASK   ( SLV7_MASK   ),
         .SLV8_BASE   ( SLV8_BASE   ),
         .SLV8_MASK   ( SLV8_MASK   ),
         .SLV9_BASE   ( SLV9_BASE   ),
         .SLV9_MASK   ( SLV9_MASK   ),
         .SLV10_BASE  ( SLV10_BASE  ),
         .SLV10_MASK  ( SLV10_MASK  ),
         .SLV11_BASE  ( SLV11_BASE  ),
         .SLV11_MASK  ( SLV11_MASK  ),
         .SLV12_BASE  ( SLV12_BASE  ),
         .SLV12_MASK  ( SLV12_MASK  ),
         .SLV13_BASE  ( SLV13_BASE  ),
         .SLV13_MASK  ( SLV13_MASK  ),
         .SLV14_BASE  ( SLV14_BASE  ),
         .SLV14_MASK  ( SLV14_MASK  ),
         .SLV15_BASE  ( SLV15_BASE  ),
         .SLV15_MASK  ( SLV15_MASK  ),
         .RSLV0_BASE  ( RSLV0_BASE  ),
         .RSLV0_MASK  ( RSLV0_MASK  ),
         .RSLV1_BASE  ( RSLV1_BASE  ),
         .RSLV1_MASK  ( RSLV1_MASK  ),
         .RSLV2_BASE  ( RSLV2_BASE  ),
         .RSLV2_MASK  ( RSLV2_MASK  ),
         .RSLV3_BASE  ( RSLV3_BASE  ),
         .RSLV3_MASK  ( RSLV3_MASK  ),
         .RSLV4_BASE  ( RSLV4_BASE  ),
         .RSLV4_MASK  ( RSLV4_MASK  ),
         .RSLV5_BASE  ( RSLV5_BASE  ),
         .RSLV5_MASK  ( RSLV5_MASK  ),
         .RSLV6_BASE  ( RSLV6_BASE  ),
         .RSLV6_MASK  ( RSLV6_MASK  ),
         .RSLV7_BASE  ( RSLV7_BASE  ),
         .RSLV7_MASK  ( RSLV7_MASK  ),
         .RSLV8_BASE  ( RSLV8_BASE  ),
         .RSLV8_MASK  ( RSLV8_MASK  ),
         .RSLV9_BASE  ( RSLV9_BASE  ),
         .RSLV9_MASK  ( RSLV9_MASK  ),
         .RSLV10_BASE ( RSLV10_BASE ),
         .RSLV10_MASK ( RSLV10_MASK ),
         .RSLV11_BASE ( RSLV11_BASE ),
         .RSLV11_MASK ( RSLV11_MASK ),
         .RSLV12_BASE ( RSLV12_BASE ),
         .RSLV12_MASK ( RSLV12_MASK ),
         .RSLV13_BASE ( RSLV13_BASE ),
         .RSLV13_MASK ( RSLV13_MASK ),
         .RSLV14_BASE ( RSLV14_BASE ),
         .RSLV14_MASK ( RSLV14_MASK ),
         .RSLV15_BASE ( RSLV15_BASE ),
         .RSLV15_MASK ( RSLV15_MASK )
      ) mux_inst
      (
         .hclk,
         .hresetn,

         .haddr     ( im_haddr[32*gen_i+:32]     ),
         .htrans    ( im_htrans[2*gen_i+:2]      ),

         .route     ( im_route[SNUM*gen_i+:SNUM] ),
         .remap,

         .om_hrdata ( om_hrdata[32*gen_i+:32]    ),
         .om_hready ( om_hready[gen_i]           ),
         .om_hresp  ( om_hresp[2*gen_i+:2]       ),

         .os_htrans ( mst_htrans[gen_i]          ),

         .is_hrdata ( int_hrdata                 ),
         .is_hready ( mst_hready[gen_i]          ),
         .is_hresp  ( int_hresp                  )
      );
      // Note: rotate matrix to provide vector to slave
      for(gen_j = 0; gen_j <= SNUM; gen_j = gen_j + 1)
      begin : remap
         assign slv_htrans [gen_j] [2*gen_i+:2] = mst_htrans [gen_i] [gen_j*2+:2];
      end
   end
//============================================
// Output stage
//============================================
   for(gen_o = 0; gen_o <= SNUM; gen_o = gen_o + 1)
   begin : outstage
      ehl_ahb_matrix_out
      #(
         .MNUM ( MNUM )
      ) mux_inst
      (
         .hclk,
         .hresetn,

         .im_haddr  ( im_haddr                 ),
         .im_htrans ( slv_htrans[gen_o]        ),
         .im_hwrite ( im_hwrite                ),
         .im_hsize  ( im_hsize                 ),
         .im_hburst ( im_hburst                ),
         .im_hprot  ( im_hprot                 ),
         .im_hwdata ( im_hwdata                ),

         .om_hrdata ( int_hrdata[gen_o*32+:32] ),
         .om_hready ( slv_hready[gen_o]        ),
         .om_hresp  ( int_hresp[gen_o*2+:2]    ),

         .os_haddr  ( s_haddr[32*gen_o+:32]    ),
         .os_htrans ( s_htrans[2*gen_o+:2]     ),
         .os_hwrite ( s_hwrite[gen_o]          ),
         .os_hsize  ( s_hsize[3*gen_o+:3]      ),
         .os_hburst ( s_hburst[3*gen_o+:3]     ),
         .os_hprot  ( s_hprot[4*gen_o+:4]      ),
         .os_hwdata ( s_hwdata[32*gen_o+:32]   ),
         .os_hsel   ( s_hsel[gen_o]            ),

         .is_hrdata ( s_hrdata[32*gen_o+:32]   ),
         .is_hready ( s_hready[gen_o]          ),
         .is_hresp  ( s_hresp[2*gen_o+:2]      )
      );
      // Note: rotate matrix to provide vector to master
      for(gen_j = 0; gen_j < MNUM; gen_j = gen_j + 1)
      begin : remap
         assign mst_hready [gen_j] [gen_o] = slv_hready [gen_o] [gen_j];
      end
   end
//============================================
// default slave
//============================================
   ehl_ahb_default_slave dflt_slv_inst
   (
      .hclk,
      .hresetn,
      .htrans     ( dflt_htrans ),
      .hsel       ( dflt_hsel   ),
      .hready_in  ( dflt_hready ),
      .hready     ( dflt_hready ),
      .hresp      ( dflt_hresp  ),
      .hrdata     ( dflt_hrdata ),

      .resp_delay ( 8'h0        ),
      .resp_val   ( 1'b1        )
   );
//=======================
// Config checker
//=======================
`ifndef SYNTHESIS
   initial
   begin
      if(SNUM > 16 || SNUM < 1)
      begin
         $display("   Error: '%m' incorrect value %d of parameter SNUM (1..16).", SNUM);
         $finish;
      end
      if(MNUM > 16 || MNUM < 1)
      begin
         $display("   Error: '%m' incorrect value %d of parameter MNUM (1..16).", MNUM);
         $finish;
      end
   end

   reg [31:0] slv_base [15:0];
   reg [31:0] slv_mask [15:0];
   integer si;
   integer si2;
   reg [31:0] tmp;
   reg [31:0] init1, init2;
   reg [31:0] fini1, fini2;
   initial
   begin
      slv_base[0] = SLV0_BASE;   slv_mask[0] = SLV0_MASK;
      slv_base[1] = SLV1_BASE;   slv_mask[1] = SLV1_MASK;
      slv_base[2] = SLV2_BASE;   slv_mask[2] = SLV2_MASK;
      slv_base[3] = SLV3_BASE;   slv_mask[3] = SLV3_MASK;
      slv_base[4] = SLV4_BASE;   slv_mask[4] = SLV4_MASK;
      slv_base[5] = SLV5_BASE;   slv_mask[5] = SLV5_MASK;
      slv_base[6] = SLV6_BASE;   slv_mask[6] = SLV6_MASK;
      slv_base[7] = SLV7_BASE;   slv_mask[7] = SLV7_MASK;
      slv_base[8] = SLV8_BASE;   slv_mask[8] = SLV8_MASK;
      slv_base[9] = SLV9_BASE;   slv_mask[9] = SLV9_MASK;
      slv_base[10] = SLV10_BASE; slv_mask[10] = SLV10_MASK;
      slv_base[11] = SLV11_BASE; slv_mask[11] = SLV11_MASK;
      slv_base[12] = SLV12_BASE; slv_mask[12] = SLV12_MASK;
      slv_base[13] = SLV13_BASE; slv_mask[13] = SLV13_MASK;
      slv_base[14] = SLV14_BASE; slv_mask[14] = SLV14_MASK;
      slv_base[15] = SLV15_BASE; slv_mask[15] = SLV15_MASK;

      for(si = 0; si < SNUM; si = si + 1)
      begin
         tmp = slv_mask[si];
         for(si2 = 30; si2 >= 0; si2 = si2 - 1)
         begin
            if(!tmp[si2+1] && tmp[si2]) // 01 is an error
            begin
               $display("   Error: '%m' incorrect value 0x%x of x_MASK parameter - continouos list of MSB ones is expected.", tmp);
               $finish;
            end
         end
         init1 = slv_base[si]  & slv_mask[si];
         fini1 = slv_base[si] | ~slv_mask[si];

         for(si2 = si + 1; si2 < SNUM; si2 = si2 + 1)
         begin
            init2 = slv_base[si2] & slv_mask[si2];
            fini2 = slv_base[si2] | ~slv_mask[si2];
            // address range overlaps another range
            if(
               ( (init1 <= init2) && (fini1 >= init2) ) ||
               ( (init1 <= fini2) && (fini1 >= fini2) )
            )
            begin
               $display("   Error: '%m' overlapping AHB area configuration for slaves %0d and %0d ([%x:%x] v [%x:%x]).", si, si2, slv_base[si] | ~slv_mask[si], slv_base[si] & slv_mask[si], slv_base[si2] | ~slv_mask[si2], slv_base[si2] & slv_mask[si2]);
               $finish;
            end
         end
      end

      slv_base[0] = RSLV0_BASE;   slv_mask[0] = RSLV0_MASK;
      slv_base[1] = RSLV1_BASE;   slv_mask[1] = RSLV1_MASK;
      slv_base[2] = RSLV2_BASE;   slv_mask[2] = RSLV2_MASK;
      slv_base[3] = RSLV3_BASE;   slv_mask[3] = RSLV3_MASK;
      slv_base[4] = RSLV4_BASE;   slv_mask[4] = RSLV4_MASK;
      slv_base[5] = RSLV5_BASE;   slv_mask[5] = RSLV5_MASK;
      slv_base[6] = RSLV6_BASE;   slv_mask[6] = RSLV6_MASK;
      slv_base[7] = RSLV7_BASE;   slv_mask[7] = RSLV7_MASK;
      slv_base[8] = RSLV8_BASE;   slv_mask[8] = RSLV8_MASK;
      slv_base[9] = RSLV9_BASE;   slv_mask[9] = RSLV9_MASK;
      slv_base[10] = RSLV10_BASE; slv_mask[10] = RSLV10_MASK;
      slv_base[11] = RSLV11_BASE; slv_mask[11] = RSLV11_MASK;
      slv_base[12] = RSLV12_BASE; slv_mask[12] = RSLV12_MASK;
      slv_base[13] = RSLV13_BASE; slv_mask[13] = RSLV13_MASK;
      slv_base[14] = RSLV14_BASE; slv_mask[14] = RSLV14_MASK;
      slv_base[15] = RSLV15_BASE; slv_mask[15] = RSLV15_MASK;

      for(si = 0; si < SNUM; si = si + 1)
      begin
         tmp = slv_mask[si];
         for(si2 = 30; si2 >= 0; si2 = si2 - 1)
         begin
            if(!tmp[si2+1] && tmp[si2]) // 01 is an error
            begin
               $display("   Error: '%m' incorrect value 0x%x of remapped x_MASK parameter - continouos list of MSB ones is expected.", tmp);
               $finish;
            end
         end
         init1 = slv_base[si]  & slv_mask[si];
         fini1 = slv_base[si] | ~slv_mask[si];

         for(si2 = si + 1; si2 < SNUM; si2 = si2 + 1)
         begin
            init2 = slv_base[si2] & slv_mask[si2];
            fini2 = slv_base[si2] | ~slv_mask[si2];
            // address range overlaps another range
            if(
               ( (init1 <= init2) && (fini1 >= init2) ) ||
               ( (init1 <= fini2) && (fini1 >= fini2) )
            )
            begin
               $display("   Error: '%m' overlapping AHB area configuration for remapping slaves %0d and %0d ([%x:%x] v [%x:%x]).", si, si2, slv_base[si] | ~slv_mask[si], slv_base[si] & slv_mask[si], slv_base[si2] | ~slv_mask[si2], slv_base[si2] & slv_mask[si2]);
               $finish;
            end
         end
      end
   end
`ifndef ICARUS
   always@(posedge hclk)
   if(hresetn)
   if($countones(s_hready) < (SNUM-1))
      $display("   Error: '%m' more than 1 (%0d) 'is_hready' de-asserted at %0t.", SNUM - $countones(is_hready), $time);
`endif
`endif
endmodule
