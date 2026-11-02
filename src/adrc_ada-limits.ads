--  SPDX-License-Identifier: Apache-2.0
--
--  Shared bounded-subtype vocabulary and the saturation helper,
--  instantiated at each library unit's real arithmetic. This is the
--  single source of the ranges the contracts are stated against.
--
--  The subtypes are the invariants: no subprogram in the library ever
--  assigns an out-of-range value (proven by gnatprove; saturation is
--  applied before every stored assignment).

generic

   --  The real arithmetic the controller runs in: an IEEE 754 floating
   --  point type (Float, Long_Float, ...) today; a fixed-point type can
   --  instantiate the same contracts tomorrow.
   type Real_Type is digits <>;

package ADRC_Ada.Limits with SPARK_Mode is

   --  Measurements, references, and observer estimates.
   subtype Signal is Real_Type'Base range -Max_Magnitude .. Max_Magnitude;

   --  Control output range after saturation.
   subtype Control_Signal is Real_Type'Base range -Max_Magnitude .. Max_Magnitude;

   --  Internal state values (tracking differentiator, observer).
   subtype State_Value is Real_Type'Base range -Max_Magnitude .. Max_Magnitude;

   --  Loop bandwidths (1/s).
   subtype Bandwidth is Real_Type'Base range Min_Bandwidth .. Max_Bandwidth;

   --  Control effectiveness b0 (plant units per control unit). Strictly
   --  positive: it divides in the control law.
   subtype Effectiveness is Real_Type'Base range Min_Effectiveness .. Max_Magnitude;

   --  Sample times (s).
   subtype Sample_Time is Real_Type'Base range Min_Sample_Time .. Max_Sample_Time;

   --  Saturate X into [Lo, Hi]. The postcondition is what lets gnatprove
   --  discharge the range check on every saturated assignment in this
   --  library.
   function Saturate (X, Lo, Hi : Real_Type'Base) return Real_Type'Base with
     Pre  => Lo <= Hi,
     Post => Saturate'Result >= Lo and then Saturate'Result <= Hi;

end ADRC_Ada.Limits;
