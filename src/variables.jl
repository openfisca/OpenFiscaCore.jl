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
  array_by_period::Dict{DatePeriod, Union(Array, BitArray)}
end

ConcretePeriodicVariable(simulation, definition) = ConcretePeriodicVariable(simulation, definition,
  Dict{DatePeriod, Union(Array, BitArray)}())


type ConcretePermanentVariable <: PermanentVariable
  # A permanent variable is a variable whose value doesn't depend from date (example: ID, birth)
  simulation::Simulation
  definition::VariableDefinition
  array::Union(Array, BitArray)
end

ConcretePermanentVariable(simulation, definition) = ConcretePermanentVariable(simulation, definition, [])


immutable ConcreteVariableAtPeriod <: VariableAtPeriod
  variable::PeriodicVariable
  period::DatePeriod
end


function any_person_in_entity(array_handle::VariableAtPeriodOrPermanent, entity::Entity, period::DatePeriod,
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

any_person_in_entity(array_handle::VariableAtPeriodOrPermanent, entity::Entity, period::DatePeriod
) = any_person_in_entity(array_handle, entity, period, ALL_ROLES)

any_person_in_entity(array_handle::VariableAtPeriod, entity::Entity, roles::Array{Role}) = any_person_in_entity(
  array_handle, entity, array_handle.period, roles)

any_person_in_entity(array_handle::VariableAtPeriod, entity::Entity) = any_person_in_entity(array_handle, entity,
  array_handle.period, ALL_ROLES)


function calculate(variable::PeriodicVariable, period::DatePeriod; accept_other_period = false)
  variable_at_date = variable_at(variable, period, nothing)
  if variable_at_date !== nothing
    return variable_at_date
  end
  definition = variable.definition
  if ((definition.start_date === nothing || definition.start_date <= period.start)
      && (definition.stop_date === nothing || period.start <= definition.stop_date))
    formula_period, array_handle = definition.formula(variable.simulation, variable, period)
    if !accept_other_period && formula_period != period
      error("Requested period $period differs from $formula_period returned by variable $(definition.name).")
    end
  else
    formula_period = period
    array_handle = default_array(variable)
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


function divide_calculate(variable::PeriodicVariable, period::MonthPeriod)
  variable_at_date = calculate(variable, period, accept_other_period = true)
  if !isa(variable_at_date.period, YearPeriod)
    error("Requested a year period. Got $(variable_at_date.period) returned by variable $(variable.definition.name).")
  end
  if period.start < variable_at_date.period.start || stop_date(variable_at_date.period) < stop_date(period)
    error("Requested period $(variable_at_date.period) returned by variable $(variable.definition.name) doesn't include"
      * " requested period $period.")
  end
  return ConcreteEntityArray(get_entity(variable), get_array(variable_at_date) .* period.length
    ./ (12 * variable_at_date.period.length))
end

divide_calculate(variable::PeriodicVariable, period::YearPeriod) = calculate(variable, period)


macro divide_calculate(variable, period)
  global simulation
  return esc(:($variable = divide_calculate(simulation, $(string(variable)), $period)))
end


entity_to_person(array_handle::VariableAtPeriodOrPermanent, period::DatePeriod, role::Role) = entity_to_person(
  array_handle, period, Role[role])

function entity_to_person(array_handle::VariableAtPeriodOrPermanent, period::DatePeriod, roles::Array{Role})
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

entity_to_person(array_handle::VariableAtPeriodOrPermanent, period::DatePeriod) = entity_to_person(array_handle, period,
  ALL_ROLES)

entity_to_person(array_handle::VariableAtPeriod, role::Role) = entity_to_person(array_handle, array_handle.period,
  Role[role])

entity_to_person(array_handle::VariableAtPeriod, roles::Array{Role}) = entity_to_person(array_handle,
  array_handle.period, roles)

entity_to_person(array_handle::VariableAtPeriod) = entity_to_person(array_handle, array_handle.period, ALL_ROLES)


get_array(variable_at_date::VariableAtPeriod, default) = get_array(variable_at_date.variable, variable_at_date.period,
  default)

get_array(variable_at_date::VariableAtPeriod) = get_array(variable_at_date.variable, variable_at_date.period)

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


get_entity(variable_at_date::VariableAtPeriod) = get_entity(variable_at_date.variable)

get_entity(variable::Variable) = get_entity(variable.simulation, variable.definition.entity_definition)


get_variable(variable_at_date::VariableAtPeriod) = variable_at_date.variable

get_variable(variable::PermanentVariable) = variable


function set_array(variable::PeriodicVariable, period::DatePeriod, array::Union(Array, BitArray))
  @assert(length(array) == get_entity(variable).count)
  variable.array_by_period[period] = array
  return ConcreteVariableAtPeriod(variable, period)
end

function set_array(variable::PeriodicVariable, variable_at_date::VariableAtPeriod)
  array = get_array(variable_at_date)
  @assert(length(array) == get_entity(variable).count)
  variable.array_by_period[variable_at_date.period] = array
  return variable_at_date
end

set_array(variable::PeriodicVariable, array::Union(Array, BitArray)) = set_array(variable, variable.simulation.period,
  array)

function set_array(variable::PermanentVariable, array::Union(Array, BitArray))
  @assert(length(array) == get_entity(variable).count)
  variable.array = array
  return variable
end


function single_person_in_entity(array_handle::VariableAtPeriodOrPermanent, entity::Entity, period::DatePeriod,
    role::Role)
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

single_person_in_entity(array_handle::VariableAtPeriod, entity::Entity, role::Role) = single_person_in_entity(
  array_handle, entity, array_handle.period, role)


function split_person_by_role(array_handle::VariableAtPeriodOrPermanent, entity::Entity, period::DatePeriod,
    roles::Array{Role})
  @assert(is_person(get_entity(array_handle)))
  @assert(!is_person(entity))
  definition = get_variable(array_handle).definition
  if roles == ALL_ROLES
    # To ensure that existing formulas don't fail, ensure there is always at least 11 roles.
    roles = [
      Role(i)
      for i in 1:max(entity.roles_count, 11)
    ]
  end
  entity_array_by_role = (Role => Array)[
    role => fill!(Array(definition.cell_type, entity.count), definition.cell_default)
    for role in roles
  ]
  for (index_cell, role_cell, value_cell) in zip(
      get_array(get_index_variable(entity)),
      get_array(get_role_variable(entity), period),
      get_array(array_handle),
    )
    role = Role(role_cell)
    if role in roles
      entity_array_by_role[role][index_cell] = value_cell
    end
  end
  return (Role => ConcreteEntityArray)[
    role => ConcreteEntityArray(entity, entity_array)
    for (role, entity_array) in entity_array_by_role
  ]
end

split_person_by_role(array_handle::VariableAtPeriodOrPermanent, entity::Entity, period::DatePeriod
) = split_person_by_role(array_handle, entity, period, ALL_ROLES)

split_person_by_role(array_handle::VariableAtPeriod, entity::Entity, roles::Array{Role}) = split_person_by_role(
  array_handle, entity, array_handle.period, roles)

split_person_by_role(array_handle::VariableAtPeriod, entity::Entity) = split_person_by_role(array_handle, entity,
  array_handle.period, ALL_ROLES)


sum_calculate(variable::PeriodicVariable, period::MonthPeriod) = calculate(variable, period)

function sum_calculate(variable::PeriodicVariable, period::YearPeriod)
  array = zeros(variable)
  year, month, day = yearmonthday(period.start)
  for period_number in 1:period.length
    for month_index in 0:11
      month_period = MonthPeriod(Date(year, month, day))
      variable_at_date = calculate(variable, month_period)
      array += get_array(variable_at_date)
      month += 1
      if month > 12
        month -= 12
        year += 1
      end
    end
  end
  return ConcreteEntityArray(get_entity(variable), array)
end


macro sum_calculate(variable, period)
  global simulation
  return esc(:($variable = sum_calculate(simulation, $(string(variable)), $period)))
end


function sum_person_in_entity(array_handle::VariableAtPeriodOrPermanent, entity::Entity, period::DatePeriod,
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

sum_person_in_entity(array_handle::VariableAtPeriodOrPermanent, entity::Entity, period::DatePeriod
) = sum_person_in_entity(array_handle, entity, period, ALL_ROLES)

sum_person_in_entity(array_handle::VariableAtPeriod, entity::Entity, roles::Array{Role}) = sum_person_in_entity(
  array_handle, entity, array_handle.period, roles)

sum_person_in_entity(array_handle::VariableAtPeriod, entity::Entity) = sum_person_in_entity(array_handle, entity,
  array_handle.period, ALL_ROLES)


function variable_at(variable::PeriodicVariable, period::DatePeriod, default)
  array = get_array(variable, period, nothing)
  return array === nothing ? default : ConcreteVariableAtPeriod(variable, period)
end

variable_at(variable::PermanentVariable, period::DatePeriod, default) = variable_at(variable, default)

variable_at(variable::PeriodicVariable, default) = variable_at(variable, variable.simulation.period, default)

function variable_at(variable::PermanentVariable, default)
  array = variable.array
  return isempty(array) ? default : variable
end

function variable_at(variable::PeriodicVariable, period::DatePeriod)
  variable_at_date = variable_at(variable, period, nothing)
  if variable_at_date === nothing
    throw(KeyError(period))
  end
  return variable_at_date
end

variable_at(variable::PeriodicVariable) = variable_at(variable, variable.simulation.period)

function variable_at(variable::PermanentVariable)
  variable = variable_at(variable, period, nothing)
  if variable === nothing
    throw(KeyError(period))
  end
  return variable
end


macro variable_at(variable, args...)
  global simulation
  return esc(:($variable = variable_at(simulation, $(string(variable)), $(args...))))
end


zeros(variable::Variable) = zeros(variable.definition.cell_type, get_entity(variable).count)
