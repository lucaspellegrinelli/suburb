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
import suburb/coders/queue as queue_coder
import suburb/env

fn queue_flag() -> glint.Flag(String) {
  glint.string_flag("queue")
  |> glint.flag_help("The queue to list logs for")
}

pub fn list() -> glint.Command(Nil) {
  use envvars <- env.with_env_variables()
  use <- glint.command_help("List all the queues in the current namespace")
  use queue <- glint.flag(queue_flag())
  use _, _, flags <- glint.command()

  let params: List(String) =
    [create_flag_item("queue", queue(flags))]
    |> list.filter(fn(x) { !string.is_empty(x) })

  let query_params = "?" <> string.join(params, "&")
  let url = "/queues/" <> envvars.namespace <> query_params
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field(
      "response",
      of: dynamic.list(of: queue_coder.decoder),
    ))
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(queues) -> {
      let values = list.map(queues, fn(q) { [envvars.namespace, q.queue] })
      let headers = ["NAMESPACE", "QUEUE"]
      let col_sizes = [16, 999]
      print_table(headers, values, col_sizes)
    }
  }
}

pub fn create() -> glint.Command(Nil) {
  use envvars <- env.with_env_variables()
  use <- glint.command_help("Create a queue")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> envvars.namespace
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: queue_coder.decoder))
  }
  let body = json.object([#("queue", json.string(name(named)))])

  case make_request(url, http.Post, Some(body), decoder) {
    Error(e) -> io.println(e)
    Ok(q) -> {
      let values = [[envvars.namespace, q.queue]]
      let headers = ["NAMESPACE", "QUEUE"]
      let col_sizes = [16, 999]
      print_table(headers, values, col_sizes)
    }
  }
}

pub fn push() -> glint.Command(Nil) {
  use envvars <- env.with_env_variables()
  use <- glint.command_help("Push a message to a queue")
  use name <- glint.named_arg("name")
  use message <- glint.named_arg("message")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> envvars.namespace <> "/" <> name(named)
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
  use envvars <- env.with_env_variables()
  use <- glint.command_help("Delete a queue")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> envvars.namespace <> "/" <> name(named)
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
  use envvars <- env.with_env_variables()
  use <- glint.command_help("Peek at the next message in a queue")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> envvars.namespace <> "/" <> name(named) <> "/peek"
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
  use envvars <- env.with_env_variables()
  use <- glint.command_help("Pop a message from a queue")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> envvars.namespace <> "/" <> name(named) <> "/pop"
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
  use envvars <- env.with_env_variables()
  use <- glint.command_help("Get the length of a queue")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let url = "/queues/" <> envvars.namespace <> "/" <> name(named) <> "/length"
  let decoder = fn(body: String) {
    body
    |> json.decode(dynamic.field("response", of: dynamic.int))
  }

  case make_request(url, http.Get, None, decoder) {
    Error(e) -> io.println(e)
    Ok(length) -> io.println(int.to_string(length))
  }
}
