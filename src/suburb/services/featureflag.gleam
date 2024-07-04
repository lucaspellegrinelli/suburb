// import gleam/bool
// import gleam/erlang/process
// import gleam/result
// import radish
// import suburb/common.{type ServiceError, get_key, parse_radish_error}

// const service = "featureflag"

// pub fn set(
//   client: process.Subject(radish.Message),
//   namespace: String,
//   flag: String,
//   value: Bool,
// ) -> Result(String, ServiceError) {
//   use key <- result.try(get_key(service, namespace, flag))

//   radish.set(client, key, bool.to_string(value), 128)
//   |> result.map_error(parse_radish_error)
// }

// pub fn get(
//   client: process.Subject(radish.Message),
//   namespace: String,
//   flag: String,
// ) -> Result(Bool, ServiceError) {
//   use key <- result.try(get_key(service, namespace, flag))

//   radish.get(client, key, 128)
//   |> result.map(fn(x) { x == "True" })
//   |> result.map_error(parse_radish_error)
// }

// pub fn delete(
//   client: process.Subject(radish.Message),
//   namespace: String,
//   flag: String,
// ) -> Result(Int, ServiceError) {
//   use key <- result.try(get_key(service, namespace, flag))

//   radish.del(client, [key], 128)
//   |> result.map_error(parse_radish_error)
// }
