--  SPDX-License-Identifier: Apache-2.0
--
--  Composed linear ADRC controller: tracking differentiator, extended
--  state observer, and disturbance-cancelling feedback law in one call.
--
--  Step(C, S, Ref, Y, U) advances the whole loop one sample:
--
--    1. TD:    smooth Ref into (V1, V2).
--    2. LESO:  update the observer with measurement Y and the control
--              applied at the previous instant (S.Last_U) — causal.
--    3. Law:   u = sat((wc^2 (v1 - z1) - 2 wc z2 - z3) / b0).
--    4. Store U in S.Last_U for the next observer update.
--
--  The state lives in the caller's record; the library holds no global
--  state. All subprograms are reentrant. This unit is pure SPARK:
--  gnatprove proves absence of runtime errors.

with ADRC_Ada.Control;
with ADRC_Ada.LESO;
with ADRC_Ada.Limits;
with ADRC_Ada.TD;

generic

   --  The real arithmetic this unit runs in. The sibling units are
   --  instantiated at this same type: one arithmetic everywhere.
   type Real_Type is digits <>;

package ADRC_Ada.Controller with SPARK_Mode is

   --  Contract vocabulary of the library, at this package's real type.
   package Lim is new ADRC_Ada.Limits (Real_Type);
   subtype Signal is Lim.Signal;
   subtype Control_Signal is Lim.Control_Signal;
   subtype Bandwidth is Lim.Bandwidth;
   subtype Effectiveness is Lim.Effectiveness;
   subtype Sample_Time is Lim.Sample_Time;

   --  The sibling units instantiated at this package's real type.
   package Diff_Unit is new ADRC_Ada.TD (Real_Type);
   package Obs_Unit is new ADRC_Ada.LESO (Real_Type);
   package Law_Unit is new ADRC_Ada.Control (Real_Type);

   type Config is record
      --  Tracking differentiator bandwidth (1/s).
      TD_Bandwidth : Bandwidth := 10.0;
      --  Observer bandwidth (1/s).
      Wo : Bandwidth := 10.0;
      --  Controller bandwidth (1/s).
      Wc : Bandwidth := 10.0;
      --  Control effectiveness estimate b0.
      B0 : Effectiveness := 1.0;
      --  Fixed sample time (s).
      Ts : Sample_Time := 0.01;
   end record;

   --  A configuration is valid when every Euler update in the loop is
   --  inside the conservative stability fraction of the library.
   function Valid_Config (C : Config) return Boolean is
     (C.Ts * C.TD_Bandwidth <= Euler_Bound
      and then C.Ts * C.Wo <= Euler_Bound
      and then C.Ts * C.Wc <= Euler_Bound);

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

end ADRC_Ada.Controller;
