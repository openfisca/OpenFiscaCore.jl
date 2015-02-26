# OpenFisca -- A versatile microsimulation software
# By: OpenFisca Team <contact@openfisca.fr>
#
# Copyright (C) 2011, 2012, 2013, 2014, 2015 OpenFisca Team
# https://github.com/openfisca
#
# This file is part of OpenFisca.
#
# OpenFisca is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# OpenFisca is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


abstract DatePeriod


immutable DayPeriod <: DatePeriod
  start::Date
  length::Unsigned
end

DayPeriod(start::Integer, length) = DayPeriod(Date(start), length)
DayPeriod(start) = DayPeriod(start, 1)


type EmptyPeriod <: DatePeriod
end


immutable MonthPeriod <: DatePeriod
  start::Date
  length::Unsigned
end

MonthPeriod(start::Integer, length) = MonthPeriod(Date(start), length)
MonthPeriod(start) = MonthPeriod(start, 1)


immutable YearPeriod <: DatePeriod
  start::Date
  length::Unsigned
end

YearPeriod(start::Integer, length) = YearPeriod(Date(start), length)
YearPeriod(start) = YearPeriod(start, 1)


+(period::DatePeriod, offset) = typeof(period)(period.start + offset, period.length)

-(period::DatePeriod, offset) = typeof(period)(period.start - offset, period.length)


days(period::DatePeriod) = period.start - stop_date(period) + 1


empty_period = EmptyPeriod()


first_day(period::MonthPeriod) = MonthPeriod(firstdayofmonth(period.start), period.length)

first_day(period::YearPeriod) = YearPeriod(firstdayofyear(period.start), period.length)


function input_to_date_tuple(convertible::Convertible)
  """Convert an input string to a date tuple.

  .. note:: This function doesn't return a date, but a tuple that allows to construct a date.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  split_value = filter(fragment -> !isempty(fragment), [
    strip(fragment)
    for fragment in split(convertible.value, '-', false)
  ])
  return pipe(
    test(date_tuple -> 1 <= length(date_tuple) <= 3, error = N_("Invalid date tuple.")),
    call(date_tuple -> tuple(vcat(collect(date_tuple), [nothing, nothing])[1:3]...)),
    struct(
      (
        pipe(
          input_to_int,
          test_greater_or_equal(0),
          require,
        ),
        pipe(
          input_to_int,
          test_between(1, 12),
        ),
        pipe(
          input_to_int,
          test_between(1, 31),
        ),
      ),
    ),
    call(date_tuple -> tuple(filter(item -> item !== nothing, date_tuple)...)),
  )(Convertible(split_value, convertible.context))
end


function input_to_period_tuple(convertible::Convertible)
  """Convert an input string to a period tuple.

  .. note:: This function doesn't return a period, but a tuple that allows to construct a period.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  split_value = filter(fragment -> !isempty(fragment), [
    strip(fragment)
    for fragment in split(convertible.value, ':', false)
  ])
  if isempty(split_value)
    return Convertible(nothing, convertible.context)
  end
  if length(split_value) == 1
    split_start = filter(fragment -> !isempty(fragment), [
      strip(fragment)
      for fragment in split(split_value[1], '-', false)
    ])
    if length(split_start) == 1
      return pipe(
        input_to_int,
        test_greater_or_equal(0),
        call(year -> ("year", year)),
      )(Convertible(split_start[1], convertible.context))
    elseif length(split_start) == 2
      return pipe(
        struct(
          (
            pipe(
              input_to_int,
              test_greater_or_equal(0),
            ),
            pipe(
              input_to_int,
              test_between(1, 12),
            ),
          ),
        ),
        call(month_tuple -> ("month", month_tuple)),
      )(Convertible(split_start, convertible.context))
    elseif length(split_start) == 3
      return pipe(
        struct(
          (
            pipe(
              input_to_int,
              test_greater_or_equal(0),
            ),
            pipe(
              input_to_int,
              test_between(1, 12),
            ),
            pipe(
              input_to_int,
              test_between(1, 31),
            ),
          ),
        ),
        call(day_tuple -> ("day", day_tuple)),
      )(Convertible(split_start, convertible.context))
    end
    return Convertible(split_start, convertible.context,
      """Date string contains too much "-" for a year, a month or a day.""")
  elseif length(split_value) == 2
    split_start = filter(fragment -> !isempty(fragment), [
      strip(fragment)
      for fragment in split(split_value[1], '-', false)
    ])
    size, error = Convertible(split_value[2], convertible.context) |> input_to_int |> to_value_error
    if error === nothing
      if length(split_start) == 1
        start, error = Convertible(split_start[1], convertible.context) |> input_to_int |>
          test_greater_or_equal(0) |> to_value_error
        if error === nothing
          return Convertible(("year", start, size), convertible.context)
        end
      elseif length(split_start) == 2
        start, error = Convertible(split_start, convertible.context) |> struct(
          (
            pipe(
              input_to_int,
              test_greater_or_equal(0),
            ),
            pipe(
              input_to_int,
              test_between(1, 12),
            ),
          ),
        ) |> to_value_error
        if error === nothing
          return Convertible(("month", start, size), convertible.context)
        end
      elseif length(split_start) == 3
        start, error = Convertible(split_start, convertible.context) |> struct(
          (
            pipe(
              input_to_int,
              test_greater_or_equal(0),
            ),
            pipe(
              input_to_int,
              test_between(1, 12),
            ),
            pipe(
              input_to_int,
              test_between(1, 31),
            ),
          ),
        ) |> to_value_error
        if error === nothing
          return Convertible(("day", start, size), convertible.context)
        end
      end
    end
  end
  return Convertible(tuple(split_value...), convertible.context)
