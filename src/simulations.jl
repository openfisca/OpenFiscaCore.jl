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

  function Simulation(tax_benefit_system, period, variable_by_name; debug = false, debug_all = false, trace = false)
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

Simulation(tax_benefit_system, period; debug = false, debug_all = false, trace = false) = Simulation(tax_benefit_system,
  period, Dict{String, Variable}(), debug = debug, debug_all = debug_all, trace = trace)


function calculate(simulation::Simulation, variable_name, period)
  if (simulation.debug || simulation.trace) && !isempty(simulation.formulas_input_stack)
    variable_name_at_period = NameAtPeriod(variable_name, period)
    calling_formula_input_variables_name_at_period= simulation.formulas_input_stack[end].variables_name_at_period
    if !(variable_name_at_period in calling_formula_input_variables_name_at_period)
      push!(calling_formula_input_variables_name_at_period, variable_name_at_period)
    end
  end
  return calculate(get_variable!(simulation, variable_name), period)
end

calculate(simulation::Simulation, variable_name) = calculate(simulation, variable_name, simulation.period)


function divide_calculate(simulation::Simulation, variable_name, period)
  if (simulation.debug || simulation.trace) && !isempty(simulation.formulas_input_stack)
    variable_name_at_period = NameAtPeriod(variable_name, period)
    calling_formula_input_variables_name_at_period= simulation.formulas_input_stack[end].variables_name_at_period
    if !(variable_name_at_period in calling_formula_input_variables_name_at_period)
      push!(calling_formula_input_variables_name_at_period, variable_name_at_period)
    end
  end
  return divide_calculate(get_variable!(simulation, variable_name), period)
end

divide_calculate(simulation::Simulation, variable_name) = divide_calculate(simulation, variable_name, simulation.period)


get_entity(simulation::Simulation, definition::EntityDefinition) = simulation.entity_by_name[definition.name]

get_entity(simulation::Simulation, name::String) = simulation.entity_by_name[name]


get_person(simulation::Simulation) = get_entity(simulation, simulation.tax_benefit_system.person_name)


function get_variable!(simulation::Simulation, variable_name)
  return get!(simulation.variable_by_name, variable_name) do
    definition = simulation.tax_benefit_system.variable_definition_by_name[variable_name]
    return (definition.permanent ? ConcretePermanentVariable : ConcretePeriodicVariable)(simulation, definition)
  end
end


function legislation_at(simulation::Simulation, path, date::Date; reference = false)
  legislation_at_date = legislation_at(simulation, date, reference = reference)
  return path !== nothing && !isempty(path) ? legislation_at(legislation_at_date, path) : legislation_at_date
end

legislation_at(simulation::Simulation, date::Date; reference = false) = (reference ?
  get!(simulation.reference_legislation_by_date_cache, date) do
    return reference_legislation_at(simulation.tax_benefit_system, date)
  end
:
  get!(simulation.legislation_by_date_cache, date) do
    return legislation_at(simulation.tax_benefit_system, date)
  end
)


function print(io::IO, simulation::Simulation, indent = 0)
  print(io, "Simulation(tax_benefit_system, $(simulation.period))", indent)
end


set_array(simulation::Simulation, variable_name, period::DatePeriod, array::Array) = set_array(
  get_variable!(simulation, variable_name), period, array)

set_array(simulation::Simulation, variable_name, array_handle::VariableAtPeriodOrPermanent) = set_array(
  get_variable!(simulation, variable_name), array_handle)

set_array(simulation::Simulation, variable_name, array::Array) = set_array(
  get_variable!(simulation, variable_name), array)


function stringify_variables_name_at_period(simulation::Simulation, variables_name_at_period::Array{NameAtPeriod})
  return join(
    String[
      "$(variable.definition.name)@$(get_entity(variable).definition.name)<$period>$(get_array(variable, period))"
      for (variable, period) in [
        (simulation.variable_by_name[variable_name_at_period.name], variable_name_at_period.period)
        for variable_name_at_period in variables_name_at_period
      ]
    ],
    ", ")
end


function sum_calculate(simulation::Simulation, variable_name, period)
  if (simulation.debug || simulation.trace) && !isempty(simulation.formulas_input_stack)
    variable_name_at_period = NameAtPeriod(variable_name, period)
    calling_formula_input_variables_name_at_period= simulation.formulas_input_stack[end].variables_name_at_period
    if !(variable_name_at_period in calling_formula_input_variables_name_at_period)
      push!(calling_formula_input_variables_name_at_period, variable_name_at_period)
    end
  end
  return sum_calculate(get_variable!(simulation, variable_name), period)
end

sum_calculate(simulation::Simulation, variable_name) = sum_calculate(simulation, variable_name, simulation.period)


variable_at(simulation::Simulation, variable_name, period, default) = variable_at(
  get_variable!(simulation, variable_name), period, default)

variable_at(simulation::Simulation, variable_name, default) = get_array(get_variable!(simulation, variable_name),
  default)
