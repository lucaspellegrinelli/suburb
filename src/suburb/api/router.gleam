import gleam/http.{Delete, Get, Post}
import suburb/api/routes/flag
import suburb/api/routes/log
import suburb/api/routes/pubsub
import suburb/api/routes/queue
import suburb/api/web.{type Context}
import suburb/api/websocket.{type Broadcaster}
import wisp.{type Request, type Response}

pub fn handle_request(
  req: Request,
  ctx: Context,
  broadcaster: Broadcaster,
) -> Response {
  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req), req.method {
    ["queues"], Get -> queue.list_route(req, ctx)
    ["queues"], Post -> queue.create_route(req, ctx)
    ["queues", ns, name], Post -> queue.push_route(req, ctx, ns, name)
    ["queues", ns, name], Delete -> queue.delete_route(req, ctx, ns, name)
    ["queues", ns, name, "peek"], Get -> queue.peek_route(req, ctx, ns, name)
    ["queues", ns, name, "pop"], Post -> queue.pop_route(req, ctx, ns, name)
    ["queues", ns, name, "length"], Get ->
      queue.length_route(req, ctx, ns, name)

    ["flags"], Get -> flag.list_route(req, ctx)
    ["flags", ns, name], Get -> flag.get_route(req, ctx, ns, name)
    ["flags", ns, name], Post -> flag.set_route(req, ctx, ns, name)
    ["flags", ns, name], Delete -> flag.delete_route(req, ctx, ns, name)

    ["logs"], Get -> log.list_route(req, ctx)
    ["logs", ns], Post -> log.add_route(req, ctx, ns)

    ["pubsub", channel, "publish"], Post ->
      pubsub.publish_route(req, channel, broadcaster)
    _, _ -> wisp.not_found()
  }
}
