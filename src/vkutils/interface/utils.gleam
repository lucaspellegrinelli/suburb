import gleam/json
import vkutils/common.{ConnectorError, InvalidKey}
import wisp

pub fn map_both(result: Result(a, b), ok: fn(a) -> c, err: fn(b) -> d) {
  case result {
    Ok(a) -> Ok(ok(a))
    Error(b) -> Error(err(b))
  }
}

pub fn extract_error(e: common.ServiceError) {
  case e {
    common.InvalidKey(e) | common.ConnectorError(e) -> json.string(e)
  }
}

pub fn construct_response(value: json.Json, status: String) {
  json.object([#("status", json.string(status)), #("response", value)])
  |> json.to_string_builder
  |> wisp.json_response(200)
}
