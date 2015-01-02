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


type ConcretePeriodicVariable <: PeriodicVariable
  simulation::AbstractSimulation
  definition::VariableDefinition
  array_by_period::Dict{DatePeriod, Array}
end

ConcretePeriodicVariable(simulation, definition) = ConcretePeriodicVariable(simulation, definition, Dict{DatePeriod, Array}())


type ConcreteDatedVariable <: DatedVariable
  variable::PeriodicVariable
  period::DatePeriod
end


type ConcretePermanentVariable <: PermanentVariable
  # A permanent variable is a variable whose value doesn't depend from date (example: ID, birth)
  simulation::Simulation
  definition::VariableDefinition
  array::Array
end

ConcretePermanentVariable(simulation, definition) = ConcretePermanentVariable(simulation, definition, [])


function at(variable::PeriodicVariable, period::DatePeriod, default)
  array = get_array(variable, period, nothing)
  return array === nothing ? default : ConcreteDatedVariable(variable, period)
end

at(variable::PeriodicVariable, default) = at(variable, variable.simulation.period, default)

function at(variable::PeriodicVariable, period::DatePeriod)
  dated_variable = at(variable, period, nothing)
  if dated_variable === nothing
    throw(KeyError(period))
  end
  return dated_variable
end

at(variable::PeriodicVariable) = at(variable, variable.simulation.period)


macro at(new_variable, period, default)
  global simulation, variable
  return esc(:($new_variable = at(simulation, $(string(new_variable)), $period, $default)))
end


function calculate(variable::PeriodicVariable, period::DatePeriod; accept_other_period = false)
  dated_variable = at(variable, period, nothing)
  if dated_variable !== nothing
    return dated_variable
  end
  formula_period, array_handle = variable.definition.formula(variable.simulation, variable, period)
  if !accept_other_period && formula_period != period
    error("Requested period $period differs from $formula_period returned by variable $(variable.definition.name).")
  end
  return set_array(variable, formula_period, get_array(array_handle))
end

calculate(variable::PermanentVariable, period::DatePeriod) = calculate(variable)

calculate(variable::PeriodicVariable) = calculate(variable, variable.simulation.period)

function calculate(variable::PermanentVariable)
  array = get_array!(variable) do
    array_handle = variable.definition.formula(variable.simulation, variable)
    array = get_array(array_handle)
    set_array(variable, array)
    return array
  end
  return variable
end


macro calculate(new_variable, period)
  global simulation, variable
  return esc(:($new_variable = calculate(simulation, $(string(new_variable)), $period)))
end


function default_array(variable::Variable)
  definition = variable.definition
  array = Array(definition.cell_type, get_entity(variable).count)
  fill!(array, definition.cell_default)
end


function divide_year(variable::PeriodicVariable, period::MonthPeriod)
  dated_variable = calculate(variable, period, accept_other_period = true)
  if !isa(dated_variable.period, YearPeriod)
    error("Requested a year period. Got $formula_period returned by variable $(variable.definition.name).")
  end
  return ConcreteEntityArray(get_entity(variable), get_array(dated_variable) ./ (12 * dated_variable.period.length))
end


macro divide_year(new_variable, period)
  global simulation, variable
  return esc(:($new_variable = divide_year(simulation, $(string(new_variable)), $period)))
end


entity_to_person(array_handle::DatedOrPermanentVariable, role::Role) = entity_to_person(array_handle, Role[role])

function entity_to_person(array_handle::DatedOrPermanentVariable, roles::Array{Role})
  array = get_array(array_handle)
  period = array_handle.period
  entity = get_entity(array_handle)
  @assert !is_person(entity)
  simulation = entity.simulation
  person = get_person(simulation)
  variable_definition = get_variable(array_handle).definition
  if roles == ALL_ROLES
    person_array = variable_definition.cell_type[
      array[index_cell]
      for index_cell in get_array(get_index_variable(entity), period)
    ]
  else
    cell_default = variable_definition.cell_default
    person_array = variable_definition.cell_type[
      role_cell in roles ? array[index_cell] : cell_default
      for (index_cell, role_cell) in zip(
        get_array(get_index_variable(entity)),
        get_array(get_role_variable(entity), period),
      )
    ]
  end
  return ConcreteEntityArray(entity, person_array)
end

entity_to_person(array_handle::DatedOrPermanentVariable) = entity_to_person(array_handle, ALL_ROLES)


get_array(dated_variable::DatedVariable, default) = get_array(dated_variable.variable, dated_variable.period, default)

get_array(dated_variable::DatedVariable) = get_array(dated_variable.variable, dated_variable.period)

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


get_entity(dated_variable::DatedVariable) = get_entity(dated_variable.variable)

get_entity(variable::Variable) = get_entity(variable.simulation, variable.definition.entity_definition)


get_variable(dated_variable::DatedVariable) = dated_variable.variable

get_variable(variable::PermanentVariable) = variable


function set_array(variable::PeriodicVariable, period::DatePeriod, array::Array)
  @assert length(array) == get_entity(variable).count
  variable.array_by_period[period] = array
  return ConcreteDatedVariable(variable, period)
end

function set_array(variable::PeriodicVariable, dated_variable::DatedVariable)
  array = get_array(dated_variable)
  @assert length(array) == get_entity(variable).count
  variable.array_by_period[dated_variable.period] = array
  return dated_variable
end

set_array(variable::PeriodicVariable, array::Array) = set_array(variable, variable.simulation.period, array)

function set_array(variable::PermanentVariable, array::Array)
  @assert length(array) == get_entity(variable).count
  variable.array = array
  return variable
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
    dated_variable = calculate(variable, month_period)
    array += get_array(dated_variable)
  end
  return ConcreteEntityArray(get_entity(variable), array)
end


macro sum_months(new_variable, period)
  global simulation, variable
  return esc(:($new_variable = sum_months(simulation, $(string(new_variable)), $period)))
end


zeros(variable::Variable) = zeros(variable.definition.cell_type, get_entity(variable).count)
