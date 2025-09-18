import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import timezone
import timezone/database

pub fn temporary_test() {
  let db = database.load_from_os()
  let zone_names = database.get_available_timezones(db)

  let now = timestamp.system_time()

  zone_names
  |> list.map(fn(zname) {
    case timezone.get_time_in_zone_tzdb(now, zname, db) {
      Ok(tiz) ->
        io.println(string.pad_end(zname <> ":", 40, " ") <> format_time(tiz))
      Error(_) -> io.println(string.pad_end(zname <> ":", 40, " ") <> "ERROR")
    }
  })
}

fn format_time(tiz: timezone.TimeInZone) -> String {
  int.to_string(tiz.date.year)
  <> "-"
  <> int.to_string(tiz.date.month |> calendar.month_to_int)
  |> string.pad_start(2, "0")
  <> "-"
  <> int.to_string(tiz.date.day) |> string.pad_start(2, "0")
  <> "   "
  <> int.to_string(tiz.time_of_day.hours) |> string.pad_start(2, "0")
  <> ":"
  <> int.to_string(tiz.time_of_day.minutes) |> string.pad_start(2, "0")
  <> ":"
  <> int.to_string(tiz.time_of_day.seconds) |> string.pad_start(2, "0")
  <> " "
  <> tiz.designation
}
