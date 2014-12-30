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


typealias UnitIntervalFloat32 Float32  # Float32 between 0 and 1, for percent, etc


immutable DateRangeValue{T}
  start_date::Union(Date, Nothing)
  stop_date::Union(Date, Nothing)
  value::T
  comment::Union(Nothing, String)
end

DateRangeValue{T}(start_date, stop_date, value::T; comment = nothing) = DateRangeValue{T}(start_date, stop_date,
  value, comment)

convert(::Type{DateRangeValue{Float32}}, date_range_value::DateRangeValue{Float64}) = DateRangeValue{Float32}(
  date_range_value.start_date, date_range_value.stop_date, float32(date_range_value.value), date_range_value.comment)

convert(::Type{DateRangeValue{Int32}}, date_range_value::DateRangeValue{Int64}) = DateRangeValue{Int32}(
  date_range_value.start_date, date_range_value.stop_date, int32(date_range_value.value), date_range_value.comment)

# To remove for Julia 0.4?
convert(::Type{Union(Array{DateRangeValue{Float32}}, Nothing)}, date_range_values::Array{DateRangeValue{Float64}}) = [
  convert(DateRangeValue{Float32}, date_range_value)
  for date_range_value in date_range_values
]


immutable Parameter{T}
  value::Array{DateRangeValue{T}}
  # value_type = T = Float32, UnitIntervalFloat32 (between 0 and 1, for percent etc)...
  unit::Union(Nothing, String)
  check_start_date::Union(Date, Nothing)  # The first date for which this parameter (or lack of it) has been verified in legislation
  check_stop_date::Union(Date, Nothing)  # The last date for which this parameter (or lack of it) has been verified in legislation
  description::Union(Nothing, String)
  comment::Union(Nothing, String)

  Parameter(value; unit = nothing, check_start_date = nothing, check_stop_date = nothing, description = nothing,
    comment = nothing) = new(value, unit, check_start_date, check_stop_date, description, comment)
end


function at(date_range_values::Array{DateRangeValue}, date::Date; check_start_date = nothing, check_stop_date = nothing)
  max_stop_date = nothing
  max_value = nothing
  min_start_date = nothing
  min_value = nothing
  for date_range_value in date_range_values
    if date_range_value.start_date <= date <= date_range_value.stop_date
      return date_range_value.value
    end
    if max_stop_date === nothing || date_range_value.stop_date > max_stop_date
      max_stop_date = date_range_value.stop_date
      max_value = date_range_value.value
    end
    if min_start_date === nothing || date_range_value.start_date < min_start_date
      min_start_date = date_range_value.start_date
      min_value = date_range_value.value
    end
  end
  if check_stop_date !== nothing && date > check_stop_date
    # The requested date is after the end of the legislation. Use the value of the last period, when this
    # period ends the same day or after the legislation.
    if max_stop_date !== nothing && max_stop_date >= check_stop_date
      return max_value
    end
  elseif check_start_date !== nothing && date < check_start_date
    # The requested date is before the beginning of the legislation. Use the value of the first period, when this
    # period begins the same day or before the legislation.
    if min_start_date !== nothing && min_start_date <= check_start_date
      return min_value
    end
  end
  return nothing
end

at(parameter::Parameter, date::Date) = at(parameter.value, date, check_start_date = parameter.check_start_date,
  check_stop_date = parameter.check_stop_date)
