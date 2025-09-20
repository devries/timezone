import gleam/int
import gleam/io
import gleam/string
import gleam/time/timestamp
import tzif/database
import tzif/tzcalendar

pub fn main() {
  let now = timestamp.system_time()

  // Load the database from the operating system
  let db = database.load_from_os()

  case tzcalendar.get_time_and_zone(now, "America/New_York", db) {
    Ok(time_and_zone) -> {
      // Successfully converted time to the requested time zone
      io.println(
        int.to_string(time_and_zone.time_of_day.hours)
        |> string.pad_start(2, "0")
        <> ":"
        <> int.to_string(time_and_zone.time_of_day.minutes)
        |> string.pad_start(2, "0")
        <> ":"
        <> int.to_string(time_and_zone.time_of_day.seconds)
        |> string.pad_start(2, "0")
        <> " "
        <> time_and_zone.designation,
      )
    }
    Error(database.ZoneNotFound) -> io.println("Time zone not found")
    Error(database.ProcessingError) ->
      io.println("Error processing time zone conversion")
  }
}
