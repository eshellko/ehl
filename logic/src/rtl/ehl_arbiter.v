// Design:           Arbiter with fairness
// Revision:         1.3
// Date:             2021-11-24
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2016-12-05 A.Kornukhin: Initial release
//                   1.1 2016-12-20 A.Kornukhin: arbitration_type added
//                       to define 2 modes:
//                       0 (default, rev.1.0) fairness
//                       1 - lowest index has highest priority (for Flow Control)
//                       + empty output port
//                   1.2 2019-11-06 A.Kornukhin: SECOND_REQ and associated functionality added
//                   1.3 2021-11-24 A.Kornukhin: 'grant' became output
// Description:      Arbiter that produces ACK for requested REQs
//                   REQ should be pulsed for 1 cycle
//                   ACK will be asserted until DONE pulse received
//                   DONE must be pulsed only for ACKed channel
//                   REQ must not be asserted if previous REQ from same channel not completed with valid DONE pulse
//                   SECOND_REQ==1: For fairness mode if REQ-1 granted, and then REQ-1 required at the same time as REQ-2(3 or so on)
//                                  REQ-1 will be executed first, not REQ-2 - assume fairness from previously ACKed REQ
//                   SECOND_REQ==0: For fairness mode if REQ-1 granted, and then REQ-1 required at the same time as REQ-2(3 or so on)
//                                  REQ-1 will NOT be executed first

module ehl_arbiter
#(
   parameter WIDTH = 4,
   parameter [0:0] SECOND_REQ = 1 // 1 - same REQ channel accepted twice in some cases; 0 - same REQ channel accepted only once
)
(
   input wire clk,
   reset_n,
   input wire [WIDTH-1:0] req,  // should be pulsed, if no ack received, they will be kept internally
   input wire [WIDTH-1:0] done, // should be pulsed to signal process is completed
   output reg [WIDTH-1:0] ack,  // keeps last acknowledged value
   output [WIDTH-1:0] grant,
   input arbitration_type,      // 0 - fairness, 1 - lowest index == highest priority
   output empty                 // set if there is no requests in queue and no outstanding ACKs (but REQs on inputs can be)
);
   reg [WIDTH-1:0] next_ptr;
   reg [WIDTH-1:0] req_queue;
   wire [WIDTH-1:0] requests = req | req_queue;
   wire [2*WIDTH-1:0] double_req = {requests,requests};
   wire [2*WIDTH-1:0] double_grant = double_req & ~(double_req-next_ptr);
   wire [WIDTH-1:0] next_grant = (double_grant[WIDTH-1:0] | double_grant[2*WIDTH-1:WIDTH]);
   assign grant = next_grant & {WIDTH{~|(ack^done)}};

   always@(posedge clk or negedge reset_n)
   if(!reset_n)
   begin
      ack       <= {WIDTH{1'b0}};
      req_queue <= {WIDTH{1'b0}};
   end
   else
   begin
`ifndef SYNTHESIS
      // pragma coverage block = off
      if(done)
         if(done ^ ack)
            $display("   Error: '%m' arbiter receives DONE (%b) for channel without ACK (%b) at time %0t.", done, ack, $time);
//       if(req & ack)
//          $display("   Error: '%m' arbiter receives REQ (%b) for ACK channel (%b) at time %0t.", req, ack, $time);
      // pragma coverage block = on
`endif
//      req_queue<=(req_queue & (~grant)) | ((requests ^ grant)); // clear pended requests && keep requests for delay execution
      req_queue <= requests ^ grant; // clear pended requests && keep requests for delay execution

      // clear current acknowledge
      if(|(ack & done))
         ack <= 0;

      // set next request
      if(grant)
         ack <= grant;
   end
// Note: arbitration scheme based on SECOND_REQ value
//       granted request either placed on top of next search (SECOND_REQ == 1)
//       or it is placed just before top of next search (last in list) (SECOND_REQ == 0)
//        _   _   _   _   _   _   _   _   _
// clk  _/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
//          ___             ___
// req0 ___/   \___________/   \____________
//                          ___
// req1 ___________________/   \____________
//
// SECOND_REQ == 1:
//             _______        _______
// ack0 ______/   ... \______/   ... \______
//                                    ______
// ack1 _____________________________/    
//
// SECOND_REQ == 0:
//             _______                _______
// ack0 ______/   ... \______________/
//                            _______
// ack1 _____________________/   ... \______
//
`ifdef ALTERA
generate
`endif
   if(SECOND_REQ == 1)
   begin: unfair
      always@(posedge clk or negedge reset_n)
      if(!reset_n)
         next_ptr <= {{WIDTH-1{1'b0}},1'b1};
      else
      begin
         if(arbitration_type)
            next_ptr <= {{WIDTH-1{1'b0}},1'b1};
         else if(|ack)
         // Note: in such case same REQ will be granted twice if 2nd REQ came at the same time with another REQ
            next_ptr <= ack;
      end
   end
   else
   begin: fair
      always@(posedge clk or negedge reset_n)
      if(!reset_n)
         next_ptr <= {{WIDTH-1{1'b0}},1'b1};
      else
      begin
         if(arbitration_type)
            next_ptr <= {{WIDTH-1{1'b0}},1'b1};
         else if(|ack)
         // Note: in this case 2nd REQ first, but next further REQs will schedule 1-st one to tail (although it cames first)!?
            next_ptr <= {ack[WIDTH-2:0],ack[WIDTH-1]};
      end
   end
`ifdef ALTERA
endgenerate
`endif

   assign empty = (~|req_queue) & (~|ack);
endmodule
