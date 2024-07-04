import envoy
import gleam/io
import glint

pub fn remote_set() -> glint.Command(Nil) {
  use <- glint.command_help("Sets the remote server host and API key")
  use host <- glint.named_arg("remote host")
  use api_key <- glint.named_arg("remote api key")
  use named, _, _ <- glint.command()

  envoy.set("SUBURB_REMOTE_HOST", host(named))
  envoy.set("SUBURB_REMOTE_API_KEY", api_key(named))
}

pub fn remote_get() -> glint.Command(Nil) {
  use <- glint.command_help("Gets the remote server host and API key")
  use _, _, _ <- glint.command()

  let host = envoy.get("SUBURB_REMOTE_HOST")
  case host {
    Ok(host) -> io.println("Remote HOST:\t" <> host)
    _ -> io.println("Remote HOST:\tNot set")
  }
}
