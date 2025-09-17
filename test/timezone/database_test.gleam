import gleam/io
import gleam/list
import timezone/database

pub fn temporary_test() {
  let db = database.load_from_os()
  database.get_available_timezones(db)
  |> list.map(fn(name) { io.println(name) })
}
