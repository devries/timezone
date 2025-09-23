## Upcoming
- Add `tzcalendar.atomic_difference` to calculate the actual difference between
  two timestamps including leap seconds.
- Add a `tzcalendar.from_calendar` function. Test shifts around daylight savings
  time.
- Fixed an issue with the time zone change where comparisons of the timestamp to
  the transition times with a greater than, and it should have been greater than
  or equal to.

## v1.0.1 - 2025-09-23
- Fix bug where the library will crash if asked to load Time Zone information
  from a nonexistant directory.
  
## v1.0.0 - 2025-09-21
- Initial release
- Exposes parser as a module
- Adds support for leap seconds
- Explicit loading of time zone database into an opaque record
- Completely overhauled API

## v0.1.0 - 2025-09-17
- Initial proof of concept.
