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


const year_or_month_or_day_re = r"(18|19|20)\d{2}(-(0[1-9]|1[0-2])(-([0-2]\d|3[0-1]))?)?$"


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
  url
  values

  function VariableDefinition(formula, name::String, entity_definition::EntityDefinition, cell_type;
      cell_default = nothing, cell_format = nothing, cerfa_field = nothing, label = name, permanent = false,
      start_date = nothing, stop_date = nothing, url = nothing, values = nothing)
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
      start_date, stop_date, url, values)
  end
end

function VariableDefinition(name::String, entity_definition::EntityDefinition, cell_type; cell_default = nothing,
    cell_format = nothing, cerfa_field = nothing, label = name, permanent = false, start_date = nothing,
    stop_date = nothing, url = nothing, values = nothing)
  formula = (permanent
    ? (simulation, variable) -> default_array(variable)
    : (simulation, variable, period) -> (period, default_array(variable)))
  return VariableDefinition(formula, name, entity_definition, cell_type, cell_default = cell_default,
    cell_format = cell_format, cerfa_field = cerfa_field, label = label, permanent = permanent, start_date = start_date,
    stop_date = stop_date, url = url, values = values)
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
        test(value -> ismatch(year_or_month_or_day_re, value), error = N_("Invalid date.")),
        call(value -> join(union(split(value, '-'), ["01", "01"])[1:3], '-')),
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
  return convertible::Convertible -> test_isa(Int32)(convertible)
end

function json_at_date_to_cell(cell_type::Type{Int16})
  return convertible::Convertible -> test_isa(Int16)(convertible)
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
