module ehl_ahb_matrix_tb;
   `include "test.v"
   `include "ahb.v"
   parameter WIDTH = 32;

   parameter MASTER_CNT = 2;
   always #10 hclk = ~hclk;

   reg [31:0] hwhaddr = 0;
   reg [1:0] hwhtrans = 0;
   reg hwhwrite = 0;
   reg [2:0] hwhsize = 0;//todo: master_cnt as parameter
   reg [2:0] hwhburst = 0;
   reg [31:0] hwhwdata = 0;
   reg [31:0] hwhrdata = 0;
   reg [1:0] hwhresp = 0;

   wire [MASTER_CNT-1:0]    om_hready;
   wire [MASTER_CNT*2-1:0]  om_hresp;
   wire [MASTER_CNT*32-1:0] om_hrdata;
   wire [1:0] om_hgrant;
   assign hready = om_hready[0];

   wire hwhready = om_hready[1];

   wire [31:0] ahb_haddr[1:0];
   wire [1:0]  ahb_htrans[1:0];
   wire        ahb_hwrite[1:0];
   wire [2:0]  ahb_hsize[1:0], ahb_hburst[1:0];
   wire [3:0]  ahb_hprot[1:0];
   wire [31:0] ahb_hwdata[1:0];
   wire [1:0]  ahb_hsel;
   wire        ahb_hready_in = 1'b1;

   wire        s0_ahb_hready;
   wire [1:0]  s0_ahb_hresp;
   wire [31:0] s0_ahb_hrdata;
   wire        s1_ahb_hready;
   wire [1:0]  s1_ahb_hresp;
   wire [31:0] s1_ahb_hrdata;
