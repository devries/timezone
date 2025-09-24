import gleam/bit_array
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import tzif/database
import tzif/parser
import tzif/tzcalendar

const tzsample = "VFppZjIAAAAAAAAAAAAAAAAAAAAAAAAGAAAABgAAAAAAAADsAAAABgAAABSAAAAAnqYecJ+662CghgBwoZrNYKJl4nCjg+ngpGqucKU1p2CmU8rwpxWJYKgzrPCo/qXgqhOO8Kreh+Cr83DwrL5p4K3TUvCunkvgr7M08LB+LeCxnFFwsmdKYLN8M3C0RyxgtVwVcLYnDmC3O/dwuAbwYLkb2XC55tJguwT18LvGtGC85Nfwva/Q4L7EufC/j7LgwKSb8MFvlODChH3ww0924MRkX/DFL1jgxk18cMcPOuDILV5wyPhXYMoNQHDK2Dlgy4jwcNIj9HDSYPvg03Xk8NRA3eDVVcbw1iC/4Nc1qPDYAKHg2RWK8Nngg+Da/qdw28Bl4NzeiXDdqYJg3r5rcN+JZGDgnk1w4WlGYOJ+L3DjSShg5F4RcOVXLuDmRy3w5zcQ4OgnD/DpFvLg6gbx8Or21ODr5tPw7Na24O3GtfDuv9Ng76/ScPCftWDxj7Rw8n+XYPNvlnD0X3lg9U94cPY/W2D3L1pw+Ch34PkPPHD6CFng+vhY8PvoO+D82Drw/cgd4P64HPD/p//gAJf+8AGH4eACd+DwA3D+YARg/XAFUOBgBkDfcAcwwmAHjRlwCRCkYAmtlPAK8IZgC+CFcAzZouANwGdwDrmE4A+pg/AQmWbgEYll8BJ5SOATaUfwFFkq4BVJKfAWOQzgFykL8BgiKWAZCO3wGgILYBryCnAb4e1gHNHscB3Bz2Aesc5wH6GxYCB2APAhgZNgIlXi8CNqr+AkNcTwJUqR4CYVpvAnKnPgJ/7DcCkKVeAp3qVwKuo34Cu+h3As01RgLZ5pcC6zNmAvfktwMJMYYDFnZ/AycvpgM0dJ8DRS3GA1JyvwNjK+YDcHDfA4G9rgOObv8Dn7vOA6xtHwO9ue4Dyv7nA9u4DgPo/QcD+bYuBAb7JwQYR/YEJPlHBDZGFgRC92cEVEQ2BF86jwRy1f4EfTivBJDUHgSbNs8ErtI+BLnIlwTNZAYE18a3BOtiJgT1xNcFCWBGBRPC9wUnXmYFMcEXBUVchgVPvzcFY1qmBW5Q/wWB7G4FjE8fBZ/qjgWqTT8FveiuBchLXwXb5s4F5kl/Bfnk7gYE20cGGHa2BiLZZwY2dNYGQNeHBlRy9gZe1acGcnEWBnzTxwaQbzYGmtHnBq5tVga5Y68GzP8eBtdhzwbq/T4G9V/vBwj7XgcTXg8HJvl+BzFcLwdE954HT+33B2OJZgdt7BcHgYeGB4vqNwefhaYHqehXB72DxgfH5ncH24HmB+Xklwf5gAYAMBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIEBQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgEC//+6ngAA///HwAEE//+5sAAI//+5sAAI///HwAEM///HwAEQTE1UAEVEVABFU1QARVdUAEVQVAAAAAABAAEAAAABAAFUWmlmMgAAAAAAAAAAAAAAAAAAAAAAAAYAAAAGAAAAAAAAAOwAAAAGAAAAFP////9eA/CQ/////56mHnD/////n7rrYP////+ghgBw/////6GazWD/////omXicP////+jg+ng/////6RqrnD/////pTWnYP////+mU8rw/////6cViWD/////qDOs8P////+o/qXg/////6oTjvD/////qt6H4P////+r83Dw/////6y+aeD/////rdNS8P////+unkvg/////6+zNPD/////sH4t4P////+xnFFw/////7JnSmD/////s3wzcP////+0Ryxg/////7VcFXD/////ticOYP////+3O/dw/////7gG8GD/////uRvZcP////+55tJg/////7sE9fD/////u8a0YP////+85Nfw/////72v0OD/////vsS58P////+/j7Lg/////8Ckm/D/////wW+U4P/////ChH3w/////8NPduD/////xGRf8P/////FL1jg/////8ZNfHD/////xw864P/////ILV5w/////8j4V2D/////yg1AcP/////K2Dlg/////8uI8HD/////0iP0cP/////SYPvg/////9N15PD/////1EDd4P/////VVcbw/////9Ygv+D/////1zWo8P/////YAKHg/////9kVivD/////2eCD4P/////a/qdw/////9vAZeD/////3N6JcP/////dqYJg/////96+a3D/////34lkYP/////gnk1w/////+FpRmD/////4n4vcP/////jSShg/////+ReEXD/////5Vcu4P/////mRy3w/////+c3EOD/////6CcP8P/////pFvLg/////+oG8fD/////6vbU4P/////r5tPw/////+zWtuD/////7ca18P/////uv9Ng/////++v0nD/////8J+1YP/////xj7Rw//////J/l2D/////82+WcP/////0X3lg//////VPeHD/////9j9bYP/////3L1pw//////god+D/////+Q88cP/////6CFng//////r4WPD/////++g74P/////82Drw//////3IHeD//////rgc8P//////p//gAAAAAACX/vAAAAAAAYfh4AAAAAACd+DwAAAAAANw/mAAAAAABGD9cAAAAAAFUOBgAAAAAAZA33AAAAAABzDCYAAAAAAHjRlwAAAAAAkQpGAAAAAACa2U8AAAAAAK8IZgAAAAAAvghXAAAAAADNmi4AAAAAANwGdwAAAAAA65hOAAAAAAD6mD8AAAAAAQmWbgAAAAABGJZfAAAAAAEnlI4AAAAAATaUfwAAAAABRZKuAAAAAAFUkp8AAAAAAWOQzgAAAAABcpC/AAAAAAGCIpYAAAAAAZCO3wAAAAABoCC2AAAAAAGvIKcAAAAAAb4e1gAAAAABzR7HAAAAAAHcHPYAAAAAAesc5wAAAAAB+hsWAAAAAAIHYA8AAAAAAhgZNgAAAAACJV4vAAAAAAI2qv4AAAAAAkNcTwAAAAACVKkeAAAAAAJhWm8AAAAAAnKnPgAAAAACf+w3AAAAAAKQpV4AAAAAAp3qVwAAAAACrqN+AAAAAAK76HcAAAAAAs01RgAAAAAC2eaXAAAAAALrM2YAAAAAAvfktwAAAAADCTGGAAAAAAMWdn8AAAAAAycvpgAAAAADNHSfAAAAAANFLcYAAAAAA1JyvwAAAAADYyvmAAAAAANwcN8AAAAAA4G9rgAAAAADjm7/AAAAAAOfu84AAAAAA6xtHwAAAAADvbnuAAAAAAPK/ucAAAAAA9u4DgAAAAAD6P0HAAAAAAP5ti4AAAAABAb7JwAAAAAEGEf2AAAAAAQk+UcAAAAABDZGFgAAAAAEQvdnAAAAAARURDYAAAAABF86jwAAAAAEctX+AAAAAAR9OK8AAAAABJDUHgAAAAAEmzbPAAAAAASu0j4AAAAABLnIlwAAAAAEzWQGAAAAAATXxrcAAAAABOtiJgAAAAAE9cTXAAAAAAUJYEYAAAAABRPC9wAAAAAFJ15mAAAAAAUxwRcAAAAABUVchgAAAAAFT783AAAAAAVjWqYAAAAABW5Q/wAAAAAFgexuAAAAAAWMTx8AAAAABZ/qjgAAAAAFqk0/AAAAAAW96K4AAAAABchLXwAAAAAF2+bOAAAAAAXmSX8AAAAABfnk7gAAAAAGBNtHAAAAAAYYdrYAAAAABiLZZwAAAAAGNnTWAAAAAAZA14cAAAAABlRy9gAAAAAGXtWnAAAAAAZycRYAAAAABnzTxwAAAAAGkG82AAAAAAaa0ecAAAAABq5tVgAAAAAGuWOvAAAAAAbM/x4AAAAABtdhzwAAAAAG6v0+AAAAAAb1X+8AAAAABwj7XgAAAAAHE14PAAAAAAcm+X4AAAAABzFcLwAAAAAHRPeeAAAAAAdP7fcAAAAAB2OJZgAAAAAHbewXAAAAAAeBh4YAAAAAB4vqNwAAAAAHn4WmAAAAAAep6FcAAAAAB72DxgAAAAAHx+Z3AAAAAAfbgeYAAAAAB+XklwAAAAAH+YAGADAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECBAUCAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAv//up4AAP//x8ABBP//ubAACP//ubAACP//x8ABDP//x8ABEExNVABFRFQARVNUAEVXVABFUFQAAAAAAQABAAAAAQABCkVTVDVFRFQsTTMuMi4wLE0xMS4xLjAK"

