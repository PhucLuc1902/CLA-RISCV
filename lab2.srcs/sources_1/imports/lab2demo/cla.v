`timescale 1ns / 1ps

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 *
 * Ports:
 *   g[3:0]  - bit-level generate signals for bits [3:0]
 *   p[3:0]  - bit-level propagate signals for bits [3:0]
 *   cin     - carry into bit 0 of this 4-bit block
 *   gout    - window generate (carry out of bit 3, ignoring cin)
 *   pout    - window propagate (all 4 bits propagate)
 *   cout[2:0] - internal carries:
 *              cout[0] = C1 (into bit 1)
 *              cout[1] = C2 (into bit 2)
 *              cout[2] = C3 (into bit 3)
 */
module gp4(input  wire [3:0] g, p,
           input  wire       cin,
           output wire       gout, pout,
           output wire [2:0] cout);

   // carries inside this 4-bit block
   wire c1, c2, c3;

   assign c1 = g[0] | (p[0] & cin);
   assign c2 = g[1] | (p[1] & c1);
   assign c3 = g[2] | (p[2] & c2);

   assign cout[0] = c1;
   assign cout[1] = c2;
   assign cout[2] = c3;

   // window propagate: all 4 bits must propagate
   assign pout = &p;  // p[3] & p[2] & p[1] & p[0]

   // window generate: carry out of bit 3, ignoring cin
   // prefix-style computation so gout doesn't depend on cin
   wire [3:0] g_prefix;
   assign g_prefix[0] = g[0];
   assign g_prefix[1] = g[1] | (p[1] & g_prefix[0]);
   assign g_prefix[2] = g[2] | (p[2] & g_prefix[1]);
   assign g_prefix[3] = g[3] | (p[3] & g_prefix[2]);

   assign gout = g_prefix[3];
endmodule

/**
 * Top-level CLA block for eight 4-bit windows (32 bits total).
 *
 * Ports:
 *   g[7:0], p[7:0] - window generate/propagate from gp4 blocks
 *   cin            - carry into bit 0 of the whole 32-bit adder
 *   gout           - window generate for all 32 bits (carry out ignoring cin)
 *   pout           - window propagate for all 32 bits
 *   cout[6:0]      - carries between 4-bit windows:
 *                    cout[0] = C4, cout[1] = C8, ... cout[6] = C28
 */
module gp8(input  wire [7:0] g, p,
           input  wire       cin,
           output wire       gout, pout,
           output wire [6:0] cout);

   // propagate of all 8 windows
   assign pout = &p;  // p[7] & ... & p[0]

   // carries between 4-bit windows (includes cin)
   wire [7:0] c_win;
   assign c_win[0] = cin;

   genvar i;
   generate
      for (i = 0; i < 7; i = i + 1) begin : CARRY_CHAIN
         assign c_win[i+1] = g[i] | (p[i] & c_win[i]);
      end
   endgenerate

   // C4, C8, ..., C28
   assign cout = c_win[7:1];

   // window generate for all 8 windows, ignoring cin
   // prefix on G/P just like in gp4
   wire [7:0] g_prefix;
   assign g_prefix[0] = g[0];
   generate
      for (i = 1; i < 8; i = i + 1) begin : GP_PREFIX
         assign g_prefix[i] = g[i] | (p[i] & g_prefix[i-1]);
      end
   endgenerate

   assign gout = g_prefix[7];
endmodule

module cla
  (input  wire [31:0] a, b,
   input  wire        cin,
   output wire [31:0] sum);

   // bit-level generate/propagate
   wire [31:0] g_bit, p_bit;

   genvar i;
   generate
      for (i = 0; i < 32; i = i + 1) begin : GP1_ARRAY
         gp1 gp1_inst(
            .a(a[i]),
            .b(b[i]),
            .g(g_bit[i]),
            .p(p_bit[i])
         );
      end
   endgenerate

   // gp4 blocks (each handles 4 bits)
   wire [7:0] g4, p4;
   wire [2:0] cout0, cout1, cout2, cout3;
   wire [2:0] cout4, cout5, cout6, cout7;

   // carries between 4-bit windows from gp8
   wire [6:0] c_block;

   // first 4-bit window uses cin
   gp4 gp4_0(.g(g_bit[ 3: 0]), .p(p_bit[ 3: 0]),
             .cin(cin),
             .gout(g4[0]), .pout(p4[0]), .cout(cout0));

   gp4 gp4_1(.g(g_bit[ 7: 4]), .p(p_bit[ 7: 4]),
             .cin(c_block[0]),
             .gout(g4[1]), .pout(p4[1]), .cout(cout1));

   gp4 gp4_2(.g(g_bit[11: 8]), .p(p_bit[11: 8]),
             .cin(c_block[1]),
             .gout(g4[2]), .pout(p4[2]), .cout(cout2));

   gp4 gp4_3(.g(g_bit[15:12]), .p(p_bit[15:12]),
             .cin(c_block[2]),
             .gout(g4[3]), .pout(p4[3]), .cout(cout3));

   gp4 gp4_4(.g(g_bit[19:16]), .p(p_bit[19:16]),
             .cin(c_block[3]),
             .gout(g4[4]), .pout(p4[4]), .cout(cout4));

   gp4 gp4_5(.g(g_bit[23:20]), .p(p_bit[23:20]),
             .cin(c_block[4]),
             .gout(g4[5]), .pout(p4[5]), .cout(cout5));

   gp4 gp4_6(.g(g_bit[27:24]), .p(p_bit[27:24]),
             .cin(c_block[5]),
             .gout(g4[6]), .pout(p4[6]), .cout(cout6));

   gp4 gp4_7(.g(g_bit[31:28]), .p(p_bit[31:28]),
             .cin(c_block[6]),
             .gout(g4[7]), .pout(p4[7]), .cout(cout7));

   // top gp8 over the 8 gp4 windows
   wire g8, p8;
   gp8 gp8_inst(
      .g(g4),
      .p(p4),
      .cin(cin),
      .gout(g8),
      .pout(p8),
      .cout(c_block)
   );

   // full bit-level carries C0..C32
   wire [32:0] c;
   assign c[0] = cin;

   // window 0: bits 0..3
   assign c[1] = cout0[0];
   assign c[2] = cout0[1];
   assign c[3] = cout0[2];
   assign c[4] = c_block[0];

   // window 1: bits 4..7
   assign c[5] = cout1[0];
   assign c[6] = cout1[1];
   assign c[7] = cout1[2];
   assign c[8] = c_block[1];

   // window 2: bits 8..11
   assign c[9]  = cout2[0];
   assign c[10] = cout2[1];
   assign c[11] = cout2[2];
   assign c[12] = c_block[2];

   // window 3: bits 12..15
   assign c[13] = cout3[0];
   assign c[14] = cout3[1];
   assign c[15] = cout3[2];
   assign c[16] = c_block[3];

   // window 4: bits 16..19
   assign c[17] = cout4[0];
   assign c[18] = cout4[1];
   assign c[19] = cout4[2];
   assign c[20] = c_block[4];

   // window 5: bits 20..23
   assign c[21] = cout5[0];
   assign c[22] = cout5[1];
   assign c[23] = cout5[2];
   assign c[24] = c_block[5];

   // window 6: bits 24..27
   assign c[25] = cout6[0];
   assign c[26] = cout6[1];
   assign c[27] = cout6[2];
   assign c[28] = c_block[6];

   // window 7: bits 28..31
   assign c[29] = cout7[0];
   assign c[30] = cout7[1];
   assign c[31] = cout7[2];

   // final carry-out of the 32-bit adder
   assign c[32] = g8 | (p8 & cin);

   // final sum bits: Si = Ai ⊕ Bi ⊕ Ci
   generate
      for (i = 0; i < 32; i = i + 1) begin : SUM_BITS
         assign sum[i] = a[i] ^ b[i] ^ c[i];
      end
   endgenerate
endmodule
