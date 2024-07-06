import gleam/dynamic
import gleam/json
import suburb/types.{type Queue, Queue}

pub fn decoder(content: dynamic.Dynamic) {
  content
  |> dynamic.decode2(
    Queue,
    dynamic.field("namespace", dynamic.string),
    dynamic.field("queue", dynamic.string),
  )
}

pub fn encoder(queue: Queue) {
  json.object([
    #("namespace", json.string(queue.namespace)),
    #("queue", json.string(queue.queue)),
  ])
}
