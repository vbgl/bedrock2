Require Import Coq.Lists.List.
Import ListNotations.
Require bedrock2.Examples.Demos.
Require Import coqutil.Decidable.
Require Import compiler.ExprImp.
Require Import compiler.NameGen.
Require Import compiler.PipelineWithRename.
Require Import riscv.Utility.Words32Naive.
Require Import riscv.Utility.DefaultMemImpl32.
Require Import riscv.Utility.Monads.
Require Import compiler.util.Common.
Require Import coqutil.Decidable.
Require        riscv.Utility.InstructionNotations.
Require Import riscv.Platform.MinimalLogging.
Require Import bedrock2.MetricLogging.
Require Import riscv.Platform.MetricMinimal.
Require Import riscv.Utility.Utility.
Require Import riscv.Utility.Encode.
Require Import coqutil.Map.SortedList.
Require Import compiler.StringNameGen.
Require Import riscv.Utility.InstructionCoercions.
Require Import riscv.Platform.MetricRiscvMachine.
Require Import bedrock2.Byte.
Require bedrock2.Hexdump.
Require Import bedrock2.Examples.swap.

Open Scope Z_scope.
Open Scope string_scope.
Open Scope ilist_scope.

Axiom TODO: forall {T: Type}, T.

Local Existing Instance DefaultRiscvState.
Local Existing Instance coqutil.Map.SortedListString.map.
Local Existing Instance coqutil.Map.SortedListString.ok.
Instance flatToRiscvDef_params: FlatToRiscvDef.FlatToRiscvDef.parameters := {
  FlatToRiscvDef.FlatToRiscvDef.compile_ext_call retnames fname argnames :=
    if string_dec fname "nop" then [[Addi Register0 Register0 0]]
    else if string_dec fname "MMIOREAD" then
           match retnames, argnames with
           | [res], [addr] => [[ Lw res addr 0 ]]
           | _, _ => nil
           end
    else if string_dec fname "MMIOWRITE" then
           match retnames, argnames with
           | [], [addr; val] => [[ Sw addr val 0 ]]
           | _, _ => nil
           end
    else  nil;
  FlatToRiscvDef.FlatToRiscvDef.compile_ext_call_length _ := TODO;
  FlatToRiscvDef.FlatToRiscvDef.compile_ext_call_emits_valid _ _ := TODO;
}.
Notation RiscvMachine := MetricRiscvMachine.


Instance mapops: RegAlloc.map.ops (SortedListString.map Z). refine (
  {| RegAlloc.map.intersect (s1 s2 : SortedListString.map Z) :=
    {| value := ListLib.list_intersect (fun '(k,v) '(k',v') => andb (_ k k') (_ v v')) (value s1) (value s2); _value_ok := TODO |};
     RegAlloc.map.default_value := 666;
  |}).
- exact String.eqb.
- exact Z.eqb.
Defined.

Definition params : Pipeline.parameters. simple refine {|
  Pipeline.locals := _;
  Pipeline.Registers := _;
  Pipeline.ext_spec _ _ := TODO;
  Pipeline.ext_guarantee _ := False;
  Pipeline.PRParams := TODO;
  Pipeline.src2imp_ops := mapops;
|}; unshelve (try exact _); apply TODO. Defined.
Definition flatparams := (FlattenExpr.mk_Syntax_params (@Pipeline.FlattenExpr_parameters params)).
Instance pipeline_assumptions: @Pipeline.assumptions params. Admitted.

(* stack grows from high addreses to low addresses, first stack word will be written to
   (stack_pastend-4), next stack word to (stack_pastend-8) etc *)
Definition stack_pastend: Z := 1024.

Definition ml: MemoryLayout Semantics.width.
  refine {| MemoryLayout.stack_pastend := word.of_Z stack_pastend; |}.
  all: apply TODO.
Defined.

Definition compile '(functions, initial, reactive) :=
  compile_prog (p:=params)
     (@Build_Program (FlattenExpr.mk_Semantics_params (@Pipeline.FlattenExpr_parameters params))
                     _
                     (List.map fst functions)
                     (RegAlloc.map.putmany_of_pairs map.empty functions)
                     initial
                     reactive) ml.

Definition instrencode p : list byte :=
  let word8s := List.flat_map (fun inst => HList.tuple.to_list (LittleEndian.split 4 (encode inst))) p in
  List.map (fun w => Byte.of_Z (word.unsigned w)) word8s.

Require Import coqutil.Z.HexNotation.
Definition i : @varname flatparams := "i".
Definition prog := (
  [swap; swap_swap],
  @cmd.call flatparams [] "swap_swap" [expr.literal (2^9); expr.literal (2^9+4)],
  cmd.seq (cmd.set i (expr.load access_size.word (expr.literal (2^9-2))))
  (cmd.seq (cmd.store access_size.word (expr.literal (Ox"1001200c")) (expr.var i))
  (cmd.store access_size.word (expr.literal (2^9-2)) (expr.op bopname.add (expr.var i) (expr.literal 1))))).

Import riscv.Utility.InstructionNotations.
Import bedrock2.Hexdump.
Local Open Scope hexdump_scope.
Set Printing Width 108.
Goal True.
  let r := eval cbv in (([[
                             Sw 0 0 (2^9-4);
                             Addi 7 0 (42);
                             Sw 0 7 (2^9);
                             Addi 7 0 (36);
                             Sw 0 7 (2^9+4)
                         ]] ++ compile prog)%list%Z) in
  pose r as asm.
  Import bedrock2.NotationsCustomEntry.

  (* searching for "addi    x2, x2, -" shows where the functions begin, and the first
     thing they do is to save all used registers onto the stack, so we can look for the
     max there to see how many registers a function needs *)

  let x := eval cbv in (instrencode asm) in
  idtac (* x *).
Abort.
