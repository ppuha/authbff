open Idp
open Auth
open Client

let idps = [ {name = "zitadel"} ]

let mustache_of_idp idp = `O [ ("name", `String idp.name) ]

let client = {
  id = "281416810018963459";
  secret = "0hbZVND7ZJhDCXYgWWhVOaUUQvtg4lla0BDwFrVLxWEM4sflhITm584aZclSggVE";
  redirect_uri = "http://localhost:8844/redirect" |> Uri.of_string;
  base_url = "http://localhost:8080/oauth/v2/authorize" |> Uri.of_string;
  token_url = "http://localhost:8080/oauth/v2/token" |> Uri.of_string;
}

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

let post client req =
  let _ = match%lwt Dream.form ~csrf:false req with
  | `Ok form -> Util.show_form form |> print_endline;
    Lwt.return_unit
  | _ -> print_endline "error";
    Lwt.return_unit
  in
  Dream.redirect req (auth_url client |> Uri.to_string)

let redirect_get client req =
  match Dream.query req "code" with
  | Some code ->
    let%lwt resp = get_token client code in
    Dream.html resp
  | None -> Dream.html "empty"
