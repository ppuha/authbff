open Authbff

let () =
  Dream.router [
    Dream.get "/login" Handler.get;
    Dream.post "/login" Handler.post;
  ]
  |> Dream.logger
  |> Dream.run ~port:8844
