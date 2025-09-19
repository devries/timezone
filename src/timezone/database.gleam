import filepath
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import gleam/time/duration.{type Duration}
import gleam/time/timestamp
import simplifile
import timezone/tzparser

pub opaque type TzDatabase {
  TzDatabase(
    zone_names: List(String),
    zone_data: dict.Dict(String, tzparser.TzFile),
  )
}

/// TzDatabase error types
pub type TzDatabaseError {
  /// There is no information available for this zone.
  ZoneNotFound
  /// Unable to provide zone information due to missing or
  /// incomplete data.
  ProcessingError
}

/// Load timezone database from default operating system location
/// which is typically "/usr/share/zoneinfo".
pub fn load_from_os() {
  load_from_path("/usr/share/zoneinfo")
}

/// Load timezone database from provided directory
pub fn load_from_path(path: String) {
  let parts = filepath.split(path)
  let drop_number = list.length(parts)
  let assert Ok(filenames) = simplifile.get_files(path)

  let data =
    filenames
    |> list.map(process_tzfile(_, drop_number))
    |> result.values

  TzDatabase(
    list.map(data, fn(v) { v.0 }) |> list.sort(string.compare),
    dict.from_list(data),
  )
}

/// Create new empty TzDatabase.
pub fn new() -> TzDatabase {
  TzDatabase([], dict.new())
}

/// Add new timezone definition to TzDatabase.
pub fn add_tzfile(
  db: TzDatabase,
  zone_name: String,
  tzfile: tzparser.TzFile,
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
) -> Result(#(String, tzparser.TzFile), Nil) {
  let zone_name =
    filepath.split(filename)
    |> list.drop(components_to_drop)
    |> list.fold("", filepath.join)

  use tzdata <- result.try(
    simplifile.read_bits(filename) |> result.replace_error(Nil),
  )
  use timeinfo <- result.try(
    tzparser.parse(tzdata) |> result.replace_error(Nil),
  )

  Ok(#(zone_name, timeinfo))
}

/// Get all timezones in the database
pub fn get_available_timezones(db: TzDatabase) -> List(String) {
  db.zone_names
}

/// Time zone parameters record.
/// - `offset` is the offset from UTC.
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
/// let db = database.load_from_os()
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
    dict.get(db.zone_data, zone_name) |> result.replace_error(ZoneNotFound),
  )
  let default = default_slice(tzdata.fields)

  let slices = create_slices(tzdata.fields)

  use slice <- result.try(
    get_slice(ts, slices, default) |> result.replace_error(ProcessingError),
  )

  Ok(ZoneParameters(slice.utoff, slice.isdst, slice.designation))
}

// Below are some things I previously had elsewhere

/// Timezone definition slice
type TtSlice {
  TtSlice(start_time: Int, utoff: Duration, isdst: Bool, designation: String)
}

// Turn time zone fields into a list of timezone information slices
fn create_slices(fields: tzparser.TzFileFields) -> List(TtSlice) {
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

fn default_slice(fields: tzparser.TzFileFields) -> Result(TtSlice, Nil) {
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
    case slice.start_time < seconds {
      True -> list.Continue(Ok(slice))
      False -> list.Stop(acc)
    }
  })
}
