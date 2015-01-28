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


type EntityDefinition
  name::String
  index_variable_name::String  # Not used for persons
  role_variable_name::String  # Not used for persons
  is_person::Bool
  # key_plural::String

  EntityDefinition(name; index_variable_name = "", role_variable_name = "", is_person = false) = new(name,
    index_variable_name, role_variable_name, is_person)
end


type Entity
  simulation::AbstractSimulation
  definition::EntityDefinition
  count::Unsigned
  roles_count::Unsigned  # Not used for persons
  step_size::Unsigned

  Entity(simulation::AbstractSimulation, definition::EntityDefinition) = new(simulation, definition, 0, 0, 0)
end


function add_member(entity; args...)
  entity_definition = entity.definition
  entity.count += 1
  entity.step_size += 1
  member_index = entity.count
  simulation = entity.simulation

  # Add a cell to all arrays of all variables of entity.
  for (variable_name, variable) in simulation.variable_by_name
    if variable.definition.entity_definition === entity_definition
      if isa(variable, PeriodicVariable)
        for array in values(variable.array_by_period)
          push!(array, variable.definition.cell_default)
        end
      else
        @assert(isa(variable, PermanentVariable))
        push!(variable.array, variable.definition.cell_default)
      end
    end
  end

  # When entity is a person, ensure that the index & role of the person in the other entities are set.
  value_by_name = Dict{String, Any}([string(symbol) => value for (symbol, value) in args])
  if entity_definition.is_person
    for other_entity in values(simulation.entity_by_name)
      other_entity_definition = other_entity.definition
      if !other_entity_definition.is_person
        @assert(other_entity.count > 0)
        get!(value_by_name, other_entity_definition.index_variable_name) do
          return other_entity.count
        end
        role = get(value_by_name, other_entity_definition.role_variable_name, nothing)
        @assert(role !== nothing,
          "Missing role $(other_entity_definition.role_variable_name) in person arguments: $(value_by_name)")
        if role > other_entity.roles_count
          other_entity.roles_count = role
        end
      end
    end
  end

  # Set arguments in variables.
  for (variable_name, value) in value_by_name
    variable = get_variable!(entity, variable_name)
    if isa(value, Dict)
      for (period, period_value) in value
        array = get_array!(variable, period) do
          return default_array(variable)
        end
        array[member_index] = period_value
      end
    else
      period = simulation.period
      array = get_array!(variable, period) do
        return default_array(variable)
      end
      array[member_index] = value
    end
  end

  return member_index
end


get_index_variable(entity::Entity) = get_variable!(entity.simulation, entity.definition.index_variable_name)


get_role_variable(entity::Entity) = get_variable!(entity.simulation, entity.definition.role_variable_name)


function get_variable!(entity::Entity, variable_name)
  variable = get_variable!(entity.simulation, variable_name)
  @assert(variable.definition.entity_definition === entity.definition,
    "Variable $variable_name doesn't belong to entity $(entity.definition.name)")
  return variable
end


is_person(entity::Entity) = entity.definition.is_person
