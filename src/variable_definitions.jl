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
  formula
  name::String
  entity_definition::EntityDefinition
  cell_type::Type
  base_formula::Function
  cell_format
  cell_default
  cell_to_value_at_period_json::Function
  cerfa_field
  label::String
  permanent::Bool  # When true, value of variable doesn't depend from date (examples: ID, birth).
  start_date
  stop_date
  url
  value_at_period_to_cell::Function
  values

  function VariableDefinition(formula, name::String, entity_definition::EntityDefinition, cell_type::Type,
      base_formula::Function; cell_default = nothing, cell_format = nothing, cell_to_value_at_period_json = nothing, cerfa_field = nothing,
      label = name, permanent = false, start_date = nothing, stop_date = nothing, url = nothing,
      value_at_period_to_cell = nothing, values = nothing)
    if cell_default === nothing
      cell_default =
        cell_type <: Bool ? false :
        cell_type <: Day ? 0 :
        cell_type <: FloatingPoint ? 0.0 :
        cell_type <: Integer ? 0 :
        cell_type <: Month ? 0 :
        cell_type <: Role ? Role(0) :
        cell_type <: String ? "" :
        cell_type <: Year ? 0 :
        error("Unknown default for type ", cell_type)
    end
    if cell_to_value_at_period_json === nothing
      cell_to_value_at_period_json =
        cell_type <: Bool ? identity :
        cell_type <: Date ? string :
        cell_type <: Day ? int :
        cell_type <: FloatingPoint ? identity :
        cell_type <: Integer ? identity :
        cell_type <: Month ? int :
        cell_type <: Role ? int :
        cell_type <: String ? identity :
        cell_type <: Year ? int :
        error("Unknown function cell_to_value_at_period_json for type ", cell_type)
    end
    if value_at_period_to_cell === nothing
      value_at_period_to_cell =
        cell_type <: Bool ? value_at_period_to_bool :
        cell_type <: Date ? value_at_period_to_date :
        cell_type <: Day ? value_at_period_to_day :
        cell_type <: FloatingPoint ? value_at_period_to_floating_point :
        cell_type <: Integer ? value_at_period_to_integer :
        cell_type <: Month ? value_at_period_to_month :
        cell_type <: Role ? value_at_period_to_role :
        cell_type <: String ? value_at_period_to_string :
        cell_type <: Year ? value_at_period_to_year :
        error("Unknown converter value_at_period_to_cell for type ", cell_type)
    end
    return new(formula, name, entity_definition, cell_type, base_formula, cell_format, cell_default, cell_to_value_at_period_json,
      cerfa_field, label, permanent, start_date, stop_date, url, value_at_period_to_cell, values)
  end
end

VariableDefinition(name::String, entity_definition::EntityDefinition, cell_type::Type, base_formula::Function;
  cell_default = nothing, cell_format = nothing, cell_to_value_at_period_json = nothing, cerfa_field = nothing, label = name, permanent = false,
  start_date = nothing, stop_date = nothing, url = nothing, value_at_date_to_cell = nothing, values = nothing
) = VariableDefinition(nothing, name, entity_definition, cell_type, base_formula, cell_default = cell_default,
  cell_format = cell_format, cell_to_value_at_period_json = cell_to_value_at_period_json, cerfa_field = cerfa_field, label = label, permanent = permanent,
  start_date = start_date, stop_date = stop_date, url = url, value_at_date_to_cell = value_at_date_to_cell, values = values)


function to_cell(variable_definition::VariableDefinition)
  value_at_period_to_cell = variable_definition.value_at_period_to_cell(variable_definition)
  return convertible::Convertible -> condition(
    test_isa(Dict),
    pipe(
      # Value is a dict of (period, value) couples.
      uniform_mapping(
        pipe(
          to_period,
          require,
        ),
        value_at_period_to_cell,
      ),
    ),
    value_at_period_to_cell,
  )(convertible)
end


function value_at_period_to_bool(variable_definition::VariableDefinition)
  return convertible::Convertible -> pipe(
    test_isa(Union(Bool, Int, String)),
    guess_bool,
  )(convertible)
end


function value_at_period_to_date(variable_definition::VariableDefinition)
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


function value_at_period_to_day(variable_definition::VariableDefinition)
  return convertible::Convertible -> condition(
    test_isa(Day),
    noop,
    pipe(
      value_at_period_to_integer(variable_definition),
      call(value -> Day(value)),
    ),
  )(convertible)
end


function value_at_period_to_floating_point(variable_definition::VariableDefinition)
  return convertible::Convertible -> pipe(
    test_isa(Union(Real, String)),  # Type String is used for numerical expressions like 1.0 - 0.2 * 3.
    to_float(accept_expression = true),
  )(convertible)
end


function value_at_period_to_integer(variable_definition::VariableDefinition)
  return convertible::Convertible -> pipe(
    variable_definition.values === nothing ? noop : condition(
      test_isa(String),
      pipe(
        test_in(keys(variable_definition.values)),
        call(label -> variable_definition.values[label]),
      ),
    ),
    test_isa(Union(Real, String)),  # Type String is used for numerical expressions like 1 - 2 * 3.
    to_int(accept_expression = true),
#     test_between(typemin(Int32), typemax(Int32)),
#     call(value -> convert(Int32, value)),
  )(convertible)
end


function value_at_period_to_month(variable_definition::VariableDefinition)
  return convertible::Convertible -> condition(
    test_isa(Month),
    noop,
    pipe(
      value_at_period_to_integer(variable_definition),
      call(value -> Month(value)),
    ),
  )(convertible)
end


function value_at_period_to_role(variable_definition::VariableDefinition)
  return convertible::Convertible -> condition(
    test_isa(Role),
    noop,
    pipe(
      value_at_period_to_integer(variable_definition),
      call(value -> Role(value)),
    ),
  )(convertible)
end


function value_at_period_to_string(variable_definition::VariableDefinition)
  return convertible::Convertible -> condition(
    test_isa(Real),
    call(string),
    test_isa(String),
    noop,
    fail(error = N_("Unexpected type for string.")),
  )(convertible)
end


function value_at_period_to_year(variable_definition::VariableDefinition)
  return convertible::Convertible -> condition(
    test_isa(Year),
    noop,
    pipe(
      value_at_period_to_integer(variable_definition),
      call(value -> Year(value)),
    ),
  )(convertible)
end
