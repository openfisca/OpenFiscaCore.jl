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


function any_person_in_entity(array_handle::DatedOrPermanentVariable, entity::Entity, period::DatePeriod,
    roles::Array{Role})
  @assert(is_person(get_entity(array_handle)))
  @assert(!is_person(entity))
  entity_array = zeros(Bool, entity.count)
  if roles == ALL_ROLES
    for (index_cell, value_cell) in zip(
          get_array(get_index_variable(entity)),
          get_array(array_handle),
        )
      entity_array[index_cell] += value_cell
    end
  else
    for (index_cell, role_cell, value_cell) in zip(
          get_array(get_index_variable(entity)),
          get_array(get_role_variable(entity), period),
          get_array(array_handle),
        )
      if role_cell in roles
        entity_array[index_cell] += value_cell
      end
    end
  end
  return ConcreteEntityArray(entity, entity_array)
end

any_person_in_entity(array_handle::DatedOrPermanentVariable, entity::Entity, period::DatePeriod) = any_person_in_entity(
  array_handle, entity, period, ALL_ROLES)

any_person_in_entity(array_handle::DatedVariable, entity::Entity, roles::Array{Role}) = any_person_in_entity(
  array_handle, entity, array_handle.period, roles)

any_person_in_entity(array_handle::DatedVariable, entity::Entity) = any_person_in_entity(array_handle, entity,
  array_handle.period, ALL_ROLES)


function at(variable::PeriodicVariable, period::DatePeriod, default)
  array = get_array(variable, period, nothing)
  return array === nothing ? default : ConcreteDatedVariable(variable, period)
end

at(variable::PermanentVariable, period::DatePeriod, default) = at(variable, default)

at(variable::PeriodicVariable, default) = at(variable, variable.simulation.period, default)

function at(variable::PermanentVariable, default)
  array = variable.array
  return isempty(array) ? default : variable
end

function at(variable::PeriodicVariable, period::DatePeriod)
  dated_variable = at(variable, period, nothing)
  if dated_variable === nothing
    throw(KeyError(period))
  end
  return dated_variable
end

at(variable::PeriodicVariable) = at(variable, variable.simulation.period)

function at(variable::PermanentVariable)
  variable = at(variable, period, nothing)
  if variable === nothing
    throw(KeyError(period))
  end
  return variable
end


macro at(variable, args...)
  global simulation
  return esc(:($variable = at(simulation, $(string(variable)), $(args...))))
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


macro calculate(variable, args...)
  global simulation
  return esc(:($variable = calculate(simulation, $(string(variable)), $(args...))))
end


function default_array(variable::Variable)
  definition = variable.definition
  array = Array(definition.cell_type, get_entity(variable).count)
  return fill!(array, definition.cell_default)
end


function divide_year(variable::PeriodicVariable, period::MonthPeriod)
  dated_variable = calculate(variable, period, accept_other_period = true)
  if !isa(dated_variable.period, YearPeriod)
    error("Requested a year period. Got $formula_period returned by variable $(variable.definition.name).")
  end
  return ConcreteEntityArray(get_entity(variable), get_array(dated_variable) ./ (12 * dated_variable.period.length))
end


macro divide_year(variable, period)
  global simulation
  return esc(:($variable = divide_year(simulation, $(string(variable)), $period)))
end


entity_to_person(array_handle::DatedOrPermanentVariable, period::DatePeriod, role::Role) = entity_to_person(
  array_handle, period, Role[role])

function entity_to_person(array_handle::DatedOrPermanentVariable, period::DatePeriod, roles::Array{Role})
  array = get_array(array_handle)
  entity = get_entity(array_handle)
  @assert(!is_person(entity))
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

entity_to_person(array_handle::DatedOrPermanentVariable, period::DatePeriod) = entity_to_person(array_handle, period,
  ALL_ROLES)

entity_to_person(array_handle::DatedVariable, role::Role) = entity_to_person(array_handle, array_handle.period,
  Role[role])

entity_to_person(array_handle::DatedVariable, roles::Array{Role}) = entity_to_person(array_handle, array_handle.period,
  roles)

entity_to_person(array_handle::DatedVariable) = entity_to_person(array_handle, array_handle.period, ALL_ROLES)


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

get_array!(func::Function, variable::PermanentVariable, period::DatePeriod) = get_array!(func, variable)

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
  @assert(length(array) == get_entity(variable).count)
  variable.array_by_period[period] = array
  return ConcreteDatedVariable(variable, period)
end

function set_array(variable::PeriodicVariable, dated_variable::DatedVariable)
  array = get_array(dated_variable)
  @assert(length(array) == get_entity(variable).count)
  variable.array_by_period[dated_variable.period] = array
  return dated_variable
end

set_array(variable::PeriodicVariable, array::Array) = set_array(variable, variable.simulation.period, array)

function set_array(variable::PermanentVariable, array::Array)
  @assert(length(array) == get_entity(variable).count)
  variable.array = array
  return variable
end


function single_person_in_entity(array_handle::DatedOrPermanentVariable, entity::Entity, period::DatePeriod, role::Role)
  @assert(is_person(get_entity(array_handle)))
  @assert(!is_person(entity))
  entity_array = Array(get_variable(array_handle).definition.cell_type, entity.count)
  for (index_cell, role_cell, value_cell) in zip(
        get_array(get_index_variable(entity)),
        get_array(get_role_variable(entity), period),
        get_array(array_handle),
      )
    if role_cell === role
      entity_array[index_cell] = value_cell
    end
  end
  return ConcreteEntityArray(entity, entity_array)
end

single_person_in_entity(array_handle::DatedVariable, entity::Entity, role::Role) = single_person_in_entity(
  array_handle, entity, array_handle.period, role)


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


macro sum_months(variable, period)
  global simulation
  return esc(:($variable = sum_months(simulation, $(string(variable)), $period)))
end


function sum_person_in_entity(array_handle::DatedOrPermanentVariable, entity::Entity, period::DatePeriod,
    roles::Array{Role})
  @assert(is_person(get_entity(array_handle)))
  @assert(!is_person(entity))
  cell_type = get_variable(array_handle).definition.cell_type
  entity_array = zeros(cell_type === Bool ? Int16 : cell_type, entity.count)
  if roles == ALL_ROLES
    for (index_cell, value_cell) in zip(
          get_array(get_index_variable(entity)),
          get_array(array_handle),
        )
      entity_array[index_cell] += value_cell
    end
  else
    for (index_cell, role_cell, value_cell) in zip(
          get_array(get_index_variable(entity)),
          get_array(get_role_variable(entity), period),
          get_array(array_handle),
        )
      if role_cell in roles
        entity_array[index_cell] += value_cell
      end
    end
  end
  return ConcreteEntityArray(entity, entity_array)
end

sum_person_in_entity(array_handle::DatedOrPermanentVariable, entity::Entity, period::DatePeriod) = sum_person_in_entity(
  array_handle, entity, period, ALL_ROLES)

sum_person_in_entity(array_handle::DatedVariable, entity::Entity, roles::Array{Role}) = sum_person_in_entity(
  array_handle, entity, array_handle.period, roles)

sum_person_in_entity(array_handle::DatedVariable, entity::Entity) = sum_person_in_entity(array_handle, entity,
  array_handle.period, ALL_ROLES)


zeros(variable::Variable) = zeros(variable.definition.cell_type, get_entity(variable).count)
