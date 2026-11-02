--  SPDX-License-Identifier: Apache-2.0
--
--  Example 3: large reference with saturation.
--
--  A reference of 1000 demands a control effort far beyond what the
--  loop would normally output; the control law saturates at
--  +/- Max_Magnitude by contract, and the loop still converges. This
--  exercises the bounded-arithmetic guarantees the SPARK proofs are
--  about: nothing in the loop can exceed the declared ranges.

with Ada.Text_IO;
with ADRC_Ada;
with ADRC_Ada.Controller;

procedure Example_3_Saturation is

   package Ctrl is new ADRC_Ada.Controller (Long_Float);
   package FIO is new Ada.Text_IO.Float_IO (Long_Float);

   Cfg : constant Ctrl.Config :=
     (TD_Bandwidth => 10.0, Wo => 20.0, Wc => 10.0,
      B0 => 1.0, Ts => 0.01);

   S : Ctrl.State;
   U : Ctrl.Control_Signal := 0.0;
   Y, V : Long_Float := 0.0;
   Max_U : Long_Float := 0.0;

begin
   Ctrl.Reset (S, 1000.0);
   Ada.Text_IO.Put_Line ("  t         y            u     (ref = 1000)");
   for K in 0 .. 3000 loop
      Max_U := Long_Float'Max (Max_U, abs U);
      if K mod 200 = 0 then
         FIO.Put (Long_Float (K) * Cfg.Ts, 4, 2, 0);
         Ada.Text_IO.Put ("  ");
         FIO.Put (Y, 2, 3, 0);
         Ada.Text_IO.Put ("   ");
         FIO.Put (U, 2, 2, 0);
         Ada.Text_IO.New_Line;
      end if;
      Ctrl.Step (Cfg, S, 1000.0, Y, U);
      --  Plant: y'' = u.
      V := V + Cfg.Ts * U;
      Y := Y + Cfg.Ts * V;
   end loop;
   Ada.Text_IO.Put ("peak |u| = ");
   FIO.Put (Max_U, 2, 2, 0);
   Ada.Text_IO.Put ("  (saturates at ");
   FIO.Put (ADRC_Ada.Max_Magnitude, 2, 0, 0);
   Ada.Text_IO.Put (")   settling error |y - 1000| = ");
   FIO.Put (abs (Y - 1000.0), 2, 6, 0);
   Ada.Text_IO.New_Line;
end Example_3_Saturation;
