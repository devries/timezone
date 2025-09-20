//// Parser for [tzfile](https://www.man7.org/linux/man-pages/man5/tzfile.5.html)
//// formatted files. This parser can parse the header and initial data section for
//// all tzfile formatted files as well as the header and data section of version 2
//// format tzfiles. Versions 3 format and version 4 format extensions are not supported
//// by this parser right now.

import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result

/// Time zone parser error
pub type TzFileError {
  /// Error parsing header
  HeaderParseError

  /// Unexpected file format version
  HeaderVersionError

  /// Error parsing fields within body of file
  BodyParseError

  /// Error parsing an integer
  IntegerParseError

  /// Error Parsing leap second section
  LeapSecondParseError
}

/// Header of the tzfile. This uses the same label names as
/// the extensions of the `tzh_` integer variables
/// defined in the [tzfile](https://www.man7.org/linux/man-pages/man5/tzfile.5.htmlc)
/// man page.
pub type TzFileHeader {
  TzFileHeader(
    version: Int,
    ttisutcnt: Int,
    ttisstdcnt: Int,
    leapcnt: Int,
    timecnt: Int,
    typecnt: Int,
    charcnt: Int,
  )
}

/// Fields within the tzfile.
pub type TzFileFields {
  TzFileFields(
    transition_times: List(Int),
    time_types: List(Int),
    ttinfos: List(TtInfo),
    designations: List(String),
    leapsecond_values: List(#(Int, Int)),
    standard_or_wall: List(Int),
    ut_or_local: List(Int),
  )
}

/// Parsed tzfile record containing the header, fields, as well as
/// any remaining data after the fields. The remaining data is usually
/// an ASCII string starting with a newline.
pub type TzFile {
  TzFile(header: TzFileHeader, fields: TzFileFields, remains: BitArray)
}

/// This record represents the ttinfo structs as defined within the
/// [tzfile](https://www.man7.org/linux/man-pages/man5/tzfile.5.html) format
/// man page.
pub type TtInfo {
  TtInfo(utoff: Int, isdst: Int, desigidx: Int)
}

type Parser(a, b) =
  fn(BitArray, fn(a, BitArray) -> Result(b, TzFileError)) ->
    Result(b, TzFileError)

/// Parse a bitarray in the format described by the
/// [tzfile](https://www.man7.org/linux/man-pages/man5/tzfile.5.html) man
/// page.
pub fn parse(tzdata: BitArray) -> Result(TzFile, TzFileError) {
  // Parse the header for the tzfile
  use header, fields <- parse_header(tzdata)

  // Parse the first section, common to all versions
  use first_section, remain <- parse_section(header, 32, fields)

  case header.version {
    2 | 3 | 4 -> {
      use revised_header, remain <- parse_header(remain)
      use revised_section, remain <- parse_section(revised_header, 64, remain)
      Ok(TzFile(revised_header, revised_section, remain))
    }
    _ -> Ok(TzFile(header, first_section, remain))
  }
}

fn parse_header(
  tzdata: BitArray,
  next: fn(TzFileHeader, BitArray) -> Result(a, TzFileError),
) -> Result(a, TzFileError) {
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
        TzFileHeader(
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
  header: TzFileHeader,
  integer_size: Int,
  fields: BitArray,
  next: fn(TzFileFields, BitArray) -> Result(a, TzFileError),
) -> Result(a, TzFileError) {
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

  use leapsecond_values, remain <- parse_list(
    header.leapcnt,
    remain,
    [],
    leap_parser(integer_size),
  )

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
    TzFileFields(
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
  next: fn(List(a), BitArray) -> Result(b, TzFileError),
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
  next: fn(TtInfo, BitArray) -> Result(a, TzFileError),
) -> Result(a, TzFileError) {
  use utoff, bits <- integer_parser(32)(bits)
  use isdst, bits <- unsigned_integer_parser(8)(bits)
  use desigidx, bits <- unsigned_integer_parser(8)(bits)

  let ttinfo = TtInfo(utoff, isdst, desigidx)

  next(ttinfo, bits)
}

fn integer_parser(
  bit_size: Int,
) -> fn(BitArray, fn(Int, BitArray) -> Result(a, TzFileError)) ->
  Result(a, TzFileError) {
  fn(bits: BitArray, next: fn(Int, BitArray) -> Result(a, TzFileError)) {
    case bits {
      <<i:signed-int-big-size(bit_size), rest:bits>> -> next(i, rest)
      _ -> Error(IntegerParseError)
    }
  }
}

fn unsigned_integer_parser(
  bit_size: Int,
) -> fn(BitArray, fn(Int, BitArray) -> Result(a, TzFileError)) ->
  Result(a, TzFileError) {
  fn(bits: BitArray, next: fn(Int, BitArray) -> Result(a, TzFileError)) {
    case bits {
      <<i:unsigned-int-big-size(bit_size), rest:bits>> -> next(i, rest)
      _ -> Error(IntegerParseError)
    }
  }
}

fn leap_parser(
  bit_size: Int,
) -> fn(BitArray, fn(#(Int, Int), BitArray) -> Result(a, TzFileError)) ->
  Result(a, TzFileError) {
  fn(bits: BitArray, next: fn(#(Int, Int), BitArray) -> Result(a, TzFileError)) {
    case bits {
      <<
        tt:signed-int-big-size(bit_size),
        leap:signed-int-big-size(32),
        rest:bits,
      >> -> next(#(tt, leap), rest)
      _ -> Error(LeapSecondParseError)
    }
  }
}

fn parse_null_terminated_string(
  bits: BitArray,
  next: fn(String, BitArray) -> Result(a, TzFileError),
) -> Result(a, TzFileError) {
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
