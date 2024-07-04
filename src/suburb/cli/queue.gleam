import gleam/dynamic
import gleam/http
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import glint
import suburb/cli/utils/req.{make_request}
import suburb/connect

pub fn list() -> glint.Command(Nil) {
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
    Ok(queues) -> ["NAMES", ..queues] |> list.each(io.println)
  }
}

pub fn length() -> glint.Command(Nil) {
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
    Ok(length) -> io.println(int.to_string(length))
  }
}

pub fn push() -> glint.Command(Nil) {
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
    Ok(response) -> io.println(response)
  }
}

pub fn pop() -> glint.Command(Nil) {
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
    Ok(response) -> io.println(response)
  }
}

pub fn create() -> glint.Command(Nil) {
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
    Ok(response) -> io.println(response)
  }
}

pub fn peek() -> glint.Command(Nil) {
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
    Ok(response) -> io.println(response)
  }
}
