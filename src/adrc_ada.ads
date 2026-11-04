--  SPDX-License-Identifier: Apache-2.0
--
--  Root of the ADRC library: shared bounds and the library contract.
--
--  Active Disturbance Rejection Control after Han, in the linear
--  bandwidth-parameterized form of Gao: a tracking differentiator
--  (ADRC_Ada.TD) smooths the reference, a linear extended state observer
--  (ADRC_Ada.LESO) estimates the plant states and the lumped disturbance,
--  and a state-feedback law with disturbance cancellation
--  (ADRC_Ada.Controller) produces the control signal. ADRC_Ada.Limits
--  holds the shared bounded-subtype vocabulary instantiated at each
--  unit's real arithmetic.
--
--  Every unit is generic over its real type and is pure SPARK: bounded
--  memory, no heap, no I/O, no OS calls. gnatprove proves absence of
--  runtime errors (SPARK Silver) for floating-point instantiations. A
--  fixed-point instantiation is legal and carries its own overflow-proof
--  work (see PLAN.md).
package ADRC_Ada with SPARK_Mode is

   --  Largest magnitude of any measurement, reference, estimate, or
   --  control value this library stores. Every stored value is saturated
   --  into +/- Max_Magnitude and every contract is stated against that
   --  bound, so gnatprove discharges every range check.
   Max_Magnitude : constant := 1.0E6;

   --  Bandwidth window (1/s): high enough for practical loops, low
   --  enough that squared and cubed gain products stay tame.
   Min_Bandwidth : constant := 1.0E-3;
   Max_Bandwidth : constant := 1.0E4;

   --  Control effectiveness window: strictly positive because b0 divides
   --  the disturbance-cancellation term.
   Min_Effectiveness : constant := 1.0E-6;

   --  Correction and feedback gain window of the nonlinear units.
   --  Strictly positive; cubic observer gains reach 1.0e12 at the top
   --  of the bandwidth window, so the ceiling carries margin.
   Max_Gain : constant := 1.0E14;

   --  Sample-time window (s).
   Min_Sample_Time : constant := 1.0E-5;
   Max_Sample_Time : constant := 1.0E1;

   --  Conservative Euler-stability fraction: every configuration is
   --  required to satisfy Ts * bandwidth <= Euler_Bound. This is a
   --  design contract for explicit Euler at a fixed sample time, not a
   --  theorem about the controlled plant.
   Euler_Bound : constant := 0.3;

end ADRC_Ada;
