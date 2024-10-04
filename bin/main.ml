open Authbff

module Idp_store = Idp.FileStore (struct let path = "./bin/idps.json" end)
module H = Handler.Make (Idp_store)
module R = Router.Make (H)

let () =
  Dream.router [
    R.routes ~prefix:"";
  ]
  |> Dream.logger
  |> Dream.cookie_sessions
  |> Dream.run ~port:8844
