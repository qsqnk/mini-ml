open Ast
open Parser
open Typing

let test_type ~label ~code ~expected =
  match parse exp code with
  | Error _ ->
    let () = Printf.printf "Parse error!" in
    false
  | Ok exp ->
    let ctx = TypeContext.empty in
    (match R.run (infer_exp ctx exp) with
    | Error e ->
      let () = Printf.printf "Error occured with %s: %s" label (show_error e) in
      false
    | Result.Ok (_, ty) when expected = ty -> true
    | Result.Ok (_, ty) ->
      let () =
        Printf.printf "[Typing test] %s failed.\nActual is:\n%s\n" label (show_tyexp ty)
      in
      false)
;;

let%test _ =
  test_type ~label:"Id" ~code:{|
 fun x -> x
 |} ~expected:(TArrow (TVar 0, TVar 0))
;;

let%test _ =
  test_type
    ~label:"Simple lambda"
    ~code:{| 
  fun x -> x + 1
  |}
    ~expected:(TArrow (TInt, TInt))
;;

let%test _ =
  test_type
    ~label:"Let exp"
    ~code:{|
  let f x = x in f
  |}
    ~expected:(TArrow (TVar 1, TVar 1))
;;

let%test _ =
  test_type
    ~label:"Nested let expressions"
    ~code:{|
    let a = let b = let c = true in c in b in a
    |}
    ~expected:TBool
;;

let%test _ =
  test_type
    ~label:"Many args"
    ~code:{|
    let func a b c d e f = a b c d e f in func
    |}
    ~expected:
      (TArrow
         ( TArrow
             ( TVar 11
             , TArrow
                 (TVar 12, TArrow (TVar 13, TArrow (TVar 14, TArrow (TVar 15, TVar 16))))
             )
         , TArrow
             ( TVar 11
             , TArrow
                 (TVar 12, TArrow (TVar 13, TArrow (TVar 14, TArrow (TVar 15, TVar 16))))
             ) ))
;;

let%test _ =
  test_type
    ~label:"Recursive factorial"
    ~code:{|
    let rec f = function 0 -> 1 | n -> n * f (n - 1) in f
    |}
    ~expected:(TArrow (TInt, TInt))
;;

let%test _ =
  test_type
    ~label:"Pattern matching + recursion"
    ~code:
      {|
      let rec int_from_list = function 
        | [ (a, b) ] -> a + b
        | hd :: tl -> int_from_list tl 
        | [] -> 0 
      in
      int_from_list
  |}
    ~expected:(TArrow (TList (TTuple [ TInt; TInt ]), TInt))
;;

let%test _ =
  test_type
    ~label:"Lambda applying to lambda"
    ~code:{|
      (fun x y -> x y) (fun z -> z > 0)
  |}
    ~expected:(TArrow (TInt, TBool))
;;

let%test _ =
  test_type
    ~label:"Lambda with perform"
    ~code:{|
     fun x -> perform x
  |}
    ~expected:(TArrow (TEffect (TVar 1), TVar 1))
;;

let%test _ =
  test_type
    ~label:"Fixpoint"
    ~code:{|
     let rec fix f x = f (fix f) x in fix
  |}
    ~expected:
      (TArrow
         ( TArrow (TArrow (TVar 6, TVar 7), TArrow (TVar 6, TVar 7))
         , TArrow (TVar 6, TVar 7) ))
;;

let%test _ =
  test_type
    ~label:"Fold"
    ~code:
      {|
     let rec fold f init = function [] -> init | hd :: tl -> fold f (f init hd) tl in fold
  |}
    ~expected:
      (TArrow
         ( TArrow (TVar 14, TArrow (TVar 13, TVar 14))
         , TArrow (TVar 14, TArrow (TList (TVar 13), TVar 14)) ))
;;

let%test _ =
  test_type
    ~label:"List reverse"
    ~code:
      {|

        let reverse = 
          let rec aux acc = function 
          | [] -> acc 
          | hd :: tl -> aux (hd :: acc) tl in
          aux []
        in reverse


  |}
    ~expected:(TArrow (TList (TVar 12), TList (TVar 12)))
;;

let%test _ =
  test_type
    ~label:"Just example"
    ~code:
      {|

        let f = 
          let plus_one x = x + 1 in 
          let to_str = function 
          | 0 -> "0"
          | 1 -> "1"
          | _ -> "42" in 
          let fst x y = x in 
        fun x y -> to_str (plus_one (fst x y))
        in f

  |}
    ~expected:(TArrow (TInt, TArrow (TVar 16, TString)))
;;

let%test _ =
  test_type
    ~label:"Declaration pattern matching"
    ~code:{|


      let a, b, (d, e) = 1, true, (1 :: [], "wtf") in (a, b, d, e)

  |}
    ~expected:(TTuple [ TInt; TBool; TList TInt; TString ])
;;

let%test _ =
  test_type
    ~label:"Fold + fixpoint"
    ~code:
      {|

     let fold = 
      let ffold self f init = function 
      | [] -> init
      | hd :: tl -> self f (f init hd) tl 
      in let rec fix f x = f (fix f) x in 
      fix ffold in fold

  |}
    ~expected:
      (TArrow
         ( TArrow (TVar 27, TArrow (TVar 26, TVar 27))
         , TArrow (TVar 27, TArrow (TList (TVar 26), TVar 27)) ))
;;
