import gleam/int
import gleam/io
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import timezone

pub fn main() -> Result(Nil, timezone.TimeZoneError) {
  let now = timestamp.system_time()

  use new_york <- result.try(timezone.get_time_in_zone(now, "America/New_York"))
  use vevay <- result.try(timezone.get_time_in_zone(
    now,
    "America/Indiana/Vevay",
  ))
  use utc <- result.try(timezone.get_time_in_zone(now, "UTC"))
  use phoenix <- result.try(timezone.get_time_in_zone(now, "America/Phoenix"))
  use amsterdam <- result.try(timezone.get_time_in_zone(now, "Europe/Amsterdam"))
  use london <- result.try(timezone.get_time_in_zone(now, "Europe/London"))
  use tokyo <- result.try(timezone.get_time_in_zone(now, "Asia/Tokyo"))
  use auckland <- result.try(timezone.get_time_in_zone(now, "Pacific/Auckland"))
  use cairo <- result.try(timezone.get_time_in_zone(now, "Africa/Cairo"))
  use calcutta <- result.try(timezone.get_time_in_zone(now, "Asia/Calcutta"))

  io.println("UTC:       " <> format_time(utc))
  io.println("New York:  " <> format_time(new_york))
  io.println("Vevay:     " <> format_time(vevay))
  io.println("Phoenix:   " <> format_time(phoenix))
  io.println("Amsterdam: " <> format_time(amsterdam))
  io.println("London:    " <> format_time(london))
  io.println("Tokyo:     " <> format_time(tokyo))
  io.println("Auckland:  " <> format_time(auckland))
  io.println("Cairo:     " <> format_time(cairo))
  io.println("Calcutta:  " <> format_time(calcutta))
  io.println("")
  io.println("RFC3339:")
  io.println("UTC:       " <> timestamp.to_rfc3339(now, utc.offset))
  io.println("New York:  " <> timestamp.to_rfc3339(now, new_york.offset))
  io.println("Vevay:     " <> timestamp.to_rfc3339(now, vevay.offset))
  io.println("Phoenix:   " <> timestamp.to_rfc3339(now, phoenix.offset))
  io.println("Amsterdam: " <> timestamp.to_rfc3339(now, amsterdam.offset))
  io.println("London:    " <> timestamp.to_rfc3339(now, london.offset))
  io.println("Tokyo:     " <> timestamp.to_rfc3339(now, tokyo.offset))
  io.println("Auckland:  " <> timestamp.to_rfc3339(now, auckland.offset))
  io.println("Cairo:     " <> timestamp.to_rfc3339(now, cairo.offset))
  io.println("Calcutta:  " <> timestamp.to_rfc3339(now, calcutta.offset))
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
