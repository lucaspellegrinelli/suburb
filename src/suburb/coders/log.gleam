import gleam/dynamic
import gleam/json
import suburb/types.{type Log, Log}

pub fn decoder(content: dynamic.Dynamic) {
  content
  |> dynamic.decode4(
    Log,
    dynamic.field("source", dynamic.string),
    dynamic.field("level", dynamic.string),
    dynamic.field("message", dynamic.string),
    dynamic.field("created_at", dynamic.string),
  )
}

pub fn encoder(log: Log) {
  json.object([
    #("source", json.string(log.source)),
    #("level", json.string(log.level)),
    #("message", json.string(log.message)),
    #("created_at", json.string(log.created_at)),
  ])
}
