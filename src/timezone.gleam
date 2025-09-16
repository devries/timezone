import gleam/bit_array
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/time/timestamp

pub fn main() -> Nil {
  io.println("Hello from timezone!")
}

pub type TimeZoneError {
  HeaderParseError
  HeaderVersionError
  BodyParseError
  IntegerParseError
}

pub type TimeZoneHeader {
  TimeZoneHeader(
    version: Int,
    ttisutcnt: Int,
    ttisstdcnt: Int,
    leapcnt: Int,
    timecnt: Int,
    typecnt: Int,
    charcnt: Int,
  )
}

pub type TimeZoneFields {
  TimeZoneFields(
    transition_times: List(Int),
    time_types: List(Int),
    ttinfos: List(TTInfo),
    designations: List(String),
    leapsecond_values: List(List(Int)),
    standard_or_wall: List(Int),
    ut_or_local: List(Int),
  )
}

pub type TimeZoneData {
  TimeZoneData(
    header: TimeZoneHeader,
    fields: TimeZoneFields,
    remains: BitArray,
  )
}

pub type TTInfo {
  TTInfo(utoff: Int, isdst: Int, desigidx: Int)
}

pub type TTSlice {
  TTSlice(start_time: Int, utoff: Int, isdst: Bool, designation: String)
}

type Parser(a, b) =
  fn(BitArray, fn(a, BitArray) -> Result(b, TimeZoneError)) ->
    Result(b, TimeZoneError)

pub fn parse(tzdata: BitArray) -> Result(TimeZoneData, TimeZoneError) {
  // Parse the header for the tzfile
  use header, fields <- parse_header(tzdata)

  // Parse the first section, common to all versions
  use first_section, remain <- parse_first_section(header, fields)

  case header.version {
    2 -> {
      use revised_header, remain <- parse_header(remain)
      use revised_section, remain <- parse_v2_section(revised_header, remain)
      Ok(TimeZoneData(revised_header, revised_section, remain))
    }
    _ -> Ok(TimeZoneData(header, first_section, remain))
  }
}

fn parse_header(
  tzdata: BitArray,
  next: fn(TimeZoneHeader, BitArray) -> Result(a, TimeZoneError),
) -> Result(a, TimeZoneError) {
  case tzdata {
    <<
      "TZif":utf8,
      version:bits-size(8),
      0:unit(8)-size(15),
      ttisutcnt:unsigned-big-int-size(32),
      ttisstdcnt:unsigned-big-int-size(32),
      leapcnt:unsigned-big-int-size(32),
      timecnt:unsigned-big-int-size(32),
      typecnt:unsigned-big-int-size(32),
      charcnt:unsigned-big-int-size(32),
      fields:bits,
    >> -> {
      use parsed_version <- result.try(case version {
        <<0>> -> Ok(1)
        <<"2">> -> Ok(2)
        <<"3">> -> Ok(3)
        <<"4">> -> Ok(4)
        _ -> Error(HeaderVersionError)
      })
      let header =
        TimeZoneHeader(
          parsed_version,
          ttisutcnt,
          ttisstdcnt,
          leapcnt,
          timecnt,
          typecnt,
          charcnt,
        )

      next(header, fields)
    }
    _ -> Error(HeaderParseError)
  }
}

