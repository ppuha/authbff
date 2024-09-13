module Token = struct
  type t = {
    header : string;
    payload : string;
    signature : string;
  }

  let parse (str : string) =
    match String.split_on_char '.' str with
    | [header; payload; signature] -> Some { header; payload; signature }
    | _ -> None

  let decode_payload token =
    Base64.decode_exn ~pad:false token.payload
end