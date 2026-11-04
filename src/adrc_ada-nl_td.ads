--  SPDX-License-Identifier: Apache-2.0
--
--  Second-order nonlinear tracking differentiator (fhan-TD).
--
--  Han's fastest-discrete tracking differentiator: the linear TD's
--  acceleration term is replaced by the fastest-control synthesis
--  function fhan, which drives the state onto the switching curve in
--  minimum time for the rate limit Rate:
--
--      v1' = v2
--      v2' = v2 + Ts * fhan(v1 - ref, v2, r, h0)
--
--  with r the speed factor (1/s) and h0 the filter factor (s; raising
--  it above Ts suppresses noise at the cost of lag). fhan's output is
--  bounded by r by construction: the inner function a is truncated to
--  +/- r (sign only beyond r). Discretized with explicit Euler. This
--  unit is pure SPARK: gnatprove proves absence of runtime errors.

with ADRC_Ada.Limits;

generic

   --  The real arithmetic this unit runs in.
   type Real_Type is digits <>;

package ADRC_Ada.NL_TD with SPARK_Mode is

   --  Contract vocabulary of the library, at this unit's real type.
   package Lim is new ADRC_Ada.Limits (Real_Type);
   subtype Signal is Lim.Signal;
   subtype State_Value is Lim.State_Value;
   subtype Bandwidth is Lim.Bandwidth;
   subtype Sample_Time is Lim.Sample_Time;

   type Config is record
      --  Speed factor (1/s): the fastest-discrete rate limit and the
      --  bound of the synthesized acceleration.
      Rate : Bandwidth := 20.0;
      --  Filter factor (s). Equal to Ts gives the plain differentiator;
      --  larger values filter harder with more lag.
      Filter : Sample_Time := 0.05;
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

   --  Han's fastest-control synthesis function for the tracking error
   --  (E1, E2), the speed factor Rate, and the filter factor H0. The
   --  result is bounded by Rate in absolute value; the caller keeps
   --  E1 and E2 saturated into the signal range.
   function Fhan
     (E1, E2 : Signal; Rate : Bandwidth; H0 : Sample_Time) return Signal
     with Post => abs Fhan'Result <= Rate;

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

end ADRC_Ada.NL_TD;
