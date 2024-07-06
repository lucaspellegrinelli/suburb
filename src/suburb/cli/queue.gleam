import gleam/dynamic
import gleam/http
import gleam/int
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

fn queue_flag() -> glint.Flag(String) {
  glint.string_flag("queue")
  |> glint.flag_help("The queue to list logs for")
}

pub fn list() -> glint.Command(Nil) {
  use <- glint.command_help("List all the queues in a namespace")
  use namespace <- glint.flag(namespace_flag())
  use queue <- glint.flag(queue_flag())
  use _, _, flags <- glint.command()

  let params: List(String) =
    [
      create_flag_item("namespace", namespace(flags)),
      create_flag_item("queue", queue(flags)),
    ]
    |> list.filter(fn(x) { !string.is_empty(x) })

  let query_params = "?" <> string.join(params, "&")
  let url = "/queues" <> query_params
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(of: fn(item) {
        let assert Ok(ns) =
          item |> dynamic.field(named: "namespace", of: dynamic.string)
        let assert Ok(queue) =
          item |> dynamic.field(named: "queue", of: dynamic.string)

        Ok(#(ns, queue))
      }),
    ))
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(queues) -> {
      let values = list.map(queues, fn(l) { [l.0, l.1] })
      let headers = ["NAMESPACE", "QUEUE"]
      let col_sizes = [16, 999]
      print_table(headers, values, col_sizes)
    }
  }
}

pub fn create() -> glint.Command(Nil) {
  use <- glint.command_help("Create a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues"
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }
  let body =
    json.object([
      #("namespace", json.string(namespace(named))),
      #("queue", json.string(name(named))),
    ])

  case make_request(url, http.Post, Some(body), decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}

pub fn push() -> glint.Command(Nil) {
  use <- glint.command_help("Push a message to a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use message <- glint.named_arg("message")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> namespace(named) <> "/" <> name(named)
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }
  let body = json.object([#("message", json.string(message(named)))])

  case make_request(url, http.Post, Some(body), decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}

pub fn delete() -> glint.Command(Nil) {
  use <- glint.command_help("Delete a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> namespace(named) <> "/" <> name(named)
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }

  case make_request(url, http.Delete, None, decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}

pub fn peek() -> glint.Command(Nil) {
  use <- glint.command_help("Peek at the next message in a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> namespace(named) <> "/" <> name(named) <> "/peek"
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}

pub fn pop() -> glint.Command(Nil) {
  use <- glint.command_help("Pop a message from a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> namespace(named) <> "/" <> name(named) <> "/pop"
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.string))
  }

  case make_request(url, http.Post, None, decoder) {
    Error(e) -> io.println(e)
    Ok(response) -> io.println(response)
  }
}

pub fn length() -> glint.Command(Nil) {
  use <- glint.command_help("Get the length of a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> namespace(named) <> "/" <> name(named) <> "/length"
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.int))
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(length) -> io.println(int.to_string(length))
  }
}
