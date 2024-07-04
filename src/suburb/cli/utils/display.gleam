import gleam/io
import gleam/list

pub fn display_list(name: String, items: List(String)) {
  [name, ..items] |> list.each(io.println)
}
