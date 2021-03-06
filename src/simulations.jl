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


immutable NameAtDate
  name::String
  date::Date
end


immutable NameAtPeriod
  name::String
  period::Union(DatePeriod, Nothing)
end


type FormulaInput
  variable_name::String
  period::Union(DatePeriod, Nothing)
  parameters_name_at_date::Array{NameAtDate}
  variables_name_at_period::Array{NameAtPeriod}

  FormulaInput(variable_name, period) = new(variable_name, period, NameAtDate[], NameAtPeriod[])
end

FormulaInput(variable_name) = FormulaInput(variable_name, nothing)


type Simulation <: AbstractSimulation
  tax_benefit_system::TaxBenefitSystem
  period::DatePeriod
  debug::Bool
  debug_all::Bool  # TODO: To rename to debug_default?
  entity_by_name::Dict{String, Entity}
  formulas_input_stack::Array{FormulaInput}
  legislation_by_date_cache::Dict{Date, Legislation}
  reference_legislation_by_date_cache::Dict{Date, Legislation}
  trace::Bool
  variable_by_name::Dict{String, Variable}

  function Simulation(tax_benefit_system::TaxBenefitSystem, period::DatePeriod, variable_by_name; debug = false,
      debug_all = false, trace = false)
    if !debug && debug_all
      debug = true
    end
    simulation = new(tax_benefit_system, period, debug, debug_all, (String => Entity)[], FormulaInput[],
      (Date => Legislation)[], (Date => Legislation)[], trace, variable_by_name)
    simulation.entity_by_name = [
      name => Entity(simulation, entity_definition)
      for (name, entity_definition) in tax_benefit_system.entity_definition_by_name
    ]
    return simulation
  end
end

function Simulation(scenario::Scenario; debug = false, debug_all = false, trace = false)
  simulation = Simulation(
    scenario.tax_benefit_system,
    scenario.period,
    debug = debug,
    debug_all = debug_all,
    trace = trace,
  )
  fill!(simulation, scenario)
  for entity in values(simulation.entity_by_name)
    @assert(entity.count > 0, "Entity $(entity.definition.name) has no member.")
  end
  return simulation
end

Simulation(tax_benefit_system::TaxBenefitSystem, period::DatePeriod; debug = false, debug_all = false, trace = false
  ) = Simulation(tax_benefit_system, period, Dict{String, Variable}(), debug = debug, debug_all = debug_all,
  trace = trace)


function calculate(simulation::Simulation, variable_name::String, period; accept_other_period = false)
  if (simulation.debug || simulation.trace) && !isempty(simulation.formulas_input_stack)
    variable_name_at_period = NameAtPeriod(variable_name, period)
    calling_formula_input_variables_name_at_period = simulation.formulas_input_stack[end].variables_name_at_period
    if !(variable_name_at_period in calling_formula_input_variables_name_at_period)
      push!(calling_formula_input_variables_name_at_period, variable_name_at_period)
    end
  end
  return calculate(get_variable!(simulation, variable_name), period, accept_other_period = accept_other_period)
end

calculate(simulation::Simulation, variable_name::String; accept_other_period = false) = calculate(simulation, variable_name,
  simulation.period, accept_other_period = accept_other_period)


function calculate_add(simulation::Simulation, variable_name::String, period)
  if (simulation.debug || simulation.trace) && !isempty(simulation.formulas_input_stack)
    variable_name_at_period = NameAtPeriod(variable_name, period)
    calling_formula_input_variables_name_at_period = simulation.formulas_input_stack[end].variables_name_at_period
    if !(variable_name_at_period in calling_formula_input_variables_name_at_period)
      push!(calling_formula_input_variables_name_at_period, variable_name_at_period)
    end
  end
  return calculate_add(get_variable!(simulation, variable_name), period)
end

calculate_add(simulation::Simulation, variable_name::String) = calculate_add(simulation, variable_name, simulation.period)


function calculate_add_divide(simulation::Simulation, variable_name::String, period)
  if (simulation.debug || simulation.trace) && !isempty(simulation.formulas_input_stack)
    variable_name_at_period = NameAtPeriod(variable_name, period)
    calling_formula_input_variables_name_at_period = simulation.formulas_input_stack[end].variables_name_at_period
    if !(variable_name_at_period in calling_formula_input_variables_name_at_period)
      push!(calling_formula_input_variables_name_at_period, variable_name_at_period)
    end
  end
  return calculate_add_divide(get_variable!(simulation, variable_name), period)
