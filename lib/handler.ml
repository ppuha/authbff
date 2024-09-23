let token_field = "token"

let mustache_of_idp idp =
  let open Idp in
  `O [ ("name", `String idp.name) ]

module Make (Store : Idp.Store) = struct
  let get req =
    let redirect_uri = Dream.query req "redirect_uri" |> Option.get in
    let data = `O [
      ("idps", `A (Store.get_all () |> List.map mustache_of_idp));
      ("redirect_uri", `String redirect_uri)
    ] in
    Util.render_template "login" data

  let post req =
    match%lwt Dream.form ~csrf:false req with
    | `Ok [("name", idp_name); ("redirect_uri", redirect_uri)] ->
      let idp = Store.get idp_name |> Option.get in
      Dream.redirect req (Idp.auth_url idp redirect_uri |> Uri.to_string)
    | `Ok form -> Util.show_form form |> Dream.html;
    | _ -> Dream.html "err"

  let redirect_get req =
    let idp = Dream.param req "idp" |> Store.get |> Option.get in
    match (Dream.query req "code"), (Dream.query req "state") with
    | Some code, Some redirect_uri ->
      let%lwt resp = Idp.get_token idp code in
      let result = resp |> Yojson.Safe.from_string |> Idp.auth_result_of_yojson in
      let id_token = result.id_token |> Jwt.Token.parse |> Option.get in
      let%lwt _ =  Dream.set_session_field req token_field (id_token |> Jwt.Token.to_string) in
      Dream.redirect req redirect_uri
    | _ -> Dream.json "err"

  let error_resp =
    `Assoc [("error", `String "Not authenticated")]
    |> Yojson.Safe.to_string

  let user_get req =
    match Dream.session_field req token_field with
    | Some token ->
      token
      |> Jwt.Token.parse
      |> Option.get
      |> Jwt.Token.decode_payload
      |> Dream.json
    | None -> error_resp |> Dream.json
end
