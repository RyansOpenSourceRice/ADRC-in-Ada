--  SPDX-License-Identifier: Apache-2.0
--
--  Second-order linear tracking differentiator (TD).
--
--  Smooths the reference signal and provides its derivative without
--  numerical differentiation:
--
--      v1' = v2
--      v2' = -r^2 (v1 - ref) - 2 r v2
--
--  with r the differentiator bandwidth (1/s). Discretized with explicit
--  Euler at the configuration's fixed sample time. This unit is pure
--  SPARK: gnatprove proves absence of runtime errors.

with ADRC_Ada.Limits;

generic

   --  The real arithmetic this unit runs in.
   type Real_Type is digits <>;

package ADRC_Ada.TD with SPARK_Mode is

   --  Contract vocabulary of the library, at this unit's real type.
   package Lim is new ADRC_Ada.Limits (Real_Type);
   subtype Signal is Lim.Signal;
   subtype Bandwidth is Lim.Bandwidth;
   subtype Sample_Time is Lim.Sample_Time;

   type Config is record
      --  Differentiator bandwidth (1/s).
      Rate : Bandwidth := 10.0;
      --  Fixed sample time (s).
      Ts : Sample_Time := 0.01;
   end record;

   --  A configuration is valid when the Euler update is inside the
   --  conservative stability fraction of the library.
   function Valid_Config (C : Config) return Boolean is
     (C.Ts * C.Rate <= Euler_Bound);

   type State is record
      --  Smoothed reference estimate.
      V1 : Signal := 0.0;
      --  Reference derivative estimate.
      V2 : Signal := 0.0;
   end record;

   --  Start tracking Ref immediately with zero derivative.
   procedure Reset (S : out State; Ref : Signal) with
     Post => S.V1 = Ref and then S.V2 = 0.0;

   --  One differentiator step. V1 and V2 are the updated estimates for
   --  the current instant.
   procedure Step
     (C   : Config;
      S   : in out State;
      Ref : Signal;
      V1, V2 : out Signal)
     with Pre => Valid_Config (C);

end ADRC_Ada.TD;
