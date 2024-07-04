import gleam/dynamic
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string

pub fn make_request(
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