end

calculate_add_divide(simulation::Simulation, variable_name::String) = calculate_add_divide(simulation, variable_name,
  simulation.period)


function calculate_divide(simulation::Simulation, variable_name::String, period)
  if (simulation.debug || simulation.trace) && !isempty(simulation.formulas_input_stack)
    variable_name_at_period = NameAtPeriod(variable_name, period)
    calling_formula_input_variables_name_at_period = simulation.formulas_input_stack[end].variables_name_at_period
    if !(variable_name_at_period in calling_formula_input_variables_name_at_period)
      push!(calling_formula_input_variables_name_at_period, variable_name_at_period)
    end
  end
  return calculate_divide(get_variable!(simulation, variable_name), period)
end

calculate_divide(simulation::Simulation, variable_name::String) = calculate_divide(simulation, variable_name, simulation.period)


entity_to_entity_period_value(simulation::Simulation, variable::PeriodicVariable, period::DatePeriod
) = variable.definition.formula(simulation, variable, period)


function fill!(simulation::Simulation, scenario::InputVariablesScenario)
  person = get_person(simulation)
  variable_definition_by_name = simulation.tax_benefit_system.variable_definition_by_name

  if scenario.input_variables !== nothing
    for (variable_name, array_by_period) in scenario.input_variables
      variable = get_variable!(simulation, variable_name)
      entity = get_entity(variable)
      for (period, array) in array_by_period
        if entity.count == 0
          entity.count = length(array)
        end
        set_array(variable, period, array)
      end
    end
  end

  if person.count == 0
    person.count = 1
  end
  for entity in values(simulation.entity_by_name)
    if entity === person
      continue
    end

    index_variable = get_index_variable(entity)
    index_array = get_array!(index_variable, simulation.period) do
      index_array = Array(index_variable.definition.cell_type, person.count)
      for i in 1:person.count
        index_array[i] = i
      end
      return index_array
    end

    role_variable = get_role_variable(entity)
    role_array = get_array!(role_variable, simulation.period) do
      return ones(role_variable.definition.cell_type, person.count)
    end
    entity.roles_count = 1

    if entity.count == 0
      entity.count = maximum(index_array)
    end
  end
end


