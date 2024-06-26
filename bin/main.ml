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

open Smtml
open Solver_dispatcher

type prove_mode =
  | Batch
  | Cached
  | Incremental

let solver_conv =
  Cmdliner.Arg.conv
    (Solver_dispatcher.solver_type_of_string, Solver_dispatcher.pp_solver_type)

let prove_mode_conv =
  Cmdliner.Arg.enum
    [ ("batch", Batch); ("cached", Cached); ("incremental", Incremental) ]

let parse_cmdline =
  let aux files solver prover_mode debug print_statistics =
    let module Mappings =
      (val mappings_of_solver solver : Mappings_intf.S_with_fresh)
    in
    Mappings.set_debug debug;
    let module Solver =
      ( val match prover_mode with
            | Batch -> (module Solver.Batch (Mappings))
            | Cached -> (module Solver.Cached (Mappings))
            | Incremental -> (module Solver.Incremental (Mappings))
          : Solver_intf.S )
    in
    let module Interpret = Interpret.Make (Solver) in
    let state =
      match files with
      | [] ->
        let ast = Parse.from_file ~filename:"-" in
        Some (Interpret.start ast)
      | _ ->
        List.fold_left
          (fun state filename ->
            let ast = Parse.from_file ~filename in
            Some (Interpret.start ?state ast) )
          None files
    in
    if print_statistics then begin
      let state = Option.get state in
      let stats : Gc.stat = Gc.stat () in
      Format.eprintf
        "@[<v 2>(statistics @\n\
         (major-words %f)@\n\
         (solver-time %f)@\n\
         (solver-calls %d)@\n\
         @[<v 2>(solver-misc @\n\
         %a@])@])@\n"
        stats.major_words !Solver.solver_time !Solver.solver_count
        Solver.pp_statistics state.solver
    end
  in
  let open Cmdliner in
  let files =
    Arg.(value & pos_all string [] & info [] ~docv:"files" ~doc:"files to read")
  and prover =
    Arg.(
      value & opt solver_conv Z3_solver
      & info [ "s"; "solver" ] ~doc:"SMT solver to use" )
  and prover_mode =
    Arg.(
      value & opt prove_mode_conv Batch & info [ "mode" ] ~doc:"SMT solver mode" )
  and debug =
    Arg.(value & flag & info [ "debug" ] ~doc:"Print debugging messages")
  and print_statistics =
    Arg.(value & flag & info [ "st" ] ~doc:"Print statistics")
  in
  Cmd.v
    (Cmd.info "smtml" ~version:"%%VERSION%%")
    Term.(const aux $ files $ prover $ prover_mode $ debug $ print_statistics)

let () =
  match Cmdliner.Cmd.eval_value parse_cmdline with
  | Error (`Parse | `Term | `Exn) -> exit 2
  | Ok (`Ok () | `Version | `Help) -> ()
