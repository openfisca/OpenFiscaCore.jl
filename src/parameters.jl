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


type DateRangeValue{T}
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


type Parameter{T}
  values::Array{DateRangeValue{T}}
  # value_type = T = Float32, UnitIntervalFloat32 (between 0 and 1, for percent etc)...
  unit::Union(Nothing, String)
  check_start_date::Union(Date, Nothing)  # The first date for which this parameter (or lack of it) has been verified in legislation
  check_stop_date::Union(Date, Nothing)  # The last date for which this parameter (or lack of it) has been verified in legislation
  description::Union(Nothing, String)
  comment::Union(Nothing, String)

  Parameter(values; unit = nothing, check_start_date = nothing, check_stop_date = nothing, description = nothing,
    comment = nothing) = new(values, unit, check_start_date, check_stop_date, description, comment)
end
