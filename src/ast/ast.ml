(***************************************************************************)
(* This file is part of the third-party OCaml library `smtml`.             *)
(* Copyright (C) 2023-2024 formalsec                                       *)
(*                                                                         *)
(* This program is free software: you can redistribute it and/or modify    *)
(* it under the terms of the GNU General Public License as published by    *)
(* the Free Software Foundation, either version 3 of the License, or       *)
(* (at your option) any later version.                                     *)
(*                                                                         *)
(* This program is distributed in the hope that it will be useful,         *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of          *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *)
(* GNU General Public License for more details.                            *)
(*                                                                         *)
(* You should have received a copy of the GNU General Public License       *)
(* along with this program.  If not, see <https://www.gnu.org/licenses/>.  *)
(***************************************************************************)

type t =
  | Assert of Expr.t
  | Check_sat of Expr.t list
  | Declare_const of
      { id : Symbol.t
      ; sort : Symbol.t
      }
  | Echo of string
  | Exit
  | Get_assertions
  | Get_assignment
  | Get_info of string
  | Get_option of string
  | Get_model
  | Get_value of Expr.t list
  | Pop of int
  | Push of int
  | Reset
  | Reset_assertions
  | Set_info of Expr.t
  | Set_logic of Ty.logic
  | Set_option of Expr.t

type script = t list

let pp fmt (instr : t) =
  match instr with
  | Assert e -> Fmt.pf fmt "@[<hov 1>(assert@ %a@])" Expr.pp e
  | Check_sat [] -> Fmt.string fmt "(check-sat)"
  | Check_sat assumptuions ->
    Fmt.pf fmt "(check-sat-assuming@ (%a))"
      (Fmt.list ~sep:Fmt.sp Expr.pp)
      assumptuions
  | Push n -> Fmt.pf fmt "(push %d)" n
  | Pop n -> Fmt.pf fmt "(pop %d)" n
  | Declare_const { id; sort } ->
    Fmt.pf fmt "(declare-const %a %a)" Symbol.pp id Symbol.pp sort
  | Get_model -> Fmt.string fmt "(get-model)"
  | Set_logic logic -> Fmt.pf fmt "(set-logic %a)" Ty.pp_logic logic
  | Exit -> Fmt.string fmt "(exit)"
  | Get_assertions | Get_assignment | Reset | Reset_assertions | Echo _
  | Get_info _ | Get_option _ | Get_value _ | Set_info _ | Set_option _ ->
    Fmt.failwith "pp: TODO printing of unused cases"

let to_string (instr : t) : string = Fmt.str "%a" pp instr