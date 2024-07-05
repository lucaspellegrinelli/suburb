import gleam/dynamic
import gleam/http
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import glint
import suburb/cli/utils/display.{print_table}
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
      let values = list.map(flags, fn(l) { [l.0, l.1, l.2] })
      let headers = ["NAMESPACE", "FLAG", "VALUE"]
      let col_sizes = [16, 16, 99_999]
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
    Ok(response) -> io.println(response)
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
    Ok(response) -> io.println(response)
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
    Ok(response) -> io.println(response)
  }
}
