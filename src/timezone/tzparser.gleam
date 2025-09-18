import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result

pub type TZFileError {
  HeaderParseError
  HeaderVersionError
  BodyParseError
  IntegerParseError
  ZoneFileError
}

pub type TZFileHeader {
  TZFileHeader(
    version: Int,
    ttisutcnt: Int,
    ttisstdcnt: Int,
    leapcnt: Int,
    timecnt: Int,
    typecnt: Int,
    charcnt: Int,
  )
}

pub type TZFileFields {
  TZFileFields(
    transition_times: List(Int),
    time_types: List(Int),
    ttinfos: List(TTInfo),
    designations: List(String),
    leapsecond_values: List(List(Int)),
    standard_or_wall: List(Int),
    ut_or_local: List(Int),
  )
}

pub type TZFile {
  TZFile(header: TZFileHeader, fields: TZFileFields, remains: BitArray)
}

pub type TTInfo {
  TTInfo(utoff: Int, isdst: Int, desigidx: Int)
}

type Parser(a, b) =
  fn(BitArray, fn(a, BitArray) -> Result(b, TZFileError)) ->
    Result(b, TZFileError)

pub fn parse(tzdata: BitArray) -> Result(TZFile, TZFileError) {
  // Parse the header for the tzfile
  use header, fields <- parse_header(tzdata)

  // Parse the first section, common to all versions
  use first_section, remain <- parse_section(header, 32, fields)

  case header.version {
    2 -> {
      use revised_header, remain <- parse_header(remain)
      use revised_section, remain <- parse_section(revised_header, 64, remain)
      Ok(TZFile(revised_header, revised_section, remain))
    }
    _ -> Ok(TZFile(header, first_section, remain))
  }
}

pub fn parse_header(
  tzdata: BitArray,
  next: fn(TZFileHeader, BitArray) -> Result(a, TZFileError),
) -> Result(a, TZFileError) {
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
        TZFileHeader(
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

fn parse_section(
  header: TZFileHeader,
  integer_size: Int,
  fields: BitArray,
  next: fn(TZFileFields, BitArray) -> Result(a, TZFileError),
) -> Result(a, TZFileError) {
  // Get list of time zone transition times
  use transition_times, remain <- parse_list(
    header.timecnt,
    fields,
    [],
    integer_parser(integer_size),
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
    integer_parser(integer_size),
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
    TZFileFields(
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
  next: fn(List(a), BitArray) -> Result(b, TZFileError),
) {
  case length {
    0 -> next(list.reverse(acc), bits)
    _ -> {
      use result, remain <- parser(bits)
      parse_list(length - 1, remain, [result, ..acc], parser, next)
    }
  }
}

pub fn parse_ttinfo(
  bits: BitArray,
  next: fn(TTInfo, BitArray) -> Result(a, TZFileError),
) -> Result(a, TZFileError) {
  use utoff, bits <- integer_parser(32)(bits)
  use isdst, bits <- unsigned_integer_parser(8)(bits)
  use desigidx, bits <- unsigned_integer_parser(8)(bits)

  let ttinfo = TTInfo(utoff, isdst, desigidx)

  next(ttinfo, bits)
}

fn integer_parser(
  bit_size: Int,
) -> fn(BitArray, fn(Int, BitArray) -> Result(a, TZFileError)) ->
  Result(a, TZFileError) {
  fn(bits: BitArray, next: fn(Int, BitArray) -> Result(a, TZFileError)) {
    case bits {
      <<i:signed-int-big-size(bit_size), rest:bits>> -> next(i, rest)
      _ -> Error(IntegerParseError)
    }
  }
}

fn unsigned_integer_parser(
  bit_size: Int,
) -> fn(BitArray, fn(Int, BitArray) -> Result(a, TZFileError)) ->
  Result(a, TZFileError) {
  fn(bits: BitArray, next: fn(Int, BitArray) -> Result(a, TZFileError)) {
    case bits {
      <<i:unsigned-int-big-size(bit_size), rest:bits>> -> next(i, rest)
      _ -> Error(IntegerParseError)
    }
  }
}

pub fn parse_null_terminated_string(
  bits: BitArray,
  next: fn(String, BitArray) -> Result(a, TZFileError),
) -> Result(a, TZFileError) {
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

pub fn split_at_null(
  bits: BitArray,
  start: Int,
) -> Result(#(BitArray, BitArray), Nil) {
  case bits {
    <<a:bits-size(start), 0:int-size(8), b:bits>> -> Ok(#(a, b))
    <<_:bits-size(start)>> -> Error(Nil)
    _ -> split_at_null(bits, start + 8)
  }
}
