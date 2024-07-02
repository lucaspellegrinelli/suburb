import gleam/bool
import gleam/string
import radish/error

pub type ServiceError {
  InvalidKey(String)
  ConnectorError(String)
}

pub fn get_key(
  service: String,
  namespace: String,
  name: String,
) -> Result(String, ServiceError) {
  use <- bool.guard(
    string.is_empty(service),
    Error(InvalidKey("Service name cannot be empty")),
  )

  use <- bool.guard(
    string.is_empty(namespace),
    Error(InvalidKey("Namespace name cannot be empty")),
  )

  use <- bool.guard(
    string.is_empty(name),
    Error(InvalidKey("Name cannot be empty")),
  )

  use <- bool.guard(
    string.contains(service, ":"),
    Error(InvalidKey("Service name cannot contain ':'")),
  )

  use <- bool.guard(
    string.contains(namespace, ":"),
    Error(InvalidKey("Namespace name cannot contain ':'")),
  )

  use <- bool.guard(
    string.contains(name, ":"),
    Error(InvalidKey("Name cannot contain ':'")),
  )

  Ok(string.concat([service, ":", namespace, ":", name]))
}

pub fn parse_radish_error(e: error.Error) -> ServiceError {
  case e {
    error.NotFound -> ConnectorError("Queue not found")
    error.RESPError -> ConnectorError("Error in RESP protocol")
    error.ActorError -> ConnectorError("Error in actor")
    error.ConnectionError -> ConnectorError("Connection error")
    error.TCPError(_) -> ConnectorError("TCP error")
    error.ServerError(e) -> ConnectorError(e)
  }
}
