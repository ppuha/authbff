module Make (Http : Http.S) = struct
  let middleware (inner_handler : Http.handler) (req : Http.request) =
    let new_headers = [
      ("Allow", "OPTIONS, GET, HEAD, POST");
      ("Access-Control-Allow-Origin", "*");
      ("Access-Control-Allow-Headers", "*");
    ]
    in
    let%lwt response = inner_handler req in
    new_headers
    |> List.map (fun (key, value) -> Http.add_header response key value)
    |> ignore;
    response |> Lwt.return
end
