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
    let result = resp |> Yojson.Safe.from_string |> AuthResult.t_of_yojson in
    let id_token = result.id_token |> Jwt.Token.parse |> Option.get in
    let%lwt _ =  Dream.set_session_field req "token" (id_token |> Jwt.Token.to_string ) in
    Dream.html "<a href='http://localhost:8844/user'>User data</a>"
  | None -> Dream.html "empty"

let user_get req =
  match Dream.session_field req "token" with
  | Some token ->
    token
    |> Jwt.Token.parse
    |> Option.get
    |> Jwt.Token.decode_payload
    |> Dream.html
  | None -> Dream.html "Not authenticated"
