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


*(left::ArrayHandle, right::ArrayHandle) = get_array(left) * get_array(right)

*(left::ArrayHandle, right::Union(Array, Number)) = get_array(left) * right

*(left::Union(Array, Number), right::ArrayHandle) = left * get_array(right)


+(left::ArrayHandle, right::ArrayHandle) = get_array(left) + get_array(right)

+(left::ArrayHandle, right::Union(Array, Number)) = get_array(left) + right

+(left::Union(Array, Number), right::ArrayHandle) = left + get_array(right)


-(left::ArrayHandle, right::ArrayHandle) = get_array(left) - get_array(right)

-(left::ArrayHandle, right::Union(Array, Date, Number)) = get_array(left) - right

-(left::Union(Array, Date, Number), right::ArrayHandle) = left - get_array(right)


.<(left::ArrayHandle, right::ArrayHandle) = get_array(left) .< get_array(right)

.<(left::ArrayHandle, right::Union(Array, Number)) = get_array(left) .< right

.<(left::Union(Array, Number), right::ArrayHandle) = left .< get_array(right)


.<=(left::ArrayHandle, right::ArrayHandle) = get_array(left) .<= get_array(right)

.<=(left::ArrayHandle, right::Union(Array, Number)) = get_array(left) .<= right

.<=(left::Union(Array, Number), right::ArrayHandle) = left .<= get_array(right)


.==(left::ArrayHandle, right::ArrayHandle) = get_array(left) .== get_array(right)

.==(left::ArrayHandle, right::Union(Array, Number)) = get_array(left) .== right

.==(left::Union(Array, Number), right::ArrayHandle) = left .== get_array(right)


(&)(left::ArrayHandle, right::ArrayHandle) = get_array(left) & get_array(right)

(&)(left::ArrayHandle, right::Union(Array, Number, BitArray)) = get_array(left) & right

(&)(left::Union(Array, Number, BitArray), right::ArrayHandle) = left & get_array(right)


|(left::ArrayHandle, right::ArrayHandle) = get_array(left) | get_array(right)

|(left::ArrayHandle, right::Union(Array, Number, BitArray)) = get_array(left) | right

|(left::Union(Array, Number, BitArray), right::ArrayHandle) = left | get_array(right)


!(array_handle::ArrayHandle) = !get_array(array_handle)


assert_near(left::Array, right::ArrayHandle; error_margin = 1) = assert_near(left, get_array(right),
  error_margin = error_margin)

assert_near(left::ArrayHandle, right::Array; error_margin = 1) = assert_near(get_array(left), right,
  error_margin = error_margin)

assert_near(left::ArrayHandle, right::ArrayHandle; error_margin = 1) = assert_near(get_array(left), get_array(right),
  error_margin = error_margin)


beginswith(array_handle::ArrayHandle, prefix) = beginswith(get_array(array_handle), prefix)


div(left::ArrayHandle, right::ArrayHandle) = div(get_array(left), get_array(right))

div(left::ArrayHandle, right::Union(Array, Number)) = div(get_array(left), right)

div(left::Union(Array, Number), right::ArrayHandle) = div(left, get_array(right))


done(array_handle::ArrayHandle, state) = done(get_array(array_handle), state)


isless(left::ArrayHandle, right::ArrayHandle) = isless(get_array(left), get_array(right))

isless(left::ArrayHandle, right::Union(Array, Date, Number)) = isless(get_array(left), right)

isless(left::Union(Array, Date, Number), right::ArrayHandle) = isless(left, get_array(right))


length(array_handle::ArrayHandle) = length(get_array(array_handle))


next(array_handle::ArrayHandle, state) = next(get_array(array_handle), state)


start(array_handle::ArrayHandle) = start(get_array(array_handle))
