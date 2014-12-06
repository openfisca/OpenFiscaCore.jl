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


abstract ArrayHandle


type PeriodArrayHandle <: ArrayHandle
  variable::Variable
  period::DatePeriod
end


type PermanentArrayHandle <: ArrayHandle
  variable::Variable
end


*(array_handle::ArrayHandle, right::Number) = get_array(array_handle) * right

*(array_handle::ArrayHandle, right::Array) = get_array(array_handle) * right

*(left::Number, array_handle::ArrayHandle) = left * get_array(array_handle)

*(left::Array, array_handle::ArrayHandle) = left * get_array(array_handle)


+(array_handle::ArrayHandle, right::Number) = get_array(array_handle) + right

+(array_handle::ArrayHandle, right::Array) = get_array(array_handle) + right

+(left::Number, array_handle::ArrayHandle) = left + get_array(array_handle)

+(left::Array, array_handle::ArrayHandle) = left + get_array(array_handle)


.<(array_handle::ArrayHandle, right::Number) = get_array(array_handle) .< right

.<(array_handle::ArrayHandle, right::Array) = get_array(array_handle) .< right

.<(left::Number, array_handle::ArrayHandle) = left .< get_array(array_handle)

.<(left::Array, array_handle::ArrayHandle) = left .< get_array(array_handle)


beginswith(array_handle::ArrayHandle, prefix) = beginswith(get_array(array_handle), prefix)


done(array_handle::ArrayHandle, state) = done(get_array(array_handle), state)


entity_to_person(array_handle::ArrayHandle, role::Role) = entity_to_person(array_handle, Role[role])

function entity_to_person(array_handle::ArrayHandle, roles::Array{Role})
  array = get_array(array_handle)
  period = array_handle.period
  entity = get_entity(array_handle)
  @assert !is_person(entity)
  simulation = entity.simulation
  person = get_person(simulation)
  variable_definition = array_handle.variable.definition
  if roles == ALL_ROLES
    person_array = variable_definition.cell_type[
      array[index_cell]
      for index_cell in get_array(get_index_variable(entity), period)
    ]
  else
    cell_default = variable_definition.cell_default
    person_array = variable_definition.cell_type[
      role_cell in roles ? array[index_cell] : cell_default
      for (index_cell, role_cell) in zip(
        get_array(get_index_variable(entity)),
        get_array(get_role_variable(entity), period),
      )
    ]
  end
  return person_array
end

entity_to_person(array_handle::ArrayHandle) = entity_to_person(array_handle, ALL_ROLES)


get_array(array_handle::PeriodArrayHandle, default) = get_array(array_handle.variable, array_handle.period, default)

get_array(array_handle::PeriodArrayHandle) = get_array(array_handle.variable, array_handle.period)

get_array(array_handle::PermanentArrayHandle, default) = get_array(array_handle.variable, default)

get_array(array_handle::PermanentArrayHandle) = get_array(array_handle.variable)


get_entity(array_handle::ArrayHandle) = get_entity(array_handle.variable)


length(array_handle::ArrayHandle) = length(get_array(array_handle))


next(array_handle::ArrayHandle, state) = next(get_array(array_handle), state)


start(array_handle::ArrayHandle) = start(get_array(array_handle))
