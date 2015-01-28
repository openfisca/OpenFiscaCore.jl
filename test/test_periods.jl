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


@test is(Date(2014, 11, 29), Date(2014, 11, 29))
@test firstdayofyear(Date(2014, 11, 29)) == Date(2014, 1, 1)
@test firstdayofmonth(Date(2014, 11, 29)) == Date(2014, 11, 1)

@test DayPeriod(Date(2014, 11, 29), 1).start == Date(2014, 11, 29)
@test MonthPeriod(Date(2014, 11, 29), 1).start == Date(2014, 11, 29)
@test YearPeriod(Date(2014, 11, 29), 1).start == Date(2014, 11, 29)

@test DayPeriod(firstdayofmonth(DayPeriod(Date(2014, 11, 29), 1).start)) == DayPeriod(Date(2014, 11, 1), 1)
@test DayPeriod(firstdayofyear(DayPeriod(Date(2014, 11, 29), 1).start)) == DayPeriod(Date(2014, 1, 1), 1)
@test MonthPeriod(firstdayofmonth(DayPeriod(Date(2014, 11, 29), 1).start)) == MonthPeriod(Date(2014, 11, 1), 1)
@test MonthPeriod(firstdayofyear(DayPeriod(Date(2014, 11, 29), 1).start)) == MonthPeriod(Date(2014, 1, 1), 1)
@test YearPeriod(firstdayofmonth(DayPeriod(Date(2014, 11, 29), 1).start)) == YearPeriod(Date(2014, 11, 1), 1)
@test YearPeriod(firstdayofyear(DayPeriod(Date(2014, 11, 29), 1).start)) == YearPeriod(Date(2014, 1, 1), 1)

@test period(2014) == YearPeriod(2014)
@test period("2014") == YearPeriod(2014)

@test Convertible("2014") |> to_period |> to_value == YearPeriod(2014)
@test Convertible("2014:2") |> to_period |> to_value == YearPeriod(2014, 2)
@test Convertible("2014-2") |> to_period |> to_value == MonthPeriod(Date(2014, 2, 1))
@test Convertible("2014-2:2") |> to_period |> to_value == MonthPeriod(Date(2014, 2, 1), 2)
@test Convertible("2014-2-3") |> to_period |> to_value == DayPeriod(Date(2014, 2, 3))
@test Convertible("2014-2-3:2") |> to_period |> to_value == DayPeriod(Date(2014, 2, 3), 2)

@test Convertible("year:2014") |> to_period |> to_value == YearPeriod(2014)
@test Convertible("month:2014") |> to_period |> to_value == MonthPeriod(2014, 12)
@test Convertible("day:2014") |> to_period |> to_value == DayPeriod(2014, 365)

@test Convertible("year:2014-2") |> to_period |> to_value == YearPeriod(Date(2014, 2, 1))
@test Convertible("month:2014-2") |> to_period |> to_value == MonthPeriod(Date(2014, 2, 1))
@test Convertible("day:2014-2") |> to_period |> to_value == DayPeriod(Date(2014, 2, 1), 28)

@test Convertible("year:2014-2-3") |> to_period |> to_value == YearPeriod(Date(2014, 2, 3))
@test Convertible("month:2014-2-3") |> to_period |> to_value == MonthPeriod(Date(2014, 2, 3))
@test Convertible("day:2014-2-3") |> to_period |> to_value == DayPeriod(Date(2014, 2, 3))

@test Convertible("year:2014-2-3:2") |> to_period |> to_value == YearPeriod(Date(2014, 2, 3), 2)
@test Convertible("month:2014-2-3:2") |> to_period |> to_value == MonthPeriod(Date(2014, 2, 3), 2)
@test Convertible("day:2014-2-3:2") |> to_period |> to_value == DayPeriod(Date(2014, 2, 3), 2)
