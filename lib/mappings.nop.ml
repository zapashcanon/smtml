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

module Nop = struct
  module Make () = struct
    type ty

    type term

    type interp

    type model

    type solver

    type handle

    type optimizer

    let true_ = Obj.magic 0

    let false_ = Obj.magic 0

    let int _ = assert false

    let real _ = assert false

    let const _ = assert false

    let not_ _ = assert false

    let and_ _ = assert false

    let or_ _ = assert false

    let xor _ = assert false

    let eq _ = assert false

    let distinct _ = assert false

    let ite _ = assert false

    module Types = struct
      let int = Obj.magic 0

      let real = Obj.magic 0

      let bool = Obj.magic 0

      let string = Obj.magic 0

      let bitv = Obj.magic 0

      let float _ = assert false

      let ty _ = assert false

      let to_ety _ = assert false
    end

    module Interp = struct
      let to_int _ = assert false

      let to_real _ = assert false

      let to_bool _ = assert false

      let to_string _ = assert false

      let to_bitv _ = assert false

      let to_float _ = assert false
    end

    module Int = struct
      let neg _ = assert false

      let to_real _ = assert false

      let add _ = assert false

      let sub _ = assert false

      let mul _ = assert false

      let div _ = assert false

      let rem _ = assert false

      let pow _ = assert false

      let lt _ = assert false

      let le _ = assert false

      let gt _ = assert false

      let ge _ = assert false
    end

    module Real = struct
      let neg _ = assert false

      let to_int _ = assert false

      let add _ = assert false

      let sub _ = assert false

      let mul _ = assert false

      let div _ = assert false

      let pow _ = assert false

      let lt _ = assert false

      let le _ = assert false

      let gt _ = assert false

      let ge _ = assert false
    end

    module String = struct
      let v _ = assert false

      let length _ = assert false

      let to_code _ = assert false

      let of_code _ = assert false

      let to_int _ = assert false

      let of_int _ = assert false

      let at _ = assert false

      let concat _ = assert false

      let contains _ = assert false

      let is_prefix _ = assert false

      let is_suffix _ ~suffix:_ = assert false

      let sub _ ~pos:_ ~len:_ = assert false

      let index_of _ ~sub:_ ~pos:_ = assert false

      let replace _ ~pattern:_ ~with_:_ = assert false
    end

    module Bitv = struct
      let v _ = assert false

      let neg _ = assert false

      let lognot _ = assert false

      let add _ = assert false

      let sub _ = assert false

      let mul _ = assert false

      let div _ = assert false

      let div_u _ = assert false

      let logor _ = assert false

      let logand _ = assert false

      let logxor _ = assert false

      let shl _ = assert false

      let ashr _ = assert false

      let lshr _ = assert false

      let rem _ = assert false

      let rem_u _ = assert false

      let rotate_left _ = assert false

      let rotate_right _ = assert false

      let lt _ = assert false

      let lt_u _ = assert false

      let le _ = assert false

      let le_u _ = assert false

      let gt _ = assert false

      let gt_u _ = assert false

      let ge _ = assert false

      let ge_u _ = assert false

      let concat _ = assert false

      let extract _ ~high:_ ~low:_ = assert false

      let zero_extend _ = assert false

      let sign_extend _ = assert false
    end

    module Float = struct
      module Rounding_mode = struct
        let rne = Obj.magic 0

        let rna = Obj.magic 0

        let rtp = Obj.magic 0

        let rtn = Obj.magic 0

        let rtz = Obj.magic 0
      end

      let v _ = assert false

      let neg _ = assert false

      let abs _ = assert false

      let sqrt ~rm:_ = assert false

      let is_nan _ = assert false

      let round_to_integral ~rm:_ = assert false

      let add ~rm:_ = assert false

      let sub ~rm:_ = assert false

      let mul ~rm:_ = assert false

      let div ~rm:_ = assert false

      let min _ = assert false

      let max _ = assert false

      let rem _ = assert false

      let eq _ = assert false

      let lt _ = assert false

      let le _ = assert false

      let gt _ = assert false

      let ge _ = assert false

      let to_fp _ _ ~rm:_ = assert false

      let sbv_to_fp _ _ ~rm:_ = assert false

      let ubv_to_fp _ _ ~rm:_ = assert false

      let to_ubv _ ~rm:_ = assert false

      let to_sbv _ ~rm:_ = assert false

      let of_ieee_bv _ = assert false

      let to_ieee_bv _ = assert false
    end

    module Model = struct
      let get_symbols _ = assert false

      let eval ?completion:_ _ = assert false
    end

    module Solver = struct
      let make ?params:_ ?logic:_ =
        Format.ksprintf failwith "%s not installed" solver_name

      let clone _ = assert false

      let push _ = assert false

      let pop _ = assert false

      let reset _ = assert false

      let add _ = assert false

      let check _ ~assumptions:_ = assert false

      let model _ = assert false

      let add_simplifier _ = assert false

      let interrupt _ = assert false

      let pp_statistics _ = assert false
    end

    module Optimizer = struct
      let make _ = assert false

      let push _ = assert false

      let pop _ = assert false

      let add _ = assert false

      let check _ = assert false

      let model _ = assert false

      let maximize _ = assert false

      let minimize _ = assert false

      let interrupt _ = assert false

      let pp_statistics _ = assert false
    end
  end

  include Make ()
end

include Mappings.Make (Nop)
