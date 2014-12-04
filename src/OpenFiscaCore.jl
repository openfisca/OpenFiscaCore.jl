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


module OpenFiscaCore


export *, +, .<, @calculate, @get_array_handle, BareVariableDefinition, beginswith, calculate, DatePeriod, DayPeriod, Entity, entity_to_person, EntityDefinition, FormulaDefinition, get_array_handle, get_entity, get_variable!,isfinite, length, MonthPeriod, next, PeriodArrayHandle, PermanentArrayHandle, PeriodicVariable, PermanentVariable, real, Role, set_array_handle, Simulation, start, TaxBenefitSystem, VariableDefinition, YearPeriod


using Dates

import Base: *, +, .<, beginswith, done, isfinite, length, next, real, start


abstract AbstractSimulation
abstract Variable


include("entities.jl")
include("periods.jl")
include("arrays.jl")
include("array_handles.jl")
include("variable_definitions.jl")
include("tax_benefit_systems.jl")
include("simulations.jl")
include("variables.jl")


end # module