fn parse_first_section(
  header: TimeZoneHeader,
  fields: BitArray,
  next: fn(TimeZoneFields, BitArray) -> Result(a, TimeZoneError),
) -> Result(a, TimeZoneError) {
  // Get list of time zone transition times
  use transition_times, remain <- parse_list(
    header.timecnt,
    fields,
    [],
    integer_parser(32),
  )
  // Get the ttinfo index associated with each transition time
  use ttinfo_indecies, remain <- parse_list(
    header.timecnt,
    remain,
    [],
    unsigned_integer_parser(8),
  )

  // Get the ttinfo structures used in this time zone
  use ttinfos, remain <- parse_list(header.typecnt, remain, [], parse_ttinfo)

  // Get the designations for each ttinfo.
  use designation_tuples <- result.try(
    ttinfos
    |> list.try_map(fn(ttinfo) {
      let desigidx = ttinfo.desigidx
      case remain {
        <<_:unit(8)-size(desigidx), substring:bits>> -> {
          use s, rest <- parse_null_terminated_string(substring)
          Ok(#(s, rest))
        }
        _ -> Error(BodyParseError)
      }
    }),
  )

  // Some messing around to try to get past the null terminated strings
  use smallest_bitarray_tuple <- result.try(
    designation_tuples
    |> list.map(fn(tup) { #(-bit_array.bit_size(tup.1), tup.1) })
    |> list.max(fn(tupa, tupb) { int.compare(tupa.0, tupb.0) })
    |> result.replace_error(BodyParseError),
  )

  let remain = smallest_bitarray_tuple.1

  let designations = designation_tuples |> list.map(fn(tup) { tup.0 })

  // Get leap second information
  use leapsecond_integers, remain <- parse_list(
    header.leapcnt,
    remain,
    [],
    integer_parser(32),
  )

  let leapsecond_values = leapsecond_integers |> list.sized_chunk(2)

  // Booleans to indicate if these are standard time or local time indicators
  use standard_wall_indicators, remain <- parse_list(
    header.ttisstdcnt,
    remain,
    [],
    unsigned_integer_parser(8),
  )

  // Booleans to indicate if these are UT or local indicators
  use ut_local_indicators, remain <- parse_list(
    header.ttisutcnt,
    remain,
    [],
    unsigned_integer_parser(8),
  )

  next(
    TimeZoneFields(
      transition_times,
      ttinfo_indecies,
      ttinfos,
      designations,
      leapsecond_values,
      standard_wall_indicators,
      ut_local_indicators,
    ),
    remain,
  )
}

fn parse_v2_section(
  header: TimeZoneHeader,
  fields: BitArray,
  next: fn(TimeZoneFields, BitArray) -> Result(a, TimeZoneError),
) -> Result(a, TimeZoneError) {
  // Get list of time zone transition times
  use transition_times, remain <- parse_list(
    header.timecnt,
    fields,
    [],
    integer_parser(64),
  )

  // Get the ttinfo index associated with each transition time
  use ttinfo_indecies, remain <- parse_list(
    header.timecnt,
    remain,
    [],
    unsigned_integer_parser(8),
  )

  // Get the ttinfo structures used in this time zone
  use ttinfos, remain <- parse_list(header.typecnt, remain, [], parse_ttinfo)

  // Get the designations for each ttinfo.
  use designation_tuples <- result.try(
    ttinfos
    |> list.try_map(fn(ttinfo) {
      let desigidx = ttinfo.desigidx
      case remain {
        <<_:unit(8)-size(desigidx), substring:bits>> -> {
          use s, rest <- parse_null_terminated_string(substring)
          Ok(#(s, rest))
        }
        _ -> Error(BodyParseError)
      }
    }),
  )

  // Some messing around to try to get past the null terminated strings
  use smallest_bitarray_tuple <- result.try(
    designation_tuples
    |> list.map(fn(tup) { #(-bit_array.bit_size(tup.1), tup.1) })
    |> list.max(fn(tupa, tupb) { int.compare(tupa.0, tupb.0) })
    |> result.replace_error(BodyParseError),
  )

  let remain = smallest_bitarray_tuple.1

  let designations = designation_tuples |> list.map(fn(tup) { tup.0 })

  // Get leap second information
  use leapsecond_integers, remain <- parse_list(
    header.leapcnt,
    remain,
    [],
    integer_parser(64),
  )

  let leapsecond_values = leapsecond_integers |> list.sized_chunk(2)

  // Booleans to indicate if these are standard time or local time indicators
  use standard_wall_indicators, remain <- parse_list(
    header.ttisstdcnt,
    remain,
    [],
    unsigned_integer_parser(8),
  )

  // Booleans to indicate if these are UT or local indicators
  use ut_local_indicators, remain <- parse_list(
    header.ttisutcnt,
    remain,
    [],
    unsigned_integer_parser(8),
  )

  next(
    TimeZoneFields(
      transition_times,
      ttinfo_indecies,
      ttinfos,
      designations,
      leapsecond_values,
      standard_wall_indicators,
      ut_local_indicators,
    ),
    remain,
  )
}

fn parse_list(
  length: Int,
  bits: BitArray,
  acc: List(a),
  parser: Parser(a, b),
  next: fn(List(a), BitArray) -> Result(b, TimeZoneError),
) {
  case length {
    0 -> next(list.reverse(acc), bits)
    _ -> {
      use result, remain <- parser(bits)
      parse_list(length - 1, remain, [result, ..acc], parser, next)
    }
  }
}

fn parse_ttinfo(
  bits: BitArray,
  next: fn(TTInfo, BitArray) -> Result(a, TimeZoneError),
) -> Result(a, TimeZoneError) {
  use utoff, bits <- integer_parser(32)(bits)
  use isdst, bits <- unsigned_integer_parser(8)(bits)
  use desigidx, bits <- unsigned_integer_parser(8)(bits)

  let ttinfo = TTInfo(utoff, isdst, desigidx)

  next(ttinfo, bits)
}

fn integer_parser(
  bit_size: Int,
) -> fn(BitArray, fn(Int, BitArray) -> Result(a, TimeZoneError)) ->
  Result(a, TimeZoneError) {
  fn(bits: BitArray, next: fn(Int, BitArray) -> Result(a, TimeZoneError)) {
    case bits {
      <<i:signed-int-big-size(bit_size), rest:bits>> -> next(i, rest)
      _ -> Error(IntegerParseError)
    }
  }
}

fn unsigned_integer_parser(
  bit_size: Int,
) -> fn(BitArray, fn(Int, BitArray) -> Result(a, TimeZoneError)) ->
  Result(a, TimeZoneError) {
  fn(bits: BitArray, next: fn(Int, BitArray) -> Result(a, TimeZoneError)) {
    case bits {
      <<i:unsigned-int-big-size(bit_size), rest:bits>> -> next(i, rest)
      _ -> Error(IntegerParseError)
    }
  }
}

fn parse_null_terminated_string(
  bits: BitArray,
  next: fn(String, BitArray) -> Result(a, TimeZoneError),
) -> Result(a, TimeZoneError) {
  case split_at_null(bits, 0) {
    Ok(#(prefix, postfix)) -> {
      case bit_array.to_string(prefix) {
        Ok(v) -> next(v, postfix)
        Error(Nil) -> Error(BodyParseError)
      }
    }
    Error(Nil) -> Error(BodyParseError)
  }
}

fn split_at_null(
  bits: BitArray,
  start: Int,
) -> Result(#(BitArray, BitArray), Nil) {
  case bits {
    <<a:bits-size(start), 0:int-size(8), b:bits>> -> Ok(#(a, b))
    <<_:bits-size(start)>> -> Error(Nil)
    _ -> split_at_null(bits, start + 8)
  }
}

// Turn time zone fields into a list of timezone information slices
pub fn create_slices(fields: TimeZoneFields) -> List(TTSlice) {
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
        Ok(TTSlice(tup.0, ttinfo.utoff, isdst, designation))
      }
      _ -> Error(Nil)
    }
  })
  |> result.values
}

pub fn get_slice(
  ts: timestamp.Timestamp,
  slices: List(TTSlice),
) -> Result(TTSlice, Nil) {
  let #(seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(ts)

  slices
  |> list.fold_until(list.first(slices), fn(acc, slice) {
    case slice.start_time < seconds {
      True -> list.Continue(Ok(slice))
      False -> list.Stop(acc)
    }
  })
}
