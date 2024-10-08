let token_field = "token"

let mustache_of_idp idp =
  let open Idp in
  `O [ ("name", `String idp.name) ]

module type S = sig
  type request
  type response
  type handler = request -> response Lwt.t

  val get : handler
  val post : handler
  val redirect_get : handler
  val user_get : handler
end

module Make (Http : Http.S) (Store : Idp.Store) = struct
  let get req =
    let redirect_uri = Http.query req "redirect_uri" |> Option.get in
    let data = `O [
      ("idps", `A (Store.get_all () |> List.map mustache_of_idp));
      ("redirect_uri", `String redirect_uri)
    ] in
    Util.render_template "login" data |> Http.html

  let post req =
    match%lwt Http.form req with
    | Some [("name", idp_name); ("redirect_uri", redirect_uri)] ->
      let idp = Store.get idp_name |> Option.get in
      Http.redirect req (Idp.auth_url idp redirect_uri |> Uri.to_string)
    | _ -> Http.html "err"

  let redirect_get req =
    let idp = Http.param req "idp" |> Store.get |> Option.get in
    match (Http.query req "code"), (Http.query req "state") with
    | Some code, Some redirect_uri ->
      let%lwt resp = Idp.get_token idp code in
      let result = resp |> Yojson.Safe.from_string |> Idp.auth_result_of_yojson in
      let id_token = result.id_token |> Jwt.Token.parse |> Option.get in
      let%lwt _ =  Http.set_session_field req token_field (id_token |> Jwt.Token.to_string) in
      Http.redirect req redirect_uri
    | _ -> Http.json "err"

  let error_resp =
    `Assoc [("error", `String "Not authenticated")]
    |> Yojson.Safe.to_string

  let user_get req =
    match Http.session_field req token_field with
    | Some token ->
      token
      |> Jwt.Token.parse
      |> Option.get
      |> Jwt.Token.decode_payload
      |> Http.json
    | None -> error_resp |> Http.json
end
