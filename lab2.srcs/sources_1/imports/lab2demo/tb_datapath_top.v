`timescale 1ns / 1ps

// Self-checking testbench for SystemDatapath.
// Drives btn[2] as reset and btn[3] as the "step" button, then checks
// led[5:0] (= low 6 bits of the last ALU result) after each instruction.
//
// Program in instr_rom.v, with R1=5, R2=3 after reset:
//   I0: R3 = R1 + R2  = 5 + 3  =  8
//   I1: R3 = R1 - R2  = 5 - 3  =  2
//   I2: R3 = R2 + R3  = 3 + 2  =  5
//   I3: R3 = R2 - R3  = 3 - 5  = -2  (wraps to 6'b111110 = 0x3E on 6 bits)
//   then PC wraps back to I0 and the same sequence repeats.
module tb_datapath_top;

   reg        clk;
   reg [6:0]  btn;
   wire [5:0] led;

   SystemDatapath dut (
      .clk(clk),
      .btn(btn),
      .led(led)
   );

   // Clock generation
   initial begin
      clk = 0;
      forever #5 clk = ~clk;   // 10ns period
   end

   // Helpers

   task wait_posedge;
      input integer n;
      integer k;
      begin
         for (k = 0; k < n; k = k + 1)
            @(posedge clk);
      end
   endtask

   // Buttons are active HIGH on the board, so btn[2]=1 means "BTN0 pressed"
   // which is what asserts the design's active-low reset.
   task do_reset;
      begin
         btn = 7'b0000000;
         btn[2] = 1'b1;      // press BTN0 -> rst_n asserted
         wait_posedge(2);
         #1;
         btn[2] = 1'b0;      // release BTN0 -> out of reset
      end
   endtask

   // Presses btn[3] the way a human would: held for several clocks, then
   // released for several clocks. btn[3] passes through a 2-flop
   // synchronizer plus one edge-detect flop inside the DUT, so the press
   // must be held long enough to propagate (and the release long enough for
   // the synchronizer to fall back to 0 before the next press). The DUT
   // turns that into exactly one single-cycle "step" pulse.
   task do_step;
      begin
         btn[3] = 1'b1;
         wait_posedge(4);
         #1;
         btn[3] = 1'b0;
         wait_posedge(4);
         #1;
      end
   endtask

   task check_led;
      input [5:0]   exp;
      input [255:0] msg;
      begin
         #1;
         if (led !== exp) begin
            $display("FAIL @%0t : %s | expected=%h got=%h", $time, msg, exp, led);
            $stop;
         end
         else begin
            $display("PASS @%0t : %s | led=%h", $time, msg, led);
         end
      end
   endtask

   // Main test

   initial begin
      // CASE 1: Reset -> PC=0, R3=0, led all 0

      do_reset();
      check_led(6'h00, "after reset, led = R3 = 0");

      // CASE 2: I0  R3 = R1 + R2 = 5 + 3 = 8

      do_step();
      check_led(6'h08, "I0: R3 = R1 + R2 = 8");

      // CASE 3: I1  R3 = R1 - R2 = 5 - 3 = 2 (CLA reused for subtraction)

      do_step();
      check_led(6'h02, "I1: R3 = R1 - R2 = 2");

      // CASE 4: I2  R3 = R2 + R3 = 3 + 2 = 5 (chained, uses previous result)

      do_step();
      check_led(6'h05, "I2: R3 = R2 + R3 = 5");

      // CASE 5: I3  R3 = R2 - R3 = 3 - 5 = -2 -> low 6 bits = 111110 (0x3E)

      do_step();
      check_led(6'h3E, "I3: R3 = R2 - R3 = -2 (wraps to 0x3E on 6 bits)");

      // CASE 6: PC wraps back to I0, program repeats identically

      do_step();
      check_led(6'h08, "wrap-around: I0 again, R3 = R1 + R2 = 8");

      // CASE 7: Reset mid-sequence must restore the program to a known start

      do_reset();
      check_led(6'h00, "reset mid-sequence, back to R3 = 0");

      do_step();
      check_led(6'h08, "after mid-sequence reset, I0 gives 8 again");

      $display("==========================================");
      $display("ALL TESTS PASSED");
      $display("==========================================");
      $finish;
   end

endmodule