function fill!(simulation::Simulation, scenario::TestCaseScenario)
  variable_definition_by_name = simulation.tax_benefit_system.variable_definition_by_name
  person = get_person(simulation)
  person_plural = person.definition.name_plural
  test_case = scenario.test_case

  scenario_steps_count = steps_count(scenario)
  for entity in values(simulation.entity_by_name)
    entity.count = scenario_steps_count * length(test_case[entity.definition.name_plural])
  end

  person_index_by_id = [
    person["id"] => person_index
    for (person_index, person) in enumerate(test_case[person_plural])
  ]

  for entity in values(simulation.entity_by_name)
    if entity === person
      continue
    end

    entity_plural = entity.definition.name_plural
    index_variable = get_index_variable(entity)
    index_array = get_array!(index_variable, simulation.period) do
      return Array(index_variable.definition.cell_type, person.count)
    end
    role_variable = get_role_variable(entity)
    role_array = get_array!(role_variable, simulation.period) do
      return Array(role_variable.definition.cell_type, person.count)
    end
    for (member_index, member) in enumerate(test_case[entity_plural])
      for (person_id, person_role) in entity.definition.each_person_id_and_role(member)
        person_index = person_index_by_id[person_id]
        for step_index in 1:scenario_steps_count
          absolute_person_index = (step_index - 1) * length(test_case[person_plural]) + person_index
          index_array[absolute_person_index] = (step_index - 1) * length(test_case[entity_plural]) + member_index
          role_array[absolute_person_index] = person_role
        end
      end
    end
    entity.roles_count = maximum(role_array)
  end

  for entity in values(simulation.entity_by_name)
    entity_plural = entity.definition.name_plural
    allowed_variables_name = Set(vcat([
      collect(keys(filter(member) do key, value
        return value !== nothing && !(key in (entity.definition.index_variable_name,
          entity.definition.role_variable_name))
      end))
      for member in test_case[entity_plural]
    ]...))
    for (variable_name, variable_definition) in variable_definition_by_name
      if variable_definition.entity_definition !== entity.definition || !(variable_name in allowed_variables_name)
        continue
      end

      variable_periods = Set{DatePeriod}()
      for member in test_case[entity_plural]
        cell = get(member, variable_name, nothing)
        if isa(cell, Union(Dict, OrderedDict))
          if any(value -> value !== nothing, values(cell))
            union!(variable_periods, keys(cell))
          end
        elseif cell !== nothing
          push!(variable_periods, simulation.period)
        end
      end

      variable = get_variable!(entity, variable_name)
      for variable_period in variable_periods
        variable_values = map(test_case[entity_plural]) do member
          cell = get(member, variable_name, nothing)
          cell_at_period = isa(cell, Union(Dict, OrderedDict)) ?
            get(cell, variable_period, nothing) :
            variable_period == simulation.period ? cell : nothing
          return cell_at_period === nothing ? variable_definition.cell_default : cell_at_period
        end
        set_array(variable, variable_period, repeat(variable_values, outer = [scenario_steps_count]))
      end
    end
  end

  if scenario.axes !== nothing
    if length(scenario.axes) == 1
      parallel_axes = scenario.axes[1]
      # All parallel axes have the same count and entity.
      first_axis = parallel_axes[1]
      axis_count = first_axis["count"]
      axis_variable = get_variable!(simulation, first_axis["name"])
      axis_entity = get_entity(axis_variable)
      axis_entity_plural = axis_entity.definition.name_plural
      for axis in parallel_axes
        axis_period = axis["period"] === nothing ? simulation.period : axis["period"]
        axis_variable = get_variable!(simulation, axis["name"])
        axis_array = get_array!(axis_variable, axis_period) do
          return default_array(axis_variable)
        end
        axis_values = linspace(axis["min"], axis["max"], axis_count)
        if axis_variable.definition.cell_type <: Integer
          axis_values = map(x -> round(Integer, x), axis_values)
        end
        axis_array[axis["index"] + 1:length(test_case[axis_entity_plural]):end] = axis_values
        # TODO: set_input(...).
      end
    else
      for (parallel_axes_index, parallel_axes) in enumerate(scenario.axes)
        # All parallel axes have the same count and entity.
        first_axis = parallel_axes[1]
        axis_count = first_axis["count"]

        linspace_vector = linspace(0, axis_count - 1, axis_count)
        linspace_array = reshape(linspace_vector, [
          index == parallel_axes_index ? axis_count : 1
          for index in 1:length(scenario.axes)
        ]...)
        ranges = [
          index == parallel_axes_index ? [1:axis_count]: ones(Int, parallel_axes1[1]["count"])
          for (index, parallel_axes1) in enumerate(scenario.axes)
        ]
        mesh_array = linspace_array[ranges...]
        mesh_vector = reshape(linspace_vector, [
          index == parallel_axes_index ? scenario_steps_count : 1
          for index in 1:length(scenario.axes)
        ]...)

        axis_variable = get_variable!(simulation, first_axis["name"])
        axis_entity = get_entity(axis_variable)
        axis_entity_plural = axis_entity.definition.name_plural
        for axis in parallel_axes
          axis_period = axis["period"] === nothing ? simulation.period : axis["period"]
          axis_variable = get_variable!(simulation, axis["name"])
          axis_array = get_array!(axis_variable, axis_period) do
            return default_array(axis_variable)
          end
          axis_array[axis["index"] + 1:length(test_case[axis_entity_plural]):end] = axis["min"] +
            mesh_vector * (axis["max"] - axis["min"]) / (axis_count - 1)
          # TODO: set_input(...).
        end
      end
    end
  end
end


get_entity(simulation::Simulation, definition::EntityDefinition) = simulation.entity_by_name[definition.name]

get_entity(simulation::Simulation, name::String) = simulation.entity_by_name[name]


get_person(simulation::Simulation) = get_entity(simulation, simulation.tax_benefit_system.person_name)


get_variable(simulation::Simulation, variable_name::String) = simulation.variable_by_name[variable_name]


