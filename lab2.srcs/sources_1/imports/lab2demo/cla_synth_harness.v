`timescale 1ns / 1ps

// Synthesis harness whose only job is to let the full 32-bit CLA survive
// optimisation so it can actually be measured.
//
// Two conditions must hold, and the plain board demo breaks both:
//   1. The operands must not be compile-time constants, otherwise synthesis
//      constant-folds the whole adder away. Two LFSRs supply 32 genuinely
//      unknown bits each.
//   2. Every one of the 32 sum bits must reach an output, otherwise the bits
//      that only feed unused upper bits are dead logic. The six LEDs are
//      driven by XOR reductions that between them cover all 32 bits.
//
// Operands and result are registered, so the adder sits on a clean
// register-to-register path and the timing report measures the carry
// network itself rather than I/O delay.
module cla_synth_harness(
   input  wire       clk,
   input  wire [6:0] btn,
   output wire [5:0] led
);
   wire rst_n = ~btn[2];

   // maximal-length-style LFSRs: synthesis cannot fold these to constants
   reg [31:0] lfsr_a, lfsr_b;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         lfsr_a <= 32'h1234_5678;
         lfsr_b <= 32'h9ABC_DEF0;
      end
      else begin
         lfsr_a <= {lfsr_a[30:0], lfsr_a[31] ^ lfsr_a[21] ^ lfsr_a[1] ^ lfsr_a[0]};
         lfsr_b <= {lfsr_b[30:0], lfsr_b[31] ^ lfsr_b[21] ^ lfsr_b[1] ^ lfsr_b[0]};
      end
   end

   // registered operands -> adder is on a register-to-register path
   reg [31:0] a_reg, b_reg;
   reg        cin_reg;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         a_reg   <= 32'd0;
         b_reg   <= 32'd0;
         cin_reg <= 1'b0;
      end
      else begin
         a_reg   <= lfsr_a;
         b_reg   <= lfsr_b;
         cin_reg <= lfsr_a[0];
      end
   end

   wire [31:0] sum;

   cla dut (
      .a(a_reg),
      .b(b_reg),
      .cin(cin_reg),
      .sum(sum)
   );

   reg [31:0] sum_reg;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) sum_reg <= 32'd0;
      else        sum_reg <= sum;
   end

   // 5+5+6+5+6+5 = 32 bits, so every sum bit is observable
   assign led = { ^sum_reg[31:27],
                  ^sum_reg[26:22],
                  ^sum_reg[21:16],
                  ^sum_reg[15:11],
                  ^sum_reg[10:5],
                  ^sum_reg[4:0]  };
endmodule
