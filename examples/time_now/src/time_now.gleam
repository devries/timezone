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
  use phoenix <- result.try(timezone.get_time_in_zone(now, "America/Phoenix"))
  use amsterdam <- result.try(timezone.get_time_in_zone(now, "Europe/Amsterdam"))
  use london <- result.try(timezone.get_time_in_zone(now, "Europe/London"))
  use tokyo <- result.try(timezone.get_time_in_zone(now, "Asia/Tokyo"))
  use auckland <- result.try(timezone.get_time_in_zone(now, "Pacific/Auckland"))
  use cairo <- result.try(timezone.get_time_in_zone(now, "Africa/Cairo"))

  io.println("New York:  " <> format_time(new_york))
  io.println("Vevay:     " <> format_time(vevay))
  io.println("Phoenix:   " <> format_time(phoenix))
  io.println("Amsterdam: " <> format_time(amsterdam))
  io.println("London:    " <> format_time(london))
  io.println("Tokyo:     " <> format_time(tokyo))
  io.println("Auckland:  " <> format_time(auckland))
  io.println("Cairo:     " <> format_time(cairo))

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
  <> int.to_string(tiz.time_of_day.hours) |> string.pad_start(2, " ")
  <> ":"
  <> int.to_string(tiz.time_of_day.minutes) |> string.pad_start(2, "0")
  <> ":"
  <> int.to_string(tiz.time_of_day.seconds) |> string.pad_start(2, "0")
  <> " "
  <> tiz.designation
}
