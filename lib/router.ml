module Make (H : Handler.S) = struct
  let routes ~prefix = Dream.scope prefix [] [
    Dream.get "/login" H.get;
    Dream.post "/login" H.post;
    Dream.get "/redirect/:idp" H.redirect_get;
    Dream.get "/user" (Cors.middleware H.user_get);
    Dream.options "/login" (fun _req ->
      Dream.respond ~headers:[ ("Allow", "OPTIONS, GET, HEAD, POST") ] "");
  ]
end
