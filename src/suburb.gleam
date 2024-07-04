import argv
import glint
import suburb/cli/host
import suburb/cli/queue
import suburb/cli/remote

pub fn main() {
  glint.new()
  |> glint.with_name("suburb")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: ["host"], do: host.host())
  |> glint.add(at: ["remote", "set"], do: remote.remote_set())
  |> glint.add(at: ["remote", "get"], do: remote.remote_get())
  |> glint.add(at: ["queue", "list"], do: queue.queue_list())
  |> glint.add(at: ["queue", "length"], do: queue.queue_length())
  |> glint.add(at: ["queue", "push"], do: queue.queue_push())
  |> glint.add(at: ["queue", "pop"], do: queue.queue_pop())
  |> glint.run(argv.load().arguments)
}
