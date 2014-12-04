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


type PeriodicVariable <: Variable
  simulation::AbstractSimulation
  definition::VariableDefinition
  array_by_period::Dict{DatePeriod, Array}
end

PeriodicVariable(simulation, definition) = PeriodicVariable(simulation, definition, Dict{DatePeriod, Array}())


type PermanentVariable <: Variable
  # A permanent variable is a variable whose value doesn't depend from date (example: ID, birth)
  simulation::Simulation
  definition::VariableDefinition
  array::Array
end

PermanentVariable(simulation, definition) = PermanentVariable(simulation, definition, [])


function calculate(variable::PeriodicVariable, period)
  array = get!(variable.array_by_period, period) do
    definition = variable.definition
    if isa(definition, FormulaDefinition)
      array_handle = definition.func(variable, period)
      @assert isa(array_handle, PeriodArrayHandle)
      return array_handle.array
    end
    array = Array(definition.cell_type, get_entity(variable).count)
    fill!(array, definition.cell_default)
    set_array_handle(variable, period, array)
    return array
  end
  return PeriodArrayHandle(variable, period, array)
end

function calculate(variable::PermanentVariable, period)
  array = variable.array
  if isempty(array)
    definition = variable.definition
    if isa(definition, FormulaDefinition)
      array_handle = definition.func(variable, period)
      @assert isa(array_handle, PermanentArrayHandle)
    else
      array = Array(definition.cell_type, get_entity(variable).count)
      fill!(array, definition.cell_default)
      set_array_handle(variable, array)
    end
  end
  return PermanentArrayHandle(variable, array)
end

calculate(variable::Variable) = calculate(variable, variable.simulation.period)

calculate(simulation::Simulation, variable_name, period) = calculate(
  get_variable!(simulation, variable_name), period)

calculate(simulation::Simulation, variable_name) = calculate(
  get_variable!(simulation, variable_name), simulation.period)


macro calculate(new_variable, period)
  global variable
  return esc(:($new_variable = calculate(variable.simulation, $(string(new_variable)), $period)))
end


function get_array_handle(variable::PeriodicVariable, period, default)
  array = get(variable.array_by_period, period, nothing)
  return array === nothing ? default : PeriodArrayHandle(variable, period, array)
end

get_array_handle(variable::PeriodicVariable, default) = get_array(variable, variable.simulation.period, default)

function get_array_handle(variable::PermanentVariable, default)
  array = variable.array
  return isempty(array) ? default : PermanentArrayHandle(variable, array)
end

get_array_handle(variable::PermanentVariable, period, default) = get_array_handle(variable, default)


macro get_array_handle(new_variable, period, default)
  global variable
  return esc(:($new_variable = get_array_handle(variable.simulation, $(string(new_variable)), $period, $default)))
end


get_entity(variable::Variable) = get_entity(variable.simulation, variable.definition.entity_definition)


function set_array_handle(variable::PeriodicVariable, period::DatePeriod, array::Array)
  @assert length(array) == get_entity(variable).count
  variable.array_by_period[period] = array
  return PeriodArrayHandle(variable, period, array)
end

function set_array_handle(variable::PeriodicVariable, array_handle::PeriodArrayHandle)
  array = array_handle.array
  @assert length(array) == get_entity(variable).count
  variable.array_by_period[array_handle.period] = array
  return array_handle
end

set_array_handle(variable::PeriodicVariable, array::Array) = set_array_handle(variable, variable.simulation.period,
  array)

function set_array_handle(variable::PermanentVariable, array_handle::PermanentArrayHandle)
  array = array_handle.array
  @assert length(array) == get_entity(variable).count
  variable.array = array
  return array_handle
end

function set_array_handle(variable::PermanentVariable, array::Array)
  @assert length(array) == get_entity(variable).count
  variable.array = array
  return PermanentArrayHandle(variable, array)
end
