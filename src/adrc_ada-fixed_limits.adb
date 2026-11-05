--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.Fixed_Limits with SPARK_Mode is

   function Saturate (X, Lo, Hi : Real_Type'Base) return Real_Type'Base is
   begin
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Saturate;

   function S_Mul (A, B : Signal) return Signal is
      CA : constant Signal := Saturate (A, -Product_Band, Product_Band);
      CB : constant Signal := Saturate (B, -Product_Band, Product_Band);
      P  : constant Real_Type'Base := CA * CB;
   begin
      if P > Signal'Last then
         return Signal'Last;
      elsif P < Signal'First then
         return Signal'First;
      else
         return Signal (P);
      end if;
   end S_Mul;

   function S_Add (A, B : Signal) return Signal is
      CA : constant Signal := Saturate (A, -Sum_Band, Sum_Band);
      CB : constant Signal := Saturate (B, -Sum_Band, Sum_Band);
      S  : constant Real_Type'Base := CA + CB;
   begin
      if S > Signal'Last then
         return Signal'Last;
      elsif S < Signal'First then
         return Signal'First;
      else
         return Signal (S);
      end if;
   end S_Add;

   function S_Sub (A, B : Signal) return Signal is
      CA : constant Signal := Saturate (A, -Sum_Band, Sum_Band);
      CB : constant Signal := Saturate (B, -Sum_Band, Sum_Band);
      D  : constant Real_Type'Base := CA - CB;
   begin
      if D > Signal'Last then
         return Signal'Last;
      elsif D < Signal'First then
         return Signal'First;
      else
         return Signal (D);
      end if;
   end S_Sub;

   function S_Recip (B : Signal) return Signal is
      One : constant Real_Type := 1.0;
   begin
      return Signal (One / B);
   end S_Recip;

end ADRC_Ada.Fixed_Limits;
