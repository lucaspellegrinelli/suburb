import argv
import glint
import suburb/cli/flag
import suburb/cli/host
import suburb/cli/log
import suburb/cli/queue
import suburb/cli/remote

pub fn main() {
  glint.new()
  |> glint.with_name("suburb")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: ["host"], do: host.host())
  |> glint.add(at: ["remote", "set"], do: remote.set())
  |> glint.add(at: ["remote", "get"], do: remote.get())
  |> glint.add(at: ["queue", "create"], do: queue.create())
  |> glint.add(at: ["queue", "list"], do: queue.list())
  |> glint.add(at: ["queue", "length"], do: queue.length())
  |> glint.add(at: ["queue", "push"], do: queue.push())
  |> glint.add(at: ["queue", "pop"], do: queue.pop())
  |> glint.add(at: ["queue", "peek"], do: queue.peek())
  |> glint.add(at: ["flag", "set"], do: flag.set())
  |> glint.add(at: ["flag", "get"], do: flag.get())
  |> glint.add(at: ["flag", "delete"], do: flag.delete())
  |> glint.add(at: ["flag", "list"], do: flag.list())
  |> glint.add(at: ["log", "list"], do: log.list())
  |> glint.run(argv.load().arguments)
}
