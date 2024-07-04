import gleam/dynamic
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import suburb/connect

fn make_request(
  host: String,
  path: String,
  key: String,
  method: http.Method,
  body: Option(String),
) {
  let scheme = case string.starts_with("https://", host) {
    True -> http.Https
    False -> http.Http
  }

  let host = case string.split(host, "://") {
    [_, host] -> host
    _ -> host
  }

  let req =
    request.new()
    |> request.set_method(method)
    |> request.set_path(path)
    |> request.set_host(host)
    |> request.set_scheme(scheme)
    |> request.set_header("authorization", key)
    |> request.set_header("content-type", "application/json")

  let req = case body {
    Some(body) -> {
      json.object([#("value", json.string(body))])
      |> json.to_string
      |> request.set_body(req, _)
    }
    None -> req
  }

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> Ok(resp.body)
        _ -> {
          let decoded =
            resp.body
            |> json.decode(dynamic.field("response", of: dynamic.string))

          case decoded {
            Ok(error) -> Error(error)
            Error(_) -> Error("Failed to decode response")
          }
        }
      }
    }
    _ -> Error("Failed to send request")
  }
}

pub fn queue_list() -> glint.Command(Nil) {
  use <- glint.command_help("List all the queues in a namespace")
  use namespace <- glint.named_arg("namespace")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/queue/" <> namespace(named) <> "/list",
        key,
        http.Get,
        None,
      ))

      let decoded =
        resp
        |> json.decode(dynamic.field(
          "response",
          of: dynamic.list(of: dynamic.string),
        ))

      case decoded {
        Ok(queues) -> Ok(queues)
        Error(_) -> Error("Failed to decode response")
      }
    }
    _ -> Error("No connection to a Suburb server")
  }

  case result {
    Error(e) -> io.println(e)
    Ok(queues) -> {
      io.println("Queues:")
      queues
      |> list.each(fn(q) { io.println(" - " <> q) })
    }
  }
}

pub fn queue_length() -> glint.Command(Nil) {
  use <- glint.command_help("Get the length of a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/queue/" <> namespace(named) <> "/" <> name(named) <> "/length",
        key,
        http.Get,
        None,
      ))

      let decoded =
        resp
        |> json.decode(dynamic.field("response", of: dynamic.int))

      case decoded {
        Ok(length) -> Ok(length)
        Error(_) -> Error("Failed to decode error response")
      }
    }
    _ -> Error("No connection to a Suburb server")
  }

  case result {
    Error(e) -> io.println(e)
    Ok(length) -> io.println("Length: " <> int.to_string(length))
  }
}

pub fn queue_push() -> glint.Command(Nil) {
  use <- glint.command_help("Push a message to a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use message <- glint.named_arg("message")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/queue/" <> namespace(named) <> "/" <> name(named),
        key,
        http.Post,
        Some(message(named)),
      ))

      let decoded =
        resp
        |> json.decode(dynamic.field("response", of: dynamic.string))

      case decoded {
        Ok(response) -> Ok(response)
        Error(_) -> Error("Failed to decode response")
      }
    }
    _ -> Error("No connection to a Suburb server")
  }

  case result {
    Error(e) -> io.println(e)
    Ok(response) -> io.println("Response: " <> response)
  }
}

pub fn queue_pop() -> glint.Command(Nil) {
  use <- glint.command_help("Pop a message from a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/queue/" <> namespace(named) <> "/" <> name(named),
        key,
        http.Delete,
        None,
      ))

      let decoded =
        resp
        |> json.decode(dynamic.field("response", of: dynamic.string))

      case decoded {
        Ok(response) -> Ok(response)
        Error(_) -> Error("Failed to decode response")
      }
    }
    _ -> Error("No connection to a Suburb server")
  }

  case result {
    Error(e) -> io.println(e)
    Ok(response) -> io.println("Response: " <> response)
  }
}

pub fn queue_create() -> glint.Command(Nil) {
  use <- glint.command_help("Create a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/queue/" <> namespace(named) <> "/create",
        key,
        http.Post,
        Some(name(named)),
      ))

      let decoded =
        resp
        |> json.decode(dynamic.field("response", of: dynamic.string))

      case decoded {
        Ok(response) -> Ok(response)
        Error(_) -> Error("Failed to decode response")
      }
    }
    _ -> Error("No connection to a Suburb server")
  }

  case result {
    Error(e) -> io.println(e)
    Ok(response) -> io.println("Response: " <> response)
  }
}

pub fn queue_peek() -> glint.Command(Nil) {
  use <- glint.command_help("Peek at the next message in a queue")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/queue/" <> namespace(named) <> "/" <> name(named),
        key,
        http.Get,
        None,
      ))

      let decoded =
        resp
        |> json.decode(dynamic.field("response", of: dynamic.string))

      case decoded {
        Ok(response) -> Ok(response)
        Error(_) -> Error("Failed to decode response")
      }
    }
    _ -> Error("No connection to a Suburb server")
  }

  case result {
    Error(e) -> io.println(e)
    Ok(response) -> io.println("Response: " <> response)
  }
}