const tzsample2 = "VFppZjIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAQAAAAAAABVVEMAVFppZjIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAQAAAAAAABVVEMAClVUQzAK"

const canberra = "VFppZjIAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAACOAAAABAAAAA6AAAAAnE7CgJy8LwDLVLMAy8dlgMy3VoDNp0eAzqBzAM+HKYADcDmABA0cAAVQG4AF9jiABy/9gAfWGoAJD9+ACbX8gArvwYALnxkADNjeAA1++wAOuMAAD17dABCYogARPr8AEniEABMeoQAUWGYAFP6DABY4SAAXDImAGCFkgBjHgYAaAUaAGqdjgBvhKIAch0WAHcEKgB55nIAfl7IAIFl+gCGAzoAiQpsAI2nrACQifQAlSc0AJe/qACcprwAnz8wAKQmRACmvrgAq6XMAK5jKgCzSj4AteKyALrJxgC9YjoAwklOAMV1agDJyNYAzPTyANFIXgDUdHoA2MfmANv0AgDgbFgA43OKAOafpgDq8xIA72toAPKXhAD26vAA+hcMAP5qeAEBlpQBBg7qAQkWHAENjnIBELqOARUN+gEYFSwBHI2CAR/eiAEjnkwBJ14QASsd1AEu3ZgBMp1cATZdIAE6HOQBPdyoAUHBVgFFgRoBSUDeAU0AogFQwGYBVIAqAVg/7gFb/7IBX792AWN/OgFnPv4Bav7CAW7jcAFyozQBdmL4AXoivAF94oABgaJEAYViCAGJIcwBjOGQAZChVAGUYRgBmEXGAZwFigGfxU4Bo4USAadE1gGrBJoBrsReAbKEIgG2Q+YBugOqAb3DbgHBqBwBxWfgAcknpAHM52gB0KcsAdRm8AHYJrQB2+Z4Ad+mPAHjZgAB5yXEAerliAHuyjYB8on6AfZJvgH6CYIB/clGAAwECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQAAjcQAAAAAmrABBAAAjKAACQAAjKAACUxNVABBRURUAEFFU1QAAAEBAFRaaWYyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAjgAAAAQAAAAO/////3MWfzz/////nE7CgP////+cvC8A/////8tUswD/////y8dlgP/////Mt1aA/////82nR4D/////zqBzAP/////PhymAAAAAAANwOYAAAAAABA0cAAAAAAAFUBuAAAAAAAX2OIAAAAAABy/9gAAAAAAH1hqAAAAAAAkP34AAAAAACbX8gAAAAAAK78GAAAAAAAufGQAAAAAADNjeAAAAAAANfvsAAAAAAA64wAAAAAAAD17dAAAAAAAQmKIAAAAAABE+vwAAAAAAEniEAAAAAAATHqEAAAAAABRYZgAAAAAAFP6DAAAAAAAWOEgAAAAAABcMiYAAAAAAGCFkgAAAAAAYx4GAAAAAABoBRoAAAAAAGqdjgAAAAAAb4SiAAAAAAByHRYAAAAAAHcEKgAAAAAAeeZyAAAAAAB+XsgAAAAAAIFl+gAAAAAAhgM6AAAAAACJCmwAAAAAAI2nrAAAAAAAkIn0AAAAAACVJzQAAAAAAJe/qAAAAAAAnKa8AAAAAACfPzAAAAAAAKQmRAAAAAAApr64AAAAAACrpcwAAAAAAK5jKgAAAAAAs0o+AAAAAAC14rIAAAAAALrJxgAAAAAAvWI6AAAAAADCSU4AAAAAAMV1agAAAAAAycjWAAAAAADM9PIAAAAAANFIXgAAAAAA1HR6AAAAAADYx+YAAAAAANv0AgAAAAAA4GxYAAAAAADjc4oAAAAAAOafpgAAAAAA6vMSAAAAAADva2gAAAAAAPKXhAAAAAAA9urwAAAAAAD6FwwAAAAAAP5qeAAAAAABAZaUAAAAAAEGDuoAAAAAAQkWHAAAAAABDY5yAAAAAAEQuo4AAAAAARUN+gAAAAABGBUsAAAAAAEcjYIAAAAAAR/eiAAAAAABI55MAAAAAAEnXhAAAAAAASsd1AAAAAABLt2YAAAAAAEynVwAAAAAATZdIAAAAAABOhzkAAAAAAE93KgAAAAAAUHBVgAAAAABRYEaAAAAAAFJQN4AAAAAAU0AogAAAAABUMBmAAAAAAFUgCoAAAAAAVg/7gAAAAABW/+yAAAAAAFfv3YAAAAAAWN/OgAAAAABZz7+AAAAAAFq/sIAAAAAAW7jcAAAAAABcqM0AAAAAAF2YvgAAAAAAXoivAAAAAABfeKAAAAAAAGBokQAAAAAAYViCAAAAAABiSHMAAAAAAGM4ZAAAAAAAZChVAAAAAABlGEYAAAAAAGYRcYAAAAAAZwFigAAAAABn8VOAAAAAAGjhRIAAAAAAadE1gAAAAABqwSaAAAAAAGuxF4AAAAAAbKEIgAAAAABtkPmAAAAAAG6A6oAAAAAAb3DbgAAAAABwagcAAAAAAHFZ+AAAAAAAcknpAAAAAABzOdoAAAAAAHQpywAAAAAAdRm8AAAAAAB2Ca0AAAAAAHb5ngAAAAAAd+mPAAAAAAB42YAAAAAAAHnJcQAAAAAAerliAAAAAAB7so2AAAAAAHyifoAAAAAAfZJvgAAAAAB+gmCAAAAAAH9yUYADAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAACNxAAAAACasAEEAACMoAAJAACMoAAJTE1UAEFFRFQAQUVTVAAAAQEACkFFU1QtMTBBRURULE0xMC4xLjAsTTQuMS4wLzMK"

