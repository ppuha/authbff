module type Router = sig
  type handler
  type route

  val get : string -> handler -> route
  val post : string -> handler -> route
  val options : string -> handler -> route
end

module type S = sig
  type route
  val routes : unit -> route list
end

module Make (Http : Http.S) (Idp_store : Idp.Store) (Router : Router with type handler = Http.handler) = struct
  module H = Handler.Make (Http) (Idp_store)
  module Cors = Cors.Make (Http)
  
  type route = Router.route

  let routes () = [
    Router.get "/login" H.get;
    Router.post "/login" H.post;
    Router.get "/redirect/:idp" H.redirect_get;
    Router.get "/user" (Cors.middleware H.user_get);
  ]
end
