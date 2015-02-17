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


function to_test(tax_benefit_system::TaxBenefitSystem)
  variable_definition_by_name = tax_benefit_system.variable_definition_by_name
  variables_name = Set(keys(variable_definition_by_name))
  validate = struct(
    merge(
      [
        "axes" => to_axes(tax_benefit_system),
        "description" => pipe(
          test_isa(String),
          strip,
        ),
        "ignore" => pipe(
          test_isa(Union(Bool, Integer)),
          to_bool,
        ),
        "input_variables" => pipe(
          test_isa(Dict),
          uniform_mapping(
            pipe(
              test_isa(String),
              test_in(variables_name),
              require,
            ),
            noop,
          ),
          empty_to_nothing,
        ),
        "name" => pipe(
          test_isa(String),
          strip,
        ),
        "output_variables" => pipe(
          test_isa(Dict),
          uniform_mapping(
            pipe(
              test_isa(String),
              test_in(variables_name),
              require,
            ),
            noop,
          ),
          convertible::Convertible -> begin
            if convertible.error !== nothing || convertible.value === nothing
              return convertible
            end
            output_by_variable_name = (String => Any)[]
            error_by_variable_name = (String => Any)[]
            for (variable_name, value) in convertible.value
              variable_definition = variable_definition_by_name[variable_name]
              converted_variable = Convertible(value, convertible.context) |> to_cell(variable_definition)
              if converted_variable.value !== nothing
                output_by_variable_name[variable_name] = converted_variable.value
              end
              if converted_variable.error !== nothing
                error_by_variable_name[variable_name] = converted_variable.error
              end
            end
            return Convertible(output_by_variable_name, convertible.context,
              isempty(error_by_variable_name) ? nothing : error_by_variable_name)
          end,
          empty_to_nothing,
        ),
        "period" => to_period,
      ],
      [
        entity_definition.name_plural => item_to_singleton
        for entity_definition in values(tax_benefit_system.entity_definition_by_name)
      ],
    ),
  )

  return convertible::Convertible -> begin
    if convertible.error !== nothing || convertible.value === nothing
      return convertible
    end

    converted = validate(convertible)
    if converted.error !== nothing
      return converted
    end

    test_case = copy(converted.value)
    axes = pop!(test_case, "axes")
    description = pop!(test_case, "description")
    ignore = pop!(test_case, "ignore")
    input_variables = pop!(test_case, "input_variables")
    name = pop!(test_case, "name")
    output_variables = pop!(test_case, "output_variables")
    period = pop!(test_case, "period")

    if input_variables !== nothing
      # When using input_variables, always ensure that the test_case contains at least one person. Otherwise scenario
      # validation will fail.
      person_name_plural = tax_benefit_system.entity_definition_by_name[tax_benefit_system.person_name].name_plural
      person_members = test_case[person_name_plural]
      if person_members === nothing
        test_case[person_name_plural] = person_members = Dict{String, Any}[]
      end
      if isempty(person_members)
        push!(person_members, (String => Any)[])
      end
    end

    converted_scenario = Convertible([
      "axes" => axes,
      "period" => period,
      "test_case" => test_case,
    ], convertible.context) |> to_scenario(tax_benefit_system, repair = true)
    if converted_scenario.error !== nothing
      return Convertible(converted.value, convertible.context, converted_scenario.error)
    end
    scenario = converted_scenario.value

    if input_variables !== nothing
      # Dispatch input variables to their respective entities.
      # When there are several entities of the same type, the first one is used.
      error_by_variable_name = (String => Any)[]
      test_case = scenario.test_case
      for (variable_name, value) in input_variables
        variable_definition = variable_definition_by_name[variable_name]
        entity_definition = variable_definition.entity_definition
        entity_name_plural = entity_definition.name_plural
        entity_members = test_case[entity_name_plural]
        entity_member = first(entity_members)
        existing_value = get(entity_member, variable_name, nothing)
        if existing_value !== nothing
          error_by_variable_name[variable_name] = N_("Input variable can't override an existing value in entity.")
          continue
        end
        converted_cell = Convertible(value) |> to_cell(variable_definition)
        if converted_cell.error !== nothing
          error_by_variable_name[variable_name] = converted_cell.error
        end
        entity_member[variable_name] = converted_cell.value
      end
      if !isempty(error_by_variable_name)
        return Convertible(converted.value, convertible.context, ["input_variables" => error_by_variable_name])
      end
    end

    return Convertible(
      filter((key, value) -> value !== nothing, [
          "description" => description,
          "ignore" => ignore,
          "name" => name,
          "scenario" => scenario,
          "output_variables" => output_variables,
        ]
      ),
      convertible.context,
    )
  end
end
