let read_lines ch =
  let rec read' ch acc =
    try
      let line = input_line ch in
      read' ch (line::acc)
    with
      | End_of_file -> acc
  in read' ch [] |> List.rev

let show_form (form : (string * string) list) =
  form
  |> List.map (fun (k, v) -> k ^ ": " ^ v)
  |> String.concat ", "

let render_template name data =
  let ic = open_in (Printf.sprintf "./lib/%s.mustache" name) in
  let lines = read_lines ic in
  let content = lines |> String.concat "\n" in
  let templ = Mustache.of_string content in
  Mustache.render templ data |> Dream.html
