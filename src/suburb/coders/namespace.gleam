import gleam/dynamic
import gleam/json
import suburb/types.{type Namespace, Namespace}

pub fn decoder(content: dynamic.Dynamic) {
  content
  |> dynamic.decode1(Namespace, dynamic.field("name", dynamic.string))
}

pub fn encoder(namespace: Namespace) {
  json.object([#("name", json.string(namespace.name))])
}