end


function intersection(period::DatePeriod, start::Date, stop::Date)
  period_start = period.start
  period_stop = stop_date(period)
  if stop < period_start || period_stop < start
    return empty_period
  end
  intersection_start = max(period_start, start)
  intersection_stop = min(period_stop, stop)
  if intersection_start == period_start && intersection_stop == period_stop
    return period
  end
  if (day(intersection_start) == 1 && month(intersection_start) == 1 && day(intersection_stop) == 31
      && month(intersection_stop) == 12)
    return YearPeriod(intersection_start, year(intersection_stop) - year(intersection_start) + 1)
  end
  if day(intersection_start) == 1 && day(intersection_stop) == day(lastdayofmonth(intersection_stop))
    return MonthPeriod(intersection_start, (year(intersection_stop) - year(intersection_start)) * 12
      + month(intersection_stop) - month(intersection_start) + 1)
  end
  return DayPeriod(intersection_start, int(intersection_stop - intersection_start) + 1)
end


isfinite(::Period) = true


next(period::DatePeriod) = period + unit_type(period)(period.length)
"""Return the next contigous period of the same unit and the same length."""


function period(unit::String, start::(Int...), size = nothing)
  if size === nothing
    if length(start) == 1
      year = start[1]
      size = unit == "day" ? daysinyear(year) : unit == "month" ? 12 : 1
    elseif length(start) == 2
      year, month = start
      size = unit == "day" ? daysinmonth(year, month) : 1
    else
      @assert(length(start) == 3)
      size = 1
    end
  end
  return period(unit, Date(start...), size)
end

period(unit::String, start::Array{Int}, size = nothing) = period(unit, tuple(start...), size)

function period(unit::String, start::Date, size = nothing)
  @assert(unit in ("day", "month", "year"))
  if size === nothing
    size = 1
  end
  @assert(size >= 1)
  return unit_constructor(unit)(start, size)
end

period(unit::String, start::Int, size = nothing) = period(unit, (start, ), size)

period(unit::String, start::DatePeriod, size = 1) = period(unit, start.start, size)

period(unit::String, start::String, size = nothing) = period(
  unit,
  tuple([
    int(fragment)
    for fragment in split(start, "-", 3)
  ]...),
  size,
)

period(value::DatePeriod) = value

period(value::Int) = YearPeriod(value)

period(value) = Convertible(value) |> to_period |> to_value


show(io::IO, period::DayPeriod) = show(io, string(period.start, (length > 1 ? string(":", period.length) : "")))

show(io::IO, period::EmptyPeriod) = show(io, "$(typeof(period))()")

