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


type VariableDefinition
  formula::Function
  name::String
  entity_definition::EntityDefinition
  cell_type::Type
  cell_format
  cell_default
  cerfa_field
  label::String
  permanent::Bool  # When true, value of variable doesn't depend from date (example: ID, birth)
  start_date
  stop_date
  values

  function VariableDefinition(formula, name::String, entity_definition::EntityDefinition, cell_type;
      cell_default = nothing, cell_format = nothing, cerfa_field = nothing, label = name, permanent = false,
      start_date = nothing, stop_date = nothing, values = nothing)
    if cell_default === nothing
      cell_default =
        cell_type <: Date ? Date(1970, 1, 1) :
        cell_type <: Day ? 0 :
        cell_type <: Real ? 0.0 :
        cell_type <: Int ? 0 :
        cell_type <: Month ? 0 :
        cell_type <: Role ? Role(0) :
        cell_type <: String ? "" :
        cell_type <: Unsigned ? 0 :
        cell_type <: Year ? 0 :
        error("Unknown default for type ", cell_type)
    end
    return new(formula, name, entity_definition, cell_type, cell_format, cell_default, cerfa_field, label, permanent,
      start_date, stop_date, values)
  end
end

function VariableDefinition(name::String, entity_definition::EntityDefinition, cell_type; cell_default = nothing,
    cell_format = nothing, cerfa_field = nothing, label = name, permanent = false, start_date = nothing,
    stop_date = nothing, values = nothing)
  formula = permanent ? variable -> default_array(variable) : (variable, period) -> (period, default_array(variable))
  return VariableDefinition(formula, name, entity_definition, cell_type, cell_default = cell_default,
    cell_format = cell_format, cerfa_field = cerfa_field, label = label, permanent = permanent, start_date = start_date,
    stop_date = stop_date, values = values)
end