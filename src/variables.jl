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


function calculate(variable::PeriodicVariable, period::DatePeriod; accept_other_period = false)
  array_handle = get_array_handle(variable, period, nothing)
  if array_handle !== nothing
    return array_handle
  end
  formula_period, array = variable.definition.formula(variable.simulation, variable, period)
  if !accept_other_period && formula_period != period
    error("Requested period $period differs from $formula_period returned by variable $(variable.definition.name).")
  end
  return set_array_handle(variable, formula_period, array)
end

calculate(variable::PermanentVariable, period::DatePeriod) = calculate(variable)

calculate(variable::PeriodicVariable) = calculate(variable, variable.simulation.period)

function calculate(variable::PermanentVariable)
  array = get_array!(variable) do
    array = variable.definition.formula(variable.simulation, variable)
    set_array_handle(variable, array)
    return array
  end
  return PermanentArrayHandle(variable)
end


macro calculate(new_variable, period)
  global variable
  return esc(:($new_variable = calculate(variable.simulation, $(string(new_variable)), $period)))
end


function default_array(variable::Variable)
  definition = variable.definition
  array = Array(definition.cell_type, get_entity(variable).count)
  fill!(array, definition.cell_default)
end


function divide_year(variable::PeriodicVariable, period::MonthPeriod)
  array_handle = calculate(variable, period, accept_other_period = true)
  if !isa(array_handle.period, YearPeriod)
    error("Requested a year period. Got $formula_period returned by variable $(variable.definition.name).")
  end
  return get_array(array_handle) ./ (12 * array_handle.period.length)
end


macro divide_year(new_variable, period)
  global variable
  return esc(:($new_variable = divide_year(variable.simulation, $(string(new_variable)), $period)))
end


get_array(variable::PeriodicVariable, period::DatePeriod, default) = get(variable.array_by_period, period, default)

get_array(variable::PeriodicVariable, default) = get_array(variable, variable.simulation.period, default)

function get_array(variable::PeriodicVariable, period::DatePeriod)
  array = get_array(variable, period, nothing)
  if array === nothing
    throw(KeyError(period))
  end
  return array
end

get_array(variable::PeriodicVariable) = get_array(variable, variable.simulation.period)

get_array(variable::PermanentVariable, period::DatePeriod, default) = get_array(variable, default)

get_array(variable::PermanentVariable, period::DatePeriod) = get_array(variable)

function get_array(variable::PermanentVariable, default)
  array = variable.array
  return isempty(array) ? default : array
end

function get_array(variable::PermanentVariable)
  array = get_array(variable, nothing)
  if array === nothing
    throw(KeyError(period))
  end
  return array
end


get_array!(func::Function, variable::PeriodicVariable, period::DatePeriod) = get!(func, variable.array_by_period,
  period)

function get_array!(func::Function, variable::PermanentVariable)
  array = variable.array
  if !isempty(array)
    return array
  end
  array = func()
  variable.array = array
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
  variable.array_by_period[period] = array
  return PeriodArrayHandle(variable, period)
end

function set_array_handle(variable::PeriodicVariable, array_handle::PeriodArrayHandle)
  array = get_array(array_handle)
  @assert length(array) == get_entity(variable).count
  variable.array_by_period[array_handle.period] = array
  return array_handle
end

set_array_handle(variable::PeriodicVariable, array::Array) = set_array_handle(variable, variable.simulation.period,
  array)

function set_array_handle(variable::PermanentVariable, array_handle::PermanentArrayHandle)
  array = get_array(array_handle)
  @assert length(array) == get_entity(variable).count
  variable.array = array
  return array_handle
end

function set_array_handle(variable::PermanentVariable, array::Array)
  @assert length(array) == get_entity(variable).count
  variable.array = array
  return PermanentArrayHandle(variable)
end


function sum_months(variable::PeriodicVariable, period::YearPeriod)
  array = zeros(variable)
  start_year, start_month, start_day = yearmonthday(period.start)
  for month_index in 0:11
    year = start_year
    month = start_month + month_index
    if month > 12
      month -= 12
      year += 1
    end
    month_period = MonthPeriod(Date(year, month, start_day))
    array_handle = calculate(variable, month_period)
    array += get_array(array_handle)
  end
  return array
end


macro sum_months(new_variable, period)
  global variable
  return esc(:($new_variable = sum_months(variable.simulation, $(string(new_variable)), $period)))
end


zeros(variable::Variable) = zeros(variable.definition.cell_type, get_entity(variable).count)
