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
import suburb/coders/log
import suburb/env

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

fn limit_flag() -> glint.Flag(String) {
  glint.string_flag("limit")
  |> glint.flag_help("The number of logs to list")
  |> glint.flag_default("25")
}

pub fn list() -> glint.Command(Nil) {
  use envvars <- env.with_env_variables()
  use <- glint.command_help("List the logs for the current namespace")
  use source <- glint.flag(source_flag())
  use level <- glint.flag(level_flag())
  use from_time <- glint.flag(from_time_flag())
  use to_time <- glint.flag(to_time_flag())
  use limit <- glint.flag(limit_flag())
  use _, _, flags <- glint.command()

  let params: List(String) =
    [
      create_flag_item("namespace", Ok(envvars.namespace)),
      create_flag_item("source", source(flags)),
      create_flag_item("level", level(flags)),
      create_flag_item("from_time", from_time(flags)),
      create_flag_item("to_time", to_time(flags)),
      create_flag_item("limit", limit(flags)),
    ]
    |> list.filter(fn(x) { !string.is_empty(x) })

  let query_params = "?" <> string.join(params, "&")
  let url = "/logs" <> query_params

  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.list(log.decoder)))
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(logs) -> {
      let values =
        list.map(logs, fn(l) {
          [l.created_at, envvars.namespace, l.source, l.level, l.message]
        })
      let headers = ["TIMESTAMP", "NAMESPACE", "SOURCE", "LEVEL", "MESSAGE"]
      let col_sizes = [24, 16, 16, 12, 999]
      print_table(headers, values, col_sizes)
    }
  }
}
