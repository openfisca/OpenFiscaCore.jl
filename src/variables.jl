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

ConcretePermanentVariable(simulation, definition) = ConcretePermanentVariable(simulation, definition,
  Array(definition.cell_type, 0))


immutable ConcreteVariableAtPeriod <: VariableAtPeriod
  variable::PeriodicVariable
  period::DatePeriod
end


function any_person_in_entity(array_handle::ArrayHandle, entity::Entity, period::DatePeriod, roles::Array{Role})
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
      if Role(role_cell) in roles
        entity_array[index_cell] += value_cell
      end
    end
  end
  return ConcreteEntityArray(entity, entity_array)
end

any_person_in_entity(array_handle::ArrayHandle, entity::Entity, period::DatePeriod
) = any_person_in_entity(array_handle, entity, period, ALL_ROLES)

any_person_in_entity(array_handle::VariableAtPeriod, entity::Entity, roles::Array{Role}) = any_person_in_entity(
  array_handle, entity, array_handle.period, roles)

any_person_in_entity(array_handle::VariableAtPeriod, entity::Entity) = any_person_in_entity(array_handle, entity,
  array_handle.period, ALL_ROLES)


function calculate(variable::PeriodicVariable, period::DatePeriod; accept_other_period = false)
  variable_at_period = variable_at(variable, period, nothing)
  if variable_at_period !== nothing
    return variable_at_period
  end
  definition = variable.definition
  if ((definition.start_date === nothing || definition.start_date <= period.start)
      && (definition.stop_date === nothing || period.start <= definition.stop_date))
    simulation = variable.simulation
    debug = simulation.debug
    debug_all = simulation.debug_all
    trace = simulation.trace
    debug_or_trace = debug || trace
    if debug_or_trace
      push!(simulation.formulas_input_stack, FormulaInput(definition.name, period))
    end
    formula_period, array_handle = definition.base_formula(simulation, variable, period)
    if debug_or_trace
      formula_input = pop!(simulation.formulas_input_stack)
      if !debug_all || trace
        has_only_default_input_variables = all([
          # TODO: getarray() has a default argument because when accept_other_period is true an input variable may be
          # returned for a period different from the requested period.
          all(get_array(input_variable, input_variable_period, ["dummy"]) .== input_variable.definition.cell_default)
          for (input_variable, input_variable_period) in [
            (simulation.variable_by_name[input_variable_name_at_period.name], input_variable_name_at_period.period)
            for input_variable_name_at_period in formula_input.variables_name_at_period
          ]
        ])
      end
      if debug && (debug_all || !has_only_default_input_variables)
        info("<=> $(definition.name)@$(get_entity(variable).definition.name)<$(string(period))>"
          * "($(stringify_variables_name_at_period(simulation, formula_input.variables_name_at_period))) -->"
          * " <$(string(formula_period))>$(get_array(array_handle))")
      end
    end
    if !accept_other_period && formula_period != period
      error("Requested period $(string(period)) differs from $(string(formula_period)) returned by variable" *
        " $(definition.name).")
    end
  else
    formula_period = period
    array_handle = default_array(variable)
  end
  return set_array(variable, formula_period, get_array(array_handle))
end

calculate(variable::PermanentVariable, period::DatePeriod; accept_other_period = false) = calculate(variable)

calculate(variable::PeriodicVariable; accept_other_period = false) = calculate(variable, variable.simulation.period,
  accept_other_period = accept_other_period)

