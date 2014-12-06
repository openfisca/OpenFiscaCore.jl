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
  exact_array_by_period::Dict{DatePeriod, Array}
  extrapolated_array_by_period::Dict{DatePeriod, Array}
end

PeriodicVariable(simulation, definition) = PeriodicVariable(simulation, definition, Dict{DatePeriod, Array}(),
  Dict{DatePeriod, Array}())


type PermanentVariable <: Variable
  # A permanent variable is a variable whose value doesn't depend from date (example: ID, birth)
  simulation::Simulation
  definition::VariableDefinition
  exact_array::Array
  extrapolated_array::Array
end

PermanentVariable(simulation, definition) = PermanentVariable(simulation, definition, [], [])


function calculate(variable::PeriodicVariable, period::DatePeriod)
  array = get_array!(variable, period) do
    definition = variable.definition
    if isa(definition, FormulaDefinition)
      array_handle = definition.func(variable, period)
      @assert isa(array_handle, PeriodArrayHandle)
      return get_array(array_handle, nothing)
    end
    array = Array(definition.cell_type, get_entity(variable).count)
    fill!(array, definition.cell_default)
    set_array_handle(variable, period, array)
    return array
  end
  return PeriodArrayHandle(variable, period)
end

function calculate(variable::PermanentVariable, period::DatePeriod)
  array = get_array!(variable) do
    definition = variable.definition
    if isa(definition, FormulaDefinition)
      array_handle = definition.func(variable, period)
      @assert isa(array_handle, PermanentArrayHandle)
      return get_array(array_handle, nothing)
    end
    array = Array(definition.cell_type, get_entity(variable).count)
    fill!(array, definition.cell_default)
    set_array_handle(variable, array)
    return array
  end
  return PermanentArrayHandle(variable)
end

calculate(variable::Variable) = calculate(variable, variable.simulation.period)


macro calculate(new_variable, period)
  global variable
  return esc(:($new_variable = calculate(variable.simulation, $(string(new_variable)), $period)))
end


function get_array(variable::PeriodicVariable, period::DatePeriod, default)
  array = get(variable.exact_array_by_period, period, nothing)
  return array === nothing ? get(variable.extrapolated_array_by_period, period, default) : array
end

get_array(variable::PeriodicVariable, default) = get_array(variable, variable.simulation.period, default)

function get_array(variable::PeriodicVariable, period::DatePeriod)
  array = get_array(variable, period, nothing)
  if array === nothing
    throw(KeyError(period))
  end
  return array
end

get_array(variable::PeriodicVariable) = get_array(variable, variable.simulation.period)

function get_array(variable::PermanentVariable, default)
  array = variable.exact_array
  if !isempty(array)
    return array
  end
  array = variable.extrapolated_array
  return isempty(array) ? default : array
end

get_array(variable::PermanentVariable, period::DatePeriod, default) = get_array(variable, default)

function get_array(variable::PermanentVariable)
  array = get_array(variable, nothing)
  if array === nothing
    throw(KeyError(period))
  end
  return array
end

get_array(variable::PermanentVariable, period::DatePeriod) = get_array(variable)


function get_array!(func::Function, variable::PeriodicVariable, period::DatePeriod; set_extrapolated = false)
  array = get(variable.exact_array_by_period, period, nothing)
  if array !== nothing
    return array
  end
  if set_extrapolated
    return get!(func, variable.extrapolated_array_by_period, period)
  end
  array = get(variable.extrapolated_array_by_period, period, nothing)
  if array !== nothing
    return array
  end
  array = func()
  variable.exact_array_by_period[period] = array
  return array
end

function get_array!(func::Function, variable::PermanentVariable; set_extrapolated = false)
  array = variable.exact_array
  if !isempty(array)
    return array
  end
  array = variable.extrapolated_array
  if !isempty(array)
    return array
  end
  array = func()
  if set_extrapolated
    variable.extrapolated_array = array
  else
    variable.exact_array = array
  end
  return array
end


function get_array_handle(variable::PeriodicVariable, period::DatePeriod, default)
  array = get_array(variable, period, nothing)
  return array === nothing ? default : PeriodArrayHandle(variable, period)
end

get_array_handle(variable::PeriodicVariable, default) = get_array_handle(variable, variable.simulation.period, default)

function get_array_handle(variable::PeriodicVariable, period::DatePeriod)
  array_handle = get_array_handle(variable, period, nothing)
  if array_handle === nothing
    throw(KeyError(period))
  end
  return array_handle
end

get_array_handle(variable::PeriodicVariable) = get_array_handle(variable, variable.simulation.period)

function get_array_handle(variable::PermanentVariable, default)
  array = get_array(variable, nothing)
  return array === nothing ? default : PermanentArrayHandle(variable)
end

get_array_handle(variable::PermanentVariable, period::DatePeriod, default) = get_array_handle(variable, default)

function get_array_handle(variable::PermanentVariable)
  array_handle = get_array_handle(variable, nothing)
  if array_handle === nothing
    throw(KeyError(period))
  end
  return array_handle
end

get_array_handle(variable::PermanentVariable, period::DatePeriod) = get_array_handle(variable)


macro get_array_handle(new_variable, period, default)
  global variable
  return esc(:($new_variable = get_array_handle(variable.simulation, $(string(new_variable)), $period, $default)))
end


get_entity(variable::Variable) = get_entity(variable.simulation, variable.definition.entity_definition)


function set_array_handle(variable::PeriodicVariable, period::DatePeriod, array::Array)
  @assert length(array) == get_entity(variable).count
  variable.exact_array_by_period[period] = array
  return PeriodArrayHandle(variable, period)
end

function set_array_handle(variable::PeriodicVariable, array_handle::PeriodArrayHandle)
  array = get_array(array_handle)
  @assert length(array) == get_entity(variable).count
  variable.exact_array_by_period[array_handle.period] = array
  return array_handle
end

set_array_handle(variable::PeriodicVariable, array::Array) = set_array_handle(variable, variable.simulation.period,
  array)

function set_array_handle(variable::PermanentVariable, array_handle::PermanentArrayHandle)
  array = get_array(array_handle)
  @assert length(array) == get_entity(variable).count
  variable.exact_array = array
  return array_handle
end

function set_array_handle(variable::PermanentVariable, array::Array)
  @assert length(array) == get_entity(variable).count
  variable.exact_array = array
  return PermanentArrayHandle(variable)
end