function show(io::IO, period::MonthPeriod)
  year, month, day = yearmonthday(period.start)
  show(io,
    string((day > 1 ? string("month:", period.start) : string(year, "-", month)),
      (period.length > 1 ? string(":", period.length) : "")))
end

function show(io::IO, period::YearPeriod)
  year, month, day = yearmonthday(period.start)
  show(io,
    string((month > 1 || day > 1 ? string("year:", year, "-", month, (day > 1 ? string("-", day) : "")) : string(year)),
      (period.length > 1 ? string(":", period.length) : "")))
end


real(period::Period) = real(period.value)


stop_date(period::DayPeriod) = period.start + Day(period.length - 1)

stop_date(period::MonthPeriod) = period.start + Month(period.length) - Day(1)

stop_date(period::YearPeriod) = period.start + Year(period.length) - Day(1)


"""Return a converter that creates a period from a Julia or JSON object."""
to_date_tuple(convertible::Convertible) = condition(
  test_isa(Date),
  call(date -> yearmonthday(date)),
  test_isa(String),
  input_to_date_tuple,
  test_isa(Int),
  pipe(
    test_greater_or_equal(0),
    call(year -> (year, )),
  ),
  pipe(
    test_isa(Union(Array, Tuple)),
    test(date_tuple -> 1 <= length(date_tuple) <= 3, error = N_("Invalid date tuple.")),
    call(date_tuple -> tuple(vcat(collect(date_tuple), [nothing, nothing])[1:3]...)),
    struct(
      (
        # year
        pipe(
          to_int,
          test_greater_or_equal(0),
          require,
        ),
        # month
        pipe(
          to_int,
          test_between(1, 12),
        ),
        # day
        pipe(
          to_int,
          test_between(1, 31),
        ),
      ),
    ),
    call(value -> tuple(filter(item -> item !== nothing, value)...)),
  ),
)(convertible)


"""Return a converter that creates a period from a Julia or JSON object."""
to_period(convertible::Convertible; max_date = Date(2099, 12, 31), min_date = Date(1870, 1, 1)) = pipe(
  condition(
    test_isa(String),
    input_to_period_tuple,
    test_isa(Int),
    pipe(
      test_greater_or_equal(0),
      call(year -> ("year", year)),
    ),
  ),
  condition(
    test_isa(DatePeriod),
    noop,
    test_isa(Dict),
    pipe(
      struct(
        [
          "size" => pipe(
            test_isa(Union(Int, String)),
            to_int,
            test_greater_or_equal(1),
          ),
          "start" => pipe(
            to_date_tuple,
            require,
          ),
          "unit" => pipe(
            test_isa(String),
            test_in(["day", "month", "year"]),
            require,
          ),
        ],
      ),
      call(value -> period(value["unit"], value["start"], value["size"])),
      # TODO test_converter(call(value -> value.start), test_between(min_date, max_date)),
    ),
    pipe(
      test_isa(Union(Array, Tuple)),
      test(period_tuple -> 2 <= length(period_tuple) <= 3, error = N_("Invalid period tuple.")),
      call(period_tuple -> tuple(vcat(collect(period_tuple), [nothing])[1:3]...)),
      struct(
        (
          # unit
          pipe(
            test_isa(String),
            test_in(["day", "month", "year"]),
            require,
          ),
          # start
          pipe(
            to_date_tuple,
            require,
          ),
          # size
          pipe(
            test_isa(Union(Int, String)),
            to_int,
            test_greater_or_equal(1),
          ),
        ),
      ),
      call(value -> period(value...)),
      # TODO test_converter(call(value -> value.start), test_between(min_date, max_date)),
    ),
  ),
)(convertible)

to_period(; max_date = Date(2099, 12, 31), min_date = Date(1870, 1, 1)) = convertible::Convertible -> to_period(
  convertible, max_date = max_date, min_date = min_date)


unit_constructor(unit::String) = [
  "day" => DayPeriod,
  "month" => MonthPeriod,
  "year" => YearPeriod,
][unit]


unit_type(period::DayPeriod) = Day

unit_type(period::MonthPeriod) = Month

unit_type(period::YearPeriod) = Year
