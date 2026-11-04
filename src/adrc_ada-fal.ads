--  SPDX-License-Identifier: Apache-2.0
--
--  Han's fal power function: the nonlinear core of the ADRC variants.
--
--      fal(e, a, d) = e^a                  when |e| <= d
--                   = d^(a-1) * e          when |e| >  d
--
--  The two branches agree at |e| = d, so fal is continuous: the power
--  law gives high gain near zero (fast small-error response) and the
--  linear continuation keeps large errors well behaved. This unit is
--  pure SPARK: gnatprove proves absence of runtime errors, and the
--  result is saturated into the library's signal range.

with ADRC_Ada.Limits;

generic

   --  The real arithmetic this unit runs in.
   type Real_Type is digits <>;

package ADRC_Ada.Fal with SPARK_Mode is

   --  Contract vocabulary of the library, at this unit's real type.
   package Lim is new ADRC_Ada.Limits (Real_Type);
   subtype Signal is Lim.Signal;

   --  Exponent window of the power law. Covers the classical ADRC
   --  choices (0.25 and 0.5 in the observer, 0.75 and 1.25 in the
   --  nonlinear state error feedback) with margin on both ends.
   subtype Alpha_Range is Real_Type'Base range 0.25 .. 1.5;

   --  Width of the power-law region around zero (Han's delta
   --  parameter; the name is spelled Width here because delta is a
   --  reserved word). Below 1.0e-3 the continuation scale could
   --  exceed the library bounds.
   subtype Delta_Range is Real_Type'Base range 1.0E-3 .. Max_Magnitude;

   --  The fractional power is trusted numerics: the elementary
   --  exponentiation sits outside the SPARK view, so its contracts are
   --  assumptions at the trust boundary. The mathematical result of
   --  x^y with |x| <= Max_Magnitude and y in the alpha window is <=
   --  Max_Magnitude^1.5 = 1.0e9, far inside the real type's float
   --  range; the result is NOT clipped to the signal range here, the
   --  call sites saturate after combining.
   Max_Power : constant := 1.0E9;

   function Frac_Power
     (X : Real_Type'Base; Y : Real_Type'Base) return Real_Type'Base
     with Pre  => -Max_Magnitude <= X and then X <= Max_Magnitude,
          Post => -Max_Power <= Frac_Power'Result
                  and then Frac_Power'Result <= Max_Power;

   --  One fal evaluation: the power law inside +/- Width, the linear
   --  continuation outside. The result is saturated into Signal. The
   --  caller saturates the error into the signal range first (the
   --  library's bounded-arithmetic discipline).
   function Fal
     (E     : Real_Type'Base;
      Alpha : Alpha_Range;
      Width : Delta_Range) return Signal
     with Pre => -Max_Magnitude <= E and then E <= Max_Magnitude;

end ADRC_Ada.Fal;
