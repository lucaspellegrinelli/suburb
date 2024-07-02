import gleam/erlang/process
import radish
import wisp

pub type Context {
  Context(client: process.Subject(radish.Message), api_secret: String)
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)

  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}
