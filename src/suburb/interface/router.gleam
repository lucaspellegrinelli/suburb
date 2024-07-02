import gleam/http.{Delete, Get, Post}
import suburb/interface/routes/flag
import suburb/interface/routes/queue
import suburb/interface/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req), req.method {
    ["queue", ns, name, "length"], Get -> queue.length_route(req, ctx, ns, name)
    ["queue", ns, name], Post -> queue.push_route(req, ctx, ns, name)
    ["queue", ns, name], Delete -> queue.pop_route(req, ctx, ns, name)
    ["flag", ns, name], Get -> flag.get_route(req, ctx, ns, name)
    ["flag", ns, name], Post -> flag.set_route(req, ctx, ns, name)
    ["flag", ns, name], Delete -> flag.delete_route(req, ctx, ns, name)
    _, _ -> wisp.not_found()
  }
}
