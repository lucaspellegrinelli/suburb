import gleam/bool
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
import suburb/coders/flag as flag_coder
import suburb/env

fn flag_flag() -> glint.Flag(String) {
  glint.string_flag("flag")
  |> glint.flag_help("The name of the feature flag")
}

pub fn list() -> glint.Command(Nil) {
  use envvars <- env.with_env_variables()
  use <- glint.command_help("List feature flags in the current namespace")
  use flag <- glint.flag(flag_flag())
  use _, _, flags <- glint.command()

  let params: List(String) =
    [create_flag_item("flag", flag(flags))]
    |> list.filter(fn(x) { !string.is_empty(x) })

  let query_params = "?" <> string.join(params, "&")
  let url = "/flags/" <> envvars.namespace <> query_params

  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(of: flag_coder.decoder),
    ))
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(flags) -> {
      let values =
        list.map(flags, fn(l) {
          [envvars.namespace, l.flag, bool.to_string(l.value)]
        })
      let headers = ["NAMESPACE", "FLAG", "VALUE"]
      let col_sizes = [16, 16, 999]
      print_table(headers, values, col_sizes)
    }
  }
}

pub fn set(value: Bool) -> glint.Command(Nil) {
  use envvars <- env.with_env_variables()
  use <- glint.command_help("Set a value for a feature flag")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/flags/" <> envvars.namespace <> "/" <> name(named)
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: flag_coder.decoder))
  }
  let body =
    json.object([
      #("namespace", json.string(envvars.namespace)),
      #("flag", json.string(name(named))),
      #("value", json.bool(value)),
    ])

  case make_request(url, http.Post, Some(body), decoder) {
    Error(e) -> io.println(e)
    Ok(f) -> {
      let values = [[envvars.namespace, f.flag, bool.to_string(f.value)]]
      let headers = ["NAMESPACE", "FLAG", "VALUE"]
      let col_sizes = [16, 16, 999]
      print_table(headers, values, col_sizes)
    }
  }
}

pub fn get() -> glint.Command(Nil) {
  use envvars <- env.with_env_variables()
  use <- glint.command_help("Get the value of a feature flag")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/flags/" <> envvars.namespace <> "/" <> name(named)
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: flag_coder.decoder))
  }

  case make_request(url, http.Get, None, decoder) {
    Ok(r) -> io.println(bool.to_string(r.value))
    Error(e) -> io.println(e)
  }
}

pub fn delete() -> glint.Command(Nil) {
  use envvars <- env.with_env_variables()
  use <- glint.command_help("Delete a feature flag")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/flags/" <> envvars.namespace <> "/" <> name(named)
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }

  case make_request(url, http.Delete, None, decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}