function calculate(variable::PermanentVariable)
  array = get_array!(variable) do
    definition = variable.definition
    simulation = variable.simulation
    debug = simulation.debug
    debug_all = simulation.debug_all
    trace = simulation.trace
    debug_or_trace = debug || trace
    if debug_or_trace
      push!(simulation.formulas_input_stack, FormulaInput(definition.name))
    end
    array_handle = definition.base_formula(simulation, variable)
    array = get_array(array_handle)
    set_array(variable, array)
    if debug_or_trace
      formula_input = pop!(simulation.formulas_input_stack)
      if !debug_all || trace
        has_only_default_input_variables = all([
          # TODO: getarray() has a default argument because when accept_other_period is true an input variable may be
          # returned for a period different from the requested period.
          all(get_array(input_variable, input_variable_period, ["dummy"]) .== input_variable.definition.cell_default)
          for (input_variable, input_variable_period) in [
            (simulation.variable_by_name[input_variable_name_at_period.name], input_variable_name_at_period.period)
            for input_variable_name_at_period in formula_input.variables_name_at_period
          ]
        ])
      end
      if debug && (debug_all || !has_only_default_input_variables)
        info("<=> $(definition.name)@$(get_entity(variable).definition.name)"
          * "($(stringify_variables_name_at_period(simulation, formula_input.variables_name_at_period))) --> $(array)")
      end
    end
    return array
  end
  return variable
end


macro calculate(variable, args...)
  global simulation
  return esc(:($variable = calculate(simulation, $(string(variable)), $(args...))))
end


function calculate_add(variable::PeriodicVariable, period::MonthPeriod)
  cell_type = variable.definition.cell_type
  @assert !issubtype(cell_type, Bool)
  @assert !issubtype(cell_type, Integer)  # TODO: Remove this test, once all Python formulas work in Julia.

  variable_at_period = variable_at(variable, period, nothing)
  if variable_at_period !== nothing
    return variable_at_period
  end

  array = zeros(variable)
  year, month, day = yearmonthday(period.start)
  for month_number in 1:period.length
    month_period = MonthPeriod(Date(year, month, day))
    variable_at_period = calculate(variable, month_period)
    array .+= get_array(variable_at_period)
    month += 1
    if month > 12
      month -= 12
      year += 1
    end
  end
  return set_array(variable, period, array)
end

function calculate_add(variable::PeriodicVariable, period::YearPeriod)
  cell_type = variable.definition.cell_type
  @assert !issubtype(cell_type, Bool)
  @assert !issubtype(cell_type, Integer)  # TODO: Remove this test, once all Python formulas work in Julia.

  variable_at_period = variable_at(variable, period, nothing)
  if variable_at_period !== nothing
    return variable_at_period
  end

  array = zeros(variable)
  year, month, day = yearmonthday(period.start)
  for year_number in 1:period.length
    for month_number in 1:12
      month_period = MonthPeriod(Date(year, month, day))
      variable_at_period = calculate(variable, month_period)
      array += get_array(variable_at_period)
      month += 1
      if month > 12
        month -= 12
        year += 1
      end
    end
  end
  return set_array(variable, period, array)
end


macro calculate_add(variable, period)
  global simulation
  return esc(:($variable = calculate_add(simulation, $(string(variable)), $period)))
end


function calculate_add_divide(variable::PeriodicVariable, period::MonthPeriod)
  cell_type = variable.definition.cell_type
  @assert !issubtype(cell_type, Bool)
  @assert !issubtype(cell_type, Integer)
  @assert day(period.start) == 1

  variable_at_period = variable_at(variable, period, nothing)
  if variable_at_period !== nothing
    return variable_at_period
  end

  array = zeros(variable)
  remaining_period_months = period.length
  requested_period = period
  while true
    variable_at_period = calculate(variable, requested_period, accept_other_period = true)
    requested_start = requested_period.start
    returned_period = variable_at_period.period
    returned_start = returned_period.start
    @assert day(returned_start) == 1
    if requested_start < returned_start || stop_date(returned_period) < requested_start
      error("Period $(string(returned_period)) returned by variable $(variable.definition.name) doesn't include" *
        " start of requested period $(string(requested_period)).")
    end
    requested_start_months = year(requested_start) * 12 + month(requested_start)
    returned_start_months = year(returned_start) * 12 + month(returned_start)
    if isa(returned_period, MonthPeriod)
      intersection_months = min(requested_start_months + requested_period.length,
        returned_start_months + returned_period.length) - requested_start_months
      array .+= get_array(variable_at_period) .* intersection_months ./ returned_period.length
    else
      if !isa(returned_period, YearPeriod)
        error("Requested a monthly or yearly period. Got $(string(returned_period)) returned by variable" *
          " $(variable.definition.name).")
      end
      intersection_months = min(requested_start_months + requested_period.length,
        returned_start_months + 12 * returned_period.length) - requested_start_months
      array .+= get_array(variable_at_period) .* intersection_months ./ (12 * returned_period.length)
    end

    remaining_period_months -= intersection_months
    if remaining_period_months <= 0
      return set_array(variable, period, array)
    end
    requested_period_length = requested_period.length - intersection_months
    requested_period = MonthPeriod(requested_start + Month(intersection_months), requested_period_length)
  end
