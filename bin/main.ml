open Authbff

module Idp_store = Idp.InMemStore
module H = Handler.Make (Idp_store)
module R = Router.Make (H)

let () =
  Dream.router [
    R.routes ~prefix:"";
  ]
  |> Dream.logger
  |> Dream.cookie_sessions
  |> Dream.run ~port:8844
