--  SPDX-License-Identifier: Apache-2.0
--
--  Composed nonlinear ADRC controller: fhan tracking differentiator,
--  fal-based extended state observer, and NLSEF law with disturbance
--  cancellation in one call.
--
--  Step(C, S, Ref, Y, U) advances the whole loop one sample:
--
--    1. NL_TD:  smooth Ref into (V1, V2) through fhan.
--    2. NL_ESO: update the observer with measurement Y and the control
--               applied at the previous instant (S.Last_U) — causal.
--    3. NLSEF:  u = sat((Beta1 fal(e1,a1,d) + Beta2 fal(e2,a2,d) - z3)/b0).
--    4. Store U in S.Last_U for the next observer update.
--
--  The state lives in the caller's record; the library holds no global
--  state. All subprograms are reentrant. This unit is pure SPARK:
--  gnatprove proves absence of runtime errors.

with ADRC_Ada.NL_Control;
with ADRC_Ada.NL_ESO;
with ADRC_Ada.NL_TD;

generic

   --  The real arithmetic this unit runs in. The sibling units are
   --  instantiated at this same type: one arithmetic everywhere.
   type Real_Type is digits <>;

package ADRC_Ada.NL_Controller with SPARK_Mode is

   --  The sibling units instantiated at this package's real type.
   package Diff_Unit is new ADRC_Ada.NL_TD (Real_Type);
   package Obs_Unit is new ADRC_Ada.NL_ESO (Real_Type);
   package Law_Unit is new ADRC_Ada.NL_Control (Real_Type);

   subtype Signal is Obs_Unit.Signal;
   subtype Control_Signal is Obs_Unit.Control_Signal;
   subtype Bandwidth is Diff_Unit.Bandwidth;
   subtype Sample_Time is Diff_Unit.Sample_Time;

   type Config is record
      --  Tracking differentiator speed and filter factors.
      TD_Rate : Bandwidth := 20.0;
      TD_Filter : Sample_Time := 0.05;
      --  Observer correction gains and fal parameters.
      Beta01 : Obs_Unit.Gain := 30.0;
      Beta02 : Obs_Unit.Gain := 300.0;
      Beta03 : Obs_Unit.Gain := 1000.0;
      Eso_Alpha1 : Obs_Unit.Fal_Unit.Alpha_Range := 0.5;
      Eso_Alpha2 : Obs_Unit.Fal_Unit.Alpha_Range := 0.25;
      Eso_Width : Obs_Unit.Fal_Unit.Delta_Range := 0.01;
      --  Control effectiveness estimate b0.
      B0 : Obs_Unit.Effectiveness := 1.0;
      --  Feedback gains and fal parameters of the NLSEF law.
      Beta1 : Law_Unit.Gain := 100.0;
      Beta2 : Law_Unit.Gain := 20.0;
      Ctl_Alpha1 : Law_Unit.Fal_Unit.Alpha_Range := 0.75;
      Ctl_Alpha2 : Law_Unit.Fal_Unit.Alpha_Range := 1.25;
      Ctl_Width : Law_Unit.Fal_Unit.Delta_Range := 0.01;
      --  Fixed sample time (s).
      Ts : Sample_Time := 0.01;
   end record;

   --  A configuration is valid when every Euler-updated unit is inside
   --  the conservative stability fraction of the library.
   function Valid_Config (C : Config) return Boolean is
     (Diff_Unit.Valid_Config
        (Diff_Unit.Config'(Rate => C.TD_Rate, Filter => C.TD_Filter, Ts => C.Ts))
      and then Obs_Unit.Valid_Config
        (Obs_Unit.Config'(
           Beta01 => C.Beta01, Beta02 => C.Beta02, Beta03 => C.Beta03,
           Alpha1 => C.Eso_Alpha1, Alpha2 => C.Eso_Alpha2,
           Width => C.Eso_Width, B0 => C.B0, Ts => C.Ts)));

   type State is record
      --  Tracking differentiator state.
      Diff : Diff_Unit.State;
      --  Extended state observer state.
      Obs : Obs_Unit.State;
      --  Control applied at the previous instant, used by the observer
      --  for causality.
      Last_U : Control_Signal := 0.0;
   end record;

   --  Start with the differentiator tracking Ref, the observer at zero,
   --  and zero previous control.
   procedure Reset (S : out State; Ref : Signal) with
     Post => S.Diff.V1 = Ref
             and then S.Diff.V2 = 0.0
             and then S.Obs.Z1 = 0.0
             and then S.Obs.Z2 = 0.0
             and then S.Obs.Z3 = 0.0
             and then S.Last_U = 0.0;

   --  One full controller step. Ref is the reference, Y the plant
   --  measurement, U the control to apply over the next sample period.
   procedure Step (C : Config; S : in out State; Ref : Signal; Y : Signal; U : out Control_Signal) with
     Pre => Valid_Config (C);

end ADRC_Ada.NL_Controller;
