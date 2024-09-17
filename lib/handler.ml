open Idp

let init =
  let zitadel = {
    name = "zitadel";
    base_url = "http://localhost:8080/oauth/v2/authorize" |> Uri.of_string;
    token_url = "http://localhost:8080/oauth/v2/token" |> Uri.of_string;
    client =  {
      id = "281416810018963459";
      secret = "0hbZVND7ZJhDCXYgWWhVOaUUQvtg4lla0BDwFrVLxWEM4sflhITm584aZclSggVE";
      redirect_uri = "http://localhost:8844/redirect/zitadel" |> Uri.of_string;
    }
  }
  in
  Store.add zitadel

let token_field = "token"

let get _req =
  let mustache_of_idp idp = `O [ ("name", `String idp.name) ] in
  let data = `O [
    "idps", `A (Store.get_all () |> List.map mustache_of_idp)
  ] in
  Util.render_template "login" data

let post req =
  match%lwt Dream.form ~csrf:false req with
  | `Ok ["name", idp_name] ->
    let idp = Store.get idp_name in
    Dream.redirect req (Idp.auth_url idp |> Uri.to_string)
| `Ok form -> Util.show_form form |> Dream.html;
  | _ -> Dream.html "err"

let redirect_get req =
  let idp = Dream.param req "idp" |> Store.get in
  match Dream.query req "code" with
  | Some code ->
    let%lwt resp = get_token idp code in
    let result = resp |> Yojson.Safe.from_string |> auth_result_of_yojson in
    let id_token = result.id_token |> Jwt.Token.parse |> Option.get in
    let%lwt _ =  Dream.set_session_field req token_field (id_token |> Jwt.Token.to_string ) in
    Dream.html "<a href='http://localhost:8844/user'>User data</a>"
  | None -> Dream.html "empty"

let user_get req =
  match Dream.session_field req token_field with
  | Some token ->
    token
    |> Jwt.Token.parse
    |> Option.get
    |> Jwt.Token.decode_payload
    |> Dream.html
  | None -> Dream.html "Not authenticated"
