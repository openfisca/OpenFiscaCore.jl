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


export *, +, -, .<, .<=, .==, .!=, .*, .+, .-, ./, &, |, !, @calculate, @calculate_add, @calculate_add_divide, @calculate_divide, @define_decomposition, @variable_at, add_member, add_to_legislation, AmountBracket, AmountScale, AmountScaleAtDate, any_person_in_entity, apply_tax_scale, ArrayHandle, assert_near, at, beginswith, calculate, calculate_add, calculate_add_divide, calculate_divide, cleanup_period_item, convert, DatePeriod, DateRangeValue, DayPeriod, days, DecompositionNode, default_array, div, empty_period, Entity, entity_to_entity_period_value, entity_to_person, EntityArray, EntityDefinition, fill!, first_day, get_array, get_entity, get_variable, get_variable!, input_to_date_tuple, input_to_period_tuple, InputVariablesScenario, intersection, isfinite, isless, last_duration_last_value, Legislation, legislation_at, length, LinearAverageRateScale, LinearAverageRateScaleAtDate, MarginalRateScale, MarginalRateScaleAtDate, max, min, missing_value, MonthPeriod, next, Parameter, period, PeriodicVariable, PermanentVariable, permanent_default_value, RateBracket, RateScale, RateScaleAtDate, real, requested_period_default_value, requested_period_last_value, Role, round, Scenario, set_array, set_entities_json_id, show, Simulation, single_person_in_entity, split_person_by_role, start, steps_count, stop_date, string, sum_person_in_entity, TaxBenefitSystem, TaxScale, TaxScaleAtDate, TestCaseScenario, to_array, to_axes, to_cell, to_date_tuple, to_json, to_period, to_scenario, to_test, unit_type, UnitIntervalFloat32, value_at_period_to_bool, value_at_period_to_date, value_at_period_to_day, value_at_period_to_floating_point, value_at_period_to_integer, value_at_period_to_month, value_at_period_to_role, value_at_period_to_string, value_at_period_to_year, variable_at, VariableAtPeriod, VariableAtPeriodOrPermanent, VariableDefinition, visit_decomposition, YearPeriod, zeros


import Base: *, +, -, .<, .<=, .==, .!=, .*, .+, .-, ./, &, |, !, beginswith, convert, div, done, fill!, isfinite, isless, length, max, min, next, real, round, start, zeros

importall Biryani
importall Biryani.DatesConverters
import DataStructures: OrderedDict
import Dates: Date, Day, day, daysinmonth, daysinyear, firstdayofmonth, firstdayofyear, Month, month, Period, Year, year, yearmonthday
import Iterators: partition


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
include("decompositions.jl")
include("scenarios.jl")
include("simulations.jl")
include("tests.jl")
include("variables.jl")


end # module
