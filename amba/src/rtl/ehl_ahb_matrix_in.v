// Design:           AHB maxtrix input stage
// Revision:         1.0
// Date:             2022-09-29
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-09-29 A.Kornukhin: initial release

module ehl_ahb_matrix_in
#(
   parameter SNUM = 8,
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
// Slave configuration
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
   input wire                   hclk, hresetn,
// Inputs from master
   input wire [31:0]            haddr,
   input wire [1:0]             htrans,
   input wire [SNUM-1:0]        route,
   input wire                   remap,
// Outputs to masters
   output reg [31:0]            om_hrdata,
   output reg                   om_hready,
   output reg [1:0]             om_hresp,
// Inputs to Slaves
   output reg [(SNUM+1)*2-1:0]  os_htrans,
// Outputs from Slaves
   input wire [(SNUM+1)*32-1:0] is_hrdata,
   input wire [(SNUM+1)-1:0]    is_hready,
   input wire [(SNUM+1)*2-1:0]  is_hresp
);
//============================================
// select which slave to access
// mask htrans to every output, other controls (except for write data) provided externally 1-to-SNUM
//============================================
   wire [SNUM:0] slv_sel; // MSB is default slave
   wire [SNUM-1:0] slv_sel_raw;
   assign slv_sel[SNUM-1:0] = slv_sel_raw[SNUM-1:0] & route;
   assign slv_sel[SNUM] = ~|slv_sel[SNUM-1:0];
   if(SNUM>0)  assign slv_sel_raw[0]  = remap ? (haddr & RSLV0_MASK) == RSLV0_BASE : (haddr & SLV0_MASK)  == SLV0_BASE;
   if(SNUM>1)  assign slv_sel_raw[1]  = remap ? (haddr & RSLV1_MASK) == RSLV1_BASE : (haddr & SLV1_MASK)  == SLV1_BASE;
   if(SNUM>2)  assign slv_sel_raw[2]  = remap ? (haddr & RSLV2_MASK) == RSLV2_BASE : (haddr & SLV2_MASK)  == SLV2_BASE;
   if(SNUM>3)  assign slv_sel_raw[3]  = remap ? (haddr & RSLV3_MASK) == RSLV3_BASE : (haddr & SLV3_MASK)  == SLV3_BASE;
   if(SNUM>4)  assign slv_sel_raw[4]  = remap ? (haddr & RSLV4_MASK) == RSLV4_BASE : (haddr & SLV4_MASK)  == SLV4_BASE;
   if(SNUM>5)  assign slv_sel_raw[5]  = remap ? (haddr & RSLV5_MASK) == RSLV5_BASE : (haddr & SLV5_MASK)  == SLV5_BASE;
   if(SNUM>6)  assign slv_sel_raw[6]  = remap ? (haddr & RSLV6_MASK) == RSLV6_BASE : (haddr & SLV6_MASK)  == SLV6_BASE;
   if(SNUM>7)  assign slv_sel_raw[7]  = remap ? (haddr & RSLV7_MASK) == RSLV7_BASE : (haddr & SLV7_MASK)  == SLV7_BASE;
   if(SNUM>8)  assign slv_sel_raw[8]  = remap ? (haddr & RSLV8_MASK) == RSLV8_BASE : (haddr & SLV8_MASK)  == SLV8_BASE;
   if(SNUM>9)  assign slv_sel_raw[9]  = remap ? (haddr & RSLV9_MASK) == RSLV9_BASE : (haddr & SLV9_MASK)  == SLV9_BASE;
   if(SNUM>10) assign slv_sel_raw[10] = remap ? (haddr & RSLV10_MASK) == RSLV10_BASE : (haddr & SLV10_MASK) == SLV10_BASE;
   if(SNUM>11) assign slv_sel_raw[11] = remap ? (haddr & RSLV11_MASK) == RSLV11_BASE : (haddr & SLV11_MASK) == SLV11_BASE;
   if(SNUM>12) assign slv_sel_raw[12] = remap ? (haddr & RSLV12_MASK) == RSLV12_BASE : (haddr & SLV12_MASK) == SLV12_BASE;
   if(SNUM>13) assign slv_sel_raw[13] = remap ? (haddr & RSLV13_MASK) == RSLV13_BASE : (haddr & SLV13_MASK) == SLV13_BASE;
   if(SNUM>14) assign slv_sel_raw[14] = remap ? (haddr & RSLV14_MASK) == RSLV14_BASE : (haddr & SLV14_MASK) == SLV14_BASE;
   if(SNUM>15) assign slv_sel_raw[15] = remap ? (haddr & RSLV15_MASK) == RSLV15_BASE : (haddr & SLV15_MASK) == SLV15_BASE;

   reg [SNUM:0] slv_sel_cpt;
   always@(posedge hclk or negedge hresetn)
   if(!hresetn)
      slv_sel_cpt <= {SNUM+1{1'b0}};
   // when access required by master, it is captured, until new non-interrupted requst
   else
   begin
      if(slv_sel_cpt & is_hready) // slave completed
         slv_sel_cpt <= {SNUM+1{1'b0}};
      if(htrans && om_hready) // New transaction has higher priority
         slv_sel_cpt <= slv_sel;
   end

   // route responses
   integer i;
   always@*
   begin
      om_hready = 1'b1;
      om_hrdata = 32'h0;
      om_hresp  = 2'h0;

      for(i=0; i<=SNUM; i=i+1)
      begin
         if(slv_sel_cpt[i])
         begin
            om_hready = is_hready[i];
            om_hrdata = is_hrdata[32*i+:32];
            om_hresp  = is_hresp[2*i+:2];
         end
      end
   end

   integer j;
   always@*
   begin
      os_htrans = {SNUM+1{2'h0}};
      for(j=0; j<=SNUM; j=j+1)
         if(slv_sel[j])
            os_htrans[j*2+:2] = htrans;
   end

endmodule
