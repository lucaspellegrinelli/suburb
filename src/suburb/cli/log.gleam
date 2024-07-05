import gleam/dynamic
import gleam/http
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/result
import glint
import suburb/cli/utils/display.{print_table}
import suburb/cli/utils/req.{make_request}
import suburb/connect

pub fn list() -> glint.Command(Nil) {
  use <- glint.command_help("List the logs for a namespace")
  use namespace <- glint.named_arg("namespace")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/log/" <> namespace(named),
        key,
        http.Get,
        None,
      ))

      let decoded =
        resp
        |> json.decode(dynamic.field(
          "response",
          of: dynamic.list(of: fn(item) {
            let assert Ok(ns) =
              item |> dynamic.field(named: "namespace", of: dynamic.string)
            let assert Ok(src) =
              item |> dynamic.field(named: "source", of: dynamic.string)
            let assert Ok(lvl) =
              item |> dynamic.field(named: "level", of: dynamic.string)
            let assert Ok(msg) =
              item |> dynamic.field(named: "message", of: dynamic.string)
            let assert Ok(when) =
              item |> dynamic.field(named: "created_at", of: dynamic.string)
            Ok(#(ns, src, lvl, msg, when))
          }),
        ))

      case decoded {
        Ok(flags) -> Ok(flags)
        Error(_) -> Error("Failed to decode response")
      }
    }
    _ -> Error("No connection to a Suburb server")
  }

  case result {
    Error(e) -> io.println(e)
    Ok(logs) -> {
      let values = list.map(logs, fn(l) { [l.4, l.0, l.1, l.2, l.3] })
      let headers = ["TIMESTAMP", "NAMESPACE", "SOURCE", "LEVEL", "MESSAGE"]
      let col_sizes = [24, 16, 16, 12, 99_999]
      print_table(headers, values, col_sizes)
    }
  }
}
