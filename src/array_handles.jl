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
  array::Array
end


type PermanentArrayHandle <: ArrayHandle
  variable::Variable
  array::Array
end


*(array_handle::ArrayHandle, right::Number) = array_handle.array * right

*(array_handle::ArrayHandle, right::Array) = array_handle.array * right

*(left::Number, array_handle::ArrayHandle) = left * array_handle.array

*(left::Array, array_handle::ArrayHandle) = left * array_handle.array


+(array_handle::ArrayHandle, right::Number) = array_handle.array + right

+(array_handle::ArrayHandle, right::Array) = array_handle.array + right

+(left::Number, array_handle::ArrayHandle) = left + array_handle.array

+(left::Array, array_handle::ArrayHandle) = left + array_handle.array


.<(array_handle::ArrayHandle, right::Number) = array_handle.array .< right

.<(array_handle::ArrayHandle, right::Array) = array_handle.array .< right

.<(left::Number, array_handle::ArrayHandle) = left .< array_handle.array

.<(left::Array, array_handle::ArrayHandle) = left .< array_handle.array


beginswith(array_handle::ArrayHandle, prefix) = beginswith(array_handle.array, prefix)


done(array_handle::ArrayHandle, state) = done(array_handle.array, state)


entity_to_person(array_handle::ArrayHandle, role::Role) = entity_to_person(array_handle, Role[role])

function entity_to_person(array_handle::ArrayHandle, roles::Array{Role})
  array = array_handle.array
  period = array_handle.period
  entity = get_entity(array_handle)
  @assert !is_person(entity)
  simulation = entity.simulation
  person = get_person(simulation)
  variable_definition = array_handle.variable.definition
  if roles == ALL_ROLES
    person_array = variable_definition.cell_type[
      array[index_cell]
      for index_cell in get_index_variable(entity).array
    ]
  else
    cell_default = variable_definition.cell_default
    person_array = variable_definition.cell_type[
      role_cell in roles ? array[index_cell] : cell_default
      for (index_cell, role_cell) in zip(
        get_index_variable(entity).array,
        get_array_handle(get_role_variable(entity), period, nothing).array,
      )
    ]
  end
  return person_array
end

entity_to_person(array_handle::ArrayHandle) = entity_to_person(array_handle, ALL_ROLES)


get_entity(array_handle::ArrayHandle) = get_entity(array_handle.variable)


length(array_handle::ArrayHandle) = length(array_handle.array)


next(array_handle::ArrayHandle, state) = next(array_handle.array, state)


start(array_handle::ArrayHandle) = start(array_handle.array)
