`timescale 1ns / 1ps

// NOTE: no `include here on purpose. cla.v / regfile.v / instr_rom.v are
// added to the Vivado project as their own sources, so including them
// textually would define every module twice (that is what produces the
// "overwriting previous definition" CRITICAL WARNINGs in system.v's
// synthesis log). Command-line tools just list all the files instead.

// Reduced single-cycle RISC-V-style datapath: each press of btn[3] fetches
// one R-type ADD/SUB instruction from a 4-entry ROM, reads two operands
// from a 4-entry register file, executes it on the SAME 32-bit CLA adder
// from cla.v (subtraction reuses it via invert + cin -- no separate
// subtractor needed), and writes the result back. led[5:0] show the low
// 6 bits of the last computed result.
//
// btn[2] = BTN0, press to reset (program restarts at PC=0, R1=5, R2=3, R3=0)
// btn[3] = BTN1, "step": advances the datapath by exactly one instruction per press
module SystemDatapath(
   input  wire       clk,
   input  wire [6:0] btn,
   output wire [5:0] led
);
   // Arty Z7-20 pushbuttons are active HIGH (released = 0, pressed = 1),
   // so the active-low reset must be the inverse of the button level.
   wire rst_n = ~btn[2];

   // btn[3] is asynchronous to clk, so it goes through a 2-flop synchronizer
   // before being used. Feeding the raw pin into logic that fans out to pc,
   // the register file and result_reg could let those registers sample
   // different values in the same cycle if the press lands near a clock edge.
   reg btn3_sync1, btn3_sync2, btn3_d;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         btn3_sync1 <= 1'b0;
         btn3_sync2 <= 1'b0;
         btn3_d     <= 1'b0;
      end
      else begin
         btn3_sync1 <= btn[3];
         btn3_sync2 <= btn3_sync1;
         btn3_d     <= btn3_sync2;   // one more delay for edge detection
      end
   end

   // rising edge on the synchronized button = execute exactly one instruction
   wire step = btn3_sync2 & ~btn3_d;

   // program counter: wraps 0 -> 1 -> 2 -> 3 -> 0
   reg [1:0] pc;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n)    pc <= 2'd0;
      else if (step) pc <= pc + 2'd1;
   end

   // fetch
   wire [31:0] instr;
   instr_rom irom(.pc(pc), .instr(instr));

   // decode (RV32I R-type field layout)
   wire [6:0] funct7  = instr[31:25];
   wire [4:0] rs2_f   = instr[24:20];
   wire [4:0] rs1_f   = instr[19:15];
   wire [4:0] rd_f    = instr[11:7];
   wire       alu_sub = funct7[5];   // 0000000=ADD, 0100000=SUB

   // register read/write
   wire [31:0] rs1_data, rs2_data;
   wire [31:0] alu_result;
   regfile rf(
      .clk(clk), .rst_n(rst_n),
      .rs1_addr(rs1_f[1:0]), .rs2_addr(rs2_f[1:0]), .rd_addr(rd_f[1:0]),
      .we(step), .wdata(alu_result),
      .rs1_data(rs1_data), .rs2_data(rs2_data)
   );

   // execute: same cla adder does both ADD and SUB
   // SUB = A + (~B) + 1  (standard two's-complement trick)
   wire [31:0] alu_b   = alu_sub ? ~rs2_data : rs2_data;
   wire        alu_cin = alu_sub;

   cla alu_adder(
      .a(rs1_data),
      .b(alu_b),
      .cin(alu_cin),
      .sum(alu_result)
   );

   // display register: latches the result each time an instruction executes
   reg [31:0] result_reg;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n)    result_reg <= 32'd0;
      else if (step) result_reg <= alu_result;
   end

   assign led = result_reg[5:0];
endmodule
