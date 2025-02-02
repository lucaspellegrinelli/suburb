import gleam/dynamic
import gleam/http
import gleam/json
import gleam/list
import suburb/api/utils.{construct_response, extract_error}
import suburb/api/web.{type Context}
import suburb/coders/queue as queue_coder
import suburb/services/queue.{QueueName}
import suburb/types.{EmptyQueue}
import wisp.{type Request, type Response}

pub fn length_route(
  req: Request,
  ctx: Context,
  namespace: String,
  queue: String,
) -> Response {
  use <- wisp.require_method(req, http.Get)
  case queue.length(ctx.conn, namespace, queue) {
    Ok(length) -> length |> json.int |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn push_route(
  req: Request,
  ctx: Context,
  namespace: String,
  queue: String,
) -> Response {
  use <- wisp.require_method(req, http.Post)
  use json <- wisp.require_json(req)
  let message = json |> dynamic.field("message", dynamic.string)

  case message {
    Ok(msg) -> {
      case queue.push(ctx.conn, namespace, queue, msg) {
        Ok(v) -> v |> json.string |> construct_response("success", 200)
        Error(e) -> e |> extract_error |> construct_response("error", 404)
      }
    }
    Error(_) ->
      json.string("Couldn't parse value") |> construct_response("error", 400)
  }
}

pub fn pop_route(
  req: Request,
  ctx: Context,
  namespace: String,
  queue: String,
) -> Response {
  use <- wisp.require_method(req, http.Post)
  case queue.pop(ctx.conn, namespace, queue) {
    Ok(value) -> value |> json.string |> construct_response("success", 200)
    Error(EmptyQueue(e)) -> e |> json.string |> construct_response("error", 204)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn list_route(req: Request, ctx: Context, namespace: String) -> Response {
  use <- wisp.require_method(req, http.Get)
  let query_params = wisp.get_query(req)

  let filters =
    list.filter_map(query_params, fn(param) {
      let #(key, value) = param
      case key {
        "queue" -> Ok(QueueName(value))
        _ -> Error(Nil)
      }
    })

  case queue.list(ctx.conn, namespace, filters) {
    Ok(values) ->
      json.array(values, fn(log) {
        json.object([#("queue", json.string(log.queue))])
      })
      |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn create_route(req: Request, ctx: Context, namespace: String) -> Response {
  use <- wisp.require_method(req, http.Post)
  use json <- wisp.require_json(req)
  let queue = json |> dynamic.field("queue", dynamic.string)

  case queue {
    Ok(q) -> {
      case queue.create(ctx.conn, namespace, q) {
        Ok(v) -> v |> queue_coder.encoder |> construct_response("success", 200)
        Error(e) -> e |> extract_error |> construct_response("error", 404)
      }
    }
    Error(_) ->
      json.string("Couldn't parse queue") |> construct_response("error", 400)
  }
}

pub fn peek_route(
  req: Request,
  ctx: Context,
  namespace: String,
  queue: String,
) -> Response {
  use <- wisp.require_method(req, http.Get)
  case queue.peek(ctx.conn, namespace, queue) {
    Ok(value) -> value |> json.string |> construct_response("success", 200)
    Error(EmptyQueue(e)) -> e |> json.string |> construct_response("error", 204)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn delete_route(
  req: Request,
  ctx: Context,
  namespace: String,
  queue: String,
) -> Response {
  use <- wisp.require_method(req, http.Delete)
  case queue.delete(ctx.conn, namespace, queue) {
    Ok(_) ->
      { "Queue " <> queue <> " deleted." }
      |> json.string
      |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}
