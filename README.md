# timezone

<!--#
[![Package Version](https://img.shields.io/hexpm/v/timezone)](https://hex.pm/packages/timezone)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/timezone/)
-->

This package can be used to load the timezone database from the standard location
(`/usr/share/zoneinfo`) on MacOS and Linux computers. It includes a parser for
the `tzfile` format, as well as a utility functions to convert a timestamp from
the [gleam_time](https://hexdocs.pm/gleam_time/) library into a date and time
of day in the given timezone.

> We could really do with a timezone database package with a
> fn(Timestamp, Zone) -> #(Date, TimeOfDay) function
>
> --- Louis Pilfold

To use, add the following entry in your `gleam.toml` file dependencies:

```
timezone = { git = "git@github.com:devries/timezone.git", ref = "main" }
```
# Installing the zoneinfo data files

## MacOS
The files should be included in your operating system by default. Check the
`/usr/share/zoneinfo` directory and see if they are present.

## Ubuntu/Debian Linux Systems

## Alpine Linux Systems

## Red Hat/Rocky/Alma Linux Systems

## Windows
At this time we have not tested the windows operating system.
