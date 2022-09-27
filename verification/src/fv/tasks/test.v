// Design:           Commonly used tasks for Verilog verification
// Revision:         1.2
// Date:             2022-0-29
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2013-07-09 A.Kornukhin: initial release
//                   1.1 2017-04-27 A.Kornukhin: fail_test_fifo added for final diagnostic
//                   1.2 2022-06-29 A.Kornukhin: test index added into final list of failed tests

`define TEST_WATCHDOG(NUM,CLK) integer watchdog; always@(posedge CLK) begin watchdog <= watchdog + 1; if(watchdog == NUM) begin $display("   Info: test finished due to watchdog expiration at %0t.", $time); $finish; end end initial watchdog = 0;

   integer test_pass, tests_success, tests_num, test_fail;
   initial begin test_pass=0; tests_success=0; tests_num=0; test_fail=0; end
   reg [31*8-1:0] test_name = "-------";
   reg [35*8-1:0] fail_test_fifo [31:0]; // Note: up to 32 entries (with indexes)
   reg [4:0] fail_test_ptr = 0;

   task TEST_TITLE(
      input reg [8*64-1:0] title_ip,   // Name of tested IP
      input reg [8*64-1:0] title_test, // Name of test
      input reg [8*64-1:0] title_descr // Test description
   );
   begin
      $display("#############################################");
      $display("#");
      $display("# %0s", title_ip);
      $display("# Testbench: %0s", title_test);
      $display("# Title: %0s", title_descr);
      $display("#");
      $display("#############################################");
   end
   endtask

task TEST_SUMMARY;
integer i;
begin
   if(tests_success==tests_num) $display("ALL %0d TESTS COMPLETE SUCCESSFULLY", tests_success);
   else if(tests_success!=tests_num) $display("SOME TESTS FAILED DURING SIMULATION (%0d/%0d)", tests_success, tests_num);
   $display("                TESTS SUMMARY");
   $display("TESTS COMPLETE                %0d", tests_num);
   $display("TESTS COMPLETE SUCCESSFULL    %0d", tests_success);
   $display("TESTS FAILED                  %0d", tests_num - tests_success);
   if(tests_num - tests_success != 0)
   begin
      $display("List of failed test(s):");
      for(i=0; i<fail_test_ptr; i=i+1)
         $display("  %s", fail_test_fifo[i]);
   end
   #300 $display("END OF SIMULATION at %0t", $time);
   if(tests_num == tests_success) PRINT_PASS;
   else PRINT_FAIL;
   $finish(2);
end
endtask

task PRINT_PASS;
begin
   $display("");
   $display("   #### #### #### ####");
   $display("   #  # #  # #    #   ");
   $display("   #### #### #### ####");
   $display("   #    #  #    #    #");
   $display("   #    #  # #### ####");
   $display("");
end
endtask

task PRINT_FAIL;
begin
   $display("");
   $display("   #### #### ### #   ");
   $display("   #    #  #  #  #   ");
   $display("   #### ####  #  #   ");
   $display("   #    #  #  #  #   ");
   $display("   #    #  # ### ####");
   $display("");
end
endtask

task TEST_INIT(input reg [31*8-1:0] tname);
begin
   test_name = tname;
   #1000 test_pass=0; tests_num=tests_num+1;
end
endtask

task TEST_CHECK(input integer CntrlNumber);
begin
   #1000
   if(test_pass==CntrlNumber)
   begin // Note: $write doesn't automatically adds \n at the end, while $display does
`ifdef __ehl_color__
      $fflush();
      $system("echo -n $(tput setaf 2)");
      $display("TEST-%0d: PASS : '%s' [%0t]", tests_num, test_name, $time);
      $fflush();
      $system("echo -n $(tput sgr 0)");
      $fflush();
