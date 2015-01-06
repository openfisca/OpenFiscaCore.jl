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


type TaxBenefitSystem
  entity_definition_by_name::Dict{String, EntityDefinition}
  parameter_by_date_by_name::Dict{String, Dict{Date, Any}}  # Cache of parameter_at_date items
  parameter_by_name::Dict{String, Union(Parameter, TaxScale)}
  person_name::String  # Name of person entity
  variable_definition_by_name::Dict{String, VariableDefinition}

  TaxBenefitSystem(entity_definition_by_name::Dict{String, EntityDefinition},
    parameter_by_name::Dict{String, Union(Parameter, TaxScale)},
    variable_definition_by_name::Dict{String, VariableDefinition}
  ) = new(
    entity_definition_by_name,
    Dict{String, Dict{Date, Any}}(),
    parameter_by_name,
    get_person_name(entity_definition_by_name),
    variable_definition_by_name,
  )
end

TaxBenefitSystem(entities_definition::Array{EntityDefinition},
  parameter_by_name::Dict{String, Union(Parameter, TaxScale)}, variables_definition::Array{VariableDefinition}
) = TaxBenefitSystem(
  [
    entity_definition.name => entity_definition
    for entity_definition in entities_definition
  ],
  parameter_by_name,
  [
    variable_definition.name => variable_definition
    for variable_definition in variables_definition
  ],
)


function get_person_name(entity_definition_by_name::Dict{String, EntityDefinition})
  for (entity_name, entity_definition) in entity_definition_by_name
    if entity_definition.is_person
      return entity_name
    end
  end
  error("List of entities ", entity_definition_by_name, " contains no person entity")
end
