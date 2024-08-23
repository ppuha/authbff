open Cohttp_lwt_unix

let client_id = "281416810018963459"
let client_secret = "0hbZVND7ZJhDCXYgWWhVOaUUQvtg4lla0BDwFrVLxWEM4sflhITm584aZclSggVE"
let redirect_uri = "http://localhost:8844/redirect"

let base_url = "http://localhost:8080/oauth/v2/authorize"

let auth_url =
  base_url ^
  "?client_id=" ^ client_id ^
  "&response_type=code" ^
  "&state=12345678" ^
  "&redirect_uri=" ^ redirect_uri ^
  "&scope=openid"

let token_url = "http://localhost:8080/oauth/v2/token"

let basic_header id secret =
  id ^ ":" ^ secret
  |> Base64.encode_string

let get_token code =
  let headers = Cohttp.Header.of_list [
    ("Authorization", "Basic " ^ basic_header client_id client_secret);
  ] in
  let params = [
    ("code", [code]);
    ("grant_type", ["authorization_code"]);
    ("redirect_uri", [redirect_uri]);
    ("client_id", [client_id]);
  ] in
  let%lwt (_resp, resp_body) =
    Client.post_form ~headers ~params
      (Uri.of_string token_url)
  in
  resp_body |> Cohttp_lwt.Body.to_string
