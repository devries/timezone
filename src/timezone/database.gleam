import filepath
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import gleam/time/duration.{type Duration}
import gleam/time/timestamp
import simplifile
import timezone/internal

pub opaque type TzDatabase {
  TzDatabase(
    zone_names: List(String),
    zone_data: dict.Dict(String, internal.TimeZoneData),
  )
}

pub fn load_from_os() {
  load_from_path("/usr/share/zoneinfo")
}

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

fn process_tzfile(
  filename: String,
  components_to_drop: Int,
) -> Result(#(String, internal.TimeZoneData), Nil) {
  let zone_name =
    filepath.split(filename)
    |> list.drop(components_to_drop)
    |> list.fold("", filepath.join)

  use tzdata <- result.try(
    simplifile.read_bits(filename) |> result.replace_error(Nil),
  )

  use timeinfo <- result.try(
    internal.parse(tzdata) |> result.replace_error(Nil),
  )

  Ok(#(zone_name, timeinfo))
}

pub fn get_available_timezones(db: TzDatabase) -> List(String) {
  db.zone_names
}

pub type ZoneParameters {
  ZoneParameters(offset: Duration, is_dst: Bool, designation: String)
}

pub fn get_zone_parameters(
  ts: timestamp.Timestamp,
  zone_name: String,
  db: TzDatabase,
) -> Result(ZoneParameters, Nil) {
  use tzdata <- result.try(dict.get(db.zone_data, zone_name))
  let default = default_slice(tzdata.fields)

  let slices = create_slices(tzdata.fields)

  use slice <- result.try(get_slice(ts, slices, default))

  Ok(ZoneParameters(slice.utoff, slice.isdst, slice.designation))
}

// Below are some things I previously had elsewhere

/// Timezone definition slice
type TTSlice {
  TTSlice(start_time: Int, utoff: Duration, isdst: Bool, designation: String)
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
