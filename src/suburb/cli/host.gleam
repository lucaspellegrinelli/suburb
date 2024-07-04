import glint
import suburb/api/host

pub fn host() -> glint.Command(Nil) {
  use <- glint.command_help("Hosts the Suburb server")
  use _, _, _ <- glint.command()
  host.serve()
}
