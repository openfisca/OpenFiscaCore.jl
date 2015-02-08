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


module OpenFiscaCore


export *, +, -, .<, .<=, .==, .!=, .*, .+, .-, ./, &, |, !, @calculate, @divide_calculate, @sum_calculate, @variable_at, add_member, add_to_legislation, AmountBracket, AmountScale, AmountScaleAtDate, any_person_in_entity, apply_tax_scale, ArrayHandle, assert_near, at, beginswith, calculate, cleanup_period_item, convert, DatePeriod, DateRangeValue, DayPeriod, days, default_array, div, divide_calculate, empty_period, Entity, entity_to_person, EntityArray, EntityDefinition, fill!, first_day, get_array, get_entity, get_variable!, input_to_period_tuple, intersection, isfinite, isless, last_period_value, Legislation, legislation_at, length, LinearAverageRateScale, LinearAverageRateScaleAtDate, MarginalRateScale, MarginalRateScaleAtDate, max, min, MonthPeriod, next, Parameter, period, PeriodicVariable, PermanentVariable, print, RateBracket, RateScale, RateScaleAtDate, real, Role, round, Scenario, set_array, Simulation, single_person_in_entity, split_person_by_role, start, steps_count, stop_date, sum_calculate, sum_person_in_entity, TaxBenefitSystem, TaxScale, TaxScaleAtDate, to_axes, to_cell, to_period, to_scenario, unit_type, UnitIntervalFloat32, variable_at, VariableAtPeriod, VariableAtPeriodOrPermanent, VariableDefinition, YearPeriod, zeros


import Base: *, +, -, .<, .<=, .==, .!=, .*, .+, .-, ./, &, |, !, beginswith, convert, div, done, fill!, isfinite, isless, length, max, min, next, print, real, round, start, zeros

importall Biryani
importall Biryani.DatesConverters
import Dates: Date, Day, daysinmonth, daysinyear, firstdayofmonth, firstdayofyear, Month, Period, Year, yearmonthday


abstract AbstractSimulation
abstract EntityArray
abstract Variable
abstract VariableAtPeriod

abstract PeriodicVariable <: Variable
abstract PermanentVariable <: Variable

typealias ArrayHandle Union(EntityArray, PermanentVariable, VariableAtPeriod)
typealias VariableAtPeriodOrPermanent Union(PermanentVariable, VariableAtPeriod)


include("roles.jl")
include("entities.jl")
include("periods.jl")
include("arrays.jl")
include("array_handles.jl")
include("entity_arrays.jl")
include("parameters.jl")
include("tax_scales.jl")
include("variable_definitions.jl")
include("tax_scales.jl")
include("legislations.jl")
include("tax_benefit_systems.jl")
include("scenarios.jl")
include("simulations.jl")
include("variables.jl")


end # module
