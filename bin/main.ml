open Authbff

let cors_middleware inner_handler req =
  let new_headers = [
    ("Allow", "OPTIONS, GET, HEAD, POST");
    ("Access-Control-Allow-Origin", "*");
    ("Access-Control-Allow-Headers", "*");
  ]
  in
  let%lwt response = inner_handler req in
  new_headers
  |> List.map (fun (key, value) -> Dream.add_header response key value)
  |> ignore;

  response |> Lwt.return

let () =
  Dream.router [
    Dream.get "/login" Handler.get;
    Dream.post "/login" (Handler.post Handler.client);
    Dream.get "/redirect" (Handler.redirect_get Handler.client);
    Dream.get "/user" (cors_middleware Handler.user_get);
    Dream.options "/login" (fun _req ->
      Dream.respond ~headers:[ ("Allow", "OPTIONS, GET, HEAD, POST") ] "");
  ]
  |> Dream.logger
  |> Dream.cookie_sessions
  |> Dream.run ~port:8844
