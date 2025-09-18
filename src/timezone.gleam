//// This module is for working with time zones and converting timestamps
//// from the `gleam/time` library into dates and times of day in a
//// timezone.
////
//// This library makes use of the [IANA tz database](https://www.iana.org/time-zones)
//// which is generally already installed on computers.
//// This library will search for timezone data in the [tzfile](https://www.man7.org/linux/man-pages/man5/tzfile.5.html)
//// file format. These are generally located in the `/usr/share/zoneinfo`
//// directory on posix systems, however if they are installed elsewhere the
//// ZONEINFO environment variable can be set to the full path of the directory
//// containing the tz database files.
////
//// Time zone identifiers are generally of the form "Continent/City" for example
//// `America/New_York`, `Europe/Amsterdam`, or `Asia/Tokyo`. A list of time zone
//// identifiers is in the [list of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
//// article on Wikipedia. The time zone identifiers are passed to many of the
//// functions of this library as the `zone_name` parameter.

import gleam/result
import gleam/time/calendar.{type Date, type TimeOfDay}
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import timezone/database

/// Time Zone error type
/// This needs review and change as we split things up
pub type TimeZoneError {
  /// Error parsing timezone data
  ParseError

  /// Error constructing time zone transition table.
  TimeSliceError

  /// Other error in the Zone file
  ZoneFileError
}

/// Representation of time in a time zone
pub type TimeInZone {
  TimeInZone(
    date: Date,
    time_of_day: TimeOfDay,
    offset: Duration,
    designation: String,
    is_dst: Bool,
  )
}

/// Potentially new API for time_in_zone
pub fn get_time_in_zone_tzdb(
  ts: Timestamp,
  zone_name: String,
  db: database.TzDatabase,
) -> Result(TimeInZone, TimeZoneError) {
  use zone_parameters <- result.map(
    database.get_zone_parameters(ts, zone_name, db)
    |> result.replace_error(ParseError),
  )

  let #(dt, tm) = timestamp.to_calendar(ts, zone_parameters.offset)

  TimeInZone(
    dt,
    tm,
    zone_parameters.offset,
    zone_parameters.designation,
    zone_parameters.is_dst,
  )
}
