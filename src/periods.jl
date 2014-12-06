# OpenFisca -- A versatile microsimulation software
# By: OpenFisca Team <contact@openfisca.fr>
#
# Copyright (C) 2011, 2012, 2013, 2014 OpenFisca Team
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


days(period::DatePeriod) = period.start - stop_date(period) + 1


empty_period = EmptyPeriod()


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


real(period::Period) = real(period.value)


stop_date(period::DayPeriod) = period.start + Day(period.length - 1)

stop_date(period::MonthPeriod) = period.start + Month(period.length) - Day(1)

stop_date(period::YearPeriod) = period.start + Year(period.length) - Day(1)


unit_type(period::DayPeriod) = Day

unit_type(period::MonthPeriod) = Month

unit_type(period::YearPeriod) = Year
