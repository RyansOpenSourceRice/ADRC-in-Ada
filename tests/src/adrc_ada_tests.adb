--  SPDX-License-Identifier: Apache-2.0
--
--  Test crate for adrc_ada at IEEE double capacity (Long_Float).
--
--  Sections:
--    1. Unit checks: saturation, control law, configuration validity,
--       tracking differentiator convergence.
--    2. Closed-loop simulation: double integrator and damped second-
--       order plant, with and without constant output disturbances,
--       checking convergence and observer estimation.
--    3. Golden regression: key trajectory values recorded from a
--       verified run (printed as golden candidates each run).
--    4. Nonlinear units: fal power law, fhan synthesis bound, and the
--       nonlinear (fal-based) controller on the same plant family.
--
--  Exit status 0 = all checks passed.

with Ada.Command_Line;
with Ada.Text_IO;
with ADRC_Ada;
with ADRC_Ada.Controller;
with ADRC_Ada.Control;
with ADRC_Ada.Fal;
with ADRC_Ada.LESO;
with ADRC_Ada.NL_Controller;
with ADRC_Ada.NL_TD;
with ADRC_Ada.TD;

procedure Adrc_Ada_Tests is

   Checks_Total  : Natural := 0;
   Checks_Failed : Natural := 0;

   procedure Check (Name : String; OK : Boolean) is
   begin
      Checks_Total := Checks_Total + 1;
      if OK then
         Ada.Text_IO.Put_Line ("PASS  " & Name);
      else
         Checks_Failed := Checks_Failed + 1;
         Ada.Text_IO.Put_Line ("FAIL  " & Name);
      end if;
   end Check;

   --  Instances under test, at IEEE double capacity.
   package Ctrl is new ADRC_Ada.Controller (Long_Float);
   package Law_Unit is new ADRC_Ada.Control (Long_Float);
   package TD_Unit is new ADRC_Ada.TD (Long_Float);
   package Obs_Unit is new ADRC_Ada.LESO (Long_Float);
   package NL_Ctrl is new ADRC_Ada.NL_Controller (Long_Float);
   package F_Unit is new ADRC_Ada.Fal (Long_Float);
   package NTD is new ADRC_Ada.NL_TD (Long_Float);
   package FIO is new Ada.Text_IO.Float_IO (Long_Float);

   --  The reference configuration for the closed-loop sims.
   Base_Cfg : constant Ctrl.Config :=
     (TD_Bandwidth => 10.0,
      Wo           => 20.0,
      Wc           => 10.0,
      B0           => 1.0,
      Ts           => 0.01);

   --  The reference configuration for the nonlinear closed-loop sims.
   --  The observer cascade and fal exponents are chosen for Euler
   --  stability at Ts = 0.01: outside the fal width the continuation
   --  slope is delta^(alpha-1), so the classical Han gain triple
   --  (30 / 300 / 1000) needs much finer sample times than this sim
   --  uses; the classical values remain the library defaults for
   --  fine-sample deployments.
   NL_Cfg : constant NL_Ctrl.Config :=
     (TD_Rate    => 20.0,
      TD_Filter  => 0.05,
      Beta01     => 15.0,
      Beta02     => 45.0,
      Beta03     => 70.0,
      Eso_Alpha1 => 0.9,
      Eso_Alpha2 => 0.9,
      Eso_Width  => 0.1,
      B0         => 1.0,
      Beta1      => 40.0,
      Beta2      => 10.0,
      Ctl_Alpha1 => 0.75,
      Ctl_Alpha2 => 1.25,
      Ctl_Width  => 0.01,
      Ts         => 0.01);

   --  Golden values from the verified baseline run (double integrator,
   --  unit step, no disturbance; trajectory at t = 2 s, 5 s, 10 s).
   --  Regression compares against these with a tight tolerance; a
   --  behavioral drift anywhere in the loop breaks the build.
   Golden_Y_2s : Long_Float := 0.0;
   Golden_Y_5s : Long_Float := 0.0;
   Golden_Y_10s : Long_Float := 0.0;
   Golden_Y_2s_Ref : constant := 0.999989106;
   Golden_Tol : constant := 1.0E-9;

   --  Golden value of the nonlinear loop (double integrator, unit
   --  step, no disturbance, at t = 2 s). The power-law fal terms
   --  limit-cycle at small amplitude around the fixed point, so the
   --  convergence tolerances below are correspondingly wider than
   --  the linear loop's.
   Golden_NL_Y_2s : Long_Float := 0.0;
   Golden_NL_Y_2s_Ref : constant := 0.989316672;

   --  Simulate the double-integrator plant y'' = u + d with explicit
   --  Euler, tracking Ref. Returns trajectory checkpoints for the
   --  golden regression.
   procedure Sim_Double_Integrator
     (Cfg      : Ctrl.Config;
      Ref      : Long_Float;
      D        : Long_Float;
      Steps    : Natural;
      Record_Golden : Boolean;
      Final_Y  : out Long_Float;
      Final_Z3 : out Long_Float;
      Max_Abs_U : out Long_Float)
   is
      S : Ctrl.State;
      U : Ctrl.Control_Signal := 0.0;
      Y, V : Long_Float := 0.0;
   begin
      Ctrl.Reset (S, Ref);
      for K in 1 .. Steps loop
         Ctrl.Step (Cfg, S, Ref, Y, U);
         --  Plant: y'' = u + d (effectiveness b = 1).
         V := V + Cfg.Ts * (U + D);
         Y := Y + Cfg.Ts * V;
         Max_Abs_U := Long_Float'Max (Max_Abs_U, abs U);
         if Record_Golden then
            if K = 200 then
               Golden_Y_2s := Y;
            end if;
            if K = 500 then
               Golden_Y_5s := Y;
            end if;
            if K = 1000 then
               Golden_Y_10s := Y;
            end if;
         end if;
      end loop;
      Final_Y := Y;
      Final_Z3 := S.Obs.Z3;
   end Sim_Double_Integrator;

   --  Same plant under the nonlinear (fal-based) controller.
   procedure Sim_NL_Double_Integrator
     (Cfg      : NL_Ctrl.Config;
      Ref      : Long_Float;
      D        : Long_Float;
      Steps    : Natural;
      Record_Golden : Boolean;
      Final_Y  : out Long_Float;
      Final_Z3 : out Long_Float;
      Max_Abs_U : out Long_Float)
   is
      S : NL_Ctrl.State;
      U : NL_Ctrl.Control_Signal := 0.0;
      Y, V : Long_Float := 0.0;
   begin
      NL_Ctrl.Reset (S, Ref);
      for K in 1 .. Steps loop
         NL_Ctrl.Step (Cfg, S, Ref, Y, U);
         --  Plant: y'' = u + d (effectiveness b = 1).
         V := V + Cfg.Ts * (U + D);
         Y := Y + Cfg.Ts * V;
         Max_Abs_U := Long_Float'Max (Max_Abs_U, abs U);
         if Record_Golden and then K = 200 then
            Golden_NL_Y_2s := Y;
         end if;
      end loop;
      Final_Y := Y;
      Final_Z3 := S.Obs.Z3;
   end Sim_NL_Double_Integrator;

   Final_Y : Long_Float;
   Final_Z3 : Long_Float;
   Max_Abs_U : Long_Float := 0.0;

