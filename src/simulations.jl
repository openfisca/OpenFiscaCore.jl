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


type Simulation <: AbstractSimulation
  tax_benefit_system::TaxBenefitSystem
  period::DatePeriod
  entity_by_name::Dict{String, Entity}
  variable_by_name::Dict{String, Variable}

  function Simulation(tax_benefit_system, period, variable_by_name)
    simulation = new(tax_benefit_system, period, Dict{String, Entity}(), variable_by_name)
    simulation.entity_by_name = [
      name => Entity(simulation, entity_definition)
      for (name, entity_definition) in tax_benefit_system.entity_definition_by_name
    ]
    return simulation
  end
end

Simulation(tax_benefit_system, period) = Simulation(tax_benefit_system, period, Dict{String, Variable}())


get_array_handle(simulation::Simulation, variable_name, default) = get_array(get_variable!(simulation, variable_name),
  default)

get_array_handle(simulation::Simulation, variable_name, period, default) = get_array_handle(
  get_variable!(simulation, variable_name), period, default)


get_entity(simulation::Simulation, definition::EntityDefinition) = simulation.entity_by_name[definition.name]

get_entity(simulation::Simulation, name::String) = simulation.entity_by_name[name]


get_person(simulation::Simulation) = get_entity(simulation, simulation.tax_benefit_system.person_name)


function get_variable!(simulation::Simulation, variable_name)
  get!(simulation.variable_by_name, variable_name) do
    definition = simulation.tax_benefit_system.variable_definition_by_name[variable_name]
    return (definition.permanent ? PermanentVariable : PeriodicVariable)(simulation, definition)
  end
end


set_array_handle(simulation::Simulation, variable_name, period::DatePeriod, array::Array) = set_array_handle(
  get_variable!(simulation, variable_name), period, array)

set_array_handle(simulation::Simulation, variable_name, array_handle::ArrayHandle) = set_array_handle(
  get_variable!(simulation, variable_name), array_handle)

set_array_handle(simulation::Simulation, variable_name, array::Array) = set_array_handle(
  get_variable!(simulation, variable_name), array)
