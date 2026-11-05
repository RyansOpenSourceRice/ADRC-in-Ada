--  SPDX-License-Identifier: Apache-2.0
--
--  Example 5: the same loop without a floating-point unit.
--
--  Example 2's disturbance-rejection scenario (y'' = u + 5, tracking
--  the unit step), run entirely in a 32-bit fixed-point type. The
--  controller instantiates the fixed-point family; the plant model is
--  simulated in the same fixed type, so the loop performs no floating
--  point arithmetic. Floating point appears only in printing, outside
--  the loop.
--
--  The type is Q20_11 (delta 2**(-11), span +/- 2**20): the smallest
--  power-of-two grid a 32-bit word can hold that covers the library's
--  +/- 1.0e6 signal bound. Its resolution of about 5e-4 is visible as
--  a quantization noise floor on the disturbance estimate z3.

with Ada.Text_IO;
with ADRC_Ada.Fixed_Controller;

procedure Example_5_Fixed_Point is

   --  32-bit fixed point: 1 sign bit, 20 integer bits, 11 fraction bits.
   type Q20_11 is delta 2.0**(-11) range -1048576.0 .. 1048575.99951171875
     with Size => 32;

   package FCtrl is new ADRC_Ada.Fixed_Controller (Q20_11);
   package FIO is new Ada.Text_IO.Float_IO (Long_Float);

   Cfg : constant FCtrl.Config :=
     (TD_Bandwidth => 10.0, Wo => 20.0, Wc => 10.0,
      B0 => 1.0, Ts => 0.01);

   S : FCtrl.State;
   U : FCtrl.Control_Signal := 0.0;
   Y, V : Q20_11 := 0.0;
   D : constant Q20_11 := 5.0;

begin
   FCtrl.Reset (S, 1.0);
   Ada.Text_IO.Put_Line ("  t         y           z3           u");
   for K in 0 .. 3000 loop
      if K mod 200 = 0 then
         FIO.Put (Long_Float (K) * 0.01, 4, 2, 0);
         Ada.Text_IO.Put ("  ");
         FIO.Put (Long_Float (Y), 1, 6, 0);
         Ada.Text_IO.Put ("   ");
         FIO.Put (Long_Float (S.Obs.Z3), 1, 5, 0);
         Ada.Text_IO.Put ("   ");
         FIO.Put (Long_Float (U), 1, 4, 0);
         Ada.Text_IO.New_Line;
      end if;
      FCtrl.Step (Cfg, S, 1.0, Y, U);
      --  Plant: y'' = u + d, simulated in the same fixed type.
      V := Q20_11 (V + Cfg.Ts * (U + D));
      Y := Q20_11 (Y + Cfg.Ts * V);
   end loop;
   Ada.Text_IO.Put ("settling error |y - 1| = ");
   FIO.Put (abs (Long_Float (Y) - 1.0), 1, 9, 0);
   Ada.Text_IO.Put ("   z3 estimate = ");
   FIO.Put (Long_Float (S.Obs.Z3), 1, 6, 0);
   Ada.Text_IO.Put_Line ("  (true disturbance: 5)");
end Example_5_Fixed_Point;
