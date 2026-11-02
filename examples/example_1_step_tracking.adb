--  SPDX-License-Identifier: Apache-2.0
--
--  Example 1: step tracking on a double integrator.
--
--  The plant is y'' = u (effectiveness b = 1). The ADRC loop tracks a
--  unit step with controller bandwidth wc = 10, observer bandwidth
--  wo = 20. Prints the trajectory every second for the first ten
--  seconds and the settling error at the end.

with Ada.Text_IO;
with ADRC_Ada.Controller;

procedure Example_1_Step_Tracking is

   package Ctrl is new ADRC_Ada.Controller (Long_Float);
   package FIO is new Ada.Text_IO.Float_IO (Long_Float);

   Cfg : constant Ctrl.Config :=
     (TD_Bandwidth => 10.0, Wo => 20.0, Wc => 10.0,
      B0 => 1.0, Ts => 0.01);

   S : Ctrl.State;
   U : Ctrl.Control_Signal := 0.0;
   Y, V : Long_Float := 0.0;

begin
   Ctrl.Reset (S, 1.0);
   Ada.Text_IO.Put_Line ("  t         y            u");
   for K in 0 .. 1000 loop
      if K mod 100 = 0 then
         FIO.Put (Long_Float (K) * Cfg.Ts, 4, 2, 0);
         Ada.Text_IO.Put ("  ");
         FIO.Put (Y, 1, 6, 0);
         Ada.Text_IO.Put ("   ");
         FIO.Put (U, 1, 4, 0);
         Ada.Text_IO.New_Line;
      end if;
      Ctrl.Step (Cfg, S, 1.0, Y, U);
      --  Plant: y'' = u.
      V := V + Cfg.Ts * U;
      Y := Y + Cfg.Ts * V;
   end loop;
   Ada.Text_IO.Put ("settling error |y - 1| = ");
   FIO.Put (abs (Y - 1.0), 1, 9, 0);
   Ada.Text_IO.New_Line;
end Example_1_Step_Tracking;
