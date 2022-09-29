// Design:           AHB matrix output stage
// Revision:         1.0
// Date:             2022-09-29
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-09-29 A.Kornukhin: initial release

module ehl_matrix_out
#(
   parameter MNUM = 8
)
(
   input                   hclk, hresetn,
// Inputs from master
   input [MNUM*32-1:0]     im_haddr,
   input [MNUM*2-1:0]      im_htrans,
   input [MNUM-1:0]        im_hwrite,
   input [MNUM*3-1:0]      im_hsize, im_hburst,
   input [MNUM*4-1:0]      im_hprot,
   input [MNUM*32-1:0]     im_hwdata,
// Outputs to masters
   output reg [31:0]       om_hrdata,
   output                  om_hready, // TODO: actually for one of two arbitered masters slave is not ready...
//   output reg [MNUM*2-1:0] om_hresp,
   output reg [1:0]        om_hresp,
// Inputs to Slave
   output reg [31:0]       os_haddr,
   output reg [1:0]        os_htrans,
   output reg              os_hwrite,
   output reg [2:0]        os_hsize, os_hburst,
   output reg [3:0]        os_hprot,
   output reg [31:0]       os_hwdata,
   output                  os_hsel,
// Outputs from Slaves
   input [31:0]            is_hrdata,
   input                   is_hready,
   input [1:0]             is_hresp
);
   wire [31:0]     haddr  [MNUM-1:0];
   wire [1:0]      htrans [MNUM-1:0];
   wire [MNUM-1:0] hwrite;
   wire [2:0]      hsize  [MNUM-1:0];
   wire [2:0]      hburst [MNUM-1:0];
   wire [3:0]      hprot  [MNUM-1:0];
   wire [31:0]     hwdata [MNUM-1:0];
   genvar gen_i;
`ifdef ALTERA
generate
`endif
   for(gen_i=0; gen_i<MNUM; gen_i=gen_i+1)
   begin : remap
      assign haddr  [gen_i] = im_haddr  [gen_i*32+:32];
      assign htrans [gen_i] = im_htrans [gen_i*2+:2];
      assign hwrite [gen_i] = im_hwrite [gen_i];
      assign hsize  [gen_i] = im_hsize  [gen_i*3+:3];
      assign hburst [gen_i] = im_hburst [gen_i*3+:3];
      assign hprot  [gen_i] = im_hprot  [gen_i*4+:4];
      assign hwdata [gen_i] = im_hwdata [gen_i*32+:32];
   end
`ifdef ALTERA
endgenerate
`endif
   reg [31:0]     haddr_r  [MNUM-1:0];
   reg [1:0]      htrans_r [MNUM-1:0];
   reg [MNUM-1:0] hwrite_r;
   reg [2:0]      hsize_r  [MNUM-1:0];
   reg [2:0]      hburst_r [MNUM-1:0];
   reg [3:0]      hprot_r  [MNUM-1:0];
   reg [31:0]     hwdata_r [MNUM-1:0];

   // request master access
   reg [MNUM-1:0]  ahb_req;        // pulsed when MASTER requests the bus
   wire [MNUM-1:0] ahb_ack;        // asserted when MASTER granted SLAVE bus
   reg [MNUM-1:0]  ahb_req_data;   // asserted when MASTER moves into DATA phase at SLAVE bus
   reg [MNUM-1:0]  ahb_done;       // pulsed when transfer at SLAVE will be completed (at the next cycle - pipeline to start new transaction)
   wire [MNUM-1:0] ahb_gnt;

   ehl_arbiter
   #(
      .WIDTH ( MNUM )
   ) arb_inst
   (
      .clk              ( hclk     ),
      .reset_n          ( hresetn  ),
      .req              ( ahb_req  ),
      .done             ( ahb_done ),
      .ack              ( ahb_ack  ),
      .grant            ( ahb_gnt  ),
      .arbitration_type ( 1'b0     ),
      .empty            (          )
   );

   integer j;
   always@*
   for(j=0; j<MNUM; j=j+1)
   begin
      ahb_req[j]  = is_hready && htrans[j];
// Note: arbiter allows next transaction to be captured while previous is not finished yet!??? no response ready yet!!!
      ahb_done[j] = is_hready && ahb_req_data[j]; // slave completes
   end

   integer i;
   always@(posedge hclk or negedge hresetn)
   if(!hresetn)
   begin
      ahb_req_data <= {MNUM{1'b0}};

      om_hrdata    <= 32'h0;
      om_hresp     <= 2'h0;

      for(i=0; i<MNUM; i=i+1)
      begin
         haddr_r  [i] <= 32'hx;
         hwdata_r [i] <= 32'hx;
         hprot_r  [i] <= 4'hx;
         hwrite_r [i] <= 1'hx;
         htrans_r [i] <= 2'hx;
         hburst_r [i] <= 3'hx;
         hsize_r  [i] <= 3'hx;
      end
   end
   else
   begin

      om_hresp <= 2'b00;
      for(i=0; i<MNUM; i=i+1)
      begin
         if(ahb_gnt[i] & is_hready & ~ahb_req_data[i])
            ahb_req_data[i] <= 1'b1; // transaction accepted at slave port - move to data stage
         else if(ahb_req_data[i] & is_hready)
            ahb_req_data[i] <= 1'b0;

         // capture master transaction
         if(ahb_req[i])
         begin
            haddr_r  [i] <= haddr[i]; // TODO: preserve registers to avoid merging of equivalent registers
            htrans_r [i] <= (ahb_gnt[i] && is_hready) ? 2'h0 : htrans[i];
            hwrite_r [i] <= hwrite[i];
            hsize_r  [i] <= hsize[i];
            hburst_r [i] <= hburst[i];
            hprot_r  [i] <= hprot[i];
         end

         if(ahb_ack[i] & is_hready & hwrite_r[i])
            hwdata_r [i] <= hwdata[i];

         if(ahb_ack[i])
         begin
            om_hresp  <= is_hresp;
            om_hrdata <= is_hrdata;
         end
/*
         if(ahb_req_data[i] & is_hready)
         begin
            // Note: shared hrdata used - and multiple assignment possible in code, but not by logic in for loop...
            om_hrdata <= is_hrdata;
         end
*/
      end
   end

   integer k;
   always@*
   begin
      os_haddr  = 32'h0;
      os_htrans = 2'h0;
      os_hsize  = 3'h0;
      os_hwrite = 1'h0;
      os_hburst = 3'h0;
      os_hprot  = 4'h0;
      os_hwdata = 32'h0;
      for(k=0; k<MNUM; k=k+1)
      begin
         if(ahb_gnt[k]) // grant -> bus IDLE direct drivers (Q: hready independent?)
         begin
            os_haddr  = haddr  [k];
            os_htrans = htrans [k];
            os_hsize  = hsize  [k];
            os_hwrite = hwrite [k];
            os_hburst = hburst [k];
            os_hprot  = hprot  [k];
         end
         else if(ahb_ack[k]) // ack -> proceed transaction from master
         begin
            os_haddr  = haddr_r  [k];
            os_htrans = htrans_r [k];
            os_hsize  = hsize_r  [k];
            os_hwrite = hwrite_r [k];
            os_hburst = hburst_r [k];
            os_hprot  = hprot_r  [k];
            os_hwdata = hwdata/*_r*/ [k];
         end

         //if(ahb_req_data[k])
            //os_hwdata = hwdata/*_r*/ [k];
      end
   end

   assign os_hsel = |os_htrans;

   assign om_hready = is_hready;

endmodule
