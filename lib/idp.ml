open Cohttp_lwt_unix
open Ppx_yojson_conv_lib.Yojson_conv

type client = {
  id : string;
  secret : string;
  redirect_uri : Uri.t;
}

type t = {
  name : string;
  base_url : Uri.t;
  token_url : Uri.t;
  client : client;
}

let auth_url idp =
  Uri.add_query_params'
    idp.base_url
    [
      ("client_id", idp.client.id);
      ("client_secret", idp.client.secret);
      ("redirect_uri", idp.client.redirect_uri |> Uri.to_string);
      ("response_type", "code");
      ("scope", "openid");
      ("state", Uuidm.ns_X500 |> Uuidm.to_string)
    ]

let basic_header client =
  client.id ^ ":" ^ client.secret
  |> Base64.encode_string

let get_token idp code =
  let headers = Cohttp.Header.of_list [
    ("Authorization", "Basic " ^ basic_header idp.client);
  ] in
  let params = [
    ("code", [code]);
    ("grant_type", ["authorization_code"]);
    ("redirect_uri", [idp.client.redirect_uri |> Uri.to_string]);
    ("client_id", [idp.client.id]);
  ] in
  let%lwt (_resp, resp_body) =
    Client.post_form ~headers ~params
      idp.token_url
  in
  resp_body |> Cohttp_lwt.Body.to_string

type auth_result = {
  access_token : string;
  token_type : string;
  expires_in : int;
  id_token : string;
}[@@deriving yojson]

module Store = struct
  let idps : (string, t) Hashtbl.t = Hashtbl.create 20
  let add idp = Hashtbl.add idps idp.name idp
  let get idp_name = Hashtbl.find idps idp_name
  let get_all () = Hashtbl.to_seq idps |> List.of_seq |> List.map snd
end
