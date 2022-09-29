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
   SLV15_MASK = 32'h00000000
)
(
   input                       hclk, hresetn,
// Inputs from master
   input [31:0]                haddr,
   input [1:0]                 htrans,
// Outputs to masters
   output reg [31:0]           om_hrdata,
   output reg                  om_hready,
   output reg [1:0]            om_hresp,
// Inputs to Slaves
   output reg [(SNUM+1)*2-1:0] os_htrans,
// Outputs from Slaves
   input [(SNUM+1)*32-1:0]     is_hrdata,
   input [(SNUM+1)-1:0]        is_hready,
   input [(SNUM+1)*2-1:0]      is_hresp
);
//============================================
// select which slave to access
// mask htrans to every output, other controls (except for write data) provided externally 1-to-SNUM
//============================================
   wire [SNUM:0] slv_sel; // MSB is default slave
   assign slv_sel[SNUM] = ~|slv_sel[SNUM-1:0];
   if(SNUM>0) assign slv_sel[0]  = (haddr & SLV0_MASK)  == SLV0_BASE;
   if(SNUM>1) assign slv_sel[1]  = (haddr & SLV1_MASK)  == SLV1_BASE;
   if(SNUM>2) assign slv_sel[2]  = (haddr & SLV2_MASK)  == SLV2_BASE;
   if(SNUM>3) assign slv_sel[3]  = (haddr & SLV3_MASK)  == SLV3_BASE;
   if(SNUM>4) assign slv_sel[4]  = (haddr & SLV4_MASK)  == SLV4_BASE;
   if(SNUM>5) assign slv_sel[5]  = (haddr & SLV5_MASK)  == SLV5_BASE;
   if(SNUM>6) assign slv_sel[6]  = (haddr & SLV6_MASK)  == SLV6_BASE;
   if(SNUM>7) assign slv_sel[7]  = (haddr & SLV7_MASK)  == SLV7_BASE;
   if(SNUM>8) assign slv_sel[8]  = (haddr & SLV8_MASK)  == SLV8_BASE;
   if(SNUM>9) assign slv_sel[9]  = (haddr & SLV9_MASK)  == SLV9_BASE;
   if(SNUM>10) assign slv_sel[10] = (haddr & SLV10_MASK) == SLV10_BASE;
   if(SNUM>11) assign slv_sel[11] = (haddr & SLV11_MASK) == SLV11_BASE;
   if(SNUM>12) assign slv_sel[12] = (haddr & SLV12_MASK) == SLV12_BASE;
   if(SNUM>13) assign slv_sel[13] = (haddr & SLV13_MASK) == SLV13_BASE;
   if(SNUM>14) assign slv_sel[14] = (haddr & SLV14_MASK) == SLV14_BASE;
   if(SNUM>15) assign slv_sel[15] = (haddr & SLV15_MASK) == SLV15_BASE;

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
//   assign os_hsel = slv_sel;

endmodule
