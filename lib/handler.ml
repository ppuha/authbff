open Idp

let idps = [ {name = "zitadel"} ]

let mustache_of_idp idp = `O [ ("name", `String idp.name) ]

let get _req =
  let ic = open_in "./lib/login.mustache" in
  let lines = Util.read_lines ic in
  let content = lines |> String.concat "\n" in
  let templ = Mustache.of_string content in
  Mustache.render templ (
    `O [
      "idps", `A (idps |> List.map mustache_of_idp)
    ]
  )
  |> Dream.html

let post req =
  let _ = match%lwt Dream.form ~csrf:false req with
  | `Ok form -> Util.show_form form |> print_endline;
    Lwt.return_unit
  | _ -> print_endline "error";
    Lwt.return_unit
  in
  Dream.redirect req (Auth.auth_url)

let redirect_get req =
  match Dream.query req "code" with
  | Some code ->
    let%lwt resp = Auth.get_token code in
    Dream.html resp
  | None -> Dream.html "empty"
