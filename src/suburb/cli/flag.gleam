import gleam/dynamic
import gleam/http
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import glint
import suburb/cli/utils/req.{make_request}
import suburb/connect

pub fn list() -> glint.Command(Nil) {
  use <- glint.command_help("List all the feature flags in a namespace")
  use namespace <- glint.named_arg("namespace")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/flag/" <> namespace(named) <> "/list",
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
        Ok(flags) -> Ok(flags)
        Error(_) -> Error("Failed to decode response")
      }
    }
    _ -> Error("No connection to a Suburb server")
  }

  case result {
    Error(e) -> io.println(e)
    Ok(flags) -> {
      io.println("Feature Flags:")
      flags
      |> list.each(fn(q) { io.println(" - " <> q) })
    }
  }
}

pub fn set() -> glint.Command(Nil) {
  use <- glint.command_help("Set a value for a feature flag")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use value <- glint.named_arg("value")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/flag/" <> namespace(named) <> "/" <> name(named),
        key,
        http.Post,
        Some(value(named)),
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

pub fn get() -> glint.Command(Nil) {
  use <- glint.command_help("Get the value of a feature flag")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/flag/" <> namespace(named) <> "/" <> name(named),
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

pub fn delete() -> glint.Command(Nil) {
  use <- glint.command_help("Delete a feature flag")
  use namespace <- glint.named_arg("namespace")
  use name <- glint.named_arg("name")
  use named, _, _ <- glint.command()

  let result = case connect.remote_connection() {
    Ok(#(host, key)) -> {
      use resp <- result.try(make_request(
        host,
        "/flag/" <> namespace(named) <> "/" <> name(named),
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
