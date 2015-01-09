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


export *, +, -, .<, .<=, .==, .*, .+, .-, ./, &, |, !, @calculate, @divide_year, @sum_months, @variable_at, add_member, add_to_legislation, AmountBracket, AmountScale, any_person_in_entity, apply_tax_scale, ArrayHandle, assert_near, at, beginswith, calculate, convert, DatedAmountScale, DatedLinearAverageRateScale, DatedMarginalRateScale, DatedRateScale, DatedTaxScale, DatePeriod, DateRangeValue, DayPeriod, days, default_array, div, divide_year, empty_period, Entity, entity_to_person, EntityArray, EntityDefinition, get_array, get_entity, get_variable!, intersection, isfinite, isless, Legislation, legislation_at, length, LinearAverageRateScale, MarginalRateScale, max, min, MonthPeriod, next, Parameter, parameter_at, PeriodicVariable, PermanentVariable, RateBracket, RateScale, real, Role, set_array, Simulation, single_person_in_entity, start, stop_date, sum_months, sum_person_in_entity, tax_scale_at, TaxBenefitSystem, TaxScale, unit_type, UnitIntervalFloat32, value_at, variable_at, VariableAtDate, VariableAtDateOrPermanent, VariableDefinition, YearPeriod, zeros


using Dates

import Base: *, +, -, .<, .<=, .==, .*, .+, .-, ./, &, |, !, beginswith, convert, div, done, isfinite, isless, length, max, min, next, real, start, zeros


abstract AbstractSimulation
abstract EntityArray
abstract Variable
abstract VariableAtDate

abstract PeriodicVariable <: Variable
abstract PermanentVariable <: Variable

typealias ArrayHandle Union(EntityArray, PermanentVariable, VariableAtDate)
typealias VariableAtDateOrPermanent Union(PermanentVariable, VariableAtDate)


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
include("simulations.jl")
include("variables.jl")


end # module
