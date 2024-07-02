import gleam/dynamic.{type Dynamic}
import gleam/http.{Post}
import gleam/json
import gleam/result
import vkutils/interface/utils.{construct_response, extract_error, map_both}
import vkutils/interface/web.{type Context}
import vkutils/services/queue
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

fn perform_request(ctx: Context, r: QueueRequest) {
  case r.action {
    "length" ->
      map_both(
        queue.length(ctx.client, r.namespace, r.name),
        json.int,
        extract_error,
      )
    "push" ->
      map_both(
        queue.push(ctx.client, r.namespace, r.name, r.value),
        json.int,
        extract_error,
      )
    "pop" ->
      map_both(
        queue.pop(ctx.client, r.namespace, r.name),
        json.string,
        extract_error,
      )
    _ -> Error(json.string("Invalid action"))
  }
}

pub fn queue_route(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Post)
  use json <- wisp.require_json(req)
  case decode_queue_request(json) {
    Ok(r) ->
      perform_request(ctx, r)
      |> result.unwrap_both
      |> construct_response("success")
    Error(_) -> json.string("Invalid request") |> construct_response("error")
  }
}
