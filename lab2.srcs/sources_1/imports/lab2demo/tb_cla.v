`timescale 1ns / 1ps

// Self-checking testbench for the 32-bit CLA adder.
// Reference model: plain Verilog "+" (behavioral golden model), compared
// against the CLA's structural output for both directed edge cases and
// randomized regression.
module tb_cla;

   reg  [31:0] a, b;
   reg         cin;
   wire [31:0] sum;

   integer errors;
   integer i;
   reg [32:0] expected;

   cla dut (.a(a), .b(b), .cin(cin), .sum(sum));

   task check;
      input [255:0] msg;
      begin
         #1;
         expected = a + b + cin;   // golden reference model
         if (sum !== expected[31:0]) begin
            $display("FAIL : %s | a=%h b=%h cin=%b => got=%h expected=%h",
                      msg, a, b, cin, sum, expected[31:0]);
            errors = errors + 1;
         end
         else begin
            $display("PASS : %s | a=%h b=%h cin=%b => sum=%h", msg, a, b, cin, sum);
         end
      end
   endtask

   initial begin
      errors = 0;

      // ---- Directed edge cases ----
      a = 32'h0;        b = 32'h0;        cin = 0; check("0 + 0 + 0");
      a = 32'd5;        b = 32'd3;        cin = 0; check("5 + 3, no carry chain");
      a = 32'hFFFFFFFF; b = 32'h1;        cin = 0; check("all-ones + 1 -> overflow wraps to 0");
      a = 32'h7FFFFFFF; b = 32'h1;        cin = 0; check("max positive + 1 (signed-overflow case)");
      a = 32'hAAAAAAAA; b = 32'h55555555; cin = 0; check("alternating bits: pure propagate, zero generate");
      a = 32'hFFFFFFFF; b = 32'hFFFFFFFF; cin = 1; check("all-ones + all-ones + cin=1");
      a = 32'h12345678; b = 32'h87654321; cin = 1; check("mixed pattern with cin=1");
      a = 32'hFFFFFFFF; b = 32'h0;        cin = 1; check("cin must ripple through all 32 bits (worst-case chain)");

      // ---- Carry crossing every 4-bit window boundary ----
      // The CLA is built from eight 4-bit gp4 windows merged by gp8, so the
      // boundaries at bits 4, 8, 12, ... 28 are where a hierarchical carry
      // bug would hide. Each case forces a carry to cross one boundary.
      for (i = 1; i < 32; i = i + 1) begin
         a = (32'd1 << i) - 32'd1;   // i ones, bits [i-1:0]
         b = 32'd1;                  // +1 -> carry ripples up past bit i
         cin = 1'b0;
         check("ripple across window boundary");
      end

      // ---- Carry generated at each individual bit position ----
      for (i = 0; i < 32; i = i + 1) begin
         a = 32'd1 << i;
         b = 32'd1 << i;             // g=1 at bit i, carry into bit i+1
         cin = 1'b0;
         check("generate at single bit");
      end

      // ---- cin forced into a full propagate chain of varying length ----
      for (i = 1; i < 32; i = i + 1) begin
         a = (32'd1 << i) - 32'd1;   // all-propagate window
         b = 32'd0;
         cin = 1'b1;
         check("cin propagates through chain");
      end

      // ---- Randomized regression ----
      for (i = 0; i < 2000; i = i + 1) begin
         a   = $random;
         b   = $random;
         cin = $random;
         check("random case");
      end

      $display("==========================================");
      if (errors == 0)
         $display("ALL %0d TESTS PASSED", 8 + 31 + 32 + 31 + 2000);
      else
         $display("%0d FAILURES out of %0d TESTS", errors, 8 + 31 + 32 + 31 + 2000);
      $display("==========================================");
      $finish;
   end

endmodule
