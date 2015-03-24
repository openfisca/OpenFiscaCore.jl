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


.-(left::Date, right::Array{Date}) = Day[left - right_item for right_item in right]

.-(left::Array{Date}, right::Date) = Day[left_item - right for left_item in left]


abs(array::Array{Day}) = array

abs(array::Array{Month}) = array

abs(array::Array{Year}) = array

abs(array::Array) = [abs(item) for item in array]


isless(left::Date, right::Array{Date}) = Bool[isless(left, right_item) for right_item in right]

isless(left::Array{Date}, right::Date) = Bool[isless(left_item, right) for left_item in left]


function assert_near(value::Union(Array, Number), target_value::Union(Array, Number); absolute_error_margin = 0,
    message = "", relative_error_margin = -1)
  @assert absolute_error_margin >= 0 || relative_error_margin >= 0
  if absolute_error_margin >= 0
    @assert(all(abs(target_value .- value) .<= absolute_error_margin),
      "$message$value differs from $target_value with an absolute margin $(abs(target_value .- value)) .>" *
      " $absolute_error_margin")
  end
  if relative_error_margin >= 0
    @assert(all(abs(target_value .- value) .<= abs(relative_error_margin .* target_value)),
      "$message$value differs from $target_value with a relative margin $(abs(target_value .- value)) .>" *
      " $(abs(relative_error_margin .* target_value))")
  end
end

function assert_near(value::Union(Array{Bool}, BitArray, Bool), target_value::Union(Array{Bool}, BitArray, Bool);
    absolute_error_margin = 0, message = "", relative_error_margin = -1)
  # Note: Ignore error margin when comparing booleans.
  @assert(all(target_value .== value), "$message$value differs from $target_value")
end


beginswith(array::Array, prefix) = Bool[beginswith(cell, prefix) for cell in array]


convert(::Type{Array{Day}}, array::Array{Date}) = Day[
  Day(date)
  for date in array
]


convert(::Type{Array{Month}}, array::Array{Date}) = Month[
  Month(date)
  for date in array
]


convert(::Type{Array{Year}}, array::Array{Date}) = Year[
  Year(date)
  for date in array
]


get_array(array::Union(Array, BitArray)) = array
