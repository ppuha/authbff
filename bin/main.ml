open Authbff

module H = Handler.Make (Store.InMem)

let () =
  Dream.router [
    Dream.get "/login" H.get;
    Dream.post "/login" (H.post Handler.client);
    Dream.get "/redirect" (H.redirect_get Handler.client);
  ]
  |> Dream.logger
  |> Dream.run ~port:8844
