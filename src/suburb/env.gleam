import gleam/dynamic
import gleam/json
import simplifile

const config_folder = "/Users/lucasmachado/.suburb"

const config_file = "config"

const default_host = "http://localhost:8080"

const default_token = "yoursecrettoken"

pub type EnvVars {
  EnvVars(host: String, token: String)
}

fn config_path() {
  config_folder <> "/" <> config_file
}

pub fn get_env_variables() {
  case simplifile.is_file(config_path()) {
    Ok(True) -> read_env_variables()
    Ok(False) -> write_env_variables(EnvVars(default_host, default_token))
    Error(e) -> Error(simplifile.describe_error(e))
  }
}

fn read_env_variables() {
  case simplifile.read(config_path()) {
    Ok(config_str) -> {
      let decoded_config =
        config_str
        |> json.decode(dynamic.decode2(
          EnvVars,
          dynamic.field("host", dynamic.string),
          dynamic.field("token", dynamic.string),
        ))

      case decoded_config {
        Ok(env_vars) -> Ok(env_vars)
        _ -> Error("Could not decode config file")
      }
    }
    Error(e) -> Error(simplifile.describe_error(e))
  }
}

pub fn write_env_variables(env_vars: EnvVars) {
  let config =
    json.object([
      #("host", json.string(env_vars.host)),
      #("token", json.string(env_vars.token)),
    ])
    |> json.to_string

  case simplifile.create_directory(config_folder) {
    _ ->
      case simplifile.is_directory(config_folder) {
        Ok(True) ->
          case simplifile.write(config_path(), config) {
            Ok(_) -> Ok(env_vars)
            Error(e) -> Error(simplifile.describe_error(e))
          }
        Ok(False) -> Error("Could not create config folder")
        Error(e) -> Error(simplifile.describe_error(e))
      }
  }
}
