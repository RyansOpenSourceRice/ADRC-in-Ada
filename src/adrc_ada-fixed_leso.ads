--  SPDX-License-Identifier: Apache-2.0
--
--  Fixed-point sibling of ADRC_Ada.LESO: third-order linear extended
--  state observer.
--
--  Estimates the two plant states and, as a third extended state, the
--  lumped disturbance f of the plant model y'' = f + b0 u:
--
--      z1' = z2 + B1 (y - z1)
--      z2' = z3 + B2 (y - z1) + b0 u
--      z3' = B3 (y - z1)
--
--  with the bandwidth parameterization (Gao 2003) B1 = 3 wo,
--  B2 = 3 wo^2, B3 = wo^3. Discretized with explicit Euler at the
--  configuration's fixed sample time. Every product and sum runs
--  through the saturating helpers of the fixed-point limits unit.
--  This unit is pure SPARK: gnatprove proves absence of runtime errors.

with ADRC_Ada.Fixed_Limits;

generic

   --  The fixed-point arithmetic this unit runs in.
   type Real_Type is delta <>;

package ADRC_Ada.Fixed_LESO with SPARK_Mode is

   --  Contract vocabulary of the family, at this unit's real type.
   package Lim is new ADRC_Ada.Fixed_Limits (Real_Type);
   subtype Signal is Lim.Signal;
   subtype Control_Signal is Lim.Control_Signal;
   subtype State_Value is Lim.State_Value;
   subtype Bandwidth is Lim.Bandwidth;
   subtype Effectiveness is Lim.Effectiveness;
   subtype Sample_Time is Lim.Sample_Time;

   type Config is record
      --  Observer bandwidth (1/s). A common starting point is 3 to 10
      --  times the controller bandwidth.
      Wo : Bandwidth := 10.0;
      --  Control effectiveness estimate b0 (plant units per control
      --  unit). Strictly positive.
      B0 : Effectiveness := 1.0;
      --  Fixed sample time (s).
      Ts : Sample_Time := 0.01;
   end record;

   --  A configuration is valid when the Euler update is inside the
   --  conservative stability fraction of the family.
   function Valid_Config (C : Config) return Boolean is
     (C.Ts * C.Wo <= Lim.Euler_Bound);

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

end ADRC_Ada.Fixed_LESO;