`else
      $display("TEST-%0d: PASS : '%s' [%0t]", tests_num, test_name, $time);
`endif
      tests_success=tests_success+1;
   end
   else if(test_pass!=CntrlNumber)
   begin
      if(fail_test_ptr != 31)
      begin
         fail_test_fifo [fail_test_ptr] = {".", test_name};
         fail_test_fifo [fail_test_ptr][35*8-1:34*8] = (tests_num % 1000) / 100 + 8'h30;
         fail_test_fifo [fail_test_ptr][34*8-1:33*8] = (tests_num % 100) / 10 + 8'h30;
         fail_test_fifo [fail_test_ptr][33*8-1:32*8] = (tests_num % 10) + 8'h30;
         fail_test_ptr = fail_test_ptr + 1;
      end
      else
         fail_test_fifo [fail_test_ptr] = "...";
`ifdef __ehl_color__
      $fflush();
      $system("echo -n $(tput setaf 1)");
      $display("TEST-%0d: FAILED (%0d/%0d) : '%s' [%0t]",tests_num, test_pass, CntrlNumber, test_name, $time);
      $fflush();
      $system("echo -n $(tput sgr 0)");
      $fflush();
`else
      $display("TEST-%0d: FAILED (%0d/%0d) : '%s' [%0t]",tests_num, test_pass, CntrlNumber, test_name, $time);
`endif
   end
end
endtask

task TEST_DIAG(input integer test_num, input integer subtest_num, input scalar_expression);
begin
   if(scalar_expression)
      test_pass=test_pass+1;
   else
      $display("   Subtest %0d.%0d fails at %0t.", test_num, subtest_num, $time);
end
endtask

// CRC function for Write and Read FIFO's data
// polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
// data width: 1
function [31:0] nextCRC32_D1;

input Data;
input [31:0] CRC;

reg [0:0] D;
reg [31:0] C;
reg [31:0] NewCRC;

begin
  D[0] = Data;
  C = CRC;

  NewCRC[0] = D[0] ^ C[31];
  NewCRC[1] = D[0] ^ C[0] ^ C[31];
  NewCRC[2] = D[0] ^ C[1] ^ C[31];
  NewCRC[3] = C[2];
  NewCRC[4] = D[0] ^ C[3] ^ C[31];
  NewCRC[5] = D[0] ^ C[4] ^ C[31];
  NewCRC[6] = C[5];
  NewCRC[7] = D[0] ^ C[6] ^ C[31];
  NewCRC[8] = D[0] ^ C[7] ^ C[31];
  NewCRC[9] = C[8];
  NewCRC[10] = D[0] ^ C[9] ^ C[31];
  NewCRC[11] = D[0] ^ C[10] ^ C[31];
  NewCRC[12] = D[0] ^ C[11] ^ C[31];
  NewCRC[13] = C[12];
  NewCRC[14] = C[13];
  NewCRC[15] = C[14];
  NewCRC[16] = D[0] ^ C[15] ^ C[31];
  NewCRC[17] = C[16];
  NewCRC[18] = C[17];
  NewCRC[19] = C[18];
  NewCRC[20] = C[19];
  NewCRC[21] = C[20];
  NewCRC[22] = D[0] ^ C[21] ^ C[31];
  NewCRC[23] = D[0] ^ C[22] ^ C[31];
  NewCRC[24] = C[23];
  NewCRC[25] = C[24];
  NewCRC[26] = D[0] ^ C[25] ^ C[31];
  NewCRC[27] = C[26];
  NewCRC[28] = C[27];
  NewCRC[29] = C[28];
  NewCRC[30] = C[29];
  NewCRC[31] = C[30];

  nextCRC32_D1 = NewCRC;
end
endfunction
//
//
//
function [31:0] crc32_func;
   input [79:0] data; // Note: MSB will be truncated
   input [31:0] crc;
   input [31:0] width; // up to 80
   reg [31:0] array;
   integer i;
   begin
      array = nextCRC32_D1(data[0], crc);
      for(i=1; i<width; i=i+1)
         array = nextCRC32_D1(data[i], array);
      crc32_func = array;
   end
endfunction
//========================
initial
begin
`ifdef __ehl_vcd__
   $dumpfile("1.vcd");
   $dumpvars(100);
`endif
end
