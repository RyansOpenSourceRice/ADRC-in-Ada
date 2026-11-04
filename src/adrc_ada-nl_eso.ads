--  SPDX-License-Identifier: Apache-2.0
--
--  Third-order nonlinear extended state observer (Han's classic form).
--
--  Estimates the two plant states and, as a third extended state, the
--  lumped disturbance f of the plant model y'' = f + b0 u, with the
--  fal function providing the nonlinear correction gains:
--
--      e   = y - z1
--      z1' = z2 + Beta01 * e
--      z2' = z3 + Beta02 * fal(e, Alpha1, Delta) + b0 u
--      z3' = Beta03 * fal(e, Alpha2, Delta)
--
--  with Alpha1 = 0.5 and Alpha2 = 0.25 in the classical tuning. The
--  gains are explicit (not bandwidth-parameterized); a common starting
--  point is Beta01 ~ 3 wo, Beta02 ~ 3 wo^2, Beta03 ~ wo^3 with wo the
--  intended observer bandwidth. Discretized with explicit Euler. This
--  unit is pure SPARK: gnatprove proves absence of runtime errors.

with ADRC_Ada.Fal;
with ADRC_Ada.Limits;

generic

   --  The real arithmetic this unit runs in.
   type Real_Type is digits <>;

package ADRC_Ada.NL_ESO with SPARK_Mode is

   --  Contract vocabulary of the library, at this unit's real type.
   package Lim is new ADRC_Ada.Limits (Real_Type);
   package Fal_Unit is new ADRC_Ada.Fal (Real_Type);

   subtype Signal is Lim.Signal;
   subtype Control_Signal is Lim.Control_Signal;
   subtype State_Value is Lim.State_Value;
   subtype Effectiveness is Lim.Effectiveness;
   subtype Sample_Time is Lim.Sample_Time;

   --  Correction gains (plant units per second powers). Strictly
   --  positive; large by design (cubic terms appear at wo ~ 1e4).
   subtype Gain is Real_Type'Base range 1.0E-9 .. Max_Gain;

   type Config is record
      --  Correction gains, in the order of the update equations above.
      Beta01 : Gain := 30.0;
      Beta02 : Gain := 300.0;
      Beta03 : Gain := 1000.0;
      --  fal parameters for the nonlinear corrections.
      Alpha1 : Fal_Unit.Alpha_Range := 0.5;
      Alpha2 : Fal_Unit.Alpha_Range := 0.25;
      Width : Fal_Unit.Delta_Range := 0.01;
      --  Control effectiveness estimate b0. Strictly positive.
      B0 : Effectiveness := 1.0;
      --  Fixed sample time (s).
      Ts : Sample_Time := 0.01;
   end record;

   --  A configuration is valid when the dominant correction update is
   --  inside the conservative Euler fraction of the library. The fal
   --  boundedness keeps every update finite regardless; this contract
   --  is the design margin, not a stability theorem (see DESIGN.md).
   function Valid_Config (C : Config) return Boolean is
     (C.Ts * C.Beta01 <= Euler_Bound);

   type State is record
      --  Output estimate.
      Z1 : State_Value := 0.0;
      --  Output-derivative estimate.
      Z2 : State_Value := 0.0;
      --  Lumped-disturbance estimate.
      Z3 : State_Value := 0.0;
   end record;

   --  Zero observer state: assume zero states and zero disturbance.
   procedure Reset (S : out State) with
     Post => S.Z1 = 0.0 and then S.Z2 = 0.0 and then S.Z3 = 0.0;

   --  One observer update. Y is the measurement at the current instant;
   --  U is the control applied at the previous instant (causality: the
   --  caller passes the previous output, not the one being computed).
   procedure Step (C : Config; S : in out State; Y : Signal; U : Control_Signal) with
     Pre => Valid_Config (C);

end ADRC_Ada.NL_ESO;
