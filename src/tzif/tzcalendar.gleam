//// This module is for working with time zones and converting timestamps
//// from the `gleam/time` library into dates and times of day in a
//// time zone.
////
//// This library makes use of the [IANA tz database](https://www.iana.org/time-zones)
//// which is generally already installed on computers.
//// This library will search for timezone data in the TZif or [tzfile](https://www.man7.org/linux/man-pages/man5/tzfile.5.html)
//// file format. These are generally located in the `/usr/share/zoneinfo`
//// directory on posix systems, however if they are installed elsewhere the
//// then they can be loaded ysung the full path of the directory
//// containing the tz database files.
////
//// Time zone identifiers are generally of the form "Continent/City" for example
//// `America/New_York`, `Europe/Amsterdam`, or `Asia/Tokyo`. A list of time zone
//// identifiers is in the [list of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
//// article on Wikipedia. The time zone identifiers are passed to many of the
//// functions of this library as the `zone_name` parameter.

import gleam/list
import gleam/result
import gleam/time/calendar.{type Date, type TimeOfDay}
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import tzif/database.{type TzDatabase, type TzDatabaseError}

/// Representation of a date and time of day in a particular time zone
/// along with the offset from UTC, the zone designation (i.e. "UTC",
/// "EST", "CEDT") and a boolean indicating if it is daylight savings
/// time.
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
/// let assert Ok(db) = database.load_from_os()
/// 
/// to_time_and_zone(ts, "America/New_York", db)
/// // Ok(TimeInZone(
/// //   Date(2025, September, 18),
/// //   TimeOfDay(15, 21, 40, 0),
/// //   Duration(-14_400, 0),
/// //   "EDT",
/// //   True,
/// // ))
/// ```
pub fn to_time_and_zone(
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
/// let assert Ok(db) = database.load_from_os()
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
  use tiz <- result.map(to_time_and_zone(ts, zone_name, db))

  #(tiz.date, tiz.time_of_day)
}

/// Create a list of timestamps from a calendar date and time. This may produce zero, one
/// or two timestamps in a list depending on if that time is possible in the given
/// time zone or if it is ambiguous. This tends to happen every daylight saving
/// period. When moving forward one hour, the calendar times during the skipped hour
/// are not possible, so no timestamp values would be returned. When moving back
/// one hour the overlap period is repeated, yielding two timestamps per wall clock time.
///
/// This
/// returns a `TzDatabaseError` if there is an issue finding time zone information.
pub fn from_calendar(
  date: Date,
  time: TimeOfDay,
  zone_name: String,
  db: TzDatabase,
) -> Result(List(Timestamp), database.TzDatabaseError) {
  // Assume no shift will be more than 24 hours
  let ts_utc = timestamp.from_calendar(date, time, duration.seconds(0))

  // What are the offsets at +/- the 24 hour window
  use before_zone <- result.try(
    timestamp.add(ts_utc, duration.hours(-24))
    |> database.get_zone_parameters(zone_name, db),
  )
  use after_zone <- result.try(
    timestamp.add(ts_utc, duration.hours(24))
    |> database.get_zone_parameters(zone_name, db),
  )

  case before_zone.offset == after_zone.offset {
    True -> {
      // No time shift in the period of interest. Easy conversion.
      Ok([timestamp.from_calendar(date, time, before_zone.offset)])
    }
    False -> {
      // Check that we get the same UTC offset if we convert the date and
      // time to a timestamp using that offset and then find the offset
      // of the time zone at that timestamp. This is a round trip from utc
      // offset back to utc offset which should yield the same value if the utc
      // offset we use is correct for the time zone at that time and date.
      [before_zone.offset, after_zone.offset]
      |> list.filter(fn(offset) {
        let zone =
          timestamp.from_calendar(date, time, offset)
          |> database.get_zone_parameters(zone_name, db)
        case zone {
          Ok(database.ZoneParameters(round_trip_offset, _, _)) ->
            offset == round_trip_offset
          Error(_) -> False
        }
      })
      |> list.map(fn(offset) { timestamp.from_calendar(date, time, offset) })
      |> Ok
    }
  }
}

/// The actual difference between two timestamps. This includes intervening
/// leap seconds into the calculation. A time zone which includes leap seconds
/// should be given for the zone name. We recommend using "right/UTC" if it is
/// installed on your system.
pub fn atomic_difference(
  left: Timestamp,
  right: Timestamp,
  zone_name: String,
  db: TzDatabase,
) -> Result(Duration, database.TzDatabaseError) {
  let standard_difference = timestamp.difference(left, right)

  use right_ls <- result.try(database.leap_seconds(right, zone_name, db))
  use left_ls <- result.map(database.leap_seconds(left, zone_name, db))

  duration.add(standard_difference, duration.seconds(right_ls - left_ls))
}
