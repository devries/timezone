import gleam/bit_array
import gleam/list
import tzif/tzparser

const tzsample = "VFppZjIAAAAAAAAAAAAAAAAAAAAAAAAGAAAABgAAAAAAAADsAAAABgAAABSAAAAAnqYecJ+662CghgBwoZrNYKJl4nCjg+ngpGqucKU1p2CmU8rwpxWJYKgzrPCo/qXgqhOO8Kreh+Cr83DwrL5p4K3TUvCunkvgr7M08LB+LeCxnFFwsmdKYLN8M3C0RyxgtVwVcLYnDmC3O/dwuAbwYLkb2XC55tJguwT18LvGtGC85Nfwva/Q4L7EufC/j7LgwKSb8MFvlODChH3ww0924MRkX/DFL1jgxk18cMcPOuDILV5wyPhXYMoNQHDK2Dlgy4jwcNIj9HDSYPvg03Xk8NRA3eDVVcbw1iC/4Nc1qPDYAKHg2RWK8Nngg+Da/qdw28Bl4NzeiXDdqYJg3r5rcN+JZGDgnk1w4WlGYOJ+L3DjSShg5F4RcOVXLuDmRy3w5zcQ4OgnD/DpFvLg6gbx8Or21ODr5tPw7Na24O3GtfDuv9Ng76/ScPCftWDxj7Rw8n+XYPNvlnD0X3lg9U94cPY/W2D3L1pw+Ch34PkPPHD6CFng+vhY8PvoO+D82Drw/cgd4P64HPD/p//gAJf+8AGH4eACd+DwA3D+YARg/XAFUOBgBkDfcAcwwmAHjRlwCRCkYAmtlPAK8IZgC+CFcAzZouANwGdwDrmE4A+pg/AQmWbgEYll8BJ5SOATaUfwFFkq4BVJKfAWOQzgFykL8BgiKWAZCO3wGgILYBryCnAb4e1gHNHscB3Bz2Aesc5wH6GxYCB2APAhgZNgIlXi8CNqr+AkNcTwJUqR4CYVpvAnKnPgJ/7DcCkKVeAp3qVwKuo34Cu+h3As01RgLZ5pcC6zNmAvfktwMJMYYDFnZ/AycvpgM0dJ8DRS3GA1JyvwNjK+YDcHDfA4G9rgOObv8Dn7vOA6xtHwO9ue4Dyv7nA9u4DgPo/QcD+bYuBAb7JwQYR/YEJPlHBDZGFgRC92cEVEQ2BF86jwRy1f4EfTivBJDUHgSbNs8ErtI+BLnIlwTNZAYE18a3BOtiJgT1xNcFCWBGBRPC9wUnXmYFMcEXBUVchgVPvzcFY1qmBW5Q/wWB7G4FjE8fBZ/qjgWqTT8FveiuBchLXwXb5s4F5kl/Bfnk7gYE20cGGHa2BiLZZwY2dNYGQNeHBlRy9gZe1acGcnEWBnzTxwaQbzYGmtHnBq5tVga5Y68GzP8eBtdhzwbq/T4G9V/vBwj7XgcTXg8HJvl+BzFcLwdE954HT+33B2OJZgdt7BcHgYeGB4vqNwefhaYHqehXB72DxgfH5ncH24HmB+Xklwf5gAYAMBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIEBQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgEC//+6ngAA///HwAEE//+5sAAI//+5sAAI///HwAEM///HwAEQTE1UAEVEVABFU1QARVdUAEVQVAAAAAABAAEAAAABAAFUWmlmMgAAAAAAAAAAAAAAAAAAAAAAAAYAAAAGAAAAAAAAAOwAAAAGAAAAFP////9eA/CQ/////56mHnD/////n7rrYP////+ghgBw/////6GazWD/////omXicP////+jg+ng/////6RqrnD/////pTWnYP////+mU8rw/////6cViWD/////qDOs8P////+o/qXg/////6oTjvD/////qt6H4P////+r83Dw/////6y+aeD/////rdNS8P////+unkvg/////6+zNPD/////sH4t4P////+xnFFw/////7JnSmD/////s3wzcP////+0Ryxg/////7VcFXD/////ticOYP////+3O/dw/////7gG8GD/////uRvZcP////+55tJg/////7sE9fD/////u8a0YP////+85Nfw/////72v0OD/////vsS58P////+/j7Lg/////8Ckm/D/////wW+U4P/////ChH3w/////8NPduD/////xGRf8P/////FL1jg/////8ZNfHD/////xw864P/////ILV5w/////8j4V2D/////yg1AcP/////K2Dlg/////8uI8HD/////0iP0cP/////SYPvg/////9N15PD/////1EDd4P/////VVcbw/////9Ygv+D/////1zWo8P/////YAKHg/////9kVivD/////2eCD4P/////a/qdw/////9vAZeD/////3N6JcP/////dqYJg/////96+a3D/////34lkYP/////gnk1w/////+FpRmD/////4n4vcP/////jSShg/////+ReEXD/////5Vcu4P/////mRy3w/////+c3EOD/////6CcP8P/////pFvLg/////+oG8fD/////6vbU4P/////r5tPw/////+zWtuD/////7ca18P/////uv9Ng/////++v0nD/////8J+1YP/////xj7Rw//////J/l2D/////82+WcP/////0X3lg//////VPeHD/////9j9bYP/////3L1pw//////god+D/////+Q88cP/////6CFng//////r4WPD/////++g74P/////82Drw//////3IHeD//////rgc8P//////p//gAAAAAACX/vAAAAAAAYfh4AAAAAACd+DwAAAAAANw/mAAAAAABGD9cAAAAAAFUOBgAAAAAAZA33AAAAAABzDCYAAAAAAHjRlwAAAAAAkQpGAAAAAACa2U8AAAAAAK8IZgAAAAAAvghXAAAAAADNmi4AAAAAANwGdwAAAAAA65hOAAAAAAD6mD8AAAAAAQmWbgAAAAABGJZfAAAAAAEnlI4AAAAAATaUfwAAAAABRZKuAAAAAAFUkp8AAAAAAWOQzgAAAAABcpC/AAAAAAGCIpYAAAAAAZCO3wAAAAABoCC2AAAAAAGvIKcAAAAAAb4e1gAAAAABzR7HAAAAAAHcHPYAAAAAAesc5wAAAAAB+hsWAAAAAAIHYA8AAAAAAhgZNgAAAAACJV4vAAAAAAI2qv4AAAAAAkNcTwAAAAACVKkeAAAAAAJhWm8AAAAAAnKnPgAAAAACf+w3AAAAAAKQpV4AAAAAAp3qVwAAAAACrqN+AAAAAAK76HcAAAAAAs01RgAAAAAC2eaXAAAAAALrM2YAAAAAAvfktwAAAAADCTGGAAAAAAMWdn8AAAAAAycvpgAAAAADNHSfAAAAAANFLcYAAAAAA1JyvwAAAAADYyvmAAAAAANwcN8AAAAAA4G9rgAAAAADjm7/AAAAAAOfu84AAAAAA6xtHwAAAAADvbnuAAAAAAPK/ucAAAAAA9u4DgAAAAAD6P0HAAAAAAP5ti4AAAAABAb7JwAAAAAEGEf2AAAAAAQk+UcAAAAABDZGFgAAAAAEQvdnAAAAAARURDYAAAAABF86jwAAAAAEctX+AAAAAAR9OK8AAAAABJDUHgAAAAAEmzbPAAAAAASu0j4AAAAABLnIlwAAAAAEzWQGAAAAAATXxrcAAAAABOtiJgAAAAAE9cTXAAAAAAUJYEYAAAAABRPC9wAAAAAFJ15mAAAAAAUxwRcAAAAABUVchgAAAAAFT783AAAAAAVjWqYAAAAABW5Q/wAAAAAFgexuAAAAAAWMTx8AAAAABZ/qjgAAAAAFqk0/AAAAAAW96K4AAAAABchLXwAAAAAF2+bOAAAAAAXmSX8AAAAABfnk7gAAAAAGBNtHAAAAAAYYdrYAAAAABiLZZwAAAAAGNnTWAAAAAAZA14cAAAAABlRy9gAAAAAGXtWnAAAAAAZycRYAAAAABnzTxwAAAAAGkG82AAAAAAaa0ecAAAAABq5tVgAAAAAGuWOvAAAAAAbM/x4AAAAABtdhzwAAAAAG6v0+AAAAAAb1X+8AAAAABwj7XgAAAAAHE14PAAAAAAcm+X4AAAAABzFcLwAAAAAHRPeeAAAAAAdP7fcAAAAAB2OJZgAAAAAHbewXAAAAAAeBh4YAAAAAB4vqNwAAAAAHn4WmAAAAAAep6FcAAAAAB72DxgAAAAAHx+Z3AAAAAAfbgeYAAAAAB+XklwAAAAAH+YAGADAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECBAUCAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAgECAQIBAv//up4AAP//x8ABBP//ubAACP//ubAACP//x8ABDP//x8ABEExNVABFRFQARVNUAEVXVABFUFQAAAAAAQABAAAAAQABCkVTVDVFRFQsTTMuMi4wLE0xMS4xLjAK"

