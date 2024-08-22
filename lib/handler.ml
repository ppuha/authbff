let read_lines ch =
  let rec read' ch acc =
    try
      let line = input_line ch in
      read' ch (line::acc)
    with
      | End_of_file -> acc
  in read' ch [] |> List.rev

let get _req =
  let ic = open_in "./lib/login.mustache" in
  let lines = read_lines ic in
  let content = lines |> String.concat "\n" in
  let templ = Mustache.of_string content in
  Mustache.render templ (
    `O [
      "idps", `A [
        `String "/login";
        `String "/login2"
      ]
    ]
  )
  |> Dream.html

let post _req =
  let%lwt resp = Auth.auth () in
  Dream.html resp

let redirect_get req =
  match Dream.query req "code" with
  | Some code ->
    let%lwt resp = Auth.get_token code in
    Dream.html resp
  | None -> Dream.html "empty"
