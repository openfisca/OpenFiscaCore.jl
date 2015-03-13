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

*(left::ArrayHandle, right::Union(Array, BitArray, Number)) = get_array(left) * right

*(left::Union(Array, BitArray, Number), right::ArrayHandle) = left * get_array(right)


+(left::ArrayHandle, right::ArrayHandle) = get_array(left) + get_array(right)

+(left::ArrayHandle, right::Union(Array, BitArray, Number, Role)) = get_array(left) + right

+(left::Union(Array, BitArray, Number, Role), right::ArrayHandle) = left + get_array(right)


-(left::ArrayHandle, right::ArrayHandle) = get_array(left) - get_array(right)

-(left::ArrayHandle, right::Union(Array, Date, Number, Role)) = get_array(left) - right

-(left::Union(Array, Date, Number, Role), right::ArrayHandle) = left - get_array(right)


-(array_handle::ArrayHandle) = -get_array(array_handle)


.<(left::ArrayHandle, right::ArrayHandle) = get_array(left) .< get_array(right)

.<(left::ArrayHandle, right::Union(Array, BitArray, Number, Role)) = get_array(left) .< right

.<(left::Union(Array, BitArray, Number, Role), right::ArrayHandle) = left .< get_array(right)


.<=(left::ArrayHandle, right::ArrayHandle) = get_array(left) .<= get_array(right)

.<=(left::ArrayHandle, right::Union(Array, BitArray, Number, Role)) = get_array(left) .<= right

.<=(left::Union(Array, BitArray, Number, Role), right::ArrayHandle) = left .<= get_array(right)


.==(left::ArrayHandle, right::ArrayHandle) = get_array(left) .== get_array(right)

.==(left::ArrayHandle, right::Union(Array, BitArray, Number, Role)) = get_array(left) .== right

.==(left::Union(Array, BitArray, Number, Role), right::ArrayHandle) = left .== get_array(right)


.!=(left::ArrayHandle, right::ArrayHandle) = get_array(left) .!= get_array(right)

.!=(left::ArrayHandle, right::Union(Array, BitArray, Number, Role)) = get_array(left) .!= right

.!=(left::Union(Array, BitArray, Number, Role), right::ArrayHandle) = left .!= get_array(right)


.*(left::ArrayHandle, right::ArrayHandle) = get_array(left) .* get_array(right)

.*(left::ArrayHandle, right::Union(Array, BitArray, Number)) = get_array(left) .* right

.*(left::Union(Array, BitArray, Number), right::ArrayHandle) = left .* get_array(right)


.+(left::ArrayHandle, right::ArrayHandle) = get_array(left) .+ get_array(right)

.+(left::ArrayHandle, right::Union(Array, BitArray, Number, Role)) = get_array(left) .+ right

.+(left::Union(Array, BitArray, Number, Role), right::ArrayHandle) = left .+ get_array(right)


.-(left::ArrayHandle, right::ArrayHandle) = get_array(left) .- get_array(right)

.-(left::ArrayHandle, right::Union(Array, Date, Number, Role)) = get_array(left) .- right

.-(left::Union(Array, Date, Number, Role), right::ArrayHandle) = left .- get_array(right)


./(left::ArrayHandle, right::ArrayHandle) = get_array(left) ./ get_array(right)

./(left::ArrayHandle, right::Union(Array, BitArray, Number)) = get_array(left) ./ right

./(left::Union(Array, BitArray, Number), right::ArrayHandle) = left ./ get_array(right)



(&)(left::ArrayHandle, right::ArrayHandle) = get_array(left) & get_array(right)

(&)(left::ArrayHandle, right::Union(Array, BitArray, Number, Role)) = get_array(left) & right

(&)(left::Union(Array, BitArray, Number, Role), right::ArrayHandle) = left & get_array(right)


|(left::ArrayHandle, right::ArrayHandle) = get_array(left) | get_array(right)

|(left::ArrayHandle, right::Union(Array, BitArray, Number, Role)) = get_array(left) | right

|(left::Union(Array, BitArray, Number, Role), right::ArrayHandle) = left | get_array(right)


!(array_handle::ArrayHandle) = !get_array(array_handle)


assert_near(left::Union(Array, BitArray, Number), right::ArrayHandle; error_margin = 1, message = "") = assert_near(left,
  get_array(right), error_margin = error_margin, message = message)

assert_near(left::ArrayHandle, right::Union(Array, BitArray, Number); error_margin = 1, message = "") = assert_near(
  get_array(left), right, error_margin = error_margin, message = message)

assert_near(left::ArrayHandle, right::ArrayHandle; error_margin = 1, message = "") = assert_near(get_array(left),
  get_array(right), error_margin = error_margin, message = message)


beginswith(array_handle::ArrayHandle, prefix) = beginswith(get_array(array_handle), prefix)


div(left::ArrayHandle, right::ArrayHandle) = div(get_array(left), get_array(right))

div(left::ArrayHandle, right::Union(Array, Number)) = div(get_array(left), right)

div(left::Union(Array, Number), right::ArrayHandle) = div(left, get_array(right))


done(array_handle::ArrayHandle, state) = done(get_array(array_handle), state)


getindex(left::ArrayHandle, right::BitArray) = getindex(get_array(left), right)


isless(left::ArrayHandle, right::ArrayHandle) = isless(get_array(left), get_array(right))

isless(left::ArrayHandle, right::Union(Array, Date, Number)) = isless(get_array(left), right)

isless(left::Union(Array, Date, Number), right::ArrayHandle) = isless(left, get_array(right))


length(array_handle::ArrayHandle) = length(get_array(array_handle))


max(left::ArrayHandle, right::ArrayHandle) = max(get_array(left), get_array(right))

max(left::ArrayHandle, right::Union(Array, Date, Number)) = max(get_array(left), right)

max(left::Union(Array, Date, Number), right::ArrayHandle) = max(left, get_array(right))


min(left::ArrayHandle, right::ArrayHandle) = min(get_array(left), get_array(right))

min(left::ArrayHandle, right::Union(Array, Date, Number)) = min(get_array(left), right)

min(left::Union(Array, Date, Number), right::ArrayHandle) = min(left, get_array(right))


next(array_handle::ArrayHandle, state) = next(get_array(array_handle), state)


round(array_handle::ArrayHandle, digits::Integer = 0, base::Integer = 10) = round(get_array(array_handle), digits, base)


start(array_handle::ArrayHandle) = start(get_array(array_handle))
