import gleam/dynamic
import gleam/json
import suburb/types.{type FeatureFlag, FeatureFlag}

pub fn decoder(content: dynamic.Dynamic) {
  content
  |> dynamic.decode3(
    FeatureFlag,
    dynamic.field("namespace", dynamic.string),
    dynamic.field("flag", dynamic.string),
    dynamic.field("value", dynamic.bool),
  )
}

pub fn encoder(flag: FeatureFlag) {
  json.object([
    #("namespace", json.string(flag.namespace)),
    #("flag", json.string(flag.flag)),
    #("value", json.bool(flag.value)),
  ])
}

pub fn str_to_bool(v: dynamic.Dynamic) {
  case dynamic.string(v) {
    Ok("True") -> Ok(True)
    Ok(_) -> Ok(False)
    Error(e) -> Error(e)
  }
}
