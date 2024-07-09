import gleam/dynamic
import gleam/json
import suburb/types.{type Queue, Queue}

pub fn decoder(content: dynamic.Dynamic) {
  content
  |> dynamic.decode1(Queue, dynamic.field("queue", dynamic.string))
}

pub fn encoder(queue: Queue) {
  json.object([#("queue", json.string(queue.queue))])
}
