module type S = sig
  type request
  type response
  type handler = request -> response Lwt.t

  val param : request -> string -> string
  val query : request -> string -> string option
  val form : request -> (string * string) list option Lwt.t

  val session_field : request -> string -> string option
  val set_session_field : request -> string -> string -> unit Lwt.t

  val html : string -> response Lwt.t
  val json : string -> response Lwt.t
  val redirect : request -> string -> response Lwt.t

  val add_header : response -> string -> string -> unit
end