const tzsample2 = "VFppZjIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAQAAAAAAABVVEMAVFppZjIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAQAAAAAAABVVEMAClVUQzAK"

const right_utc_sample = "VFppZjIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABsAAAABAAAAAQAAAARqQGQbAAAAAAAAAFVUQwAEslgAAAAAAQWk7AEAAAACB4YfggAAAAMJZ1MDAAAABAtIhoQAAAAFDSsLhQAAAAYPDD8GAAAABxDtcocAAAAIEs6mCAAAAAkVn8qJAAAACheA/goAAAALGWIxiwAAAAwdJeoMAAAADSHa5Q0AAAAOJZ6djgAAAA8nf9EPAAAAECpQ9ZAAAAARLDIpEQAAABIuE1ySAAAAEzDnJBMAAAAUM7hIlAAAABU2jBAVAAAAFkO3G5YAAAAXSVwHlwAAABhP75MYAAAAGVWTLZkAAAAaWGhGmgAAABtUWmlmMgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGwAAAAEAAAABAAAABAAAAABqQGQbAAAAAAAAAFVUQwAAAAAABLJYAAAAAAEAAAAABaTsAQAAAAIAAAAAB4YfggAAAAMAAAAACWdTAwAAAAQAAAAAC0iGhAAAAAUAAAAADSsLhQAAAAYAAAAADww/BgAAAAcAAAAAEO1yhwAAAAgAAAAAEs6mCAAAAAkAAAAAFZ/KiQAAAAoAAAAAF4D+CgAAAAsAAAAAGWIxiwAAAAwAAAAAHSXqDAAAAA0AAAAAIdrlDQAAAA4AAAAAJZ6djgAAAA8AAAAAJ3/RDwAAABAAAAAAKlD1kAAAABEAAAAALDIpEQAAABIAAAAALhNckgAAABMAAAAAMOckEwAAABQAAAAAM7hIlAAAABUAAAAANowQFQAAABYAAAAAQ7cblgAAABcAAAAASVwHlwAAABgAAAAAT++TGAAAABkAAAAAVZMtmQAAABoAAAAAWGhGmgAAABsKCg=="