//------------------------------------
// DUT
//------------------------------------
   ehl_ahb_matrix
   #(
      .SNUM      ( 2            ),
      .MNUM      ( MASTER_CNT   ),
      .SLV0_BASE ( 32'h10000000 ),
      .SLV0_MASK ( 32'hF0000000 ),
      .SLV1_BASE ( 32'h30000000 ),
      .SLV1_MASK ( 32'hF0000000 )
   ) dut
   (
      .hclk      ( hclk                ),
      .hresetn   ( hresetn             ),
// Inputs from master
      .im_haddr  ( {hwhaddr,haddr}     ),
      .im_htrans ( {hwhtrans,htrans}   ),
      .im_hwrite ( {hwhwrite,hwrite}   ),
      .im_hsize  ( {hwhsize,hwhsize}   ),
      .im_hburst ( {hwhburst,hburst}   ),
      .im_hprot  ( {MASTER_CNT{4'h0}}  ),
      .im_hwdata ( {hwhwdata,hwdata}   ),

      .im_route  ( {2'b01, 2'b11}      ), // HW master only allowed to access Slave0
// Outputs to masters
      .om_hrdata ( om_hrdata           ),
      .om_hready ( om_hready           ),
      .om_hresp  ( om_hresp            ),
// Inputs to Slaves
      .os_haddr  ( {ahb_haddr[1], ahb_haddr[0]}  ),
      .os_htrans ( {ahb_htrans[1],ahb_htrans[0]} ),
      .os_hwrite ( {ahb_hwrite[1],ahb_hwrite[0]} ),
      .os_hsize  ( {ahb_hsize[1], ahb_hsize[0]}  ),
      .os_hburst ( {ahb_hburst[1],ahb_hburst[0]} ),
      .os_hprot  ( {ahb_hprot[1], ahb_hprot[0]}  ),
      .os_hwdata ( {ahb_hwdata[1],ahb_hwdata[0]} ),
      .os_hsel   ( ahb_hsel            ),
// Outputs from Slaves
      .is_hrdata ( {s1_ahb_hrdata,s0_ahb_hrdata} ),
      .is_hready ( {s1_ahb_hready,s0_ahb_hready} ),
      .is_hresp  ( {s1_ahb_hresp, s0_ahb_hresp}   )
   );
//------------------------------------
// slaves
//------------------------------------
   reg [7:0] s0_resp_delay = 8'h0;
   reg s0_resp_val = 1'b0;
   ehl_ahb_default_slave slv_0_inst
   (
// AHB
      .hclk       ( hclk           ),
      .hresetn    ( hresetn        ),
      .htrans     ( ahb_htrans[0]  ),
      .hsel       ( ahb_hsel[0]    ),
      .hready_in  ( ahb_hready_in  ),
      .hready     ( s0_ahb_hready  ),
      .hresp      ( s0_ahb_hresp   ),
      .hrdata     ( s0_ahb_hrdata  ),
// configuration
      .resp_delay ( s0_resp_delay  ),
      .resp_val   ( s0_resp_val    )
   );
   reg [7:0] s1_resp_delay = 8'h0;
   reg s1_resp_val = 1'b0;
   ehl_ahb_default_slave slv_1_inst
   (
// AHB
      .hclk       ( hclk           ),
      .hresetn    ( hresetn        ),
      .htrans     ( ahb_htrans[1]  ),
      .hsel       ( ahb_hsel[1]    ),
      .hready_in  ( ahb_hready_in  ),
      .hready     ( s1_ahb_hready  ),
      .hresp      ( s1_ahb_hresp   ),
      .hrdata     ( s1_ahb_hrdata  ),
// configuration
      .resp_delay ( s1_resp_delay  ),
      .resp_val   ( s1_resp_val    )
   );

   initial
   begin
      TEST_TITLE("AHB Matrix", "ehl_ahb_matrix_tb.v", "Basic test");
      hresetn = 1'b0;
      #44 hresetn = 1'b1;

      TEST_INIT("WRITE");
         AHB_WRITE(32'h000000AA, 32'h10000000, 3'd2);
         AHB_WRITE(32'h000000BB, 32'h30000000, 3'd2);
         AHB_WRITE(32'h000000CC, 32'h40000000, 3'd2);

         AHB_WRITE(32'h000000BB, 32'h30200000, 3'd2);
         AHB_WRITE(32'h000000CC, 32'h40000000, 3'd2);
         AHB_WRITE(32'h000000CC, 32'h40000000, 3'd2);
         AHB_WRITE(32'h000000CC, 32'h40000000, 3'd2);
         AHB_WRITE(32'h000000AA, 32'h10000100, 3'd2);
         AHB_WRITE(32'h000000BB, 32'h30200000, 3'd2);
         AHB_WRITE(32'h000000AA, 32'h10000100, 3'd2);
         AHB_WRITE(32'h000000AA, 32'h10000100, 3'd2);
         AHB_WRITE(32'h000000BB, 32'h30200000, 3'd2);
         AHB_WRITE(32'h000000AA, 32'h10000100, 3'd2);
         AHB_WRITE(32'h000000CC, 32'h40000000, 3'd2);
         AHB_WRITE(32'h000000BB, 32'h30200000, 3'd2);
         AHB_WRITE(32'h000000CC, 32'h40000000, 3'd2);
      TEST_CHECK(0);

      TEST_INIT("READ");
         AHB_READ(32'hx, 32'h10000000, 3'd2, 1'b0);
         AHB_READ(32'hx, 32'h20000000, 3'd2, 1'b0);
         AHB_READ(32'hx, 32'h30000000, 3'd2, 1'b0);
         AHB_READ(32'hx, 32'h40000000, 3'd2, 1'b0);
         AHB_READ(32'hx, 32'h40000000, 3'd2, 1'b0);
         AHB_READ(32'hx, 32'h10000000, 3'd2, 1'b0);
      TEST_CHECK(0);

// TODO: MA->S0, MB->S0 in a row
      TEST_INIT("ARBITER");
      fork
         begin : s1
            @(posedge hclk) hwhtrans <= 2; hwhwrite <= 0; hwhaddr <= 32'h10000000;
            while(hwhready == 1'b0) @(posedge hclk);
            @(posedge hclk) hwhtrans <= 0;

            repeat(12) @(posedge hclk);

            @(posedge hclk); hwhtrans <= 2; hwhwrite <= 0; hwhaddr <= 32'h40001000; @(posedge hclk);
            while(hwhready == 1'b0) @(posedge hclk);

            hwhtrans <= 2; hwhwrite <= 0; hwhaddr <= 32'h40002000; @(posedge hclk);
            while(hwhready == 1'b0) @(posedge hclk);
            hwhtrans <= 0;
         end
         begin : s0
            repeat(2) @(posedge hclk);
            AHB_WRITE(32'hA00000bc, 32'h30000000, 3'd2);
            repeat(3) @(posedge hclk);
            AHB_WRITE(32'hA00000bc, 32'hA0020000, 3'd2);
            repeat(3) @(posedge hclk);
            AHB_WRITE(32'hA00000bc, 32'h10040000, 3'd2);
            repeat(3) @(posedge hclk);
            AHB_WRITE(32'hA00000bc, 32'h11050000, 3'd2);
            repeat(3) @(posedge hclk);
            AHB_WRITE(32'hA00000bc, 32'h12060000, 3'd2);
         end
      join
      TEST_CHECK(0);

      TEST_INIT("ROUTE_MASK");
      // HW Master access to Slave 1 is prohibited
         @(posedge hclk) hwhtrans <= 2; hwhwrite <= 0; hwhaddr <= 32'h30000000;
         while(hwhready == 1'b0) @(posedge hclk);
         @(posedge hclk) hwhtrans <= 0;

         @(posedge hclk) hwhtrans <= 2; hwhwrite <= 1; hwhaddr <= 32'h30000000;
         while(hwhready == 1'b0) @(posedge hclk);
         @(posedge hclk) hwhtrans <= 0;
      // HW Master access to Slave 0
         @(posedge hclk) hwhtrans <= 2; hwhwrite <= 0; hwhaddr <= 32'h10000000;
         while(hwhready == 1'b0) @(posedge hclk);
         @(posedge hclk) hwhtrans <= 0;

         @(posedge hclk) hwhtrans <= 2; hwhwrite <= 1; hwhaddr <= 32'h10000010;
         while(hwhready == 1'b0) @(posedge hclk);
         @(posedge hclk) hwhtrans <= 2; hwhwrite <= 1; hwhaddr <= 32'h10000020;
         while(hwhready == 1'b0) @(posedge hclk);
         @(posedge hclk); hwhtrans <= 2; hwhwrite <= 1; hwhaddr <= 32'h10000030;
         while(hwhready == 1'b0) @(posedge hclk);
         @(posedge hclk); hwhtrans <= 2; hwhwrite <= 0; hwhaddr <= 32'h10000040; hwhwdata <= 32'hdada1234;
         while(hwhready == 1'b0) @(posedge hclk);
         @(posedge hclk); hwhtrans <= 2; hwhwrite <= 1; hwhaddr <= 32'h10000050;
         while(hwhready == 1'b0) @(posedge hclk);
         @(posedge hclk) hwhtrans <= 0;
      TEST_CHECK(0);

      TEST_SUMMARY;
   end

endmodule
