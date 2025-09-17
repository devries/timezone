# timezone

<!--#
[![Package Version](https://img.shields.io/hexpm/v/timezone)](https://hex.pm/packages/timezone)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/timezone/)
-->

> We could really do with a timezone database package with a
> fn(Timestamp, Zone) -> #(Date, TimeOfDay) function
>
> --- Louis Pilfold

To use, add the following entry in your `gleam.toml` file dependencies:

```
timezone = { git = "git@github.com:devries/timezone.git", ref = "main" }
```

A timezone library which uses your local ZONEINFO files to convert
`timestamp.Timestamp` values into dates and times of day.

Further documentation can be found at <https://hexdocs.pm/timezone>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
