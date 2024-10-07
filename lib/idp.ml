open Cohttp_lwt_unix
open Ppx_yojson_conv_lib.Yojson_conv

type uri = Uri.t
let yojson_of_uri (uri : Uri.t) = `String (Uri.to_string uri)
let uri_of_yojson (yojson : Yojson.Safe.t) =
  match yojson with
  | `String uri -> Uri.of_string uri
  | _ -> failwith "parse error"

type client = {
  id : string;
  secret : string;
  redirect_uri : uri;
}[@@deriving yojson]

type t = {
  name : string;
  base_url : uri;
  token_url : uri;
  client : client;
}[@@deriving yojson]

type idp_list = t list [@@deriving yojson]

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

module type File = sig
  val path : string
end

module FileStore (F : File) = struct
  let path = F.path

  let get_all () =
    let content = Util.read_file path in
    Yojson.Safe.from_string content
    |> idp_list_of_yojson

  let get idp_name =
    get_all ()
    |> List.find_opt (fun idp -> idp.name = idp_name)
end
