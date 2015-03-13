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


abstract Scenario


type InputVariablesScenario <: Scenario
  tax_benefit_system::TaxBenefitSystem
  period::DatePeriod
  input_variables

  InputVariablesScenario(tax_benefit_system, period, input_variables) = new(tax_benefit_system, period, input_variables)
end


type TestCaseScenario <: Scenario
  tax_benefit_system::TaxBenefitSystem
  period::DatePeriod
  test_case
  axes

  TestCaseScenario(tax_benefit_system, period, test_case, axes = nothing) = new(tax_benefit_system, period, test_case,
    axes)
end


function cleanup_period_item(convertible::Convertible)
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  value = (String => Any)[
    item_name => item_value
    for (item_name, item_value) in convertible.value
    ]
  if !haskey(value, "period")
    date = pop!(value, "date", nothing)
    if date === nothing
      year = pop!(value, "year", nothing)
      if year !== nothing
        value["period"] = YearPeriod(year)
      end
    else
      value["period"] = YearPeriod(date)
    end
  end
  return Convertible(value, convertible.context)
end


function set_entities_json_id(entities_json)
  for (index, entity_json) in enumerate(entities_json)
    if !haskey(entity_json, "id")
      entity_json["id"] = string(index)
    end
  end
  return entities_json
end


function steps_count(scenario::Scenario)
  count = 1
  if scenario.axes !== nothing
    for parallel_axes in scenario.axes
      # All parallel axes have the same count, entity and period.
      axis = parallel_axes[1]
      count *= axis["count"]
    end
  end
  return count
end


function to_axes(tax_benefit_system::TaxBenefitSystem)
  variable_definition_by_name = tax_benefit_system.variable_definition_by_name
  return pipe(
    test_isa(Array),
    uniform_sequence(
      item_or_sequence(
        test_isa(Dict),
        struct(
          [
            "count" => pipe(
              test_isa(Int),
              test_greater_or_equal(1),
              require,
            ),
            "index" => pipe(
              test_isa(Int),
              test_greater_or_equal(0),
              default(0),
            ),
            "max" => pipe(
              test_isa(Real),
              require,
            ),
            "min" => pipe(
              test_isa(Real),
              require,
            ),
            "name" => pipe(
              test_isa(String),
              test_in(variable_definition_by_name),
              test(
                variable_name -> issubtype(variable_definition_by_name[variable_name].cell_type, Real),
                error = N_("Invalid type for axis: integer or float expected."),
              ),
              require,
            ),
            # TODO: Check that period is valid in params.
            "period" => to_period,
          ],
        ),
        drop_nothing = true,
      ),
      item_to_singleton,
      drop_nothing = true,
    ),
    empty_to_nothing,
  )
end


function to_input_variables(tax_benefit_system::TaxBenefitSystem, period::DatePeriod)
  variable_definition_by_name = tax_benefit_system.variable_definition_by_name
  variables_name = Set(keys(variable_definition_by_name))

  return function run_to_input_variables(convertible::Convertible)
    if convertible.error !== nothing || convertible.value === nothing
      return convertible
    end

    converted = pipe(
      test_isa(Union(Dict, OrderedDict)),
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
        error_by_variable_name = (String => Any)[]
        input_by_variable_name = (String => Any)[]
        for (variable_name, value) in convertible.value
          variable_definition = variable_definition_by_name[variable_name]
          converted_variable = Convertible(value, convertible.context) |> to_array_by_period(variable_definition,
            period)
          if converted_variable.value !== nothing
            input_by_variable_name[variable_name] = converted_variable.value
          end
          if converted_variable.error !== nothing
            error_by_variable_name[variable_name] = converted_variable.error
          end
        end
        return Convertible(input_by_variable_name, convertible.context,
          isempty(error_by_variable_name) ? nothing : error_by_variable_name)
      end,
      empty_to_nothing,
    )(convertible)
    if converted.error !== nothing
      return converted
    end

    count_by_entity_definition = (EntityDefinition => Int)[]
    errors = (String => Any)[]
    for (variable_name, array_by_period) in converted.value
      variable_definition = variable_definition_by_name[variable_name]
      entity_definition = variable_definition.entity_definition
      entity_count = get(count_by_entity_definition, entity_definition, 0)
      for (variable_period, variable_array) in array_by_period
        if entity_count == 0
          count_by_entity_definition[entity_definition] = entity_count = length(variable_array)
        elseif length(variable_array) != entity_count
          errors[variable_definition.name] = context -> _(context,
            "Array has not the same length as other variables of entity $(entity_definition.name):" *
            " $(length(variable_array)) instead of $entity_count.")
        end
      end
    end

    return Convertible(converted.value, convertible.context, isempty(errors) ? nothing : errors)
  end
end


