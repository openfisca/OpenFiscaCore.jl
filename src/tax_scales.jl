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


abstract AbstractBracket
# abstract AbstractDatedTaxScale
abstract AbstractTaxScale


type AmountBracket <: AbstractBracket
  threshold::Array{DateRangeValue{Float32}}
  amount::Array{DateRangeValue{Float32}}
  base::Union(Array{DateRangeValue{Float32}}, Nothing)

  AmountBracket(; threshold = nothing, amount = nothing, base = nothing) = new(threshold, amount, base)
end


type AmountTaxScale <: AbstractTaxScale
  brackets::Array{AmountBracket}
  unit::Union(Nothing, String)
  check_start_date::Union(Date, Nothing)  # The first date for which this tax scale (or lack of it) has been verified in legislation
  check_stop_date::Union(Date, Nothing)  # The last date for which this tax scale (or lack of it) has been verified in legislation
  description::Union(Nothing, String)
  comment::Union(Nothing, String)

  AmountTaxScale(brackets; unit = nothing, check_start_date = nothing, check_stop_date = nothing, description = nothing,
    comment = nothing) = new(brackets, unit, check_start_date, check_stop_date, description, comment)
end


# DatedAmountTaxScale <: AbstractDatedTaxScale
#   amounts::Array{Float32}
#   thresholds::Array{Float32}
#   # unit ?
# end


# DatedRateTaxtScale <: AbstractDatedTaxScale
#   rates::Array{Float32}
#   thresholds::Array{Float32}
#   # unit ?
# end


type RateBracket <: AbstractBracket
  threshold::Array{DateRangeValue{Float32}}
  rate::Array{DateRangeValue{Float32}}
  base::Union(Array{DateRangeValue{Float32}}, Nothing)

  RateBracket(; threshold = nothing, rate = nothing, base = nothing) = new(threshold, rate, base)
end


type RateTaxScale <: AbstractTaxScale
  brackets::Array{RateBracket}
  unit::Union(Nothing, String)
  check_start_date::Union(Date, Nothing)  # The first date for which this tax scale (or lack of it) has been verified in legislation
  check_stop_date::Union(Date, Nothing)  # The last date for which this tax scale (or lack of it) has been verified in legislation
  description::Union(Nothing, String)
  comment::Union(Nothing, String)

  RateTaxScale(brackets; unit = nothing, check_start_date = nothing, check_stop_date = nothing, description = nothing,
    comment = nothing) = new(brackets, unit, check_start_date, check_stop_date, description, comment)
end
