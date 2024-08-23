open Authbff

let () =
  Dream.router [
    Dream.get "/login" Handler.get;
    Dream.post "/login" Handler.post;
    Dream.get "/redirect" Handler.redirect_get
  ]
  |> Dream.logger
  |> Dream.run ~port:8844
