--  SPDX-License-Identifier: Apache-2.0

with Ada.Numerics.Generic_Elementary_Functions;

package body ADRC_Ada.Fal with SPARK_Mode is

   function Frac_Power
     (X : Real_Type'Base; Y : Real_Type'Base) return Real_Type'Base
   is
      pragma SPARK_Mode (Off);
      package Elem is new Ada.Numerics.Generic_Elementary_Functions
        (Real_Type);
   begin
      return Elem."**" (X, Y);
   end Frac_Power;

   function Fal
     (E     : Real_Type'Base;
      Alpha : Alpha_Range;
      Width : Delta_Range) return Signal
   is
      --  Sign and magnitude of the error, each a single operation.
      Mag  : constant Real_Type'Base := abs E;
      Sign : constant Real_Type'Base := (if E >= 0.0 then 1.0 else -1.0);
      --  Power law: |e|^alpha. Bounded by 1.0e9 (Max_Magnitude^1.5) by
      --  the trusted-numerics contract, far inside the float range.
      Power : constant Real_Type'Base := Frac_Power (Mag, Alpha);
      --  Linear continuation with scale Width^(alpha - 1), so fal
      --  matches the power law at |e| = Width. Width carries a
      --  strictly positive subtype.
      Scale : constant Real_Type'Base := Frac_Power (Width, Alpha - 1.0);
   begin
      if Mag <= Width then
         return
           Signal
             (Lim.Saturate (Power * Sign, -Max_Magnitude, Max_Magnitude));
      else
         --  The product with the error is saturated before return.
         return Signal (Lim.Saturate (Scale * E, -Max_Magnitude, Max_Magnitude));
      end if;
   end Fal;

end ADRC_Ada.Fal;