fn get_ny_tzfile() -> BitArray {
  let assert Ok(data) = bit_array.base64_decode(tzsample)
  data
}

fn get_utc_tzfile() -> BitArray {
  let assert Ok(data) = bit_array.base64_decode(tzsample2)
  data
}

fn get_right_utc_tzfile() -> BitArray {
  let assert Ok(data) = bit_array.base64_decode(right_utc_sample)
  data
}

pub fn new_york_header_test() {
  let assert Ok(tzdata) =
    get_ny_tzfile()
    |> tzparser.parse

  assert tzdata.header == tzparser.TzFileHeader(2, 6, 6, 0, 236, 6, 20)
}

pub fn utc_header_test() {
  let assert Ok(tzdata) =
    get_utc_tzfile()
    |> tzparser.parse

  assert tzdata.header == tzparser.TzFileHeader(2, 0, 0, 0, 0, 1, 4)
}

pub fn right_utc_header_test() {
  let assert Ok(tzdata) =
    get_right_utc_tzfile()
    |> tzparser.parse

  assert tzdata.header == tzparser.TzFileHeader(2, 0, 0, 27, 1, 1, 4)
}

pub fn new_york_field_test() {
  let assert Ok(tzdata) =
    get_ny_tzfile()
    |> tzparser.parse

  assert list.length(tzdata.fields.transition_times) == 236
  assert list.length(tzdata.fields.time_types) == 236
  assert tzdata.fields.ttinfos
    == [
      tzparser.TtInfo(-17_762, 0, 0),
      tzparser.TtInfo(-14_400, 1, 4),
      tzparser.TtInfo(-18_000, 0, 8),
      tzparser.TtInfo(-18_000, 0, 8),
      tzparser.TtInfo(-14_400, 1, 12),
      tzparser.TtInfo(-14_400, 1, 16),
    ]
  assert tzdata.fields.designations
    == ["LMT", "EDT", "EST", "EST", "EWT", "EPT"]
  assert tzdata.fields.leapsecond_values == []
  assert tzdata.fields.standard_or_wall == [0, 0, 0, 1, 0, 1]
  assert tzdata.fields.ut_or_local == [0, 0, 0, 1, 0, 1]
}

