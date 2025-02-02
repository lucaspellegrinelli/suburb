import gleam/dynamic
import gleam/http
import gleam/json
import gleam/list
import suburb/api/utils.{construct_response, extract_error}
import suburb/api/web.{type Context}
import suburb/coders/flag as flag_coder
import suburb/services/flag.{Flag}
import wisp.{type Request, type Response}

pub fn list_route(req: Request, ctx: Context, namespace: String) -> Response {
  use <- wisp.require_method(req, http.Get)
  let query_params = wisp.get_query(req)

  let filters =
    list.filter_map(query_params, fn(param) {
      let #(key, value) = param
      case key {
        "flag" -> Ok(Flag(value))
        _ -> Error(Nil)
      }
    })

  case flag.list(ctx.conn, namespace, filters) {
    Ok(values) ->
      json.array(values, fn(log) {
        json.object([
          #("flag", json.string(log.flag)),
          #("value", json.bool(log.value)),
        ])
      })
      |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn get_route(
  req: Request,
  ctx: Context,
  namespace: String,
  flag: String,
) -> Response {
  use <- wisp.require_method(req, http.Get)
  case flag.get(ctx.conn, namespace, flag) {
    Ok(value) ->
      value |> flag_coder.encoder |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}

pub fn set_route(
  req: Request,
  ctx: Context,
  namespace: String,
  flag: String,
) -> Response {
  use <- wisp.require_method(req, http.Post)
  use json <- wisp.require_json(req)
  let value = json |> dynamic.field("value", dynamic.bool)

  case value {
    Ok(value) ->
      case flag.set(ctx.conn, namespace, flag, value) {
        Ok(v) -> v |> flag_coder.encoder |> construct_response("success", 200)
        Error(e) -> e |> extract_error |> construct_response("error", 404)
      }
    Error(_) ->
      json.string("Couldn't parse value") |> construct_response("error", 400)
  }
}

pub fn delete_route(
  req: Request,
  ctx: Context,
  namespace: String,
  flag: String,
) -> Response {
  use <- wisp.require_method(req, http.Delete)
  case flag.delete(ctx.conn, namespace, flag) {
    Ok(_) ->
      { "Feature Flag " <> flag <> " has been deleted." }
      |> json.string
      |> construct_response("success", 200)
    Error(e) -> e |> extract_error |> construct_response("error", 404)
  }
}
