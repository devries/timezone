import filepath
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
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
