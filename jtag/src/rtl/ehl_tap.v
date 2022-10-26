// Design:           IEEE 1149.1 TAP Controller
// Revision:         1.1
// Date:             2021-12-17
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2015-01-27 A.Kornukhin: Initial release
//                   1.1 2021-12-17 A.Kornukhin: convert *_ir outputs to internal nets
// Reference:        [1] IEEE 1149.1-2001
// Notes:
// - [1] 4.4.1 b) requires that TDI should have pull-up resistor
// Silicon history:  2018-03-05
//                   Project: test chip
//                   Fab:     TSMC 90 nm
//                   Library: tsmc90lp
// ehl_tap(TDR_CNT=2,IMPL_STATE=0)

// Note: external multiplexor for 'tdr_in' required, based on 'instruction'
module ehl_tap
#(
   parameter IR_WIDTH = 2,             // Number of Instruction Register bits
             IMPL_STATE = 0,           // 0 - binary, 1 - one-hot
   parameter [31:0] ID = 0             // user identification register (LSB defines if register and instruction present: 1 - present)
)
(
   input wire                tck,
                             tdi,
                             tms,
                             trst_n,
   output reg                tdo,
   output wire               shift_dr,
                             capture_dr,
                             update_dr,
                             reset_state,
   output reg                tdo_en,
   input  wire               tdr_in,     // data from TDRs (LSBs)
   output reg [IR_WIDTH-1:0] instruction // Width of instruction register - 
);
`ifndef SYNTHESIS
   initial
   begin
      if(ID[0] === 1'b0 && ID[31:1] !== 31'h0)
      begin
         $display("   Error: '%m' incorrect value of parameter ID, lsb must be 1 [IEEE 1149.1-2001, Figure 12-1].");
         $finish;
      end
   end
`endif
   reg [IR_WIDTH-1:0] ir_shreg;
