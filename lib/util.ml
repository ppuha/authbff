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
