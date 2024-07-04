import gleam/bool
import gleam/erlang/process
import gleam/list as glist
import gleam/result
import radish
import radish/list
import radish/set
import suburb/common.{
  type ServiceError, ResourceDoesNotExist, get_key, get_service_key,
  parse_radish_error,
}

const service = "queue"

pub fn list(
  client: process.Subject(radish.Message),
  namespace: String,
) -> Result(List(String), ServiceError) {
  let pattern = service <> ":" <> namespace <> ":*"
  use scan_result <- result.try(
    set.scan_pattern(client, service, 0, pattern, 16, 128)
    |> result.map_error(parse_radish_error),
  )

  Ok(scan_result.0)
}

fn queue_is_created(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
) -> Result(Bool, ServiceError) {
  use key <- result.try(get_key(service, namespace, name))
  use queue_list <- result.try(list(client, namespace))
  Ok(queue_list |> glist.contains(key))
}

pub fn length(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
) -> Result(Int, ServiceError) {
  use exists <- result.try(queue_is_created(client, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " does not exist.")),
  )

  use key <- result.try(get_key(service, namespace, name))

  list.len(client, key, 128)
  |> result.map_error(parse_radish_error)
}

pub fn push(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
  value: String,
) -> Result(Nil, ServiceError) {
  use exists <- result.try(queue_is_created(client, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " does not exist.")),
  )

  use key <- result.try(get_key(service, namespace, name))

  use push_out <- result.try(
    list.rpush(client, key, [value], 128)
    |> result.map_error(parse_radish_error),
  )

  case push_out {
    1 -> Ok(Nil)
    _ -> Error(ResourceDoesNotExist("Queue " <> name <> " does not exist."))
  }
}

pub fn pop(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
) -> Result(String, ServiceError) {
  use exists <- result.try(queue_is_created(client, namespace, name))
  use <- bool.guard(
    !exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " does not exist.")),
  )

  use key <- result.try(get_key(service, namespace, name))

  list.lpop(client, key, 128)
  |> result.map_error(parse_radish_error)
}

pub fn create(
  client: process.Subject(radish.Message),
  namespace: String,
  name: String,
) -> Result(Nil, ServiceError) {
  use exists <- result.try(queue_is_created(client, namespace, name))
  use <- bool.guard(
    exists,
    Error(ResourceDoesNotExist("Queue " <> name <> " already exists.")),
  )

  use service_key <- result.try(get_service_key(service, namespace))
  let queue_name = service_key <> ":" <> name
  use add_out <- result.try(
    set.add(client, service, [queue_name], 128)
    |> result.map_error(parse_radish_error),
  )

  case add_out {
    1 -> Ok(Nil)
    _ -> Error(ResourceDoesNotExist("Queue " <> name <> " already exists."))
  }
}
