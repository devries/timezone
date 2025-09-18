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

import envoy
import filepath
import gleam/dict
import gleam/list
import gleam/result
import gleam/time/calendar.{type Date, type TimeOfDay}
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import simplifile
import timezone/database
import timezone/internal

/// Time Zone error type
pub type TimeZoneError {
  ParseError
  TimeSliceError
  ZoneFileError
}

/// Timezone definition slice
type TTSlice {
  TTSlice(start_time: Int, utoff: Duration, isdst: Bool, designation: String)
}

/// Representation of time in a time zone
pub type TimeInZone {
  TimeInZone(
    date: Date,
    time_of_day: TimeOfDay,
    offset: duration.Duration,
    designation: String,
    is_dst: Bool,
  )
}

/// Get the full path to the zoneinfo file for that
/// time zone. Use IANA time zone identifiers such as
/// "America/New_York".
pub fn tzfile_path(name: String) -> String {
  let root = case envoy.get("ZONEINFO") {
    Ok(dir) -> dir
    _ -> "/usr/share/zoneinfo"
  }

  filepath.join(root, name)
}

/// Given a timestamp and a zone name, get the time in that time zone.
/// The zone_name should be an IANA identifier like "America/New_York".
pub fn get_time_in_zone(
  ts: Timestamp,
  zone_name: String,
) -> Result(TimeInZone, TimeZoneError) {
  // Parse the datafile
  use tzdata <- result.try(
    tzfile_path(zone_name)
    |> simplifile.read_bits
    |> result.replace_error(ZoneFileError),
  )
  get_time_with_tzdata(ts, tzdata)
}

/// Given a timestamp and the binary contents of a tzfile, get the time in
/// that time zone.
pub fn get_time_with_tzdata(
  ts: Timestamp,
  tzdata: BitArray,
) -> Result(TimeInZone, TimeZoneError) {
  use tz <- result.try(
    internal.parse(tzdata) |> result.replace_error(ParseError),
  )

  // Pull out the TTSlice representing the timezone at that timestamp
  use slice_of_interest <- result.map(
    get_slice(ts, create_slices(tz.fields), default_slice(tz.fields))
    |> result.replace_error(TimeSliceError),
  )
  let #(dt, tm) = timestamp.to_calendar(ts, slice_of_interest.utoff)

  TimeInZone(
    dt,
    tm,
    slice_of_interest.utoff,
    slice_of_interest.designation,
    slice_of_interest.isdst,
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

/// Convert a timestamp to a calendar date and time of day for a
/// given time zone.
pub fn to_calendar(
  ts: Timestamp,
  zone_name: String,
) -> Result(#(calendar.Date, calendar.TimeOfDay), TimeZoneError) {
  use time_in_zone <- result.map(get_time_in_zone(ts, zone_name))

  #(time_in_zone.date, time_in_zone.time_of_day)
}

/// Get the offset for a time zone at a particular moment in time.
pub fn zone_offset(
  ts: Timestamp,
  zone_name: String,
) -> Result(duration.Duration, TimeZoneError) {
  use time_in_zone <- result.map(get_time_in_zone(ts, zone_name))

  time_in_zone.offset
}

/// Get zone designation (e.g. "EST", "CEST", "JST").
pub fn zone_designation(
  ts: Timestamp,
  zone_name: String,
) -> Result(String, TimeZoneError) {
  use time_in_zone <- result.map(get_time_in_zone(ts, zone_name))

  time_in_zone.designation
}

// Turn time zone fields into a list of timezone information slices
fn create_slices(fields: internal.TimeZoneFields) -> List(TTSlice) {
  let infos =
    list.zip(fields.ttinfos, fields.designations)
    |> list.index_map(fn(tup, idx) { #(idx, tup) })
    |> dict.from_list

  list.zip(fields.transition_times, fields.time_types)
  |> list.map(fn(tup) {
    let info_tuple = dict.get(infos, tup.1)
    case info_tuple {
      Ok(#(ttinfo, designation)) -> {
        let isdst = case ttinfo.isdst {
          0 -> False
          _ -> True
        }
        Ok(TTSlice(tup.0, duration.seconds(ttinfo.utoff), isdst, designation))
      }
      _ -> Error(Nil)
    }
  })
  |> result.values
}

fn default_slice(fields: internal.TimeZoneFields) -> Result(TTSlice, Nil) {
  use ttinfo <- result.try(list.first(fields.ttinfos))
  use designation <- result.try(list.first(fields.designations))
  let isdst = case ttinfo.isdst {
    0 -> False
    _ -> True
  }

  Ok(TTSlice(0, duration.seconds(ttinfo.utoff), isdst, designation))
}

fn get_slice(
  ts: timestamp.Timestamp,
  slices: List(TTSlice),
  default: Result(TTSlice, Nil),
) -> Result(TTSlice, Nil) {
  let #(seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(ts)

  slices
  |> list.fold_until(default, fn(acc, slice) {
    case slice.start_time < seconds {
      True -> list.Continue(Ok(slice))
      False -> list.Stop(acc)
    }
  })
}