end

function calculate_add_divide(variable::PeriodicVariable, period::YearPeriod)
  cell_type = variable.definition.cell_type
  @assert !issubtype(cell_type, Bool)
  @assert !issubtype(cell_type, Integer)
  @assert day(period.start) == 1

  variable_at_period = variable_at(variable, period, nothing)
  if variable_at_period !== nothing
    return variable_at_period
  end

  array = zeros(variable)
  remaining_period_months = period.length * 12
  requested_period = period
  while true
    variable_at_period = calculate(variable, requested_period, accept_other_period = true)
    requested_start = requested_period.start
    returned_period = variable_at_period.period
    returned_start = returned_period.start
    @assert day(returned_start) == 1
    if requested_start < returned_start || stop_date(returned_period) < requested_start
      error("Period $(string(returned_period)) returned by variable $(variable.definition.name) doesn't include" *
        " start of requested period $(string(requested_period)).")
    end
    requested_start_months = year(requested_start) * 12 + month(requested_start)
    returned_start_months = year(returned_start) * 12 + month(returned_start)
    if isa(returned_period, MonthPeriod)
      intersection_months = min(requested_start_months + requested_period.length * 12,
        returned_start_months + returned_period.length) - requested_start_months
      array .+= get_array(variable_at_period) .* intersection_months ./ returned_period.length
    else
      if !isa(returned_period, YearPeriod)
        error("Requested a monthly or yearly period. Got $(string(returned_period)) returned by variable" *
          " $(variable.definition.name).")
      end
      intersection_months = min(requested_start_months + requested_period.length * 12,
        returned_start_months + returned_period.length * 12) - requested_start_months
      array .+= get_array(variable_at_period) .* intersection_months ./ (returned_period.length * 12)
    end

    # Note: Bug with Julia 0.3.2 when int() functions are not used
    remaining_period_months -= intersection_months
    if remaining_period_months <= 0
      return set_array(variable, period, array)
    end
    requested_period_length = int(requested_period.length) - int(floor(int(intersection_months) / 12))
    requested_period = YearPeriod(requested_start + Month(intersection_months), requested_period_length)
  end
end


macro calculate_add_divide(variable, period)
  global simulation
  return esc(:($variable = calculate_add_divide(simulation, $(string(variable)), $period)))
end


function calculate_divide(variable::PeriodicVariable, period::MonthPeriod)
  cell_type = variable.definition.cell_type
  @assert !issubtype(cell_type, Bool)
  @assert !issubtype(cell_type, Integer)

  variable_at_period = variable_at(variable, period, nothing)
  if variable_at_period !== nothing
    return variable_at_period
  end

  variable_at_period = calculate(variable, period, accept_other_period = true)
  if period.start < variable_at_period.period.start || stop_date(variable_at_period.period) < stop_date(period)
    error("Period $(string(variable_at_period.period)) returned by variable $(variable.definition.name)" *
      " doesn't include requested period $(string(period)).")
  end
  if isa(variable_at_period.period, MonthPeriod)
    return set_array(variable, period,
      get_array(variable_at_period) .* period.length ./ variable_at_period.period.length)
  else
    if !isa(variable_at_period.period, YearPeriod)
      error("Requested a monthly or yearly period. Got $(string(variable_at_period.period)) returned by variable" *
        " $(variable.definition.name).")
    end
    return set_array(variable, period, get_array(variable_at_period) .* period.length
      ./ (12 * variable_at_period.period.length))
  end
