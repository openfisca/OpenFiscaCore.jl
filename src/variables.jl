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


type PeriodicVariable <: Variable
  simulation::AbstractSimulation
  definition::VariableDefinition
  exact_array_by_period::Dict{DatePeriod, Array}
  extrapolated_array_by_period::Dict{DatePeriod, Array}
end

PeriodicVariable(simulation, definition) = PeriodicVariable(simulation, definition, Dict{DatePeriod, Array}(),
  Dict{DatePeriod, Array}())


type PermanentVariable <: Variable
  # A permanent variable is a variable whose value doesn't depend from date (example: ID, birth)
  simulation::Simulation
  definition::VariableDefinition
  array::Array
end

PermanentVariable(simulation, definition) = PermanentVariable(simulation, definition, [])


function calculate(variable::PeriodicVariable, period::DatePeriod)
  array_handle = get_array_handle(variable, period, nothing)
  if array_handle !== nothing
    return array_handle
  end

  definition = variable.definition
  exact_array_by_period = variable.exact_array_by_period
  simulation = variable.simulation
  requested_start_date = period.start
  requested_stop_date = stop_date(period)
  trace = simulation.trace

  formula_period = period
  while true
    formula_period, array = definition.formula(variable, formula_period)
    set_array_handle(variable, formula_period, array)
    formula_period = typeof(formula_period)(formula_period.start + unit_type(formula_period)(formula_period.length),
      formula_period.length)
    if formula_period.start > requested_stop_date
      break
    end
  end

  array = nothing
  # if trace
  #   used_periods = DatePeriod[]
  # end
  if !isempty(exact_array_by_period)
    sorted_exact_period_and_array_couples = sort(collect(exact_array_by_period),
      by = period_array_couple -> period_array_couple[1].start)
    best_first_index = -1
    best_fist_start_date = Date(0, 1, 1)
    for (index, (exact_period, exact_array)) in enumerate(sorted_exact_period_and_array_couples)
      exact_start_date = exact_period.start
      if exact_start_date == best_fist_start_date
        # When encountering several periods starting with the same date, use the smallest one.
        continue
      end
      if exact_start_date <= requested_start_date
        best_first_index = index
        best_fist_start_date = exact_start_date
        if exact_start_date == requested_start_date
          break
        end
      else
        break
      end
    end
    if best_first_index >= 0
      remaining_start_date = requested_start_date
      for (exact_period, exact_array) in sorted_exact_period_and_array_couples[best_first_index : end]
        exact_start_date = exact_period.start
        if exact_start_date > requested_stop_date
          # The existing data arrays don't fully cover the requested period.
          break
        end
        exact_stop_date = stop_date(exact_period)
        if exact_start_date <= remaining_start_date && exact_stop_date >= remaining_start_date
          if definition.period_size_independent
            # Use always the first value for the period, because the output period may end before
            # the requested period (because of base date).
            if array === nothing
              array = copy(exact_array)
            end
          else
            intersection_period = intersection(exact_period, remaining_start_date, requested_stop_date)
            @assert intersection_period !== empty_period
            exact_period_type = typeof(exact_period)
            intersection_period_type = typeof(intersection_period)
            if intersection_period_type == exact_period_type
              intersection_array = exact_array * intersection_period.length / exact_period.length
            elseif intersection_period_type === MonthPeriod && exact_period_type === YearPeriod
              intersection_array = exact_array * intersection_period.length / (exact_period.length * 12)
            elseif intersection_period_type === YearPeriod && exact_period_type === MonthPeriod
              intersection_array = exact_array * intersection_period.length * 12 / exact_period.length
            else
              intersection_array = exact_array * days(intersection_period).value / days(exact_period).value
            end
            if array === nothing
              array = copy(intersection_array)
            else
              array .+= intersection_array
            end
            # if trace
            #   push!(used_periods, exact_period)
            # end
          end
          remaining_start_date = exact_stop_date + Day(1)
          if remaining_start_date > requested_stop_date
            variable.extrapolated_array_by_period[period] = array
            # if trace
            #   simulation.traceback[(definition.name, period)]['used_periods'] = used_periods
            # end
            return PeriodArrayHandle(variable, period)
          end
        end
        if exact_stop_date >= requested_stop_date
          # The existing data arrays don't fully cover the requested period.
          break
        end
      end
    end
  end

  if array === nothing
    array = default_array(variable)
  end
  variable.extrapolated_array_by_period[period] = array
  # if trace && used_periods
  #   simulation.traceback[(definition.name, period)]['used_periods'] = used_periods
  # end
  return PeriodArrayHandle(variable, period)
end

