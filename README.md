# timezone

<!--#
[![Package Version](https://img.shields.io/hexpm/v/timezone)](https://hex.pm/packages/timezone)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/timezone/)
-->

Timezone support for Gleam time using the operating system's timezone database.
This package loads the timezone database from the standard location
(`/usr/share/zoneinfo`) on MacOS and Linux computers. It includes a parser for
the Time Zone Information Format (TZif) or `tzfile` format, as well as utility
functions to convert a timestamp from the
[gleam_time](https://hexdocs.pm/gleam_time/) library into a date and time
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
Timezone information is frequently updated, therefore it makes sense to use the
package manager for your operating system to keep the timezone database up to
date. All common unix variants have timezone database packages and install the
timezone database files into the `/usr/share/zoneinfo` directory by default.

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
Installing and configuring the timezone database on a Debian or Ubuntu based
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
The Alpine Package Keeper can install the timezone database using the command:

```
sudo apk add tzdata
```

### Alpine based docker containers
Installing and configuring the timezone database on an Alpine based docker
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
You can use the YUM package manager or DNF to install the timezone database
on Red Hat variants. To use YUM run the command:

```
sudo yum install tzdata
```

Similarly, using DNF:

```
sudo dnf install tzdata
```
## Windows
At this time we have not tested the windows operating system.