end

function calculate_divide(variable::PeriodicVariable, period::YearPeriod)
  cell_type = variable.definition.cell_type
  @assert !issubtype(cell_type, Bool)
  @assert !issubtype(cell_type, Integer)

  return calculate(variable, period)
end


macro calculate_divide(variable, period)
  global simulation
  return esc(:($variable = calculate_divide(simulation, $(string(variable)), $period)))
end


function default_array(variable::Variable)
  definition = variable.definition
  array = Array(definition.cell_type, get_entity(variable).count)
  return fill!(array, definition.cell_default)
end


entity_to_person(array_handle::VariableAtPeriodOrPermanent, period::DatePeriod, role::Role) = entity_to_person(
  array_handle, period, Role[role])

function entity_to_person(array_handle::VariableAtPeriodOrPermanent, period::DatePeriod, roles::Array{Role})
  array = get_array(array_handle)
  entity = get_entity(array_handle)
  @assert(!is_person(entity))
  variable_definition = get_variable(array_handle).definition
  if roles == ALL_ROLES
    person_array = variable_definition.cell_type[
      array[index_cell]
      for index_cell in get_array(get_index_variable(entity), period)
    ]
  else
    cell_default = variable_definition.cell_default
    person_array = variable_definition.cell_type[
      Role(role_cell) in roles ? array[index_cell] : cell_default
      for (index_cell, role_cell) in zip(
        get_array(get_index_variable(entity)),
        get_array(get_role_variable(entity), period),
      )
    ]
  end
  return ConcreteEntityArray(get_person(entity.simulation), person_array)
end

entity_to_person(array_handle::VariableAtPeriodOrPermanent, period::DatePeriod) = entity_to_person(array_handle, period,
  ALL_ROLES)

entity_to_person(array_handle::VariableAtPeriod, role::Role) = entity_to_person(array_handle, array_handle.period,
  Role[role])

entity_to_person(array_handle::VariableAtPeriod, roles::Array{Role}) = entity_to_person(array_handle,
  array_handle.period, roles)

entity_to_person(array_handle::VariableAtPeriod) = entity_to_person(array_handle, array_handle.period, ALL_ROLES)


get_array(variable_at_period::VariableAtPeriod, default) = get_array(variable_at_period.variable,
  variable_at_period.period, default)

get_array(variable_at_period::VariableAtPeriod) = get_array(variable_at_period.variable, variable_at_period.period)

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
  @assert(array !== nothing, "Permanent variable $(variable.definition.name) has an uninitialized array.")
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


get_entity(variable_at_period::VariableAtPeriod) = get_entity(variable_at_period.variable)

get_entity(variable::Variable) = get_entity(variable.simulation, variable.definition.entity_definition)


get_variable(variable_at_period::VariableAtPeriod) = variable_at_period.variable

get_variable(variable::PermanentVariable) = variable


Base.show(io::IO, variable::PermanentVariable) = print(io,
  "$(typeof(variable))($(variable.definition.name), $(variable.array))")

function Base.show(io::IO, variable_at_period::VariableAtPeriod)
  name = variable_at_period.variable.definition.name
  print(io, "$(typeof(variable_at_period))($name, $(string(variable_at_period.period)), " *
    "$(get_array(variable_at_period)))")
end


function set_array(variable::PeriodicVariable, period::DatePeriod, array::Union(Array, BitArray))
  @assert(array !== nothing, "Can't set variable $(variable.definition.name) to nothing.")
  @assert(ndims(array) == 1, "Array of $(variable.definition.name) is not a vector.")
  @assert(length(array) == get_entity(variable).count, "Can't set variable $(variable.definition.name) to an array" *
    " that is not of length $(get_entity(variable).count): $(array).")
  @assert(all(cell -> cell !== nothing, array),
    "Can't set variable $(variable.definition.name) to an array containing nothing items: $array.")
  cell_type = variable.definition.cell_type
  variable.array_by_period[period] = convert(cell_type === Bool ? BitArray: Array{cell_type}, array)
  return ConcreteVariableAtPeriod(variable, period)