begin
   Ada.Text_IO.Put_Line ("=== adrc_ada test suite (Long_Float) ===");

   --  ---- 1. Unit checks -------------------------------------------

   Check ("saturate returns midpoint unchanged",
          Ctrl.Lim.Saturate (0.5, -1.0, 1.0) = 0.5);
   Check ("saturate clamps above", Ctrl.Lim.Saturate (5.0, -1.0, 1.0) = 1.0);
   Check ("saturate clamps below", Ctrl.Lim.Saturate (-5.0, -1.0, 1.0) = -1.0);

   Check ("law at unit step returns wc^2 / b0",
          abs (Law_Unit.Law (10.0, 1.0, 0.0, 0.0, 0.0, 1.0) - 100.0) < 1.0E-9);
   Check ("law cancels observed disturbance",
          abs (Law_Unit.Law (10.0, 1.0, 0.0, 0.0, 100.0, 1.0) - 0.0) < 1.0E-9);

   Check ("valid config accepted", Ctrl.Valid_Config (Base_Cfg));
   Check ("euler-unstable config rejected",
          not Ctrl.Valid_Config
            (Ctrl.Config'(TD_Bandwidth => 10.0, Wo => 30.0, Wc => 10.0,
                          B0 => 1.0, Ts => 0.5)));

   declare
      TD_S : TD_Unit.State;
      V1, V2 : TD_Unit.Signal;
   begin
      TD_Unit.Reset (TD_S, 1.0);
      for K in 1 .. 300 loop
         pragma Unreferenced (K);
         TD_Unit.Step ((Rate => 10.0, Ts => 0.01), TD_S, 1.0, V1, V2);
      end loop;
      Check ("td converges to reference", abs (V1 - 1.0) < 1.0E-4);
      Check ("td derivative settles to zero", abs V2 < 1.0E-4);
   end;

   declare
      Obs_Cfg : constant Obs_Unit.Config :=
        (Wo => 20.0, B0 => 1.0, Ts => 0.01);
      Obs_S : Obs_Unit.State;
   begin
      Obs_Unit.Reset (Obs_S);
      Check ("leso reset zeroes state",
            Obs_S.Z1 = 0.0 and then Obs_S.Z2 = 0.0 and then Obs_S.Z3 = 0.0);
      --  Feed a constant-output plant: y stays 0, u stays 0; nothing to
      --  observe; estimates must stay put.
      for K in 1 .. 300 loop
         pragma Unreferenced (K);
         Obs_Unit.Step (Obs_Cfg, Obs_S, 0.0, 0.0);
      end loop;
      Check ("leso holds zero at zero input",
            abs Obs_S.Z1 < 1.0E-12 and then abs Obs_S.Z3 < 1.0E-12);
   end;

   --  ---- 2. Closed loop: double integrator, no disturbance --------

   Sim_Double_Integrator
     (Base_Cfg, Ref => 1.0, D => 0.0, Steps => 3000, Record_Golden => True,
      Final_Y => Final_Y, Final_Z3 => Final_Z3, Max_Abs_U => Max_Abs_U);
   Ada.Text_IO.Put ("golden candidates: Y(2s)=");
   FIO.Put (Golden_Y_2s, 2, 9, 0);
   Ada.Text_IO.Put ("  Y(5s)=");
   FIO.Put (Golden_Y_5s, 2, 9, 0);
   Ada.Text_IO.Put ("  Y(10s)=");
   FIO.Put (Golden_Y_10s, 2, 9, 0);
   Ada.Text_IO.New_Line;
   Check ("closed loop converges to unit step (y -> 1)",
          abs (Final_Y - 1.0) < 1.0E-6);
   Check ("observer disturbance estimate settles to zero (z3 -> 0)",
          abs Final_Z3 < 1.0E-6);
   Check ("control stays bounded", Max_Abs_U <= ADRC_Ada.Max_Magnitude);

   --  ---- 3. Closed loop: constant disturbance rejection -----------

   Sim_Double_Integrator
     (Base_Cfg, Ref => 1.0, D => 5.0, Steps => 3000, Record_Golden => False,
      Final_Y => Final_Y, Final_Z3 => Final_Z3, Max_Abs_U => Max_Abs_U);
   Check ("disturbance rejected: y -> 1 despite d = 5",
          abs (Final_Y - 1.0) < 1.0E-3);
   Check ("observer estimates the disturbance (z3 -> 5)",
          abs (Final_Z3 - 5.0) < 5.0E-2);

   --  ---- 4. Closed loop: damped plant with disturbance -------------

   declare
      S : Ctrl.State;
      U : Ctrl.Control_Signal := 0.0;
      Y, V : Long_Float := 0.0;
      D : constant Long_Float := 2.0;
   begin
      Ctrl.Reset (S, 1.0);
      for K in 1 .. 3000 loop
         pragma Unreferenced (K);
         Ctrl.Step (Base_Cfg, S, 1.0, Y, U);
         --  Plant: y'' = -2 y' - y + u + d (b = 1).
         V := V + Base_Cfg.Ts * (U + D - 2.0 * V - Y);
         Y := Y + Base_Cfg.Ts * V;
      end loop;
      Check ("damped plant converges to unit step with d = 2",
             abs (Y - 1.0) < 1.0E-3);
   end;

   --  ---- 5. Saturation: large reference ---------------------------

   declare
      S : Ctrl.State;
      U : Ctrl.Control_Signal := 0.0;
      Y, V : Long_Float := 0.0;
      Bounded : Boolean := True;
   begin
      Ctrl.Reset (S, 1000.0);
      for K in 1 .. 3000 loop
         pragma Unreferenced (K);
         Ctrl.Step (Base_Cfg, S, 1000.0, Y, U);
         if abs U > ADRC_Ada.Max_Magnitude then
            Bounded := False;
         end if;
         V := V + Base_Cfg.Ts * U;
         Y := Y + Base_Cfg.Ts * V;
      end loop;
      Check ("control stays saturated-bounded for ref = 1000", Bounded);
      Check ("large reference tracked (y -> 1000)", abs (Y - 1000.0) < 1.0);
   end;

   --  ---- 7. Nonlinear units: fal and fhan --------------------------

   --  Power law inside the width region: fal(e, a, d) = e^a.
   Check ("fal follows the power law inside the width",
          abs (F_Unit.Fal (1.0E-3, 0.5, 0.01) - 0.0316227766016838)
            < 1.0E-9);
   --  Linear continuation outside: scale * e with scale = d^(a-1).
   Check ("fal follows the linear continuation outside the width",
          abs (F_Unit.Fal (100.0, 0.5, 0.01) - 1000.0) < 1.0E-6);
   --  Continuity at the branch point: the two branches agree.
   Check ("fal is continuous at the branch point",
          abs (F_Unit.Fal (0.01, 0.5, 0.01)
                 - F_Unit.Fal (0.010001, 0.5, 0.01)) < 1.0E-3);
   --  Odd symmetry: fal(-e) = -fal(e); alpha = 1 gives the identity.
   Check ("fal is odd-symmetric",
          abs (F_Unit.Fal (-2.0, 1.0, 1.0) + F_Unit.Fal (2.0, 1.0, 1.0))
            < 1.0E-12);

   declare
      Big : constant Long_Float :=
        NTD.Fhan (1.0E6, 1.0E6, 20.0, 0.05);
      Small : constant Long_Float :=
        NTD.Fhan (1.0E-3, 0.0, 20.0, 0.05);
   begin
      Check ("fhan bounded by the rate factor for extreme errors",
             abs Big <= 20.0);
      Check ("fhan bounded by the rate factor near steady state",
             abs Small <= 20.0);
   end;

   --  ---- 8. Nonlinear closed loop -----------------------------------

   Sim_NL_Double_Integrator
     (NL_Cfg, Ref => 1.0, D => 0.0, Steps => 3000, Record_Golden => True,
      Final_Y => Final_Y, Final_Z3 => Final_Z3, Max_Abs_U => Max_Abs_U);
   Ada.Text_IO.Put ("nl golden candidate: Y(2s)=");
   FIO.Put (Golden_NL_Y_2s, 2, 9, 0);
   Ada.Text_IO.New_Line;
   Check ("nl closed loop converges to unit step (y -> 1)",
          abs (Final_Y - 1.0) < 5.0E-4);
   Check ("nl observer disturbance estimate settles to zero (z3 -> 0)",
          abs Final_Z3 < 1.0E-3);
   Check ("nl control stays bounded", Max_Abs_U <= ADRC_Ada.Max_Magnitude);

   Sim_NL_Double_Integrator
     (NL_Cfg, Ref => 1.0, D => 5.0, Steps => 3000, Record_Golden => False,
      Final_Y => Final_Y, Final_Z3 => Final_Z3, Max_Abs_U => Max_Abs_U);
   Check ("nl disturbance rejected: y -> 1 despite d = 5",
          abs (Final_Y - 1.0) < 1.0E-3);
   Check ("nl observer estimates the disturbance (z3 -> 5)",
          abs (Final_Z3 - 5.0) < 5.0E-2);

   --  ---- 9. Golden regression --------------------------------------

   Check ("golden regression Y(2s)",
          abs (Golden_Y_2s - Golden_Y_2s_Ref) < Golden_Tol);
   Check ("golden regression Y(5s)",
          abs (Golden_Y_5s - 1.0) < Golden_Tol);
   Check ("golden regression Y(10s)",
          abs (Golden_Y_10s - 1.0) < Golden_Tol);
   Check ("golden regression nl Y(2s)",
          abs (Golden_NL_Y_2s - Golden_NL_Y_2s_Ref) < Golden_Tol);

   --  ----------------------------------------------------------------

   Ada.Text_IO.Put_Line
     ("checks:" & Natural'Image (Checks_Total)
        & "  failed:" & Natural'Image (Checks_Failed));
   if Checks_Failed > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Adrc_Ada_Tests;
