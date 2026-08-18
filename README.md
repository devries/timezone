# tzif

[![Package Version](https://img.shields.io/hexpm/v/tzif)](https://hex.pm/packages/tzif)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/tzif/)

Time zone support for Gleam time using the IANA Time Zone Database format.
This package includes a parser for the Time Zone Information Format (TZif) or
`tzfile` format, as well as utility functions to convert a timestamp from the
[gleam_time](https://hexdocs.pm/gleam_time/) library into a date and time of day
in the given time zone.

There are two ways to obtain the timezone data:
- The [gleam_time](https://gleam-time.hexdocs.pm/) package maintains up to date
    time zone data in a native gleam package format. This is the recommended
    method for code running in the browser, docker containers, and the Windows
    operating system.
- The [tzif_loader](https://tzif-loader.hexdocs.pm/) package will load the
    operating system default time zone files from their standard location in
    Linux and MacOS operating systems.

> We could really do with a timezone database package with a
> fn(Timestamp, Zone) -> #(Date, TimeOfDay) function
>
> --- Louis Pilfold

Add to your project with the command:
```
gleam add tzif@2
```

# Using the Package
There are three modules in the `tzif` package:
- `tzif/database` has utilities for managing the IANA Time Zone database.
- `tzif/tzcalendar` has utilities for converting a [gleam_time](https://gleam-time.hexdocs.pm/)
  timestamp into date and time of day in a time zone.
- `tzif/parser` has functions and records for parsing TZif formatted data.

Below is an example of code which loads the native time zone data from the
operating system using [tzif_loader](https://tzif-loader.hexdocs.pm/) and
converts the system time to a time of day in the America/New_York time zone.

```gleam
import gleam/int
import gleam/io
import gleam/string
import gleam/time/timestamp
import tzif/database
import tzif/loader
import tzif/tzcalendar

pub fn main() {
    let now = timestamp.system_time()

    // Load the database from the operating system
    case loader.load_from_os() {
        Ok(db) -> {
            case tzcalendar.to_time_and_zone(now, "America/New_York", db) {
                Ok(time_and_zone) -> {
                    // Successfully converted time to the requested time zone
                    io.println(
                        int.to_string(time_and_zone.time_of_day.hours)
                        |> string.pad_start(2, "0")
                        <> ":"
                        <> int.to_string(time_and_zone.time_of_day.minutes)
                        |> string.pad_start(2, "0")
                        <> ":"
                        <> int.to_string(time_and_zone.time_of_day.seconds)
                        |> string.pad_start(2, "0")
                        <> " "
                        <> time_and_zone.designation
                    )
                }
                Error(database.ZoneNotFound) -> io.println("Time zone not found")
                Error(database.ProcessingError) ->
                    io.println("Error processing time zone conversion")
            }
        }
        Error(Nil) -> io.println("No parsable TZif files found.")
}
```
