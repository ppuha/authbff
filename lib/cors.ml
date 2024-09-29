let middleware inner_handler req =
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
