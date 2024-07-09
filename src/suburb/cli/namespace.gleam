import gleam/dynamic
import gleam/http
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import glint
import suburb/cli/utils/display.{print_table}
import suburb/cli/utils/req.{make_request}
import suburb/coders/namespace as namespace_coder

pub fn list() -> glint.Command(Nil) {
  use <- glint.command_help("List namespaces")
  use _, _, _ <- glint.command()

  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(of: namespace_coder.decoder),
    ))
  }

  let url = "/namespaces"
  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(flags) -> {
      let values = list.map(flags, fn(ns) { [ns.name] })
      let headers = ["NAMESPACE"]
      let col_sizes = [999]
      print_table(headers, values, col_sizes)
    }
  }
}

pub fn create() -> glint.Command(Nil) {
  use <- glint.command_help("Create a queue")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/namespaces"
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: namespace_coder.decoder))
  }
  let body = json.object([#("name", json.string(name(named)))])

  case make_request(url, http.Post, Some(body), decoder) {
    Error(e) -> io.println(e)
    Ok(ns) -> {
      let values = [[ns.name]]
      let headers = ["NAMESPACE"]
      let col_sizes = [999]
      print_table(headers, values, col_sizes)
    }
  }
}

pub fn delete() -> glint.Command(Nil) {
  use <- glint.command_help("Delete a namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/namespaces/" <> name(named)
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }

  case make_request(url, http.Delete, None, decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}