const right_utc_sample = "VFppZjIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABsAAAABAAAAAQAAAARqQGQbAAAAAAAAAFVUQwAEslgAAAAAAQWk7AEAAAACB4YfggAAAAMJZ1MDAAAABAtIhoQAAAAFDSsLhQAAAAYPDD8GAAAABxDtcocAAAAIEs6mCAAAAAkVn8qJAAAACheA/goAAAALGWIxiwAAAAwdJeoMAAAADSHa5Q0AAAAOJZ6djgAAAA8nf9EPAAAAECpQ9ZAAAAARLDIpEQAAABIuE1ySAAAAEzDnJBMAAAAUM7hIlAAAABU2jBAVAAAAFkO3G5YAAAAXSVwHlwAAABhP75MYAAAAGVWTLZkAAAAaWGhGmgAAABtUWmlmMgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGwAAAAEAAAABAAAABAAAAABqQGQbAAAAAAAAAFVUQwAAAAAABLJYAAAAAAEAAAAABaTsAQAAAAIAAAAAB4YfggAAAAMAAAAACWdTAwAAAAQAAAAAC0iGhAAAAAUAAAAADSsLhQAAAAYAAAAADww/BgAAAAcAAAAAEO1yhwAAAAgAAAAAEs6mCAAAAAkAAAAAFZ/KiQAAAAoAAAAAF4D+CgAAAAsAAAAAGWIxiwAAAAwAAAAAHSXqDAAAAA0AAAAAIdrlDQAAAA4AAAAAJZ6djgAAAA8AAAAAJ3/RDwAAABAAAAAAKlD1kAAAABEAAAAALDIpEQAAABIAAAAALhNckgAAABMAAAAAMOckEwAAABQAAAAAM7hIlAAAABUAAAAANowQFQAAABYAAAAAQ7cblgAAABcAAAAASVwHlwAAABgAAAAAT++TGAAAABkAAAAAVZMtmQAAABoAAAAAWGhGmgAAABsKCg=="

