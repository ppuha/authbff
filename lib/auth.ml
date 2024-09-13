open Cohttp_lwt_unix
open Ppx_yojson_conv_lib.Yojson_conv

module Client = struct
  type t = {
    id : string;
    secret : string;
    redirect_uri : Uri.t;
    base_url : Uri.t;
    token_url : Uri.t;
  }

  let auth_url client =
    Uri.add_query_params'
      client.base_url
      [
        ("client_id", client.id);
        ("client_secret", client.secret);
        ("redirect_uri", client.redirect_uri |> Uri.to_string);
        ("response_type", "code");
        ("scope", "openid");
        ("state", Uuidm.ns_X500 |> Uuidm.to_string)
      ]

  let basic_header client =
    client.id ^ ":" ^ client.secret
    |> Base64.encode_string

  let get_token client code =
    let headers = Cohttp.Header.of_list [
      ("Authorization", "Basic " ^ basic_header client);
    ] in
    let params = [
      ("code", [code]);
      ("grant_type", ["authorization_code"]);
      ("redirect_uri", [client.redirect_uri |> Uri.to_string]);
      ("client_id", [client.id]);
    ] in
    let%lwt (_resp, resp_body) =
      Client.post_form ~headers ~params
        client.token_url
    in
    resp_body |> Cohttp_lwt.Body.to_string

  let default_client = {
    id = "281416810018963459";
    secret = "0hbZVND7ZJhDCXYgWWhVOaUUQvtg4lla0BDwFrVLxWEM4sflhITm584aZclSggVE";
    redirect_uri = "http://localhost:8844/redirect" |> Uri.of_string;
    base_url = "http://localhost:8080/oauth/v2/authorize" |> Uri.of_string;
    token_url = "http://localhost:8080/oauth/v2/token" |> Uri.of_string;
  }
end

module AuthResult = struct
  type t = {
    access_token : string;
    token_type : string;
    expires_in : int;
    id_token : string;
  }[@@deriving yojson]
end
