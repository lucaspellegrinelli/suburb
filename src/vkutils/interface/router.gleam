import gleam/http.{Delete, Get, Post}
import vkutils/interface/routes/flag
import vkutils/interface/routes/queue
import vkutils/interface/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req), req.method {
    ["queue", ns, n, "length"], Get -> queue.queue_length_route(req, ctx, ns, n)
    ["queue", ns, n], Post -> queue.queue_push_route(req, ctx, ns, n)
    ["queue", ns, n], Delete -> queue.queue_pop_route(req, ctx, ns, n)
    ["flag", ns, n], Get -> flag.flag_get_route(req, ctx, ns, n)
    ["flag", ns, n], Post -> flag.flag_set_route(req, ctx, ns, n)
    ["flag", ns, n], Delete -> flag.flag_delete_route(req, ctx, ns, n)
    _, _ -> wisp.not_found()
  }
}