fn get_database() -> database.TzDatabase {
  let assert Ok(tzdata) = bit_array.base64_decode(tzsample)
  let assert Ok(tz_ny) = parser.parse(tzdata)

  let assert Ok(tzdata2) = bit_array.base64_decode(tzsample2)
  let assert Ok(tz_utc) = parser.parse(tzdata2)

  let assert Ok(tzdata3) = bit_array.base64_decode(canberra)
  let assert Ok(tz_au) = parser.parse(tzdata3)

  let assert Ok(tzdata4) = bit_array.base64_decode(right_utc_sample)
  let assert Ok(tz_right_utc) = parser.parse(tzdata4)

  database.new()
  |> database.add_tzfile("America/New_York", tz_ny)
  |> database.add_tzfile("UTC", tz_utc)
  |> database.add_tzfile("Australia/Canberra", tz_au)
  |> database.add_tzfile("right/UTC", tz_right_utc)
}

pub fn get_time_in_local_zone_test() {
  let db = get_database()
  let ts = timestamp.from_unix_seconds(1_758_086_280)
  assert tzcalendar.to_time_and_zone(ts, "America/New_York", db)
    == Ok(tzcalendar.TimeAndZone(
      calendar.Date(2025, calendar.September, 17),
      calendar.TimeOfDay(1, 18, 0, 0),
      duration.hours(-4),
      "EDT",
      True,
    ))
}

