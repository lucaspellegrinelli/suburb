import gleam/dynamic
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string

const host_info = "^(?:(https?)://)?([^/:]+)(?::(\\d+))?"

pub fn make_request(
  host: String,
  path: String,
  key: String,
  method: http.Method,
  body: Option(String),
) {
  let assert Ok(info_re) = regex.from_string(host_info)
  let info = case regex.scan(with: info_re, content: host) {
    [regex.Match(content: _, submatches: m)] -> {
      case m {
        [None, Some(host)] -> Ok(#(http.Https, host, None))
        [Some("http"), Some(host)] -> Ok(#(http.Http, host, None))
        [Some("https"), Some(host)] -> Ok(#(http.Https, host, None))
        [Some("http"), Some(host), Some(port)] -> {
          case int.parse(port) {
            Ok(port) -> Ok(#(http.Http, host, Some(port)))
            _ -> Error("Could not parse port")
          }
        }
        _ -> Error("Could not parse host")
      }
    }
    _ -> Error("Could not parse host")
  }

  use #(scheme, host, port) <- result.try(info)

  let req =
    request.new()
    |> request.set_method(method)
    |> request.set_path(path)
    |> request.set_host(host)
    |> request.set_scheme(scheme)
    |> request.set_header("authorization", key)
    |> request.set_header("content-type", "application/json")

  let req = case port {
    Some(port) -> request.set_port(req, port)
    None -> req
  }

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
            Error(error) -> Error(json_error_to_str(error))
          }
        }
      }
    }
    _ -> Error("Failed to send request")
  }
}

fn json_error_to_str(error: json.DecodeError) {
  case error {
    json.UnexpectedEndOfInput ->
      "Failed to decode host's response: UnexpectedEndOfInput"
    json.UnexpectedByte(b, p) ->
      "Failed to decode host's response: UnexpectedByte "
      <> b
      <> " at position "
      <> int.to_string(p)
    json.UnexpectedSequence(b, p) ->
      "Failed to decode host's response: UnexpectedSequence "
      <> b
      <> " at position "
      <> int.to_string(p)
    json.UnexpectedFormat(l) -> {
      let error_list =
        l
        |> list.map(fn(x) {
          "Expected "
          <> x.expected
          <> " and found "
          <> x.found
          <> " in path "
          <> string.join(x.path, "/")
        })

      "Failed to decode host's response: " <> string.join(error_list, ", ")
    }
  }
}
