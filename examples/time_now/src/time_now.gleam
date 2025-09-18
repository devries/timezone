import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import timezone
import timezone/database

pub fn main() {
  let now = timestamp.system_time()
  case print_all_times(now) {
    Ok(_) -> Nil
    Error(_) -> io.println("Encountered an error while running")
  }
}

fn print_all_times(
  now: timestamp.Timestamp,
) -> Result(Nil, timezone.TimeZoneError) {
  let db = database.load_from_os()

  database.get_available_timezones(db)
  |> list.map(fn(zone_name) {
    case timezone.get_time_in_zone_tzdb(now, zone_name, db) {
      Ok(tiz) ->
        io.println(
          string.pad_end(zone_name <> ":", 40, " ") <> format_time(tiz),
        )
      Error(_) ->
        io.println(string.pad_end(zone_name <> ":", 40, " ") <> "ERROR")
    }
  })
  Ok(Nil)
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
