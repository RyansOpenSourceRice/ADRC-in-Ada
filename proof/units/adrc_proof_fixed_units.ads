--  SPDX-License-Identifier: Apache-2.0
--
--  Fixed-point proof-only instantiations, mirroring
--  adrc_proof_units.ads at two fixed-point real types:
--
--  * Q20_11: 32-bit, delta 2**(-11), the smallest power-of-two
--    resolution whose +/- 2**20 span holds the +/- Max_Magnitude
--    signal bound (a 32-bit Q16.16 span of +/- 2**15 does not).
--  * Q31_32: 64-bit, delta 2**(-32), the fine-resolution no-float
--    format.
--
--  These instantiations exist for gnatprove only; the demo types live
--  with their demo programs.

with ADRC_Ada.Fixed_Control;
with ADRC_Ada.Fixed_Controller;
with ADRC_Ada.Fixed_LESO;
with ADRC_Ada.Fixed_Limits;
with ADRC_Ada.Fixed_TD;

package Adrc_Proof_Fixed_Units with SPARK_Mode is

   --  32-bit fixed point: 1 sign bit, 20 integer bits, 11 fraction bits.
   type Q20_11 is delta 2.0**(-11) range -1048576.0 .. 1048575.99951171875
     with Size => 32;

   --  64-bit fixed point: 1 sign bit, 31 integer bits, 32 fraction bits.
   type Q31_32 is delta 2.0**(-32)
     range -2147483648.0 .. 2147483647.99999999976716935634613037109375
     with Size => 64;

   package Lim_11 is new ADRC_Ada.Fixed_Limits (Q20_11);
   package TD_11 is new ADRC_Ada.Fixed_TD (Q20_11);
   package Eso_11 is new ADRC_Ada.Fixed_LESO (Q20_11);
   package Control_11 is new ADRC_Ada.Fixed_Control (Q20_11);
   package Controller_11 is new ADRC_Ada.Fixed_Controller (Q20_11);

   package Lim_32 is new ADRC_Ada.Fixed_Limits (Q31_32);
   package TD_32 is new ADRC_Ada.Fixed_TD (Q31_32);
   package Eso_32 is new ADRC_Ada.Fixed_LESO (Q31_32);
   package Control_32 is new ADRC_Ada.Fixed_Control (Q31_32);
   package Controller_32 is new ADRC_Ada.Fixed_Controller (Q31_32);

end Adrc_Proof_Fixed_Units;
