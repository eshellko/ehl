module ehl_ecc_tb;
`include "test.v"
   parameter SECDED = 1;
   parameter WIDTH = 8;
   localparam CWIDTH = 1 + $clog2(WIDTH);
   integer k, j;
   reg [WIDTH:0] i;
   reg [WIDTH-1:0] din, drand;
   wire [WIDTH-1:0] dout;

   reg [CWIDTH:0]  code; // Note: used to check if code for clean data not equal to code with single_error
   reg [WIDTH-1:0] noise_init = 0; // Note: noise on generator to check hamming distance
   reg [WIDTH-1:0] noise = 0;
   reg [CWIDTH:0]  noise_c = 0;
   wire [WIDTH-1:0] dout2;
   wire [CWIDTH:0]  cbout, cbout2;
   wire single_error, double_error;

   ehl_ecc
`ifndef __NETLIST__
   #(
      .WIDTH  ( WIDTH  ),
      .SECDED ( SECDED )
   )
`endif
   dut_gen
   (
      .gen          ( 1'b1             ),
      .chk          ( 1'b0             ),
      .din          ( din ^ noise_init ),
      .cbin         ( {CWIDTH+1{1'b0}} ),
      .dout         ( dout             ),
      .cbout        ( cbout            ),
      .se_pat_dout  (                  ),
      .se_pat_cbout (                  ),
      .single_err   (                  ),
      .double_err   (                  ),
      .cb_err       (                  )
   );
   ehl_ecc
`ifndef __NETLIST__
   #(
      .WIDTH  ( WIDTH  ),
      .SECDED ( SECDED )
   )
`endif
   dut_chk
   (
      .gen          ( 1'b0            ),
      .chk          ( 1'b1            ),
      .din          ( dout ^ noise    ),
      .cbin         ( cbout ^ noise_c ),
      .dout         ( dout2           ),
      .cbout        ( cbout2          ),
      .se_pat_dout  (                 ),
      .se_pat_cbout (                 ),
      .single_err   ( single_error    ),
      .double_err   ( double_error    ),
      .cb_err       (                 )
   );

   reg [4:0] ones_cbin;
   integer p;
   always@(drand)
   begin
      ones_cbin = 4'h0;
      for(p=0; p<CWIDTH+1; p++)
         ones_cbin = ones_cbin + drand[p];
   end

   integer exp_chk;

   initial
   begin
      // 2**p  >=   m + p + 1
      // m - data bits
      // p - parity bits
      if(SECDED)
      begin
         TEST_TITLE("Hamming ecc SECDED coder-decoder", "ehl_ecc_tb.v", "Back-to-back test");
         $display("   Info: 'ehl_ecc(%0d,%0d)' test.", WIDTH, CWIDTH+1);
      end
      else
      begin
         TEST_TITLE("Hamming ecc SEC coder-decoder", "ehl_ecc_tb.v", "Back-to-back test");
         $display("   Info: 'ehl_ecc(%0d,%0d)' test.", WIDTH, CWIDTH);
      end
`ifdef VERILATOR
      $display("   Info: VERILATOR has limited support for simulation constructs.");
      $display("   Info: Some of the test fails at version 3.864... UPDATED to 4.016.");
