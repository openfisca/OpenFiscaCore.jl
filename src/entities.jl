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


immutable Role
  value::Int8
end


ALL_ROLES = [Role(0)]


get_index_variable(entity::Entity) = get_variable!(entity.simulation, entity.definition.index_variable_name)


get_role_variable(entity::Entity) = get_variable!(entity.simulation, entity.definition.role_variable_name)


is_person(entity::Entity) = entity.definition.is_person