pub fn get_time_only_in_local_zone_test() {
  let db = get_database()
  let ts = timestamp.from_unix_seconds(1_758_086_280)
  assert tzcalendar.to_calendar(ts, "America/New_York", db)
    == Ok(#(
      calendar.Date(2025, calendar.September, 17),
      calendar.TimeOfDay(1, 18, 0, 0),
    ))
}

pub fn get_time_in_utc_zone_test() {
  let db = get_database()
  let ts = timestamp.from_unix_seconds(1_758_086_280)
  assert tzcalendar.to_time_and_zone(ts, "UTC", db)
    == Ok(tzcalendar.TimeAndZone(
      calendar.Date(2025, calendar.September, 17),
      calendar.TimeOfDay(5, 18, 0, 0),
      duration.hours(0),
      "UTC",
      False,
    ))
}

pub fn get_time_only_in_utc_zone_test() {
  let db = get_database()
  let ts = timestamp.from_unix_seconds(1_758_086_280)
  assert tzcalendar.to_calendar(ts, "UTC", db)
    == Ok(#(
      calendar.Date(2025, calendar.September, 17),
      calendar.TimeOfDay(5, 18, 0, 0),
    ))
}

pub fn timestamp_from_calendar_test() {
  let db = get_database()
  assert tzcalendar.from_calendar(
      calendar.Date(2025, calendar.January, 23),
      calendar.TimeOfDay(13, 0, 0, 0),
      "America/New_York",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_737_655_200)])
}

