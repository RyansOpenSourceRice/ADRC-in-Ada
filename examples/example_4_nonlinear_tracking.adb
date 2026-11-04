--  SPDX-License-Identifier: Apache-2.0
--
--  Example 4: nonlinear ADRC (fal-based) on a double integrator.
--
--  The plant is y'' = u + d (effectiveness b = 1) with a constant
--  output disturbance d = 5 that switches on at t = 5 s. The loop is
--  the full nonlinear stack: fhan tracking differentiator, fal-based
--  extended state observer, and nonlinear state error feedback. The
--  observer estimates the disturbance in z3 and the law cancels it.
--  Prints the trajectory, the disturbance estimate, and the control
--  signal every second for the first ten seconds.

with Ada.Text_IO;
with ADRC_Ada.NL_Controller;

procedure Example_4_Nonlinear_Tracking is

   package Ctrl is new ADRC_Ada.NL_Controller (Long_Float);
   package FIO is new Ada.Text_IO.Float_IO (Long_Float);

   --  Observer cascade and fal exponents chosen for Euler stability at
   --  Ts = 0.01; see the test suite notes on discrete fal stability.
   Cfg : constant Ctrl.Config :=
     (TD_Rate    => 20.0, TD_Filter => 0.05,
      Beta01     => 15.0, Beta02 => 45.0, Beta03 => 70.0,
      Eso_Alpha1 => 0.9, Eso_Alpha2 => 0.9, Eso_Width => 0.1,
      B0         => 1.0,
      Beta1      => 40.0, Beta2 => 10.0,
      Ctl_Alpha1 => 0.75, Ctl_Alpha2 => 1.25, Ctl_Width => 0.01,
      Ts         => 0.01);

   S : Ctrl.State;
   U : Ctrl.Control_Signal := 0.0;
   Y, V, D : Long_Float := 0.0;

begin
   Ctrl.Reset (S, 1.0);
   Ada.Text_IO.Put_Line ("  t         y            z3           u");
   for K in 0 .. 1000 loop
      if K mod 100 = 0 then
         FIO.Put (Long_Float (K) * Cfg.Ts, 4, 2, 0);
         Ada.Text_IO.Put ("  ");
         FIO.Put (Y, 1, 6, 0);
         Ada.Text_IO.Put ("   ");
         FIO.Put (S.Obs.Z3, 1, 6, 0);
         Ada.Text_IO.Put ("   ");
         FIO.Put (U, 1, 4, 0);
         Ada.Text_IO.New_Line;
      end if;
      Ctrl.Step (Cfg, S, 1.0, Y, U);
      --  Plant: y'' = u + d; the disturbance switches on at 5 s.
      D := (if Long_Float (K) * Cfg.Ts >= 5.0 then 5.0 else 0.0);
      V := V + Cfg.Ts * (U + D);
      Y := Y + Cfg.Ts * V;
   end loop;
   Ada.Text_IO.Put ("settling error |y - 1| = ");
   FIO.Put (abs (Y - 1.0), 1, 9, 0);
   Ada.Text_IO.New_Line;
end Example_4_Nonlinear_Tracking;
