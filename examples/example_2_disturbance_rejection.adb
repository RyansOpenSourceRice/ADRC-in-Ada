--  SPDX-License-Identifier: Apache-2.0
--
--  Example 2: disturbance rejection on a double integrator.
--
--  Same plant as example 1, but a constant output disturbance of +5.0
--  acts on the plant: y'' = u + 5. A PD controller would settle at the
--  wrong value; ADRC's extended state z3 estimates the disturbance and
--  cancels it, so y still converges to 1.

with Ada.Text_IO;
with ADRC_Ada.Controller;

procedure Example_2_Disturbance_Rejection is

   package Ctrl is new ADRC_Ada.Controller (Long_Float);
   package FIO is new Ada.Text_IO.Float_IO (Long_Float);

   Cfg : constant Ctrl.Config :=
     (TD_Bandwidth => 10.0, Wo => 20.0, Wc => 10.0,
      B0 => 1.0, Ts => 0.01);

   S : Ctrl.State;
   U : Ctrl.Control_Signal := 0.0;
   Y, V : Long_Float := 0.0;
   D : constant Long_Float := 5.0;

begin
   Ctrl.Reset (S, 1.0);
   Ada.Text_IO.Put_Line ("  t         y           z3           u");
   for K in 0 .. 3000 loop
      if K mod 200 = 0 then
         FIO.Put (Long_Float (K) * Cfg.Ts, 4, 2, 0);
         Ada.Text_IO.Put ("  ");
         FIO.Put (Y, 1, 6, 0);
         Ada.Text_IO.Put ("   ");
         FIO.Put (S.Obs.Z3, 1, 5, 0);
         Ada.Text_IO.Put ("   ");
         FIO.Put (U, 1, 4, 0);
         Ada.Text_IO.New_Line;
      end if;
      Ctrl.Step (Cfg, S, 1.0, Y, U);
      --  Plant: y'' = u + d.
      V := V + Cfg.Ts * (U + D);
      Y := Y + Cfg.Ts * V;
   end loop;
   Ada.Text_IO.Put ("settling error |y - 1| = ");
   FIO.Put (abs (Y - 1.0), 1, 9, 0);
   Ada.Text_IO.Put ("   z3 estimate = ");
   FIO.Put (S.Obs.Z3, 1, 6, 0);
   Ada.Text_IO.Put_Line ("  (true disturbance: 5)");
end Example_2_Disturbance_Rejection;
