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


type Simulation <: AbstractSimulation
  tax_benefit_system::TaxBenefitSystem
  period::DatePeriod
  entity_by_name::Dict{String, Entity}
  variable_by_name::Dict{String, Variable}
  trace::Bool

  function Simulation(tax_benefit_system, period, variable_by_name; trace = false)
    simulation = new(tax_benefit_system, period, Dict{String, Entity}(), variable_by_name, trace)
    simulation.entity_by_name = [
      name => Entity(simulation, entity_definition)
      for (name, entity_definition) in tax_benefit_system.entity_definition_by_name
    ]
    return simulation
  end
end

Simulation(tax_benefit_system, period; trace = false) = Simulation(tax_benefit_system, period, Dict{String, Variable}(),
  trace = trace)


calculate(simulation::Simulation, variable_name, period) = calculate(get_variable!(simulation, variable_name), period)

calculate(simulation::Simulation, variable_name) = calculate(
  get_variable!(simulation, variable_name), simulation.period)


divide_year(simulation::Simulation, variable_name, period) = divide_year(get_variable!(simulation, variable_name),
  period)

divide_year(simulation::Simulation, variable_name) = divide_year(
  get_variable!(simulation, variable_name), simulation.period)


get_entity(simulation::Simulation, definition::EntityDefinition) = simulation.entity_by_name[definition.name]

get_entity(simulation::Simulation, name::String) = simulation.entity_by_name[name]


get_person(simulation::Simulation) = get_entity(simulation, simulation.tax_benefit_system.person_name)


function get_variable!(simulation::Simulation, variable_name)
  return get!(simulation.variable_by_name, variable_name) do
    definition = simulation.tax_benefit_system.variable_definition_by_name[variable_name]
    return (definition.permanent ? ConcretePermanentVariable : ConcretePeriodicVariable)(simulation, definition)
  end
end


set_array(simulation::Simulation, variable_name, period::DatePeriod, array::Array) = set_array(
  get_variable!(simulation, variable_name), period, array)

set_array(simulation::Simulation, variable_name, array_handle::VariableAtDateOrPermanent) = set_array(
  get_variable!(simulation, variable_name), array_handle)

set_array(simulation::Simulation, variable_name, array::Array) = set_array(
  get_variable!(simulation, variable_name), array)


sum_months(simulation::Simulation, variable_name, period) = sum_months(get_variable!(simulation, variable_name), period)

sum_months(simulation::Simulation, variable_name) = sum_months(
  get_variable!(simulation, variable_name), simulation.period)


# function tax_scale_at(simulation::Simulation, tax_scale_name, date; reference = false)
#   if reference
#     reference_legislation_leaf_by_name = get!(simulation.reference_legislation_leaf_by_name_by_date, tax_scale_name) do
#       return Union(TaxRate, Parameter)
#     end
#   end
# end


variable_at(simulation::Simulation, variable_name, default) = get_array(get_variable!(simulation, variable_name),
  default)

variable_at(simulation::Simulation, variable_name, period, default) = variable_at(
  get_variable!(simulation, variable_name), period, default)