function get_variable!(simulation::Simulation, variable_name::String)
  return get!(simulation.variable_by_name, variable_name) do
    definition = simulation.tax_benefit_system.variable_definition_by_name[variable_name]
    return (definition.permanent ? ConcretePermanentVariable : ConcretePeriodicVariable)(simulation, definition)
  end
end


function last_duration_last_value(simulation::Simulation, variable::PeriodicVariable, period::DatePeriod)
  # This formula is used for variables that are constants between events but are period size dependent.
  # It returns the latest known value for the requested start of period but with the last period size.
  formula = variable.definition.formula
  for last_period in sort(collect(keys(variable.array_by_period)), by = period -> period.start, rev = true)
    if last_period.start <= period.start && (formula === nothing || stop_date(last_period) >= stop_date(period))
      return typeof(last_period)(period.start, last_period.length), variable.array_by_period[last_period]
    end
  end
  if formula !== nothing
    return formula(simulation, variable, period)
  end
  return period, default_array(variable)
end


function legislation_at(simulation::Simulation, path, date::Date; reference = false)
  legislation_at_date = legislation_at(simulation, date, reference = reference)
  return path !== nothing && !isempty(path) ? legislation_at(legislation_at_date, path) : legislation_at_date
end

legislation_at(simulation::Simulation, date::Date; reference = false) = (reference ?
  get!(simulation.reference_legislation_by_date_cache, date) do
    return legislation_at(simulation.tax_benefit_system, date, reference = true)
  end
:
  get!(simulation.legislation_by_date_cache, date) do
    return legislation_at(simulation.tax_benefit_system, date)
  end
)


function missing_value(simulation::Simulation, variable::PeriodicVariable, period::DatePeriod)
  formula = variable.definition.formula
  if formula !== nothing
    return formula(simulation, variable, period)
  end
  error("Missing value for variable $(variable.definition.name) at $(string(period))")
end


function permanent_default_value(simulation::Simulation, variable::PermanentVariable)
  formula = variable.definition.formula
  if formula !== nothing
    return formula(simulation, variable)
  end
  return default_array(variable)
end


Base.show(io::IO, simulation::Simulation) = print(io,
  "$(typeof(simulation))($(simulation.tax_benefit_system), $(string(simulation.period)))")


function requested_period_default_value(simulation::Simulation, variable::PeriodicVariable, period::DatePeriod)
  formula = variable.definition.formula
  if formula !== nothing
    return formula(simulation, variable, period)
  end
  return period, default_array(variable)
end


function requested_period_last_value(simulation::Simulation, variable::PeriodicVariable, period::DatePeriod)
  # This formula is used for variables that are constants between events and period size independent.
  # It returns the latest known value for the requested period.
  formula = variable.definition.formula
  for last_period in sort(collect(keys(variable.array_by_period)), by = period -> period.start, rev = true)
    if last_period.start <= period.start && (formula === nothing || stop_date(last_period) >= stop_date(period))
      return period, variable.array_by_period[last_period]
    end
  end
  if formula !== nothing
    return formula(simulation, variable, period)
  end
  return period, default_array(variable)
end


set_array(simulation::Simulation, variable_name::String, period::DatePeriod, array::Array) = set_array(
  get_variable!(simulation, variable_name), period, array)

set_array(simulation::Simulation, variable_name::String, array_handle::VariableAtPeriodOrPermanent) = set_array(
  get_variable!(simulation, variable_name), array_handle)

set_array(simulation::Simulation, variable_name::String, array::Array) = set_array(
  get_variable!(simulation, variable_name), array)


function stringify_variables_name_at_period(simulation::Simulation, variables_name_at_period::Array{NameAtPeriod})
  # TODO: getarray() has a default argument because when accept_other_period is true an input variable may be
  # returned for a period different from the requested period.
  return join(
    String[
      "$(variable.definition.name)@$(get_entity(variable).definition.name)<$(string(period))>" *
        "$(get_array(variable, period, nothing))"
      for (variable, period) in [
        (simulation.variable_by_name[variable_name_at_period.name], variable_name_at_period.period)
        for variable_name_at_period in variables_name_at_period
      ]
    ],
    ", ")
end


variable_at(simulation::Simulation, variable_name::String, period, default) = variable_at(
  get_variable!(simulation, variable_name), period, default)

variable_at(simulation::Simulation, variable_name::String, default) = get_array(get_variable!(simulation, variable_name),
  default)
