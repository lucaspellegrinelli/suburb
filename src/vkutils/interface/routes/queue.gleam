import gleam/dynamic.{type Dynamic}
import gleam/http.{Post}
import gleam/json
import gleam/result
import vkutils/common.{ConnectorError, InvalidKey}
import vkutils/interface/web.{type Context}
import vkutils/queue
import wisp.{type Request, type Response}

type QueueRequest {
  QueueRequest(action: String, namespace: String, name: String, value: String)
}

fn decode_queue_request(
  json: Dynamic,
) -> Result(QueueRequest, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode4(
      QueueRequest,
      dynamic.field("action", dynamic.string),
      dynamic.field("namespace", dynamic.string),
      dynamic.field("name", dynamic.string),
      dynamic.field("value", dynamic.string),
    )
  decoder(json)
}

fn call_error(e: common.ProjectError) {
  case e {
    common.InvalidKey(e) | common.ConnectorError(e) -> {
      json.object([
        #("status", json.string("error")),
        #("error", json.string(e)),
      ])
      |> json.to_string_builder
      |> wisp.json_response(400)
    }
  }
}

fn construct_response(value: json.Json) {
  json.object([#("status", json.string("success")), #("response", value)])
  |> json.to_string_builder
  |> wisp.json_response(200)
}

fn perform_request(ctx: Context, r: QueueRequest) {
  case r.action {
    "length" -> {
      use length <- result.map(result.map_error(
        queue.length(ctx.client, r.namespace, r.name),
        call_error,
      ))
      construct_response(json.int(length))
    }
    "push" -> {
      use out <- result.map(result.map_error(
        queue.push(ctx.client, r.namespace, r.name, r.value),
        call_error,
      ))
      construct_response(json.int(out))
    }
    "pop" -> {
      use value <- result.map(result.map_error(
        queue.pop(ctx.client, r.namespace, r.name),
        call_error,
      ))
      construct_response(json.string(value))
    }
    _ -> Ok(wisp.unprocessable_entity())
  }
}

pub fn queue_route(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Post)
  use json <- wisp.require_json(req)
  case decode_queue_request(json) {
    Ok(r) -> result.unwrap_both(perform_request(ctx, r))
    Error(_) -> wisp.unprocessable_entity()
  }
}
