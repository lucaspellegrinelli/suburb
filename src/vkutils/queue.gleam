import gleam/erlang/process
import gleam/result
import radish
import radish/list
import vkutils/common.{type ProjectError, get_key, parse_radish_error}

pub fn length(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
) -> Result(Int, ProjectError) {
  use key <- result.try(get_key(namespace, name))

  list.len(client, key, 128)
  |> result.map_error(parse_radish_error)
}

pub fn push_many(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
  values: List(String),
) -> Result(Int, ProjectError) {
  use key <- result.try(get_key(namespace, name))

  list.rpush(client, key, values, 128)
  |> result.map_error(parse_radish_error)
}

pub fn push(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
  value: String,
) -> Result(Int, ProjectError) {
  use key <- result.try(get_key(namespace, name))

  list.rpush(client, key, [value], 128)
  |> result.map_error(parse_radish_error)
}

pub fn pop(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
) -> Result(String, ProjectError) {
  use key <- result.try(get_key(namespace, name))

  list.lpop(client, key, 128)
  |> result.map_error(parse_radish_error)
}
