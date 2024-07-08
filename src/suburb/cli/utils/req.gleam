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
import suburb/env.{EnvVars}

const host_info = "^(?:(https?)://)?([^/:]+)(?::(\\d+))?"

pub fn create_flag_item(name: String, value: Result(String, a)) {
  case value {
    Ok(value) -> name <> "=" <> value
    Error(_) -> ""
  }
}

pub fn make_request(
  path: String,
  method: http.Method,
  body: Option(json.Json),
  decoder: fn(String) -> Result(a, json.DecodeError),
) {
  use EnvVars(env_host, key) <- result.try(env.get_env_variables())

  let assert Ok(info_re) = regex.from_string(host_info)
  let info = case regex.scan(with: info_re, content: env_host) {
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
    Some(body) -> body |> json.to_string |> request.set_body(req, _)
    None -> req
  }

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          case decoder(resp.body) {
            Ok(v) -> Ok(v)
            Error(error) -> Error(json_error_to_str(error))
          }
        }
        _ -> {
          let decoded =
            resp.body
            |> json.decode(dynamic.field("response", of: dynamic.string))

          case decoded {
            Ok(value) -> Error(value)
            Error(error) -> Error(json_error_to_str(error))
          }
        }
      }
    }
    _ ->
      Error(
        "Failed to send request to remote.\nPlease check that SUBURB_REMOTE_HOST ("
        <> env_host
        <> ") is set correctly.",
      )
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
