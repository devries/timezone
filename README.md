# tzif

[![Package Version](https://img.shields.io/hexpm/v/tzif)](https://hex.pm/packages/tzif)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/tzif/)

Time zone support for Gleam time using the IANA Time Zone Database.
This package loads the time zone database from the standard location
(`/usr/share/zoneinfo`) on MacOS and Linux computers. It includes a parser for
the Time Zone Information Format (TZif) or `tzfile` format, as well as utility
functions to convert a timestamp from the
[gleam_time](https://hexdocs.pm/gleam_time/) library into a date and time
of day in the given time zone.

> We could really do with a timezone database package with a
> fn(Timestamp, Zone) -> #(Date, TimeOfDay) function
>
> --- Louis Pilfold

Add to your project with the command:
```
gleam add tzif@1
```

# Using the Package
There are three modules in the `tzif` package:
- `tzif/database` has utilities for loading the IANA Time Zone database.
- `tzif/tzcalendar` has utilities for converting a [gleam_time](https://hexdocs.pm/gleam_time/)
  timestamp into date and time of day in a time zone.
- `tzif/parser` has functions and records for parsing TZif formatted data.

The most straightforward use would be to load the database from the default
location on the operating system, and then obtain a timestamp using the
[gleam_time](https://hexdocs.pm/gleam_time/) package, and convert that timestamp
into a time of day in a time zone using the IANA time zone name. An example
of that is shown in the code below.

```gleam
import gleam/int
import gleam/io
import gleam/string
import gleam/time/timestamp
import tzif/database
import tzif/tzcalendar

pub fn main() {
    let now = timestamp.system_time()

    // Load the database from the operating system
    case database.load_from_os() {
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
If you are on windows and have installed the IANA Time Zone Database, or want
to use a custom version you can use the `database.load_from_path` function
instead of the `database.load_from_os` function to specify a path to your
database files.

# Installing the zoneinfo data files
Time zone information is frequently updated, therefore it makes sense to use the
package manager for your operating system to keep the time zone database up to
date. All common unix variants have time zone database packages and install the
time zone database files into the `/usr/share/zoneinfo` directory by default.

## MacOS
The files should be included in your operating system by default. Check the
`/usr/share/zoneinfo` directory and see if they are present.

## Ubuntu/Debian Linux Systems
The APT package manager can be used to install the compiled TZif files with the
following command:

```
sudo apt install tzdata
```

### Debian based docker containers
Installing and configuring the time zone database on a Debian or Ubuntu based
docker container can be done by adding the following to your `Dockerfile`:

```
# Use an ARG for the timezone, with a default of UTC
ARG TIMEZONE=Etc/UTC

# Set the TZ environment variable and install tzdata
RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    ln -fs /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    apt-get install -y tzdata && \
    dpkg-reconfigure --frontend noninteractive tzdata
```

## Alpine Linux Systems
The Alpine Package Keeper can install the time zone database using the command:

```
sudo apk add tzdata
```

### Alpine based docker containers
Installing and configuring the time zone database on an Alpine based docker
container can be done by adding the following to your `Dockerfile`:

```
# Use an ARG for the timezone, with a default of UTC
ARG TIMEZONE=Etc/UTC

# 1. Install the tzdata package
# 2. Copy the correct timezone file to /etc/localtime
# 3. Set the TZ environment variable to be used by applications
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone
```

## Red Hat/Rocky/Alma Linux Systems
You can use the YUM package manager or DNF to install the time zone database
on Red Hat variants. To use YUM run the command:

```
sudo yum install tzdata
```

Similarly, using DNF:

```
sudo dnf install tzdata
```
## Windows
Microsoft Windows has a different mechanism for handling time zones, however
you can install the IANA Time Zone Database by [downloading the latest
version](https://www.iana.org/time-zones) and compiling the zone files using
[the directions in the repository](https://data.iana.org/time-zones/tz-link.html).
