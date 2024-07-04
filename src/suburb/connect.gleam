import envoy
import gleam/result

pub fn remote_connection() {
  use host <- result.try(envoy.get("SUBURB_REMOTE_HOST"))
  use api_key <- result.try(envoy.get("SUBURB_REMOTE_API_KEY"))
  Ok(#(host, api_key))
}
