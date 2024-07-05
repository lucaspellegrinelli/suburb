import gleam/dynamic
import gleam/http
import gleam/json
import suburb/api/utils.{construct_response, extract_error}
import suburb/api/web.{type Context}
import suburb/services/queue
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
  let value = json |> dynamic.field("value", dynamic.string)

  case value {
    Ok(value) -> {
      case queue.push(ctx.conn, namespace, queue, value) {
        Ok(_) -> "pushed" |> json.string |> construct_response("success", 200)
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
  use <- wisp.require_method(req, http.Delete)
  case queue.pop(ctx.conn, namespace, queue) {
    Ok(value) -> value |> json.string |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn list_route(req: Request, ctx: Context, namespace: String) -> Response {
  use <- wisp.require_method(req, http.Get)
  case queue.list(ctx.conn, namespace) {
    Ok(values) ->
      values
      |> json.array(of: json.string)
      |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn create_route(req: Request, ctx: Context, namespace: String) -> Response {
  use <- wisp.require_method(req, http.Post)
  use json <- wisp.require_json(req)
  let value = json |> dynamic.field("value", dynamic.string)

  case value {
    Ok(value) -> {
      case queue.create(ctx.conn, namespace, value) {
        Ok(_) -> "created" |> json.string |> construct_response("success", 200)
        Error(e) -> e |> extract_error |> construct_response("error", 404)
      }
    }
    Error(_) ->
      json.string("Couldn't parse value") |> construct_response("error", 400)
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
    Ok(_) -> "deleted" |> json.string |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}