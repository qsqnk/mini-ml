let std_list =
  {|

let hd = function
  | [] -> []
  | hd :: tl -> [hd]
;;

let rev = 
  let rec helper acc = function 
    | [] -> acc
    | hd :: tl -> helper (hd :: acc) tl 
  in helper []
;;

let rec map f = function [] -> [] | hd :: tl -> f hd :: map f tl;;

let rec fold_left f acc = function 
  | [] -> acc
  | hd :: tl -> fold_left f (f acc hd) tl
;;

let rec fold_right f acc = function 
  | [] -> acc
  | hd :: tl -> f hd (fold_right f acc tl)
;;

let rec take n = function 
  | [] -> []
  | hd :: tl -> if n = 0 then [] else hd :: take (n - 1) tl
;;

let rec drop n = function
  | [] -> []
  | hd :: tl -> if n = 1 then tl else drop (n - 1) tl
;;


|}
;;

let integer_ar =
  {|

let succ x = x + 1;;

let pred x = x - 1;;

let mod x y = x - y * (x / y);;

let rec gcd x y = if x = 0 || y = 0 then x + y else gcd y (mod x y);;

|}
;;

let pair_ops = {|

let fst (x, y) = x;;

let snd (x, y) = y;;

|}

let stdlib = [ std_list; integer_ar; pair_ops ]
