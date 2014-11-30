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


export DatePeriod, DayPeriod, isfinite, MonthPeriod, real, YearPeriod


abstract DatePeriod


immutable DayPeriod <: DatePeriod
  start::Date
  length::Unsigned
end

DayPeriod(start::Integer, length) = DayPeriod(Date(start), length)
DayPeriod(start) = DayPeriod(start, 1)


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


isfinite(::Period) = true
real(period::Period) = real(int(period))
