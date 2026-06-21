(* Dependency-free test runner for the DateTime structure.
 * Prints one line per assertion and exits non-zero if any assertion fails. *)

val passed = ref 0
val failed = ref 0

fun check (name : string) (cond : bool) : unit =
    if cond
    then (passed := !passed + 1; print ("ok   - " ^ name ^ "\n"))
    else (failed := !failed + 1; print ("FAIL - " ^ name ^ "\n"))

fun raisesInvalid (thunk : unit -> 'a) : bool =
    (ignore (thunk ()); false)
    handle DateTime.Invalid _ => true | _ => false

structure D = DateTime

fun d (y, m, dd) = {year = y, month = m, day = dd}

fun run () =
  let
    (* ---- leap years ---- *)
    val () = check "2000 is leap" (D.isLeapYear 2000)
    val () = check "1900 not leap" (not (D.isLeapYear 1900))
    val () = check "2024 is leap" (D.isLeapYear 2024)
    val () = check "2023 not leap" (not (D.isLeapYear 2023))
    val () = check "2100 not leap" (not (D.isLeapYear 2100))
    val () = check "1600 is leap" (D.isLeapYear 1600)

    (* ---- daysInMonth ---- *)
    val () = check "Jan 31" (D.daysInMonth (2023, 1) = 31)
    val () = check "Feb 28 non-leap" (D.daysInMonth (2023, 2) = 28)
    val () = check "Feb 29 leap" (D.daysInMonth (2024, 2) = 29)
    val () = check "Feb 28 century non-leap" (D.daysInMonth (1900, 2) = 28)
    val () = check "Apr 30" (D.daysInMonth (2023, 4) = 30)
    val () = check "Dec 31" (D.daysInMonth (2023, 12) = 31)
    val () = check "bad month raises" (raisesInvalid (fn () => D.daysInMonth (2023, 13)))

    (* ---- isValid ---- *)
    val () = check "valid date" (D.isValid (d (2024, 2, 29)))
    val () = check "invalid Feb 29 non-leap" (not (D.isValid (d (2023, 2, 29))))
    val () = check "invalid month 0" (not (D.isValid (d (2023, 0, 1))))
    val () = check "invalid month 13" (not (D.isValid (d (2023, 13, 1))))
    val () = check "invalid day 0" (not (D.isValid (d (2023, 1, 0))))
    val () = check "invalid day 32" (not (D.isValid (d (2023, 1, 32))))
    val () = check "invalid Apr 31" (not (D.isValid (d (2023, 4, 31))))

    (* ---- epoch day known values ---- *)
    val () = check "epoch day 1970-01-01 = 0" (D.toEpochDay (d (1970, 1, 1)) = 0)
    val () = check "epoch day 1970-01-02 = 1" (D.toEpochDay (d (1970, 1, 2)) = 1)
    val () = check "epoch day 1969-12-31 = ~1" (D.toEpochDay (d (1969, 12, 31)) = ~1)
    val () = check "epoch day 2000-01-01 = 10957" (D.toEpochDay (d (2000, 1, 1)) = 10957)
    val () = check "epoch day 2024-02-29" (D.toEpochDay (d (2024, 2, 29)) = 19782)
    val () = check "toEpochDay invalid raises"
                   (raisesInvalid (fn () => D.toEpochDay (d (2023, 2, 29))))

    (* ---- fromEpochDay round-trip over a wide range ---- *)
    val () = check "fromEpochDay 0" (D.fromEpochDay 0 = d (1970, 1, 1))
    val () = check "fromEpochDay ~1" (D.fromEpochDay ~1 = d (1969, 12, 31))
    val roundtripOk =
        let
          (* check every ~37 days from 1800-01-01 to ~2200 *)
          val start = D.toEpochDay (d (1800, 1, 1))
          val stop  = D.toEpochDay (d (2200, 12, 31))
          fun loop e =
              if e > stop then true
              else D.toEpochDay (D.fromEpochDay e) = e andalso loop (e + 37)
        in loop start end
    val () = check "epochDay round-trip 1800..2200 (step 37)" roundtripOk

    (* ---- addDays / diffDays ---- *)
    val () = check "addDays simple" (D.addDays (d (2023, 1, 1)) 31 = d (2023, 2, 1))
    val () = check "addDays across year" (D.addDays (d (2023, 12, 31)) 1 = d (2024, 1, 1))
    val () = check "addDays across leap day"
                   (D.addDays (d (2024, 2, 28)) 1 = d (2024, 2, 29))
    val () = check "addDays skips non-leap Feb 29"
                   (D.addDays (d (2023, 2, 28)) 1 = d (2023, 3, 1))
    val () = check "addDays negative" (D.addDays (d (2024, 1, 1)) ~1 = d (2023, 12, 31))
    val () = check "addDays 365 non-leap" (D.addDays (d (2023, 1, 1)) 365 = d (2024, 1, 1))
    val () = check "addDays 366 over leap" (D.addDays (d (2024, 1, 1)) 366 = d (2025, 1, 1))
    val () = check "addDays zero is identity" (D.addDays (d (2023, 6, 15)) 0 = d (2023, 6, 15))

    val () = check "diffDays one day" (D.diffDays (d (2023, 1, 2), d (2023, 1, 1)) = 1)
    val () = check "diffDays negative" (D.diffDays (d (2023, 1, 1), d (2023, 1, 2)) = ~1)
    val () = check "diffDays leap year span"
                   (D.diffDays (d (2025, 1, 1), d (2024, 1, 1)) = 366)
    val () = check "diffDays non-leap span"
                   (D.diffDays (d (2024, 1, 1), d (2023, 1, 1)) = 365)
    val () = check "diffDays self is 0" (D.diffDays (d (2023, 5, 5), d (2023, 5, 5)) = 0)

    (* ---- dayOfWeek (0 = Sunday) ---- *)
    val () = check "1970-01-01 is Thursday (4)" (D.dayOfWeek (d (1970, 1, 1)) = 4)
    val () = check "2000-01-01 is Saturday (6)" (D.dayOfWeek (d (2000, 1, 1)) = 6)
    val () = check "2024-02-29 is Thursday (4)" (D.dayOfWeek (d (2024, 2, 29)) = 4)
    val () = check "2023-12-25 is Monday (1)" (D.dayOfWeek (d (2023, 12, 25)) = 1)
    val () = check "1969-12-31 is Wednesday (3)" (D.dayOfWeek (d (1969, 12, 31)) = 3)

    (* ---- ISO format ---- *)
    val () = check "formatISO basic" (D.formatISO (d (2024, 2, 29)) = "2024-02-29")
    val () = check "formatISO pads" (D.formatISO (d (1, 1, 1)) = "0001-01-01")
    val () = check "formatISO zero-pad month/day" (D.formatISO (d (2023, 7, 4)) = "2023-07-04")

    (* ---- ISO parse ---- *)
    val () = check "parseISO basic" (D.parseISO "2024-02-29" = SOME (d (2024, 2, 29)))
    val () = check "parseISO round-trip"
                   (D.parseISO (D.formatISO (d (2023, 7, 4))) = SOME (d (2023, 7, 4)))
    val () = check "parseISO rejects invalid date" (D.parseISO "2023-02-29" = NONE)
    val () = check "parseISO rejects bad month" (D.parseISO "2023-13-01" = NONE)
    val () = check "parseISO rejects wrong separators" (D.parseISO "2023/01/01" = NONE)
    val () = check "parseISO rejects short month" (D.parseISO "2023-1-01" = NONE)
    val () = check "parseISO rejects non-numeric" (D.parseISO "20xx-01-01" = NONE)
    val () = check "parseISO rejects empty" (D.parseISO "" = NONE)
    val () = check "parseISO rejects garbage" (D.parseISO "hello" = NONE)
    val () = check "parseISO rejects extra field" (D.parseISO "2023-01-01-01" = NONE)

    (* format/parse round-trip across many dates *)
    val fmtRoundtripOk =
        let
          val start = D.toEpochDay (d (1950, 1, 1))
          val stop  = D.toEpochDay (d (2050, 12, 31))
          fun loop e =
              if e > stop then true
              else
                let val dt = D.fromEpochDay e
                in (D.parseISO (D.formatISO dt) = SOME dt) andalso loop (e + 53) end
        in loop start end
    val () = check "format/parse ISO round-trip 1950..2050 (step 53)" fmtRoundtripOk
  in
    print ("\n" ^ Int.toString (!passed) ^ " passed, "
           ^ Int.toString (!failed) ^ " failed\n");
    OS.Process.exit (if !failed = 0 then OS.Process.success else OS.Process.failure)
  end

val () = run ()
