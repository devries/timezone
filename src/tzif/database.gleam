//// These types and functions are designed to let you retrieve information
//// from TZif formatted data you provide, or timezone data loaded from the
//// operating system. 

import filepath
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import gleam/time/duration.{type Duration}
import gleam/time/timestamp
import simplifile
import tzif/parser

/// Time Zone Database record. This is typically created by
/// loading from the operating system with the `load_from_os`
/// function. This record stores all the data required to
/// get time zone information using the functions in this
/// package.
pub opaque type TzDatabase {
  TzDatabase(
    zone_names: List(String),
    zone_data: dict.Dict(String, parser.TzFile),
  )
}

/// TzDatabase error types
pub type TzDatabaseError {
  /// The zone was not found in the database
  ZoneNameNotFound
  /// Information, including UTC offset, zone designation, or leap
  /// second information was not found for this time zone.
  InfoNotFound
}

/// Load time zone database from default operating system location
/// which is typically "/usr/share/zoneinfo". If no parsable TZif
/// files were found, returns `Error(Nil)`.
pub fn load_from_os() -> Result(TzDatabase, Nil) {
  load_from_path("/usr/share/zoneinfo")
}

/// Load time zone database from provided directory. This is
/// useful if you have compiled your own version of the [IANA
/// time zone database](https://data.iana.org/time-zones/tz-link.html)
/// or they are not stored in the standard location. If no
/// parsable TZif files were found, returns `Error(Nil)`.
pub fn load_from_path(path: String) -> Result(TzDatabase, Nil) {
  let parts = filepath.split(path)
  let drop_number = list.length(parts)
  use filenames <- result.try(
    simplifile.get_files(path) |> result.replace_error(Nil),
  )

  let data =
    filenames
    |> list.map(process_tzfile(_, drop_number))
    |> result.values

  // If no parsable zone files were found return an Error rather than
  // fail silently.
  case list.length(data) {
    0 -> Error(Nil)
    _ ->
      Ok(TzDatabase(
        list.map(data, fn(v) { v.0 }) |> list.sort(string.compare),
        dict.from_list(data),
      ))
  }
}

/// Create new empty TzDatabase. This can be useful if you
/// will be loading TZif files using a different method, for
/// example over the internet, and wish to load them up into
/// a `TzDatabase` record.
pub fn new() -> TzDatabase {
  TzDatabase([], dict.new())
}

/// Add new time zone definition to TzDatabase. This can add
/// TZif data which has been parsed and loaded into a `parser.TzFile`
/// record. Each zone must be given a `zone_name` which can be used to
/// retrieve that time zone's data.
pub fn add_tzfile(
  db: TzDatabase,
  zone_name: String,
  tzfile: parser.TzFile,
) -> TzDatabase {
  let namelist = case dict.has_key(db.zone_data, zone_name) {
    True -> db.zone_names
    False -> [zone_name, ..db.zone_names] |> list.sort(string.compare)
  }
  TzDatabase(namelist, dict.insert(db.zone_data, zone_name, tzfile))
}

