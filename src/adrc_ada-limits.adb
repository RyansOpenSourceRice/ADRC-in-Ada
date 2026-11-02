--  SPDX-License-Identifier: Apache-2.0

package body ADRC_Ada.Limits with SPARK_Mode is

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

end ADRC_Ada.Limits;