// Note: the only reserved binary code is BYPASS = 11...11 [1 8.4.1b]
   localparam [IR_WIDTH-1:0] BYPASS = {{(IR_WIDTH-2){1'b1}}, 2'b11};
   localparam [IR_WIDTH-1:0] IDCODE = {{(IR_WIDTH-2){1'b0}}, 2'b01};
   wire bypass_select; // asserted when BYPASS instruction provided, or any of the unsupported instructions (IDCODE, ...)
   wire idcode_select;
   assign bypass_select = instruction == BYPASS;
   assign idcode_select = (instruction == IDCODE) && ID[0];

   wire shift_ir, capture_ir, update_ir;

   localparam [3:0]
      STATE_UPDATE_DR  = 4'd15,
      STATE_UPDATE_IR  = 4'd14,
      STATE_EXIT2_DR   = 4'd13,
      STATE_EXIT2_IR   = 4'd12,
      STATE_PAUSE_DR   = 4'd11,
      STATE_PAUSE_IR   = 4'd10,
      STATE_EXIT1_DR   = 4'd9,
      STATE_EXIT1_IR   = 4'd8,
      STATE_SHIFT_DR   = 4'd7,
      STATE_SHIFT_IR   = 4'd6,
      STATE_CAPTURE_IR = 4'd5,
      STATE_CAPTURE_DR = 4'd4,
      STATE_SELECT_DR  = 4'd3,
      STATE_SELECT_IR  = 4'd2,
      STATE_IDLE       = 4'd1,
      STATE_RESET      = 4'd0;
`ifndef SYNTHESIS
   wire [32*8-1:0] dbg_state;
`endif
`ifdef ALTERA
generate
`endif
   if(IMPL_STATE == 0)
   begin : state_bin
      reg [3:0] state;
   `ifndef SYNTHESIS
      assign dbg_state =
         state == STATE_RESET      ? "Reset" :
         state == STATE_IDLE       ? "IDLE" :
         state == STATE_SELECT_DR  ? "Select-DR" :
         state == STATE_SELECT_IR  ? "Select-IR" :
         state == STATE_SHIFT_IR   ? "Shift-IR" :
         state == STATE_SHIFT_DR   ? "Shift-DR" :
         state == STATE_CAPTURE_IR ? "Capture-IR" :
         state == STATE_CAPTURE_DR ? "Capture-DR" :
         state == STATE_UPDATE_IR  ? "Update-IR" :
         state == STATE_UPDATE_DR  ? "Update-DR" :
         state == STATE_PAUSE_DR   ? "Pause-DR" :
         state == STATE_PAUSE_IR   ? "Pause-IR" :
         state == STATE_EXIT1_IR   ? "Exit1-IR" :
         state == STATE_EXIT2_IR   ? "Exit2-IR" :
         state == STATE_EXIT1_DR   ? "Exit1-DR" :
         state == STATE_EXIT2_DR   ? "Exit2-DR" : "Unknown";
   `endif

      always@(posedge tck or negedge trst_n)
      if(!trst_n)
         state <= STATE_RESET;
      else
      begin
         case(state)
            STATE_RESET:      state <= tms ? STATE_RESET     : STATE_IDLE;
            STATE_IDLE:       state <= tms ? STATE_SELECT_DR : STATE_IDLE;
            STATE_SELECT_DR:  state <= tms ? STATE_SELECT_IR : STATE_CAPTURE_DR;
            STATE_SELECT_IR:  state <= tms ? STATE_RESET     : STATE_CAPTURE_IR;
            STATE_SHIFT_IR:   state <= tms ? STATE_EXIT1_IR  : STATE_SHIFT_IR;
            STATE_SHIFT_DR:   state <= tms ? STATE_EXIT1_DR  : STATE_SHIFT_DR;
            STATE_CAPTURE_IR: state <= tms ? STATE_EXIT1_IR  : STATE_SHIFT_IR;
            STATE_CAPTURE_DR: state <= tms ? STATE_EXIT1_DR  : STATE_SHIFT_DR;
            STATE_UPDATE_IR:  state <= tms ? STATE_SELECT_DR : STATE_IDLE;
            STATE_UPDATE_DR:  state <= tms ? STATE_SELECT_DR : STATE_IDLE;
            STATE_PAUSE_DR:   state <= tms ? STATE_EXIT2_DR  : STATE_PAUSE_DR;
            STATE_PAUSE_IR:   state <= tms ? STATE_EXIT2_IR  : STATE_PAUSE_IR;
            STATE_EXIT1_IR:   state <= tms ? STATE_UPDATE_IR : STATE_PAUSE_IR;
            STATE_EXIT2_IR:   state <= tms ? STATE_UPDATE_IR : STATE_SHIFT_IR;
            STATE_EXIT1_DR:   state <= tms ? STATE_UPDATE_DR : STATE_PAUSE_DR;
            STATE_EXIT2_DR:   state <= tms ? STATE_UPDATE_DR : STATE_SHIFT_DR;
            default:          state <= STATE_RESET;
         endcase
      end

      assign shift_dr    = state == STATE_SHIFT_DR;
      assign shift_ir    = state == STATE_SHIFT_IR;
      assign capture_dr  = state == STATE_CAPTURE_DR;
      assign capture_ir  = state == STATE_CAPTURE_IR;
      assign update_dr   = state == STATE_UPDATE_DR;
      assign update_ir   = state == STATE_UPDATE_IR;
      assign reset_state = state == STATE_RESET;
   end
   else if(IMPL_STATE == 1)
   begin : state_ohot
      reg [15:0] state;
   `ifndef SYNTHESIS
      assign dbg_state =
         state == (1<<STATE_RESET)      ? "Reset" :
         state == (1<<STATE_IDLE)       ? "IDLE" :
         state == (1<<STATE_SELECT_DR)  ? "Select-DR" :
         state == (1<<STATE_SELECT_IR)  ? "Select-IR" :
         state == (1<<STATE_SHIFT_IR)   ? "Shift-IR" :
         state == (1<<STATE_SHIFT_DR)   ? "Shift-DR" :
         state == (1<<STATE_CAPTURE_IR) ? "Capture-IR" :
         state == (1<<STATE_CAPTURE_DR) ? "Capture-DR" :
         state == (1<<STATE_UPDATE_IR)  ? "Update-IR" :
         state == (1<<STATE_UPDATE_DR)  ? "Update-DR" :
         state == (1<<STATE_PAUSE_DR)   ? "Pause-DR" :
         state == (1<<STATE_PAUSE_IR)   ? "Pause-IR" :
         state == (1<<STATE_EXIT1_IR)   ? "Exit1-IR" :
         state == (1<<STATE_EXIT2_IR)   ? "Exit2-IR" :
         state == (1<<STATE_EXIT1_DR)   ? "Exit1-DR" :
         state == (1<<STATE_EXIT2_DR)   ? "Exit2-DR" : "Unknown";
   `endif

      always@(posedge tck or negedge trst_n)
      if(!trst_n)
         state <= 1<<STATE_RESET;
      else
      begin
         case(state)
            1<<STATE_RESET:      state <= tms ? 1<<STATE_RESET     : 1<<STATE_IDLE;
            1<<STATE_IDLE:       state <= tms ? 1<<STATE_SELECT_DR : 1<<STATE_IDLE;
            1<<STATE_SELECT_DR:  state <= tms ? 1<<STATE_SELECT_IR : 1<<STATE_CAPTURE_DR;
            1<<STATE_SELECT_IR:  state <= tms ? 1<<STATE_RESET     : 1<<STATE_CAPTURE_IR;
            1<<STATE_SHIFT_IR:   state <= tms ? 1<<STATE_EXIT1_IR  : 1<<STATE_SHIFT_IR;
            1<<STATE_SHIFT_DR:   state <= tms ? 1<<STATE_EXIT1_DR  : 1<<STATE_SHIFT_DR;
            1<<STATE_CAPTURE_IR: state <= tms ? 1<<STATE_EXIT1_IR  : 1<<STATE_SHIFT_IR;
            1<<STATE_CAPTURE_DR: state <= tms ? 1<<STATE_EXIT1_DR  : 1<<STATE_SHIFT_DR;
            1<<STATE_UPDATE_IR:  state <= tms ? 1<<STATE_SELECT_DR : 1<<STATE_IDLE;
            1<<STATE_UPDATE_DR:  state <= tms ? 1<<STATE_SELECT_DR : 1<<STATE_IDLE;
            1<<STATE_PAUSE_DR:   state <= tms ? 1<<STATE_EXIT2_DR  : 1<<STATE_PAUSE_DR;
            1<<STATE_PAUSE_IR:   state <= tms ? 1<<STATE_EXIT2_IR  : 1<<STATE_PAUSE_IR;
            1<<STATE_EXIT1_IR:   state <= tms ? 1<<STATE_UPDATE_IR : 1<<STATE_PAUSE_IR;
            1<<STATE_EXIT2_IR:   state <= tms ? 1<<STATE_UPDATE_IR : 1<<STATE_SHIFT_IR;
            1<<STATE_EXIT1_DR:   state <= tms ? 1<<STATE_UPDATE_DR : 1<<STATE_PAUSE_DR;
            1<<STATE_EXIT2_DR:   state <= tms ? 1<<STATE_UPDATE_DR : 1<<STATE_SHIFT_DR;
            default:             state <= 1<<STATE_RESET;
         endcase
      end

      assign shift_dr    = state[STATE_SHIFT_DR];
      assign shift_ir    = state[STATE_SHIFT_IR];
      assign capture_dr  = state[STATE_CAPTURE_DR];
      assign capture_ir  = state[STATE_CAPTURE_IR];
      assign update_dr   = state[STATE_UPDATE_DR];
      assign update_ir   = state[STATE_UPDATE_IR];
      assign reset_state = state[STATE_RESET];
   end
`ifdef ALTERA
endgenerate
`endif
// The instruction register is a shift-register-based design that has an optional parallel input for register cells
// other than the two nearest to the serial output.
   always@(posedge tck)
// 7.1.2. In addition, fault isolation of the board-level serial test data path shall be supported. This is achieved by
//        loading a constant binary "01" pattern into the least significant bits of the instruction register at the start of
//        the instruction-scan cycle.
   if(capture_ir) // Table 7-1
      ir_shreg <= 2'b01;
   else if(shift_ir)
// [1] 4.4.1. a) The signal presented at TDI shall be sampled
// into the test logic on the rising edge of TCK.
      ir_shreg <= {tdi, ir_shreg[IR_WIDTH-1:1]};

// [1 7.1.1 b] The tow least significant instruction register cells (i.e., those nearest to output) shall load a fixed binary "01" pattern
//             (the 1 into least significant bit location) in the Capture-IR controller state
   always@(negedge tck or negedge trst_n) // [1 7.2.1e] negedge
   if(!trst_n)
// [1 6.1.2] ...by initializing the instruction register to contain the IDCODE instruction or,
//              if the optional device identification register is not provided, the BYPASS instruction (see 7.2).
      instruction <= ID[0] ? IDCODE : BYPASS;
   else if(reset_state) // [1] Table 7-1
      instruction <= ID[0] ? IDCODE : BYPASS;
   else if(update_ir)
      instruction <= ir_shreg; // Table 7-1 IDCODE (or BYPASS) Test-Logic-Reset
// [1] Shift-IR: ... the shift-register contained in the
// instruction register is connected between TDI and TDO and shifts data...

// [1] 4.5.1. a) Changes in state of the signal driven through
// TDO shall occur only on the failing edge of TCK.
   always@(negedge tck or negedge trst_n)
   if(!trst_n)
      tdo_en <= 1'b0;
// [1] Figure 6-3, 6-4
   else
      tdo_en <= shift_ir | shift_dr;

// [1] 4.5.1. a) Changes in state of the signal driven through
// TDO shall occur only on the failing edge of TCK.
   reg bypass_cpt;
   always@(posedge tck)
// 10.1.1.b) When the bypass register is selected for inclusion in the serial path between TDI and TDO by the
// current instruction, the shift-register stage shall be set to a logic zero on the rising edge of TCK after
// entry into the Capture-DR controller state.
   if(capture_dr)
      bypass_cpt <= 1'b0;
   else if(shift_dr)
      bypass_cpt <= tdi;

   reg [31:0] id_shreg;
   always@(posedge tck)
   if(capture_dr && idcode_select)
      id_shreg <= ID;
   else if(shift_dr && idcode_select)
      id_shreg <= {tdi, id_shreg[31:1]};

// [1 Table 6-2] states that TDO driven to defined state only when SHIFT-DR / SHIFT-IR states
   always@(negedge tck)
// 10.1.2. Rule 10.1.1 b) is included so that the presence or absence of a device identification register in the test logic
// can be determined by examination of the serial output data. The bypass register (which is selected in the
// absence of a device identification register) loads a logic 0 at the start of a scan cycle, whereas a device
// identification register loads a constant logic 1 into its LSB. When the IDCODE instruction is loaded into the
// instruction register, a subsequent data register scan cycle will allow the first bit of data shifted out of each
// component to be examined - a logic 1 showing that a device identification register is present. This allows
// blind interrogation of device identification registers by setting the IDCODE instruction as outlined in 12.1.
   if(shift_ir)
      tdo <= ir_shreg[0];
   else if(shift_dr)
      tdo <= bypass_select ? bypass_cpt :
             idcode_select ? id_shreg[0] :
             tdr_in;

endmodule