end

function set_array(variable::PeriodicVariable, variable_at_period::VariableAtPeriod)
  array = get_array(variable_at_period)
  @assert(array !== nothing, "Can't set variable $(variable.definition.name) to nothing.")
  @assert(ndims(array) == 1, "Array of $(variable.definition.name) is not a vector.")
  @assert(length(array) == get_entity(variable).count, "Can't set variable $(variable.definition.name) to an array" *
    " that is not of length $(get_entity(variable).count): $(array).")
  @assert(all(cell -> cell !== nothing, array),
    "Can't set variable $(variable.definition.name) to an array containing nothing items: $array.")
  cell_type = variable.definition.cell_type
  variable.array_by_period[variable_at_period.period] = convert(cell_type === Bool ? BitArray: Array{cell_type}, array)
  return variable_at_period
end

set_array(variable::PeriodicVariable, array::Union(Array, BitArray)) = set_array(variable, variable.simulation.period,
  array)

set_array(variable::PermanentVariable, period::DatePeriod, array::Union(Array, BitArray)) = set_array(variable, array)

function set_array(variable::PermanentVariable, array::Union(Array, BitArray))
  @assert(array !== nothing, "Can't set variable $(variable.definition.name) to nothing.")
  @assert(ndims(array) == 1, "Array of $(variable.definition.name) is not a vector.")
  @assert(length(array) == get_entity(variable).count, "Can't set variable $(variable.definition.name) to an array" *
    " that is not of length $(get_entity(variable).count): $(array).")
  @assert(all(cell -> cell !== nothing, array),
    "Can't set variable $(variable.definition.name) to an array containing nothing items: $array.")
  cell_type = variable.definition.cell_type
  variable.array = convert(cell_type === Bool ? BitArray: Array{cell_type}, array)
  return variable
end


function single_person_in_entity(array_handle::ArrayHandle, entity::Entity, period::DatePeriod, role::Role)
  @assert(is_person(get_entity(array_handle)))
  @assert(!is_person(entity))
  person_array = get_array(array_handle)
  cell_type = eltype(person_array)
  entity_array = issubtype(cell_type, String) ? fill("", entity.count) : zeros(cell_type, entity.count)
  for (index_cell, role_cell, value_cell) in zip(
        get_array(get_index_variable(entity)),
        get_array(get_role_variable(entity), period),
        person_array,
      )
    if Role(role_cell) === role
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


function sum_person_in_entity(array_handle::ArrayHandle, entity::Entity, period::DatePeriod, roles::Array{Role})
  @assert(is_person(get_entity(array_handle)))
  @assert(!is_person(entity))
  person_array = get_array(array_handle)
  cell_type = eltype(person_array)
  entity_array = zeros(cell_type === Bool ? Int16 : cell_type, entity.count)
  if roles == ALL_ROLES
    for (index_cell, value_cell) in zip(
          get_array(get_index_variable(entity)),
          person_array,
        )
      entity_array[index_cell] += value_cell
    end
  else
    for (index_cell, role_cell, value_cell) in zip(
          get_array(get_index_variable(entity)),
          get_array(get_role_variable(entity), period),
          person_array,
        )
      if Role(role_cell) in roles
        entity_array[index_cell] += value_cell
      end
    end
  end
  return ConcreteEntityArray(entity, entity_array)
end

sum_person_in_entity(array_handle::ArrayHandle, entity::Entity, period::DatePeriod
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
  return isempty(variable.array) ? default : variable
end

function variable_at(variable::PeriodicVariable, period::DatePeriod)
  variable_at_period = variable_at(variable, period, nothing)
  if variable_at_period === nothing
    throw(KeyError(period))
  end
  return variable_at_period
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
