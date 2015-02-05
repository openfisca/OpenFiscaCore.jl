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


type VariableDefinition
  formula::Function
  name::String
  entity_definition::EntityDefinition
  cell_type::Type
  cell_format
  cell_default
  cerfa_field
  input_variable::Bool
  label::String
  permanent::Bool  # When true, value of variable doesn't depend from date (examples: ID, birth).
  start_date
  stop_date
  url
  values

  function VariableDefinition(formula, name::String, entity_definition::EntityDefinition, cell_type;
      cell_default = nothing, cell_format = nothing, cerfa_field = nothing, input_variable = false, label = name,
      permanent = false, start_date = nothing, stop_date = nothing, url = nothing, values = nothing)
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
    return new(formula, name, entity_definition, cell_type, cell_format, cell_default, cerfa_field, input_variable,
      label, permanent, start_date, stop_date, url, values)
  end
end

function VariableDefinition(name::String, entity_definition::EntityDefinition, cell_type; cell_default = nothing,
    cell_format = nothing, cerfa_field = nothing, label = name, permanent = false, return_last_period_value = false,
    start_date = nothing, stop_date = nothing, url = nothing, values = nothing)
  @assert !permanent || !return_last_period_value
  formula = permanent ?
    (simulation, variable) -> default_array(variable) :
    return_last_period_value ?
      last_period_value :
      (simulation, variable, period) -> (period, default_array(variable))
  return VariableDefinition(formula, name, entity_definition, cell_type, cell_default = cell_default,
    cell_format = cell_format, cerfa_field = cerfa_field, input_variable = true, label = label, permanent = permanent,
    start_date = start_date, stop_date = stop_date, url = url, values = values)
end


function json_at_date_to_cell(cell_type::Type{Bool})
  return convertible::Convertible -> pipe(
    test_isa(Union(Bool, Int, String)),
    guess_bool,
  )(convertible)
end

function json_at_date_to_cell(cell_type::Type{Date})
  return convertible::Convertible -> pipe(
    condition(
      # test_isa(Date),
      # noop,
      test_isa(Int),
      pipe(
        test_between(1870, 2099),
        call(year -> Date(year, 1, 1)),
      ),
      pipe(
        test_isa(String),
        iso8601_input_to_date,
      ),
    ),
    test_between(Date(1870, 1, 1), Date(2099, 12, 31)),
  )(convertible)
end

function json_at_date_to_cell(cell_type::Type{Float32})
  return convertible::Convertible -> pipe(
    test_isa(Real),
    to_float,
  )(convertible)
end

function json_at_date_to_cell(cell_type::Type{Int32})
  return convertible::Convertible -> pipe(
    test_isa(Integer),
    test_between(typemin(Int32), typemax(Int32)),
    call(value -> convert(Int32, value)),
  )(convertible)
end

function json_at_date_to_cell(cell_type::Type{Int16})
  return convertible::Convertible -> pipe(
    test_isa(Integer),
    test_between(typemin(Int16), typemax(Int16)),
    call(value -> convert(Int16, value)),
  )(convertible)
end

function json_at_date_to_cell(cell_type::Type{UTF8String})
  return convertible::Convertible -> test_isa(String)(convertible)
end

json_at_date_to_cell(variable_definition::VariableDefinition) = json_at_date_to_cell(variable_definition.cell_type)


function json_to_cell(variable_definition::VariableDefinition)
  return convertible::Convertible -> condition(
    test_isa(Dict{String, Any}),
    pipe(
      # Value is a dict of (period, value) couples.
      uniform_mapping(
        pipe(
          to_period,
          require,
        ),
        json_at_date_to_cell(variable_definition),
      ),
    ),
    json_at_date_to_cell(variable_definition),
  )(convertible)
end
