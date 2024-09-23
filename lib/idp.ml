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

let auth_url idp redirect_uri =
  Uri.add_query_params'
    idp.base_url
    [
      ("client_id", idp.client.id);
      ("client_secret", idp.client.secret);
      ("redirect_uri", idp.client.redirect_uri |> Uri.to_string);
      ("response_type", "code");
      ("scope", "openid email profile");
      ("state", redirect_uri)
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

module type Store = sig
  val get : string -> t option
  val get_all : unit -> t list
end

module InMemStore = struct
  let idps : (string, t) Hashtbl.t = Hashtbl.create 5
  let add idp = Hashtbl.add idps idp.name idp
  let get idp_name = Hashtbl.find_opt idps idp_name
  let get_all () = Hashtbl.to_seq idps |> List.of_seq |> List.map snd

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
    add zitadel
end
