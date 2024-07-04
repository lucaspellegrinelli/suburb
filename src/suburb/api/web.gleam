import gleam/bool
import gleam/dict
import gleam/erlang/process
import gleam/json
import sqlight
import wisp

pub type Context {
  Context(conn: sqlight.Connection, api_secret: String)
}

fn unauthorized() {
  json.object([#("error", json.string("unauthorized"))])
  |> json.to_string_builder
  |> wisp.json_response(401)
}

fn authenticate(req: wisp.Request, ctx: Context, cb: fn() -> wisp.Response) {
  let header_list = dict.from_list(req.headers)
  case dict.get(header_list, "authorization") {
    Ok(token) -> {
      use <- bool.guard(token != ctx.api_secret, unauthorized())
      cb()
    }
    _ -> {
      unauthorized()
    }
  }
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  use <- authenticate(req, ctx)
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  handle_request(req)
}
