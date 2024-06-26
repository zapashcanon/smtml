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

include Mappings_intf

module Make (M0 : Mappings_intf.M_with_make) = struct
  module MakeMake (M : Mappings_intf.M) : Mappings_intf.S = struct
    open Ty

    type model = M.model

    type solver = M.solver

    type handle = M.handle

    type optimize = M.optimizer

    let err = Log.err

    let get_type = function
      | Ty_int -> M.Types.int
      | Ty_real -> M.Types.real
      | Ty_bool -> M.Types.bool
      | Ty_str -> M.Types.string
      | Ty_bitv 8 -> M.Types.bitv 8
      | Ty_bitv 32 -> M.Types.bitv 32
      | Ty_bitv 64 -> M.Types.bitv 64
      | Ty_fp 32 -> M.Types.float 8 24
      | Ty_fp 64 -> M.Types.float 11 53
      | Ty_bitv _ | Ty_fp _ | Ty_list | Ty_array | Ty_tuple -> assert false

    module Bool_impl = struct
      let true_ = M.true_

      let false_ = M.false_

      let unop = function
        | Not -> M.not_
        | op -> err {|Bool: Unsupported Z3 unop operator "%a"|} Ty.pp_unop op

      let binop = function
        | And -> M.and_
        | Or -> M.or_
        | Xor -> M.xor
        | op -> err {|Bool: Unsupported Z3 binop operator "%a"|} Ty.pp_binop op

      let triop = function
        | Ite -> M.ite
        | op -> err {|Bool: Unsupported Z3 triop operator "%a"|} Ty.pp_triop op

      let relop op e1 e2 =
        match op with
        | Eq -> M.eq e1 e2
        | Ne -> M.distinct [ e1; e2 ]
        | _ -> err {|Bool: Unsupported Z3 relop operator "%a"|} Ty.pp_relop op

      let cvtop _op _e = assert false
    end

    module Int_impl = struct
      let v i = M.int i [@@inline]

      let unop = function
        | Neg -> M.Int.neg
        | op -> err {|Int: Unsupported unop operator "%a"|} Ty.pp_unop op

      let binop = function
        | Add -> M.Int.add
        | Sub -> M.Int.sub
        | Mul -> M.Int.mul
        | Div -> M.Int.div
        | Rem -> M.Int.rem
        | Pow -> M.Int.pow
        | op -> err {|Int: Unsupported binop operator "%a"|} Ty.pp_binop op

      let relop = function
        | Eq -> M.eq
        | Ne -> fun e1 e2 -> M.distinct [ e1; e2 ]
        | Lt -> M.Int.lt
        | Gt -> M.Int.gt
        | Le -> M.Int.le
        | Ge -> M.Int.ge
        | op -> err {|Int: Unsupported relop operator "%a"|} Ty.pp_relop op

      (* TODO: Uninterpreted cvtops *)
      let cvtop op e =
        match op with
        | ToString -> assert false
        | OfString -> assert false
        | Reinterpret_float -> M.Real.to_int e
        | op -> err {|Int: Unsupported cvtop operator "%a"|} Ty.pp_cvtop op
    end

    module Real_impl = struct
      let v f = M.real f [@@inline]

      let unop op e =
        match op with
        | Neg -> M.Real.neg e
        | Abs -> M.ite (M.Real.gt e (M.real 0.)) e (M.Real.neg e)
        | Sqrt -> M.Real.pow e (v 0.5)
        | Ceil ->
          let x_int = M.Real.to_int e in
          let x_int_real = M.Int.to_real x_int in
          let x_int_real_eq_e = M.eq x_int_real e in
          let x_int_add_one = M.Int.add x_int (M.int 1) in
          M.ite x_int_real_eq_e x_int x_int_add_one
        | Floor -> M.Real.to_int e
        | Nearest | Is_nan | _ ->
          err {|Real: Unsupported unop operator "%a"|} Ty.pp_unop op

      let binop op e1 e2 =
        match op with
        | Add -> M.Real.add e1 e2
        | Sub -> M.Real.sub e1 e2
        | Mul -> M.Real.mul e1 e2
        | Div -> M.Real.div e1 e2
        | Pow -> M.Real.pow e1 e2
        | Min -> M.ite (M.Real.le e1 e2) e1 e2
        | Max -> M.ite (M.Real.ge e1 e2) e1 e2
        | _ -> err {|Real: Unsupported binop operator "%a"|} Ty.pp_binop op

      let relop op e1 e2 =
        match op with
        | Eq -> M.eq e1 e2
        | Ne -> M.distinct [ e1; e2 ]
        | Lt -> M.Real.lt e1 e2
        | Gt -> M.Real.gt e1 e2
        | Le -> M.Real.le e1 e2
        | Ge -> M.Real.ge e1 e2
        | _ -> err {|Real: Unsupported relop operator "%a"|} Ty.pp_relop op

      (* TODO: Uninterpreted cvtops *)
      let cvtop op e =
        match op with
        | ToString -> assert false
        | OfString -> assert false
        | ConvertUI32 -> assert false
        | Reinterpret_int -> M.Int.to_real e
        | op -> err {|Real: Unsupported cvtop operator "%a"|} Ty.pp_cvtop op
    end

    module String_impl = struct
      let v s = M.String.v s [@@inline]

      (* let trim = FuncDecl.mk_func_decl_s ctx "Trim" [ str_sort ] str_sort *)

      let unop = function
        | Seq_length -> M.String.length
        | Trim ->
          (* FuncDecl.apply trim [ e ] *)
          assert false
        | op -> err {|String: Unsupported unop operator "%a"|} Ty.pp_unop op

      let binop op e1 e2 =
        match op with
        | Seq_at -> M.String.at e1 ~pos:e2
        | Seq_concat -> M.String.concat e1 e2
        | Seq_contains -> M.String.contains e1 ~sub:e2
        | Seq_prefix -> M.String.is_prefix e1 ~prefix:e2
        | Seq_suffix -> M.String.is_suffix e1 ~suffix:e2
        | _ -> err {|String: Unsupported binop operator "%a"|} Ty.pp_binop op

      let triop op e1 e2 e3 =
        match op with
        | Seq_extract -> M.String.sub e1 ~pos:e2 ~len:e3
        | Seq_index -> M.String.index_of e1 ~sub:e2 ~pos:e3
        | Seq_replace -> M.String.replace e1 ~pattern:e2 ~with_:e3
        | _ -> err {|String: Unsupported triop operator "%a"|} Ty.pp_triop op

      let relop op e1 e2 =
        match op with
        | Eq -> M.eq e1 e2
        | Ne -> M.distinct [ e1; e2 ]
        | _ -> err {|String: Unsupported relop operator "%a"|} Ty.pp_relop op

      let cvtop = function
        | String_to_code -> M.String.to_code
        | String_from_code -> M.String.of_code
        | String_to_int -> M.String.to_int
        | String_from_int -> M.String.of_int
        | op -> err {|String: Unsupported cvtop operator "%a"|} Ty.pp_cvtop op
    end

    module type Bitv_sig = sig
      type elt

      val v : elt -> M.term

      val bitwidth : int

      module Ixx : sig
        val of_int : int -> elt

        val shift_left : elt -> int -> elt
      end
    end

    module Bitv_impl (B : Bitv_sig) = struct
      include B

      (* Stolen from @krtab in OCamlPro/owi #195 *)
      let clz n =
        let rec loop (lb : int) (ub : int) =
          if ub = lb + 1 then v @@ Ixx.of_int (bitwidth - ub)
          else
            let mid = (lb + ub) / 2 in
            let pow_two_mid = Ixx.(shift_left (of_int 1) mid) in
            let pow_two_mid = v pow_two_mid in
            let n_lt_pow_two = M.Bitv.lt_u n pow_two_mid in
            let left = loop lb mid in
            let right = loop mid ub in
            M.ite n_lt_pow_two left right
        in
        let zero = v (Ixx.of_int 0) in
        let n_eq_zero = M.eq n zero in
        let bitwidth' = v (Ixx.of_int bitwidth) in
        let right = loop 0 bitwidth in
        M.ite n_eq_zero bitwidth' right

      (* Stolen from @krtab in OCamlPro/owi #195 *)
      let ctz n =
        let zero = v (Ixx.of_int 0) in
        let rec loop (lb : int) (ub : int) =
          if ub = lb + 1 then v (Ixx.of_int lb)
          else
            let mid = (lb + ub) / 2 in
            let pow_two_mid = Ixx.(shift_left (of_int 1) mid) in
            let pow_two_mid = v pow_two_mid in
            let rem_pow_two = M.Bitv.rem n pow_two_mid in
            let rem_pow_eq_zero = M.eq rem_pow_two zero in
            let right = loop mid ub in
            let left = loop lb mid in
            M.ite rem_pow_eq_zero right left
        in
        let n_eq_zero = M.eq n zero in
        let bitwidth' = v (Ixx.of_int bitwidth) in
        let right = loop 0 bitwidth in
        M.ite n_eq_zero bitwidth' right

      let unop = function
        | Clz -> clz
        | Ctz -> ctz
        | Neg -> M.Bitv.neg
        | Not -> M.Bitv.lognot
        | op -> err {|Bitv: Unsupported unary operator "%a"|} Ty.pp_unop op

      let binop = function
        | Add -> M.Bitv.add
        | Sub -> M.Bitv.sub
        | Mul -> M.Bitv.mul
        | Div -> M.Bitv.div
        | DivU -> M.Bitv.div_u
        | And -> M.Bitv.logand
        | Xor -> M.Bitv.logxor
        | Or -> M.Bitv.logor
        | Shl -> M.Bitv.shl
        | ShrA -> M.Bitv.ashr
        | ShrL -> M.Bitv.lshr
        | Rem -> M.Bitv.rem
        | RemU -> M.Bitv.rem_u
        | Rotl -> M.Bitv.rotate_left
        | Rotr -> M.Bitv.rotate_right
        | op -> err {|Bitv: Unsupported binary operator "%a"|} Ty.pp_binop op

      let triop op _ =
        err {|Bitv: Unsupported triop operator "%a"|} Ty.pp_triop op

      let relop op e1 e2 =
        match op with
        | Eq -> M.eq e1 e2
        | Ne -> M.distinct [ e1; e2 ]
        | Lt -> M.Bitv.lt e1 e2
        | LtU -> M.Bitv.lt_u e1 e2
        | Le -> M.Bitv.le e1 e2
        | LeU -> M.Bitv.le_u e1 e2
        | Gt -> M.Bitv.gt e1 e2
        | GtU -> M.Bitv.gt_u e1 e2
        | Ge -> M.Bitv.ge e1 e2
        | GeU -> M.Bitv.ge_u e1 e2

      let cvtop op e =
        match op with
        | WrapI64 -> M.Bitv.extract e ~high:(bitwidth - 1) ~low:0
        | Sign_extend n -> M.Bitv.sign_extend n e
        | Zero_extend n -> M.Bitv.zero_extend n e
        | TruncSF32 | TruncSF64 ->
          let rm = M.Float.Rounding_mode.rtz in
          M.Float.to_sbv bitwidth ~rm e
        | TruncUF32 | TruncUF64 ->
          let rm = M.Float.Rounding_mode.rtz in
          M.Float.to_ubv bitwidth ~rm e
        | Reinterpret_float -> M.Float.to_ieee_bv e
        | ToBool ->
          let zero = v (Ixx.of_int 0) in
          M.distinct [ e; zero ]
        | OfBool ->
          let one = v (Ixx.of_int 1) in
          let zero = v (Ixx.of_int 0) in
          M.ite e one zero
        | _ -> assert false
    end

    module I8 = Bitv_impl (struct
      type elt = int

      let v i = M.Bitv.v (string_of_int i) 8

      let bitwidth = 8

      module Ixx = struct
        let of_int i = i [@@inline]

        let shift_left v i = v lsl i [@@inline]
      end
    end)

    module I32 = Bitv_impl (struct
      type elt = int32

      let v i = M.Bitv.v (Int32.to_string i) 32

      let bitwidth = 32

      module Ixx = Int32
    end)

    module I64 = Bitv_impl (struct
      type elt = int64

      let v i = M.Bitv.v (Int64.to_string i) 64

      let bitwidth = 64

      module Ixx = Int64
    end)

    module type Float_sig = sig
      type elt

      val eb : int

      val sb : int

      val v : elt -> M.term
      (* TODO: *)
      (* val to_string : Z3.FuncDecl.func_decl *)
      (* val of_string : Z3.FuncDecl.func_decl *)
    end

    module Float_impl (F : Float_sig) = struct
      include F

      let unop op e =
        match op with
        | Neg -> M.Float.neg e
        | Abs -> M.Float.abs e
        | Sqrt ->
          let rne = M.Float.Rounding_mode.rne in
          M.Float.sqrt ~rm:rne e
        | Is_nan -> M.Float.is_nan e
        | Ceil ->
          let rm = M.Float.Rounding_mode.rtp in
          M.Float.round_to_integral ~rm e
        | Floor ->
          let rm = M.Float.Rounding_mode.rtn in
          M.Float.round_to_integral ~rm e
        | Trunc ->
          let rm = M.Float.Rounding_mode.rtz in
          M.Float.round_to_integral ~rm e
        | Nearest ->
          let rm = M.Float.Rounding_mode.rne in
          M.Float.round_to_integral ~rm e
        | _ -> err {|Fp: Unsupported Z3 unary operator "%a"|} Ty.pp_unop op

      let binop op e1 e2 =
        match op with
        | Add ->
          let rm = M.Float.Rounding_mode.rne in
          M.Float.add ~rm e1 e2
        | Sub ->
          let rm = M.Float.Rounding_mode.rne in
          M.Float.sub ~rm e1 e2
        | Mul ->
          let rm = M.Float.Rounding_mode.rne in
          M.Float.mul ~rm e1 e2
        | Div ->
          let rm = M.Float.Rounding_mode.rne in
          M.Float.div ~rm e1 e2
        | Min -> M.Float.min e1 e2
        | Max -> M.Float.max e1 e2
        | Rem -> M.Float.rem e1 e2
        | _ -> err {|Fp: Unsupported Z3 binop operator "%a"|} Ty.pp_binop op

      let triop op _ =
        err {|Fp: Unsupported Z3 triop operator "%a"|} Ty.pp_triop op

      let relop op e1 e2 =
        match op with
        | Eq -> M.Float.eq e1 e2
        | Ne ->
          let eq_ = M.Float.eq e1 e2 in
          M.not_ eq_
        | Lt -> M.Float.lt e1 e2
        | Le -> M.Float.le e1 e2
        | Gt -> M.Float.gt e1 e2
        | Ge -> M.Float.ge e1 e2
        | _ -> err {|Fp: Unsupported Z3 relop operator "%a"|} Ty.pp_relop op

      let cvtop op e =
        match op with
        | PromoteF32 | DemoteF64 ->
          let rm = M.Float.Rounding_mode.rne in
          M.Float.to_fp eb sb ~rm e
        | ConvertSI32 | ConvertSI64 ->
          let rm = M.Float.Rounding_mode.rne in
          M.Float.sbv_to_fp eb sb ~rm e
        | ConvertUI32 | ConvertUI64 ->
          let rm = M.Float.Rounding_mode.rne in
          M.Float.ubv_to_fp eb sb ~rm e
        | Reinterpret_int -> M.Float.of_ieee_bv eb sb e
        | ToString ->
          (* TODO: FuncDecl.apply to_string [ e ] *)
          assert false
        | OfString ->
          (* TODO: FuncDecl.apply of_string [ e ] *)
          assert false
        | _ -> err {|Fp: Unsupported Z3 cvtop operator "%a"|} Ty.pp_cvtop op
    end

    module Float32_impl = Float_impl (struct
      type elt = int32

      let eb = 8

      let sb = 24

      let v f = M.Float.v (Int32.float_of_bits f) eb sb

      (* TODO: *)
      (* let to_string = *)
      (*   Z3.FuncDecl.mk_func_decl_s ctx "F32ToString" [ fp32_sort ] str_sort *)
      (* let of_string = *)
      (*   Z3.FuncDecl.mk_func_decl_s ctx "StringToF32" [ str_sort ] fp32_sort *)
    end)

    module Float64_impl = Float_impl (struct
      type elt = int64

      let eb = 11

      let sb = 53

      let v f = M.Float.v (Int64.float_of_bits f) eb sb

      (* TODO: *)
      (* let to_string = *)
      (*   Z3.FuncDecl.mk_func_decl_s ctx "F64ToString" [ fp64_sort ] str_sort *)
      (* let of_string = *)
      (*   Z3.FuncDecl.mk_func_decl_s ctx "StringToF64" [ str_sort ] fp64_sort *)
    end)

    let v : Value.t -> M.term = function
      | True -> Bool_impl.true_
      | False -> Bool_impl.false_
      | Int v -> Int_impl.v v
      | Real v -> Real_impl.v v
      | Str v -> String_impl.v v
      | Num (I8 x) -> I8.v x
      | Num (I32 x) -> I32.v x
      | Num (I64 x) -> I64.v x
      | Num (F32 x) -> Float32_impl.v x
      | Num (F64 x) -> Float64_impl.v x

    let unop = function
      | Ty.Ty_int -> Int_impl.unop
      | Ty.Ty_real -> Real_impl.unop
      | Ty.Ty_bool -> Bool_impl.unop
      | Ty.Ty_str -> String_impl.unop
      | Ty.Ty_bitv 8 -> I8.unop
      | Ty.Ty_bitv 32 -> I32.unop
      | Ty.Ty_bitv 64 -> I64.unop
      | Ty.Ty_fp 32 -> Float32_impl.unop
      | Ty.Ty_fp 64 -> Float64_impl.unop
      | Ty.Ty_bitv _ | Ty_fp _ | Ty_list | Ty_array | Ty_tuple -> assert false

    let binop = function
      | Ty.Ty_int -> Int_impl.binop
      | Ty.Ty_real -> Real_impl.binop
      | Ty.Ty_bool -> Bool_impl.binop
      | Ty.Ty_str -> String_impl.binop
      | Ty.Ty_bitv 8 -> I8.binop
      | Ty.Ty_bitv 32 -> I32.binop
      | Ty.Ty_bitv 64 -> I64.binop
      | Ty.Ty_fp 32 -> Float32_impl.binop
      | Ty.Ty_fp 64 -> Float64_impl.binop
      | Ty.Ty_bitv _ | Ty_fp _ | Ty_list | Ty_array | Ty_tuple -> assert false

    let triop = function
      | Ty.Ty_int | Ty.Ty_real -> assert false
      | Ty.Ty_bool -> Bool_impl.triop
      | Ty.Ty_str -> String_impl.triop
      | Ty.Ty_bitv 8 -> I8.triop
      | Ty.Ty_bitv 32 -> I32.triop
      | Ty.Ty_bitv 64 -> I64.triop
      | Ty.Ty_fp 32 -> Float32_impl.triop
      | Ty.Ty_fp 64 -> Float64_impl.triop
      | Ty.Ty_bitv _ | Ty_fp _ | Ty_list | Ty_array | Ty_tuple -> assert false

    let relop = function
      | Ty.Ty_int -> Int_impl.relop
      | Ty.Ty_real -> Real_impl.relop
      | Ty.Ty_bool -> Bool_impl.relop
      | Ty.Ty_str -> String_impl.relop
      | Ty.Ty_bitv 8 -> I8.relop
      | Ty.Ty_bitv 32 -> I32.relop
      | Ty.Ty_bitv 64 -> I64.relop
      | Ty.Ty_fp 32 -> Float32_impl.relop
      | Ty.Ty_fp 64 -> Float64_impl.relop
      | Ty.Ty_bitv _ | Ty_fp _ | Ty_list | Ty_array | Ty_tuple -> assert false

    let cvtop = function
      | Ty.Ty_int -> Int_impl.cvtop
      | Ty.Ty_real -> Real_impl.cvtop
      | Ty.Ty_bool -> Bool_impl.cvtop
      | Ty.Ty_str -> String_impl.cvtop
      | Ty.Ty_bitv 8 -> I8.cvtop
      | Ty.Ty_bitv 32 -> I32.cvtop
      | Ty.Ty_bitv 64 -> I64.cvtop
      | Ty.Ty_fp 32 -> Float32_impl.cvtop
      | Ty.Ty_fp 64 -> Float64_impl.cvtop
      | Ty.Ty_bitv _ | Ty_fp _ | Ty_list | Ty_array | Ty_tuple -> assert false

    let rec encode_expr (hte : Expr.t) : M.term =
      match Expr.view hte with
      | Val value -> v value
      | Ptr (base, offset) ->
        let base' = v (Num (I32 base)) in
        let offset' = encode_expr offset in
        I32.binop Add base' offset'
      | Symbol { name; ty } ->
        let ty = get_type ty in
        M.const name ty
      | Unop (ty, op, e) ->
        let e = encode_expr e in
        unop ty op e
      | Binop (ty, op, e1, e2) ->
        let e1 = encode_expr e1 in
        let e2 = encode_expr e2 in
        binop ty op e1 e2
      | Triop (ty, op, e1, e2, e3) ->
        let e1 = encode_expr e1 in
        let e2 = encode_expr e2 in
        let e3 = encode_expr e3 in
        triop ty op e1 e2 e3
      | Relop (ty, op, e1, e2) ->
        let e1 = encode_expr e1 in
        let e2 = encode_expr e2 in
        relop ty op e1 e2
      | Cvtop (ty, op, e) ->
        let e = encode_expr e in
        cvtop ty op e
      | Extract (e, h, l) ->
        let e = encode_expr e in
        M.Bitv.extract e ~high:((h * 8) - 1) ~low:(l * 8)
      | Concat (e1, e2) ->
        let e1 = encode_expr e1 in
        let e2 = encode_expr e2 in
        M.Bitv.concat e1 e2
      | List _ | Array _ | Tuple _ | App _ -> assert false

    (* TODO: pp_smt *)
    let pp_smt ?status:_ _ _ = assert false

    let value (m : model) (c : Expr.t) : Value.t =
      let open M in
      let term = encode_expr c in
      let v = Model.eval ~completion:true m term |> Option.get in
      match Expr.ty c with
      | Ty_int -> Value.Int (Interp.to_int v)
      | Ty_real -> Value.Real (Interp.to_real v)
      | Ty_bool -> if Interp.to_bool v then Value.True else Value.False
      | Ty_str ->
        let str = Interp.to_string v in
        Value.Str str
      | Ty_bitv 8 ->
        let i8 = Interp.to_bitv v 8 in
        Value.Num (I8 (Int64.to_int i8))
      | Ty_bitv 32 ->
        let i32 = Interp.to_bitv v 32 in
        Value.Num (I32 (Int64.to_int32 i32))
      | Ty_bitv 64 ->
        let i64 = Interp.to_bitv v 64 in
        Value.Num (I64 i64)
      | Ty_fp 32 ->
        let float = Interp.to_float v 8 24 in
        Value.Num (F32 (Int32.bits_of_float float))
      | Ty_fp 64 ->
        let float = Interp.to_float v 11 53 in
        Value.Num (F64 (Int64.bits_of_float float))
      | Ty_bitv _ | Ty_fp _ | Ty_list | Ty_array | Ty_tuple -> assert false

    let values_of_model ?symbols model =
      let m = Hashtbl.create 512 in
      let symbols =
        match symbols with
        | None -> M.Model.get_symbols model
        | Some symbols -> symbols
      in
      List.iter
        (fun sym ->
          let v = value model (Expr.mk_symbol sym) in
          Hashtbl.replace m sym v )
        symbols;
      m

    let set_debug _ = ()

    module Solver = struct
      let make ?params ?logic () = M.Solver.make ?params ?logic ()

      let clone solver = M.Solver.clone solver

      let push solver = M.Solver.push solver

      let pop solver n = M.Solver.pop solver n

      let reset solver = M.Solver.reset solver

      let add solver (exprs : Expr.t list) =
        M.Solver.add solver (List.map encode_expr exprs)

      let check solver ~assumptions =
        M.Solver.check solver ~assumptions:(List.map encode_expr assumptions)

      let model solver = M.Solver.model solver

      let add_simplifier solver = M.Solver.add_simplifier solver

      let interrupt _ = M.Solver.interrupt ()

      let pp_statistics fmt solver = M.Solver.pp_statistics fmt solver
    end

    module Optimizer = struct
      let make = M.Optimizer.make

      let push = M.Optimizer.push

      let pop = M.Optimizer.pop

      let add opt exprs = M.Optimizer.add opt (List.map encode_expr exprs)

      let check = M.Optimizer.check

      let model = M.Optimizer.model

      let maximize opt (expr : Expr.t) =
        M.Optimizer.maximize opt (encode_expr expr)

      let minimize opt (expr : Expr.t) =
        M.Optimizer.minimize opt (encode_expr expr)

      let interrupt _ = M.Optimizer.interrupt ()

      let pp_statistics fmt opt = M.Optimizer.pp_statistics fmt opt
    end
  end

  module Fresh = struct
    module Make () = MakeMake (M0.Make ())
  end

  include MakeMake (M0)
end

module Make' (M : Mappings_intf.M_with_make) : S_with_fresh = Make (M)
