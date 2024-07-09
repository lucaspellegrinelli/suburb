import argv
import glint
import suburb/cli/config
import suburb/cli/flag
import suburb/cli/host
import suburb/cli/log
import suburb/cli/queue

pub fn main() {
  glint.new()
  |> glint.with_name("suburb")
  |> glint.pretty_help(glint.default_pretty_help())
  // Hosting the webserver
  |> glint.add(at: ["host"], do: host.host())
  // Configurations
  |> glint.add(at: ["config"], do: config.handle())
  // Queue operations
  |> glint.add(at: ["queue"], do: queue.list())
  |> glint.add(at: ["queue", "new"], do: queue.create())
  |> glint.add(at: ["queue", "push"], do: queue.push())
  |> glint.add(at: ["queue", "pop"], do: queue.pop())
  |> glint.add(at: ["queue", "peek"], do: queue.peek())
  |> glint.add(at: ["queue", "delete"], do: queue.delete())
  |> glint.add(at: ["queue", "length"], do: queue.length())
  // Flag operations
  |> glint.add(at: ["flag"], do: flag.list())
  |> glint.add(at: ["flag", "get"], do: flag.get())
  |> glint.add(at: ["flag", "enable"], do: flag.set(True))
  |> glint.add(at: ["flag", "disable"], do: flag.set(False))
  |> glint.add(at: ["flag", "delete"], do: flag.delete())
  // Logging operations
  |> glint.add(at: ["logs"], do: log.list())
  |> glint.run(argv.load().arguments)
}
