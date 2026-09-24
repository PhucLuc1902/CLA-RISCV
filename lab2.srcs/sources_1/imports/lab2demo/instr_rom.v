`timescale 1ns / 1ps

// Tiny 4-entry instruction ROM. Encoding follows the RV32I R-type layout
// (funct7 | rs2 | rs1 | funct3 | rd | opcode) so it decodes exactly like
// real RV32I ADD/SUB -- rs1/rs2/rd are truncated to 2 bits by the top
// module since this demo register file only has 4 entries.
module instr_rom(
   input  wire [1:0]  pc,
   output reg  [31:0] instr
);
   localparam OPC_R      = 7'b0110011;
   localparam F3_ADD_SUB = 3'b000;
   localparam F7_ADD     = 7'b0000000;
   localparam F7_SUB     = 7'b0100000;

   always @(*) begin
      case (pc)
         // R3 = R1 + R2
         2'd0: instr = {F7_ADD, 5'd2, 5'd1, F3_ADD_SUB, 5'd3, OPC_R};
         // R3 = R1 - R2
         2'd1: instr = {F7_SUB, 5'd2, 5'd1, F3_ADD_SUB, 5'd3, OPC_R};
         // R3 = R2 + R3   (chained: uses the previous result)
         2'd2: instr = {F7_ADD, 5'd3, 5'd2, F3_ADD_SUB, 5'd3, OPC_R};
         // R3 = R2 - R3   (chained: uses the previous result)
         2'd3: instr = {F7_SUB, 5'd3, 5'd2, F3_ADD_SUB, 5'd3, OPC_R};
         default: instr = {F7_ADD, 5'd0, 5'd0, F3_ADD_SUB, 5'd0, OPC_R};
      endcase
   end
endmodule
