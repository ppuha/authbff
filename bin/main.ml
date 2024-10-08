open Authbff

module Dream_http = struct
  type request = Dream.request
  type response = Dream.response

  let param = Dream.param
  let query = Dream.query
  let form req =
    let%lwt res = Dream.form ~csrf:false req in
    match res with
    | `Ok form -> Some form |> Lwt.return
    | _ -> None |> Lwt.return

  let session_field = Dream.session_field
  let set_session_field = Dream.set_session_field

  let html resp = Dream.html resp
  let json resp = Dream.json resp
  let redirect req url = Dream.redirect req url
  let add_header = Dream.add_header

  type handler = Dream.handler
  type route = Dream.route
  let get = Dream.get
  let post = Dream.post
  let options = Dream.options
end

module Idp_store = Idp.FileStore (struct let path = "./bin/idps.json" end)
module Router = Router.Make (Dream_http) (Idp_store) (Dream_http)

let () =
  Dream.router [
    Dream.scope "/" [] (Router.routes ());
  ]
  |> Dream.logger
  |> Dream.cookie_sessions
  |> Dream.run ~port:8844
