import gleam/json
import suburb/types.{
  type ServiceError, ConnectorError, EmptyQueue, InvalidKey,
  ResourceAlreadyExists, ResourceDoesNotExist,
}
import wisp

pub fn extract_error(e: ServiceError) {
  case e {
    InvalidKey(e)
    | ConnectorError(e)
    | EmptyQueue(e)
    | ResourceDoesNotExist(e)
    | ResourceAlreadyExists(e) -> json.string(e)
  }
}

pub fn construct_response(value: json.Json, status: String, code: Int) {
  json.object([#("status", json.string(status)), #("response", value)])
  |> json.to_string_builder
  |> wisp.json_response(code)
}
