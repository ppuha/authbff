module type S = sig
  type key

  val persist : key -> Jwt.Token.t -> (Jwt.Token.t, string) Result.t
  val get : key -> (Jwt.Token.t, string) Result.t
  val delete : key -> (unit, string) Result.t
end

module InMem = struct
  type key = string

  let tokens : (key, Jwt.Token.t) Hashtbl.t = Hashtbl.create 100

  let persist key token =
    Hashtbl.add tokens key token;
    Result.ok token

  let get key =
    Hashtbl.find_opt tokens key
    |> Option.to_result ~none:"not found"

  let delete key =
    Hashtbl.remove tokens key;
    Result.ok ()
end