function to_scenario(tax_benefit_system::TaxBenefitSystem; repair = false)
  variable_definition_by_name = tax_benefit_system.variable_definition_by_name

  return function run_to_scenario(convertible::Convertible)
    if convertible.error !== nothing || convertible.value === nothing
      return convertible
    end

    # First validation and conversion step

    converted = pipe(
      test_isa(Dict),
      cleanup_period_item,
      struct(
        [
          "axes" => to_axes(tax_benefit_system),
          "input_variables" => test_isa(Union(Dict, OrderedDict)),  # Real test is done below, once period is known.
          "period" => pipe(
            to_period,  # TODO: Check that period is valid in params.
            require,
          ),
          "test_case" => test_isa(Union(Dict, OrderedDict)),  # Real test is done below, once period is known.
        ],
      ),
    )(convertible)
    if converted.error !== nothing
      return converted
    end

    # Second validation and conversion step

    data = converted.value
    converted = struct(
      [
        "input_variables" => to_input_variables(tax_benefit_system, data["period"]),
        "test_case" => tax_benefit_system.to_test_case(tax_benefit_system, data["period"], repair = repair),
      ],
      default = noop,
    )(converted)
    if converted.error !== nothing
      return converted
    end

    # Third validation and conversion step

    data = converted.value
    errors = (String => Any)[]
    if data["input_variables"] !== nothing && data["test_case"] !== nothing
      errors["input_variables"] = N_("Items input_variables and test_case can't both exist.")
      errors["test_case"] = N_("Items input_variables and test_case can't both exist.")
    elseif data["axes"] !== nothing && data["test_case"] === nothing
      errors["axes"] = N_("Axes can't be used with input_variables.")
    end
    if !isempty(errors)
      return Convertible(data, convertible.context, errors)
    end

    if data["axes"] !== nothing
      for (parallel_axes_index, parallel_axes) in enumerate(data["axes"])
        first_axis = parallel_axes[1]
        axis_count = first_axis["count"]
        axis_entity_definition = variable_definition_by_name[first_axis["name"]].entity_definition
        axis_period = first_axis["period"]
        for (axis_index, axis) in enumerate(parallel_axes)
          if axis["min"] >= axis["max"]
            axes_errors = get!(() -> (Unsigned => Any)[], errors, "axes")
            parallel_axes_errors = get!(() -> (Unsigned => Any)[], axes_errors, parallel_axes_index)
            axis_errors = get!(() -> (String => Any)[], parallel_axes_errors, axes_index)
            axis_errors["max"] = N_("Max value must be greater than min value.")
          end
          variable_definition = variable_definition_by_name[axis["name"]]
          entity_count = length(data["test_case"][variable_definition.entity_definition.name_plural])
          if axis["index"] > entity_count
            axes_errors = get!(() -> (Unsigned => Any)[], errors, "axes")
            parallel_axes_errors = get!(() -> (Unsigned => Any)[], axes_errors, parallel_axes_index)
            axis_errors = get!(() -> (String => Any)[], parallel_axes_errors, axes_index)
            axis_errors["index"] = context -> _(context, "Index must be lower than $entity_count.")
          end
          if axis_index > 1
            if axis["count"] != axis_count
              axes_errors = get!(() -> (Unsigned => Any)[], errors, "axes")
              parallel_axes_errors = get!(() -> (Unsigned => Any)[], axes_errors, parallel_axes_index)
              axis_errors = get!(() -> (String => Any)[], parallel_axes_errors, axes_index)
              axis_errors["count"] = N_("Parallel indexes must have the same count.")
            end
            if variable_definition.entity_definition != axis_entity_definition
              axes_errors = get!(() -> (Unsigned => Any)[], errors, "axes")
              parallel_axes_errors = get!(() -> (Unsigned => Any)[], axes_errors, parallel_axes_index)
              axis_errors = get!(() -> (String => Any)[], parallel_axes_errors, axes_index)
              axis_errors["name"] = N_("Parallel indexes must belong to the same entity.")
            end
            if axis["period"] != axis_period
              axes_errors = get!(() -> (Unsigned => Any)[], errors, "axes")
              parallel_axes_errors = get!(() -> (Unsigned => Any)[], axes_errors, parallel_axes_index)
              axis_errors = get!(() -> (String => Any)[], parallel_axes_errors, axes_index)
              axis_errors["period"] = N_("Parallel indexes must have the same period.")
            end
          end
        end
      end
      if !isempty(errors)
        return Convertible(data, convertible.context, errors)
      end
    end

    scenario = data["test_case"] === nothing ?
      InputVariablesScenario(tax_benefit_system, data["period"], data["input_variables"]) :
      TestCaseScenario(tax_benefit_system, data["period"], data["test_case"], data["axes"])
    return Convertible(scenario, convertible.context)
  end
end
