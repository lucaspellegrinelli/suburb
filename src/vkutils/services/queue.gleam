import gleam/erlang/process
import gleam/result
import radish
import radish/list
import vkutils/common.{type ServiceError, get_key, parse_radish_error}

const service = "queue"

pub fn length(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
) -> Result(Int, ServiceError) {
  use key <- result.try(get_key(service, namespace, name))

  list.len(client, key, 128)
  |> result.map_error(parse_radish_error)
}

pub fn push(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
  value: String,
) -> Result(Int, ServiceError) {
  use key <- result.try(get_key(service, namespace, name))

  list.rpush(client, key, [value], 128)
  |> result.map_error(parse_radish_error)
}

pub fn pop(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
) -> Result(String, ServiceError) {
  use key <- result.try(get_key(service, namespace, name))

  list.lpop(client, key, 128)
  |> result.map_error(parse_radish_error)
}
