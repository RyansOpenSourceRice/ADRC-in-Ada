--  SPDX-License-Identifier: Apache-2.0
--
--  Proof-only instantiations of the generic core at a concrete capacity
--  (IEEE double). Not shipped, not built by the library project; they
--  exist so gnatprove analyzes the generic units against a real
--  arithmetic instead of leaving them uninstantiated.

with ADRC_Ada.Control;
with ADRC_Ada.Controller;
with ADRC_Ada.LESO;
with ADRC_Ada.Limits;
with ADRC_Ada.TD;

package Adrc_Proof_Units with SPARK_Mode is

   package Lim_I is new ADRC_Ada.Limits (Long_Float);
   package TD_I is new ADRC_Ada.TD (Long_Float);
   package Leso_I is new ADRC_Ada.LESO (Long_Float);
   package Control_I is new ADRC_Ada.Control (Long_Float);
   package Controller_I is new ADRC_Ada.Controller (Long_Float);

end Adrc_Proof_Units;
