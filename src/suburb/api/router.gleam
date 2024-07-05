import gleam/http.{Delete, Get, Post}
import suburb/api/routes/flag
import suburb/api/routes/log
import suburb/api/routes/queue
import suburb/api/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req), req.method {
    ["queue", ns, "list"], Get -> queue.list_route(req, ctx, ns)
    ["queue", ns, "create"], Post -> queue.create_route(req, ctx, ns)
    ["queue", ns, name], Get -> queue.peek_route(req, ctx, ns, name)
    ["queue", ns, name], Post -> queue.push_route(req, ctx, ns, name)
    ["queue", ns, name], Delete -> queue.pop_route(req, ctx, ns, name)
    ["queue", ns, name, "length"], Get -> queue.length_route(req, ctx, ns, name)
    ["queue", ns, name, "delete"], Delete ->
      queue.delete_route(req, ctx, ns, name)

    ["flag", ns, "list"], Get -> flag.list_route(req, ctx, ns)
    ["flag", ns, name], Get -> flag.get_route(req, ctx, ns, name)
    ["flag", ns, name], Post -> flag.set_route(req, ctx, ns, name)
    ["flag", ns, name], Delete -> flag.delete_route(req, ctx, ns, name)

    ["log"], Get -> log.list_route(req, ctx)
    ["log", ns], Post -> log.add_route(req, ctx, ns)
    _, _ -> wisp.not_found()
  }
}