`endif

`ifndef VERILATOR
      TEST_INIT("RANDOM_ERR");
      exp_chk = 0;
      repeat(1024)
      begin
         drand = $random;
         din = $random;
         if(ones_cbin < 3)
         begin
            #1 noise_c = drand;
            #1;
            if(dout2 === din) test_pass = test_pass + 1;
            else $display("   Error: %s (%0d flip) data 0x%x does not match initial 0x%x (delta 0x%x).", (ones_cbin == 0 || ones_cbin == 1) ? "correctable" : "uncorrectable", ones_cbin, dout2, din, dout2 ^ din);
            if(ones_cbin == 1)
            begin
               if(single_error === 1'b1) test_pass = test_pass + 1; else $display("   Error: single error flag should be asserted.");
               if(double_error === 1'b0) test_pass = test_pass + 1; else $display("   Error: double error flag should not be asserted.");
               exp_chk = exp_chk + 2;
            end
            else if(ones_cbin > 1)
            begin
               if(single_error === 1'b0) test_pass = test_pass + 1; else $display("   Error: single error flag should not be asserted.");
               if(double_error === 1'b1) test_pass = test_pass + 1; else $display("   Error: double error flag should be asserted.");
               exp_chk = exp_chk + 2;
            end
            #1;
            exp_chk = exp_chk + 1;
         end
      end
      noise_c = 0;
      TEST_CHECK(exp_chk);
`endif

      TEST_INIT("ENC-DEC-PATH");
         CLEAN_DATA_CYCLE;
      TEST_CHECK(2**WIDTH * 3);

      if(SECDED == 1)
      begin
// Note: assignment to 'noise' cause VERILATOR to fail on this test, and also on RANDOM_ERR
`ifndef VERILATOR
         TEST_INIT("ENC-DEC-SERR");
            SINGLE_ERROR_INJECT_CYCLE(0);
         TEST_CHECK((2**WIDTH * WIDTH * 3) + (2**WIDTH * CWIDTH * 3));
`endif

`ifndef VERILATOR
         TEST_INIT("ENC-DEC-DERR");
         for(i=0; i<(2**WIDTH); i++)
            for(j=0; j<WIDTH+CWIDTH; j++)
               for(k=0; k<WIDTH+CWIDTH; k++)
               if(j != k)
               begin
                  din = i;
                  noise = 0;
                  noise_c = 0;
                  // Note: define DATA or CHECKBITS
                  if(j >= WIDTH) noise_c[j-WIDTH] = 1; else noise[j] = 1;
                  if(k >= WIDTH) noise_c[k-WIDTH] = 1; else noise[k] = 1;
                  #1
                  if(single_error !== 1'b0) $display("   Error: single error flag should not be asserted."); else test_pass = test_pass + 1;
                  if(double_error !== 1'b1) $display("   Error: double error flag should be asserted."); else test_pass = test_pass + 1;
               end
         noise = 0;
         noise_c = 0;
         TEST_CHECK(2**WIDTH * (WIDTH+CWIDTH) * ((WIDTH+CWIDTH) - 1) * 2);

         TEST_INIT("SE_HAMMING_DISTANCE");
         for(i=0; i<(2**WIDTH); i++)
            for(j=0; j<WIDTH; j++)
            begin
               din = i;
               code = cbout;
               #1 noise_init=0; noise_init[j]=1;
               #1 if(code == cbout) $display("   Error: IN %x; NOISE %x; CODE wo noise %x, CODE w noise %x", din, noise, code, cbout); else test_pass = test_pass + 1;
            end
         noise_init=0;
         TEST_CHECK(2**WIDTH * WIDTH);
`endif
      end
// Note: force-release do not supported by verilator
`ifndef VERILATOR
      if(SECDED == 0)
      begin
         // SEC (but not DED) can be implemented with 1 bit less codeword - no parity used
         // SECDED=0 configuration checked with tied low/high parities for single error check
         //    to check so, exclude generated / checked parity from data path and check all SECs are fixed
         TEST_INIT("SEC");
            // tie PARITY low
            force dut_gen.cbout[0] = 1'b0;
            force dut_chk.cbin[0] = 1'b0;
            SINGLE_ERROR_INJECT_CYCLE(1);
            CLEAN_DATA_CYCLE;

            // tie PARITY high
            force dut_gen.cbout[0] = 1'b1;
            force dut_chk.cbin[0] = 1'b1;
            SINGLE_ERROR_INJECT_CYCLE(1);
            CLEAN_DATA_CYCLE;

            release dut_gen.cbout[0];
            release dut_chk.cbin[0];
         TEST_CHECK(2 * ((2**WIDTH * WIDTH * 3) + (2**WIDTH * (CWIDTH-1) * 3))  + 2 * (2**WIDTH * 3));
      end
`endif
      TEST_SUMMARY;
   end

   task SINGLE_ERROR_INJECT_CYCLE(input integer c_start);
   begin
      // Note: single error in data
      for(i=0; i<(2**WIDTH); i++)
         for(j=0; j<WIDTH; j++)
         begin
            din = i;
            // Note: verilator doesn't support shift for more than 32, thus another coding way used instead of 'noise = 1<<j;'
            noise=0; noise[j]=1;
            #1 if(dout2 !== din) $display("   Error: IN %x; NOISE %x; OUT %x (%x)", din, dout^noise, dout2, `ifdef __NETLIST__ -1 `else dut_chk.mask `endif); else test_pass = test_pass + 1;
            if(single_error !== 1'b1) $display("   Error: single error flag should be asserted."); else test_pass = test_pass + 1;
            if(double_error !== 1'b0) $display("   Error: double error flag should not be asserted."); else test_pass = test_pass + 1;
         end
      noise = 0;

      // Note: single error in checkbits
      for(i=0; i<(2**WIDTH); i++)
         for(j=c_start; j<CWIDTH; j++)
         begin
            din = i;
            noise_c=0; noise_c[j]=1;
            #1 if(dout2 !== din) $display("   Error: IN %x; NOISE %x; OUT %x (%x)", din, dout^noise, dout2, `ifdef __NETLIST__ -1 `else dut_chk.mask `endif); else test_pass = test_pass + 1;
            if(single_error !== 1'b1) $display("   Error: single error flag should be asserted."); else test_pass = test_pass + 1;
            if(double_error !== 1'b0) $display("   Error: double error flag should not be asserted."); else test_pass = test_pass + 1;
         end
      noise_c = 0;
   end
   endtask

   task CLEAN_DATA_CYCLE;
   begin
      for(i=0; i<(2**WIDTH); i++)
      begin
         din = i;
         #1;
         if(dout !== din) $display("   Error: IN %x; OUT %x", din, dout); else test_pass = test_pass + 1;
         if(single_error !== 1'b0) $display("   Error: single error flag should not be asserted."); else test_pass = test_pass + 1;
         if(double_error !== 1'b0) $display("   Error: double error flag should not be asserted."); else test_pass = test_pass + 1;
      end
   end
   endtask

endmodule
