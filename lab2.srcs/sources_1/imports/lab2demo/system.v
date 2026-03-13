`include "cla.v"

module SystemDemo(
   input wire [6:0] btn,
   // CHANGE: Increase width to 6 bits (led[0] to led[5])
   output wire [5:0] led 
);
   wire [31:0] sum;
   
   cla cla_inst(
      .a(32'd26),
      .b({27'b0, btn[1], btn[2], btn[5], btn[4], btn[0]}), 
      .cin(1'b0), 
      .sum(sum)
   );

   // CHANGE: Assign the lower 6 bits of sum to the LEDs
   assign led = sum[5:0];
   
endmodule