pub fn us_daylight_start_test() {
  let db = get_database()
  let dst_start_date = calendar.Date(2025, calendar.March, 9)

  let one = calendar.TimeOfDay(1, 0, 0, 0)
  let one_thirty = calendar.TimeOfDay(1, 30, 0, 0)
  let two = calendar.TimeOfDay(2, 0, 0, 0)
  let two_thirty = calendar.TimeOfDay(2, 30, 0, 0)
  let three = calendar.TimeOfDay(3, 0, 0, 0)
  let three_thirty = calendar.TimeOfDay(3, 30, 0, 0)

  assert tzcalendar.from_calendar(dst_start_date, one, "America/New_York", db)
    == Ok([timestamp.from_unix_seconds(1_741_500_000)])
  assert tzcalendar.from_calendar(
      dst_start_date,
      one_thirty,
      "America/New_York",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_741_501_800)])
  assert tzcalendar.from_calendar(dst_start_date, two, "America/New_York", db)
    == Ok([])
  assert tzcalendar.from_calendar(
      dst_start_date,
      two_thirty,
      "America/New_York",
      db,
    )
    == Ok([])
  assert tzcalendar.from_calendar(dst_start_date, three, "America/New_York", db)
    == Ok([timestamp.from_unix_seconds(1_741_503_600)])
  assert tzcalendar.from_calendar(
      dst_start_date,
      three_thirty,
      "America/New_York",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_741_505_400)])
}

pub fn us_daylight_stop_test() {
  let db = get_database()
  let dst_start_date = calendar.Date(2025, calendar.November, 2)

  let one = calendar.TimeOfDay(1, 0, 0, 0)
  let one_thirty = calendar.TimeOfDay(1, 30, 0, 0)
  let two = calendar.TimeOfDay(2, 0, 0, 0)
  let two_thirty = calendar.TimeOfDay(2, 30, 0, 0)
  let three = calendar.TimeOfDay(3, 0, 0, 0)
  let three_thirty = calendar.TimeOfDay(3, 30, 0, 0)

  assert tzcalendar.from_calendar(dst_start_date, one, "America/New_York", db)
    == Ok([
      timestamp.from_unix_seconds(1_762_059_600),
      timestamp.from_unix_seconds(1_762_063_200),
    ])
  assert tzcalendar.from_calendar(
      dst_start_date,
      one_thirty,
      "America/New_York",
      db,
    )
    == Ok([
      timestamp.from_unix_seconds(1_762_061_400),
      timestamp.from_unix_seconds(1_762_065_000),
    ])
  assert tzcalendar.from_calendar(dst_start_date, two, "America/New_York", db)
    == Ok([timestamp.from_unix_seconds(1_762_066_800)])
  assert tzcalendar.from_calendar(
      dst_start_date,
      two_thirty,
      "America/New_York",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_762_068_600)])
  assert tzcalendar.from_calendar(dst_start_date, three, "America/New_York", db)
    == Ok([timestamp.from_unix_seconds(1_762_070_400)])
  assert tzcalendar.from_calendar(
      dst_start_date,
      three_thirty,
      "America/New_York",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_762_072_200)])
}

