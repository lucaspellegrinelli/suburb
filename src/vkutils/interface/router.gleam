import vkutils/interface/routes/flag
import vkutils/interface/routes/queue
import vkutils/interface/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["queue"] -> queue.queue_route(req, ctx)
    ["flag"] -> flag.flag_route(req, ctx)
    _ -> wisp.not_found()
  }
}
