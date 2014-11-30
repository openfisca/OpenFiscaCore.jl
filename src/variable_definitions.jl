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


export BareVariableDefinition, FormulaDefinition, VariableDefinition


abstract VariableDefinition


type BareVariableDefinition <: VariableDefinition
  name::String
  entity_definition::EntityDefinition
  cell_type::Type
  label::String
  permanent::Bool  # When true, value of variable doesn't depend from date (example: ID, birth)
end

BareVariableDefinition(name, entity_definition, cell_type; label = name, permanent = false) = BareVariableDefinition(
  name, entity_definition, cell_type, label, permanent)


type FormulaDefinition <: VariableDefinition
  func::Function
  name::String
  entity_definition::EntityDefinition
  cell_type::Type
  label::String
  permanent::Bool  # When true, value of variable doesn't depend from date (example: ID, birth)
end

FormulaDefinition(func, name, entity_definition, cell_type; label = name, permanent = false) = FormulaDefinition(func,
  name, entity_definition, cell_type, label, permanent)