function calculate(variable::PermanentVariable, period::DatePeriod)
  array = get_array!(variable) do
    formula_period, array = variable.definition.formula(variable, period)
    set_array_handle(variable, array)
    return array
  end
  return PermanentArrayHandle(variable)
end

calculate(variable::Variable) = calculate(variable, variable.simulation.period)


macro calculate(new_variable, period)
  global variable
  return esc(:($new_variable = calculate(variable.simulation, $(string(new_variable)), $period)))
end


function default_array(variable::Variable)
  definition = variable.definition
  array = Array(definition.cell_type, get_entity(variable).count)
  fill!(array, definition.cell_default)
end


function get_array(variable::PeriodicVariable, period::DatePeriod, default)
  array = get(variable.exact_array_by_period, period, nothing)
  return array === nothing ? get(variable.extrapolated_array_by_period, period, default) : array
end

get_array(variable::PeriodicVariable, default) = get_array(variable, variable.simulation.period, default)

function get_array(variable::PeriodicVariable, period::DatePeriod)
  array = get_array(variable, period, nothing)
  if array === nothing
    throw(KeyError(period))
  end
  return array
end

get_array(variable::PeriodicVariable) = get_array(variable, variable.simulation.period)

function get_array(variable::PermanentVariable, default)
  array = variable.array
  return isempty(array) ? default : array
end

get_array(variable::PermanentVariable, period::DatePeriod, default) = get_array(variable, default)

function get_array(variable::PermanentVariable)
  array = get_array(variable, nothing)
  if array === nothing
    throw(KeyError(period))
  end
  return array
end

get_array(variable::PermanentVariable, period::DatePeriod) = get_array(variable)


function get_array!(func::Function, variable::PeriodicVariable, period::DatePeriod; set_extrapolated = false)
  array = get(variable.exact_array_by_period, period, nothing)
  if array !== nothing
    return array
  end
  if set_extrapolated
    return get!(func, variable.extrapolated_array_by_period, period)
  end
  array = get(variable.extrapolated_array_by_period, period, nothing)
  if array !== nothing
    return array
  end
  array = func()
  variable.exact_array_by_period[period] = array
  return array
end

function get_array!(func::Function, variable::PermanentVariable)
  array = variable.array
  if !isempty(array)
    return array
  end
  array = func()
  variable.array = array
  return array
end


function get_array_handle(variable::PeriodicVariable, period::DatePeriod, default)
  array = get_array(variable, period, nothing)
  return array === nothing ? default : PeriodArrayHandle(variable, period)
end

get_array_handle(variable::PeriodicVariable, default) = get_array_handle(variable, variable.simulation.period, default)

function get_array_handle(variable::PeriodicVariable, period::DatePeriod)
  array_handle = get_array_handle(variable, period, nothing)
  if array_handle === nothing
    throw(KeyError(period))
  end
  return array_handle
end

get_array_handle(variable::PeriodicVariable) = get_array_handle(variable, variable.simulation.period)

function get_array_handle(variable::PermanentVariable, default)
  array = get_array(variable, nothing)
  return array === nothing ? default : PermanentArrayHandle(variable)
end

get_array_handle(variable::PermanentVariable, period::DatePeriod, default) = get_array_handle(variable, default)

function get_array_handle(variable::PermanentVariable)
  array_handle = get_array_handle(variable, nothing)
  if array_handle === nothing
    throw(KeyError(period))
  end
  return array_handle
end

get_array_handle(variable::PermanentVariable, period::DatePeriod) = get_array_handle(variable)


macro get_array_handle(new_variable, period, default)
  global variable
  return esc(:($new_variable = get_array_handle(variable.simulation, $(string(new_variable)), $period, $default)))
end


get_entity(variable::Variable) = get_entity(variable.simulation, variable.definition.entity_definition)


function set_array_handle(variable::PeriodicVariable, period::DatePeriod, array::Array)
  @assert length(array) == get_entity(variable).count
  variable.exact_array_by_period[period] = array
  return PeriodArrayHandle(variable, period)
end

function set_array_handle(variable::PeriodicVariable, array_handle::PeriodArrayHandle)
  array = get_array(array_handle)
  @assert length(array) == get_entity(variable).count
  variable.exact_array_by_period[array_handle.period] = array
  return array_handle
end

set_array_handle(variable::PeriodicVariable, array::Array) = set_array_handle(variable, variable.simulation.period,
  array)

function set_array_handle(variable::PermanentVariable, array_handle::PermanentArrayHandle)
  array = get_array(array_handle)
  @assert length(array) == get_entity(variable).count
  variable.array = array
  return array_handle
end

function set_array_handle(variable::PermanentVariable, array::Array)
  @assert length(array) == get_entity(variable).count
  variable.array = array
  return PermanentArrayHandle(variable)
end
