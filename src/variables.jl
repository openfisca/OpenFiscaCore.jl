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


export @calculate, calculate, @get_period_array, calculate, ConcreteVariable, get_array, get_period_array,
  get_variable!, PermanentVariable, set_array, set_period_array


type ConcreteVariable <: Variable
  simulation::Simulation
  definition::VariableDefinition
  array_by_period::Dict{DatePeriod, Array}
end

ConcreteVariable(simulation, definition) = ConcreteVariable(simulation, definition, Dict{DatePeriod, Array}())


type PermanentVariable <: Variable
  # A permanent variable is a variable whose value doesn't depend from date (example: ID, birth)
  simulation::Simulation
  definition::VariableDefinition
  array::Array
end

PermanentVariable(simulation, definition) = PermanentVariable(simulation, definition, [])


function calculate(variable::ConcreteVariable, period)
  array = get!(variable.array_by_period, period) do
    definition = variable.definition
    if isa(definition, FormulaDefinition)
      period_array = definition.func(variable, period)
      @assert isa(period_array, PeriodArray)
      return period_array.array
    end
    return zeros(definition.cell_type, entity(variable).count)
  end
  return PeriodArray(period, array)
end

function calculate(variable::PermanentVariable, period)
  array = variable.array
  if isempty(array)
    definition = variable.definition
    if isa(definition, FormulaDefinition)
      array = definition.func(variable, period)
      @assert isa(array, Array)
    else
      array = zeros(definition.cell_type, entity(variable).count)
    end
  end
  return array
end

# calculate(variable::Variable) = calculate(variable, variable.simulation.period)

calculate(simulation::Simulation, variable_name, period) = calculate(
  get_variable!(simulation, variable_name), period)

calculate(simulation::Simulation, variable_name) = calculate(
  get_variable!(simulation, variable_name), simulation.period)


macro calculate(new_variable, period)
  global variable
  return esc(:($new_variable = calculate(variable.simulation, $(string(new_variable)), $period)))
end


entity(variable::Variable) = variable.simulation.entity_by_name[variable.definition.entity_definition.name]


function get_array(variable::PermanentVariable, default)
  array = variable.array
  return isempty(array) ? default : array
end

get_array(simulation::Simulation, variable_name, default) = get_array(get_variable!(simulation, variable_name), default)


function get_period_array(variable::ConcreteVariable, period, default)
  array = get(variable.array_by_period, period, nothing)
  return array === nothing ? default : PeriodArray(period, array)
end

get_period_array(variable::PermanentVariable, period, default) = get_array(variable, default)

get_period_array(variable::Variable, default) = get_array(variable, variable.simulation.period, default)

get_period_array(simulation::Simulation, variable_name, period, default) = get_period_array(
  get_variable!(simulation, variable_name), period, default)

get_period_array(simulation::Simulation, variable_name, default) = get_period_array(
  get_variable!(simulation, variable_name), simulation.period, default)


macro get_period_array(new_variable, period, default)
  global variable
  return esc(:($new_variable = get_period_array(variable.simulation, $(string(new_variable)), $period, $default)))
end


function get_variable!(simulation::Simulation, variable_name)
  get!(simulation.variable_by_name, variable_name) do
    definition = simulation.tax_benefit_system.variable_definition_by_name[variable_name]
    return (definition.permanent ? PermanentVariable : ConcreteVariable)(simulation, definition)
  end
end


function set_array(variable::PermanentVariable, array::Array)
  variable.array = array
  return array
end

set_array(simulation::Simulation, variable_name, array) = set_array(get_variable!(simulation, variable_name), array)


function set_period_array(variable::ConcreteVariable, period_array::PeriodArray)
  variable.array_by_period[period_array.period] = period_array.array
  return period_array
end

function set_period_array(variable::ConcreteVariable, array::Array)
  period = variable.simulation.period
  variable.array_by_period[period] = array
  return PeriodArray(period, array)
end

set_period_array(simulation::Simulation, variable_name, period_array::PeriodArray) = set_period_array(
  get_variable!(simulation, variable_name), period_array)

set_period_array(simulation::Simulation, variable_name, array::Array) = set_period_array(
  get_variable!(simulation, variable_name), array)
