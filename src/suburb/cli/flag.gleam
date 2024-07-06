import gleam/dynamic
import gleam/http
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import glint
import suburb/cli/utils/display.{print_table}
import suburb/cli/utils/req.{create_flag_item, make_request}

fn namespace_flag() -> glint.Flag(String) {
  glint.string_flag("namespace")
  |> glint.flag_help("The namespace to list logs for")
}

fn flag_flag() -> glint.Flag(String) {
  glint.string_flag("flag")
  |> glint.flag_help("The name of the feature flag")
}

pub fn list() -> glint.Command(Nil) {
  use <- glint.command_help("List all the feature flags in a namespace")
  use namespace <- glint.flag(namespace_flag())
  use flag <- glint.flag(flag_flag())
  use _, _, flags <- glint.command()

  let params: List(String) =
    [
      create_flag_item("namespace", namespace(flags)),
      create_flag_item("flag", flag(flags)),
    ]
    |> list.filter(fn(x) { !string.is_empty(x) })

  let query_params = "?" <> string.join(params, "&")
  let url = "/flags" <> query_params

  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(of: fn(item) {
        let assert Ok(ns) =
          item |> dynamic.field(named: "namespace", of: dynamic.string)
        let assert Ok(flag) =
          item |> dynamic.field(named: "flag", of: dynamic.string)
        let assert Ok(value) =
          item |> dynamic.field(named: "value", of: dynamic.string)

        Ok(#(ns, flag, value))
      }),
    ))
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(flags) -> {
      let values = list.map(flags, fn(l) { [l.0, l.1, l.2] })
      let headers = ["NAMESPACE", "FLAG", "VALUE"]
      let col_sizes = [16, 16, 999]
      print_table(headers, values, col_sizes)
    }
  }
}

pub fn set() -> glint.Command(Nil) {
  use <- glint.command_help("Set a value for a feature flag")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use value <- glint.named_arg("value")
  use named, _, _ <- glint.command()

  let url = "/flags/" <> namespace(named) <> "/" <> name(named)
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }
  let body =
    json.object([
      #("namespace", json.string(namespace(named))),
      #("flag", json.string(name(named))),
      #("value", json.string(value(named))),
    ])

  case make_request(url, http.Post, Some(body), decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}

pub fn get() -> glint.Command(Nil) {
  use <- glint.command_help("Get the value of a feature flag")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/flags/" <> namespace(named) <> "/" <> name(named)
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}

pub fn delete() -> glint.Command(Nil) {
  use <- glint.command_help("Delete a feature flag")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/flags/" <> namespace(named) <> "/" <> name(named)
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }

  case make_request(url, http.Delete, None, decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}
