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
import tzif/database.{type TzDatabase, type TzDatabaseError}

/// Representation of time in a time zone
pub type TimeAndZone {
  TimeAndZone(
    date: Date,
    time_of_day: TimeOfDay,
    offset: Duration,
    designation: String,
    is_dst: Bool,
  )
}

/// Given a timestamp, IANA time zone name, and a `TzDatabase` record,
/// get the date and time of the timestamp along with information about
/// the timezone, such as its offset from UTC, designation, and if it
/// is daylight savings time in that zone.
///
/// # Example
///
/// ```gleam
/// import gleam/time/timestamp
/// import tzif/database
///
/// let ts = timestamp.from_unix_seconds(1_758_223_300)
/// let db = database.load_from_os()
/// 
/// get_time_and_zone(ts, "America/New_York", db)
/// // Ok(TimeInZone(
/// //   Date(2025, September, 18),
/// //   TimeOfDay(15, 21, 40, 0),
/// //   Duration(-14_400, 0),
/// //   "EDT",
/// //   True,
/// // ))
/// ```
pub fn get_time_and_zone(
  ts: Timestamp,
  zone_name: String,
  db: TzDatabase,
) -> Result(TimeAndZone, TzDatabaseError) {
  use zone_parameters <- result.map(database.get_zone_parameters(
    ts,
    zone_name,
    db,
  ))

  let #(dt, tm) = timestamp.to_calendar(ts, zone_parameters.offset)

  TimeAndZone(
    dt,
    tm,
    zone_parameters.offset,
    zone_parameters.designation,
    zone_parameters.is_dst,
  )
}

/// Given a timestamp, IANA time zone name, and a `TzDatabase` record,
/// get the date and time of day as a tuple in the format of the
/// `gleam/time/timestamp.to_calendar` function.
/// 
/// # Example
///
/// ```gleam
/// import gleam/time/timestamp
/// import tzif/database
///
/// let ts = timestamp.from_unix_seconds(1_758_223_300)
/// let db = database.load_from_os()
/// 
/// to_calendar(ts, "America/New_York", db)
/// // Ok(#(
/// //   Date(2025, September, 18),
/// //   TimeOfDay(15, 21, 40, 0),
/// // ))
pub fn to_calendar(
  ts: Timestamp,
  zone_name: String,
  db: TzDatabase,
) -> Result(#(calendar.Date, calendar.TimeOfDay), TzDatabaseError) {
  use tiz <- result.map(get_time_and_zone(ts, zone_name, db))

  #(tiz.date, tiz.time_of_day)
}
