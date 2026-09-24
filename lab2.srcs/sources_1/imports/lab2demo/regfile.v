`timescale 1ns / 1ps

// 4-entry register file (R0 hardwired to 0, like RISC-V x0).
// R1/R2 are the fixed demo operands, R3 is the writable accumulator.
module regfile(
   input  wire        clk,
   input  wire        rst_n,
   input  wire [1:0]  rs1_addr,
   input  wire [1:0]  rs2_addr,
   input  wire [1:0]  rd_addr,
   input  wire        we,
   input  wire [31:0] wdata,
   output wire [31:0] rs1_data,
   output wire [31:0] rs2_data
);
   // Index 0 is stored too (and kept at zero) so that reading address 0
   // never indexes outside the array.
   reg [31:0] regs [0:3];

   assign rs1_data = (rs1_addr == 2'd0) ? 32'd0 : regs[rs1_addr];
   assign rs2_data = (rs2_addr == 2'd0) ? 32'd0 : regs[rs2_addr];

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         regs[0] <= 32'd0;   // R0: hardwired zero, never written
         regs[1] <= 32'd5;   // R1: fixed operand A
         regs[2] <= 32'd3;   // R2: fixed operand B
         regs[3] <= 32'd0;   // R3: accumulator, written by ADD/SUB
      end
      else if (we && rd_addr != 2'd0) begin
         regs[rd_addr] <= wdata;
      end
   end
endmodule