fn process_tzfile(
  filename: String,
  components_to_drop: Int,
) -> Result(#(String, parser.TzFile), Nil) {
  let zone_name =
    filepath.split(filename)
    |> list.drop(components_to_drop)
    |> list.fold("", filepath.join)

  use tzdata <- result.try(
    simplifile.read_bits(filename) |> result.replace_error(Nil),
  )
  use timeinfo <- result.try(parser.parse(tzdata) |> result.replace_error(Nil))

  Ok(#(zone_name, timeinfo))
}

/// Get all list of all time zone names within the
/// time zone database.
pub fn get_available_timezones(db: TzDatabase) -> List(String) {
  db.zone_names
}

/// Time zone parameters record.
/// - `offset` is the offset from UTC using [gleam_time](https://hexdocs.pm/gleam_time/gleam/time/duration.html#Duration)
///   `Duration`.
/// - `is_dst` indicates if it is daylight savings time
/// - `designation` is the time zone designation
pub type ZoneParameters {
  ZoneParameters(offset: Duration, is_dst: Bool, designation: String)
}

/// Retrieve the time zone parameters for a zone at a particular time.
/// The time is given as a `gleam/time/timestamp.Timestamp`, the zone name
/// and a time zone database. Because of
/// daylight savings time as well as other historical shifts in how time
/// has been measured, time zone information for a location shifts over time,
/// therefore the offset or designation you get from the database is time
/// dependant. Do not assume that the time zone parameters will be the same
/// at any other time.
///
/// # Example
///
/// ```gleam
/// import gleam/time/timestamp
/// 
/// let ts = timestamp.from_unix_seconds(1_758_223_300)
/// let assert Ok(db) = database.load_from_os()
/// 
/// get_zone_parameters(ts, "America/New_York", db)
/// // Ok(ZoneParameters(
/// //   Duration(-144_40, 0),
/// //   True,
/// //   "EDT",
/// // ))
/// ```
pub fn get_zone_parameters(
  ts: timestamp.Timestamp,
  zone_name: String,
  db: TzDatabase,
) -> Result(ZoneParameters, TzDatabaseError) {
  use tzdata <- result.try(
    dict.get(db.zone_data, zone_name) |> result.replace_error(ZoneNameNotFound),
  )
  let default = default_slice(tzdata.fields)

  let slices = create_slices(tzdata.fields)

  use slice <- result.try(
    get_slice(ts, slices, default) |> result.replace_error(InfoNotFound),
  )

  Ok(ZoneParameters(slice.utoff, slice.isdst, slice.designation))
}

/// Check if a time zone within the database has leap second data.
/// For some reason not all time zone files seem to have leap second
/// data. The "right/UTC" zone generally does have leap second information, but
/// is not always available.
pub fn has_leap_second_data(
  zone_name: String,
  db: TzDatabase,
) -> Result(Bool, TzDatabaseError) {
  use tzdata <- result.try(
    dict.get(db.zone_data, zone_name) |> result.replace_error(ZoneNameNotFound),
  )

  case list.length(tzdata.fields.leapsecond_values) {
    0 -> Ok(False)
    _ -> Ok(True)
  }
}

/// Find the number of leap seconds at a given `Timestamp` ts using the
/// given time zone. Not all time zones have leap second data, and if there
/// is no data present, this function will return `Error(InfoNotFound)`.
/// Typically the "right/UTC" time zone will have leap second data.
pub fn leap_seconds(
  ts: timestamp.Timestamp,
  zone_name: String,
  db: TzDatabase,
) -> Result(Int, TzDatabaseError) {
  use tzdata <- result.try(
    dict.get(db.zone_data, zone_name) |> result.replace_error(ZoneNameNotFound),
  )

  let #(ts_seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(ts)

  case list.length(tzdata.fields.leapsecond_values) {
    0 -> Error(InfoNotFound)
    _ -> {
      tzdata.fields.leapsecond_values
      |> list.fold_until(Ok(0), fn(acc, leap_second_info) {
        case leap_second_info.0 < ts_seconds {
          True -> list.Continue(Ok(leap_second_info.1))
          False -> list.Stop(acc)
        }
      })
    }
  }
}

// Timezone definition slice
type TtSlice {
  TtSlice(start_time: Int, utoff: Duration, isdst: Bool, designation: String)
}

// Turn time zone fields into a list of timezone information slices
fn create_slices(fields: parser.TzFileFields) -> List(TtSlice) {
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
        Ok(TtSlice(tup.0, duration.seconds(ttinfo.utoff), isdst, designation))
      }
      _ -> Error(Nil)
    }
  })
  |> result.values
}

fn default_slice(fields: parser.TzFileFields) -> Result(TtSlice, Nil) {
  use ttinfo <- result.try(list.first(fields.ttinfos))
  use designation <- result.try(list.first(fields.designations))
  let isdst = case ttinfo.isdst {
    0 -> False
    _ -> True
  }

  Ok(TtSlice(0, duration.seconds(ttinfo.utoff), isdst, designation))
}

fn get_slice(
  ts: timestamp.Timestamp,
  slices: List(TtSlice),
  default: Result(TtSlice, Nil),
) -> Result(TtSlice, Nil) {
  let #(seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(ts)

  slices
  |> list.fold_until(default, fn(acc, slice) {
    case slice.start_time <= seconds {
      True -> list.Continue(Ok(slice))
      False -> list.Stop(acc)
    }
  })
}
