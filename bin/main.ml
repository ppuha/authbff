open Authbff

let () =
  Dream.router [
    Dream.get "/login" Handler.get;
    Dream.post "/login" (Handler.post Handler.client);
    Dream.get "/redirect" (Handler.redirect_get Handler.client);
  ]
  |> Dream.logger
  |> Dream.run ~port:8844