pub fn au_daylight_start_test() {
  let db = get_database()
  let dst_start_date = calendar.Date(2025, calendar.October, 5)

  let one = calendar.TimeOfDay(1, 0, 0, 0)
  let one_thirty = calendar.TimeOfDay(1, 30, 0, 0)
  let two = calendar.TimeOfDay(2, 0, 0, 0)
  let two_thirty = calendar.TimeOfDay(2, 30, 0, 0)
  let three = calendar.TimeOfDay(3, 0, 0, 0)
  let three_thirty = calendar.TimeOfDay(3, 30, 0, 0)

  assert tzcalendar.from_calendar(dst_start_date, one, "Australia/Canberra", db)
    == Ok([timestamp.from_unix_seconds(1_759_590_000)])
  assert tzcalendar.from_calendar(
      dst_start_date,
      one_thirty,
      "Australia/Canberra",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_759_591_800)])
  assert tzcalendar.from_calendar(dst_start_date, two, "Australia/Canberra", db)
    == Ok([])
  assert tzcalendar.from_calendar(
      dst_start_date,
      two_thirty,
      "Australia/Canberra",
      db,
    )
    == Ok([])
  assert tzcalendar.from_calendar(
      dst_start_date,
      three,
      "Australia/Canberra",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_759_593_600)])
  assert tzcalendar.from_calendar(
      dst_start_date,
      three_thirty,
      "Australia/Canberra",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_759_595_400)])
}

pub fn au_daylight_stop_test() {
  let db = get_database()
  let dst_start_date = calendar.Date(2025, calendar.April, 6)

  let one = calendar.TimeOfDay(1, 0, 0, 0)
  let one_thirty = calendar.TimeOfDay(1, 30, 0, 0)
  let two = calendar.TimeOfDay(2, 0, 0, 0)
  let two_thirty = calendar.TimeOfDay(2, 30, 0, 0)
  let three = calendar.TimeOfDay(3, 0, 0, 0)
  let three_thirty = calendar.TimeOfDay(3, 30, 0, 0)

  assert tzcalendar.from_calendar(dst_start_date, one, "Australia/Canberra", db)
    == Ok([timestamp.from_unix_seconds(1_743_861_600)])
  assert tzcalendar.from_calendar(
      dst_start_date,
      one_thirty,
      "Australia/Canberra",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_743_863_400)])
  assert tzcalendar.from_calendar(dst_start_date, two, "Australia/Canberra", db)
    == Ok([
      timestamp.from_unix_seconds(1_743_865_200),
      timestamp.from_unix_seconds(1_743_868_800),
    ])
  assert tzcalendar.from_calendar(
      dst_start_date,
      two_thirty,
      "Australia/Canberra",
      db,
    )
    == Ok([
      timestamp.from_unix_seconds(1_743_867_000),
      timestamp.from_unix_seconds(1_743_870_600),
    ])
  assert tzcalendar.from_calendar(
      dst_start_date,
      three,
      "Australia/Canberra",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_743_872_400)])
  assert tzcalendar.from_calendar(
      dst_start_date,
      three_thirty,
      "Australia/Canberra",
      db,
    )
    == Ok([timestamp.from_unix_seconds(1_743_874_200)])
}

pub fn atomic_difference_test() {
  let db = get_database()
  let start = timestamp.from_unix_seconds(0)

  // June 1, 1990 12:00:00 UTC
  let middle = timestamp.from_unix_seconds(644_241_600)

  // Late
  let late = timestamp.from_unix_seconds(1_748_779_200)

  assert tzcalendar.atomic_difference(start, middle, "right/UTC", db)
    == Ok(duration.seconds(644_241_615))

  assert tzcalendar.atomic_difference(start, late, "right/UTC", db)
    == Ok(duration.seconds(1_748_779_227))

  assert tzcalendar.atomic_difference(middle, late, "right/UTC", db)
    == Ok(duration.seconds(1_104_537_612))
}

pub fn atomic_difference_one_second_test() {
  let db = get_database()

  let before =
    timestamp.from_calendar(
      calendar.Date(2016, calendar.December, 31),
      calendar.TimeOfDay(23, 59, 59, 0),
      calendar.utc_offset,
    )
  let after =
    timestamp.from_calendar(
      calendar.Date(2017, calendar.January, 1),
      calendar.TimeOfDay(0, 0, 0, 0),
      calendar.utc_offset,
    )

  assert timestamp.difference(before, after) == duration.seconds(1)

  assert tzcalendar.atomic_difference(before, after, "right/UTC", db)
    == Ok(duration.seconds(2))
}
