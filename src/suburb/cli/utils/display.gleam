import gleam/io
import gleam/list
import gleam/string
import term_size

fn print_row(row: List(String), col_sizes: List(Int)) {
  let assert Ok(cols) = term_size.columns()
  let row =
    list.zip(row, col_sizes)
    |> list.map(fn(i) {
      let #(value, size) = i
      let value =
        value
        |> string.replace("\n", "")
        |> string.replace("\t", "")
      case string.length(value) < size {
        True -> string.pad_right(value, to: size, with: " ")
        False -> string.drop_right(value, string.length(value) - size)
      }
    })

  let row = string.join(row, "")
  let row_size = string.length(row)
  let drop_count = row_size - cols
  let row = string.drop_right(row, drop_count)
  io.println(row)
}

pub fn print_table(
  col_names: List(String),
  values: List(List(String)),
  col_sizes: List(Int),
) {
  print_row(col_names, col_sizes)
  list.each(values, print_row(_, col_sizes))
}
