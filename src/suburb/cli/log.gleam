import gleam/dynamic
import gleam/http
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/string
import glint
import suburb/cli/utils/display.{print_table}
import suburb/cli/utils/req.{create_flag_item, make_request}

fn namespace_flag() -> glint.Flag(String) {
  glint.string_flag("namespace")
  |> glint.flag_help("The namespace to list logs for")
}

fn source_flag() -> glint.Flag(String) {
  glint.string_flag("source")
  |> glint.flag_help("The source to list logs for")
}

fn level_flag() -> glint.Flag(String) {
  glint.string_flag("level")
  |> glint.flag_help("The level to list logs for")
}

fn from_time_flag() -> glint.Flag(String) {
  glint.string_flag("from-time")
  |> glint.flag_help("The start time to list logs from")
}

fn to_time_flag() -> glint.Flag(String) {
  glint.string_flag("to-time")
  |> glint.flag_help("The end time to list logs to")
}

pub fn list() -> glint.Command(Nil) {
  use <- glint.command_help("List the logs for a namespace")
  use namespace <- glint.flag(namespace_flag())
  use source <- glint.flag(source_flag())
  use level <- glint.flag(level_flag())
  use from_time <- glint.flag(from_time_flag())
  use to_time <- glint.flag(to_time_flag())
  use _, _, flags <- glint.command()

  let params: List(String) =
    [
      create_flag_item("namespace", namespace(flags)),
      create_flag_item("source", source(flags)),
      create_flag_item("level", level(flags)),
      create_flag_item("from_time", from_time(flags)),
      create_flag_item("to_time", to_time(flags)),
    ]
    |> list.filter(fn(x) { !string.is_empty(x) })

  let query_params = "?" <> string.join(params, "&")
  let url = "/logs" <> query_params

  let decoder = fn(body: String) {
    body
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
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(logs) -> {
      let values = list.map(logs, fn(l) { [l.4, l.0, l.1, l.2, l.3] })
      let headers = ["TIMESTAMP", "NAMESPACE", "SOURCE", "LEVEL", "MESSAGE"]
      let col_sizes = [24, 16, 16, 12, 99_999]
      print_table(headers, values, col_sizes)
    }
  }
}
