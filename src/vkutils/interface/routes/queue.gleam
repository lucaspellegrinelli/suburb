import gleam/dynamic
import gleam/http
import gleam/json
import gleam/result
import vkutils/interface/utils.{construct_response, extract_error, map_both}
import vkutils/interface/web.{type Context}
import vkutils/services/queue
import wisp.{type Request, type Response}

pub fn queue_length_route(
  req: Request,
  ctx: Context,
  namespace: String,
  queue_name: String,
) -> Response {
  use <- wisp.require_method(req, http.Get)
  queue.length(ctx.client, namespace, queue_name)
  |> map_both(json.int, extract_error)
  |> result.unwrap_both
  |> construct_response("success")
}

pub fn queue_push_route(
  req: Request,
  ctx: Context,
  namespace: String,
  queue_name: String,
) -> Response {
  use <- wisp.require_method(req, http.Post)
  use json <- wisp.require_json(req)
  let value = json |> dynamic.field("value", dynamic.string)

  case value {
    Ok(value) -> {
      queue.push(ctx.client, namespace, queue_name, value)
      |> map_both(json.int, extract_error)
      |> result.unwrap_both
      |> construct_response("success")
    }
    Error(_) ->
      json.string("Couldn't parse value") |> construct_response("error")
  }
}

pub fn queue_pop_route(
  req: Request,
  ctx: Context,
  namespace: String,
  queue_name: String,
) -> Response {
  use <- wisp.require_method(req, http.Delete)
  queue.pop(ctx.client, namespace, queue_name)
  |> map_both(json.string, extract_error)
  |> result.unwrap_both
  |> construct_response("success")
}
