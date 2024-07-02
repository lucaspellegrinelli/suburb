import gleam/bool
import gleam/erlang/process
import gleam/result
import radish
import vkutils/common.{type ProjectError, get_key, parse_radish_error}

pub fn set(
  client: process.Subject(radish.Message),
  namespace: String,
  flag: String,
  value: Bool,
) -> Result(String, ProjectError) {
  use key <- result.try(get_key(namespace, flag))

  radish.set(client, key, bool.to_string(value), 128)
  |> result.map_error(parse_radish_error)
}

pub fn get(
  client: process.Subject(radish.Message),
  namespace: String,
  flag: String,
) -> Result(Bool, ProjectError) {
  use key <- result.try(get_key(namespace, flag))

  radish.get(client, key, 128)
  |> result.map(fn(x) { x == "True" })
  |> result.map_error(parse_radish_error)
}