pub fn utc_field_test() {
  let assert Ok(tzdata) =
    get_utc_tzfile()
    |> tzparser.parse

  assert tzdata.fields.transition_times == []
  assert tzdata.fields.time_types == []
  assert tzdata.fields.ttinfos
    == [
      tzparser.TtInfo(0, 0, 0),
    ]
  assert tzdata.fields.designations == ["UTC"]
  assert tzdata.fields.leapsecond_values == []
  assert tzdata.fields.standard_or_wall == []
  assert tzdata.fields.ut_or_local == []
}

pub fn right_utc_field_test() {
  let assert Ok(tzdata) =
    get_right_utc_tzfile()
    |> tzparser.parse

  assert tzdata.fields.transition_times == [1_782_604_827]
  assert tzdata.fields.time_types == [0]
  assert tzdata.fields.ttinfos
    == [
      tzparser.TtInfo(0, 0, 0),
    ]
  assert tzdata.fields.designations == ["UTC"]
  assert tzdata.fields.leapsecond_values
    == [
      #(78_796_800, 1),
      #(94_694_401, 2),
      #(126_230_402, 3),
      #(157_766_403, 4),
      #(189_302_404, 5),
      #(220_924_805, 6),
      #(252_460_806, 7),
      #(283_996_807, 8),
      #(315_532_808, 9),
      #(362_793_609, 10),
      #(394_329_610, 11),
      #(425_865_611, 12),
      #(489_024_012, 13),
      #(567_993_613, 14),
      #(631_152_014, 15),
      #(662_688_015, 16),
      #(709_948_816, 17),
      #(741_484_817, 18),
      #(773_020_818, 19),
      #(820_454_419, 20),
      #(867_715_220, 21),
      #(915_148_821, 22),
      #(1_136_073_622, 23),
      #(1_230_768_023, 24),
      #(1_341_100_824, 25),
      #(1_435_708_825, 26),
      #(1_483_228_826, 27),
    ]
  assert tzdata.fields.standard_or_wall == []
  assert tzdata.fields.ut_or_local == []
}
