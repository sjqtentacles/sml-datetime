# sml-datetime

[![CI](https://github.com/sjqtentacles/sml-datetime/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-datetime/actions/workflows/ci.yml)

Civil (proleptic Gregorian) date arithmetic for Standard ML: leap years, day
counting, epoch-day conversion, day-of-week, and ISO-8601 parsing/formatting.

`sml-datetime` is timezone-free, I/O-free, and deterministic. A `date` is a
plain `{ year, month, day }` record. Conversions use Howard Hinnant's
branch-free days-from-civil algorithm, so there is no runtime dependency on the
host's `Date`/`Time` structures, and the arithmetic is exact for any year
(including pre-1970 dates, which have negative epoch days).

## Portability

Pure Standard ML using only the Basis library -- no FFI, no threads. Verified
on **MLton** and **Poly/ML**.

## Building and testing

```sh
make test        # build + run the suite under MLton (default)
make test-poly   # run the suite under Poly/ML
make all-tests   # run under both
make clean
```

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-datetime
smlpkg sync
```

Then reference the library basis from your own `.mlb`:

```
lib/github.com/sjqtentacles/sml-datetime/datetime.mlb
```

For Poly/ML, `use` the `datetime.sig` and `datetime.sml` sources in order.

## Usage

```sml
val leap = DateTime.isLeapYear 2024            (* true  *)
val dim  = DateTime.daysInMonth (2024, 2)      (* 29    *)

val day  = DateTime.toEpochDay {year=2000, month=1, day=1}   (* 10957 *)
val back = DateTime.fromEpochDay 0             (* {year=1970,month=1,day=1} *)

val nye  = DateTime.addDays {year=2023, month=12, day=31} 1  (* 2024-01-01 *)
val span = DateTime.diffDays ({year=2025,month=1,day=1},
                              {year=2024,month=1,day=1})     (* 366 *)

val dow  = DateTime.dayOfWeek {year=1970, month=1, day=1}    (* 4 = Thursday *)

val iso  = DateTime.formatISO {year=2024, month=2, day=29}   (* "2024-02-29" *)
val SOME dt = DateTime.parseISO "2024-02-29"
val NONE    = DateTime.parseISO "2023-02-29"   (* not a real date *)
```

`dayOfWeek` returns `0 = Sunday .. 6 = Saturday`. Invalid dates raise
`DateTime.Invalid` from `toEpochDay`/`daysInMonth` and yield `NONE`/`false`
from `parseISO`/`isValid`.

## API summary

| Function | Description |
| --- | --- |
| `isLeapYear : int -> bool` | Gregorian leap-year test. |
| `daysInMonth : int * int -> int` | Days in `(year, month)`. |
| `isValid : date -> bool` | Whether a date is well-formed. |
| `toEpochDay : date -> int` | Days since 1970-01-01. |
| `fromEpochDay : int -> date` | Inverse of `toEpochDay`. |
| `addDays : date -> int -> date` | Shift by N days (may be negative). |
| `diffDays : date * date -> int` | Difference `a - b` in days. |
| `dayOfWeek : date -> int` | `0 = Sunday .. 6 = Saturday`. |
| `parseISO : string -> date option` | Strict `YYYY-MM-DD`. |
| `formatISO : date -> string` | Zero-padded `YYYY-MM-DD`. |

## License

MIT. See [LICENSE](LICENSE).
