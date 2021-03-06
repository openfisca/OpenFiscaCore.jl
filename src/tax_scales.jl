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


abstract Bracket
abstract TaxScale
abstract TaxScaleAtDate
abstract RateScale <: TaxScale
abstract RateScaleAtDate <: TaxScaleAtDate


# Amount-based tax scales


immutable AmountBracket <: Bracket
  threshold::Array{DateRangeValue{Float32}}
  amount::Array{DateRangeValue{Float32}}
  base::Union(Array{DateRangeValue{Float32}}, Nothing)

  AmountBracket(; threshold = nothing, amount = nothing, base = nothing) = new(threshold, amount, base)
end


immutable AmountScale <: TaxScale
  brackets::Array{AmountBracket}
  unit::Union(Nothing, String)
  check_start_date::Union(Date, Nothing)  # The first date for which this tax scale (or lack of it) has been verified in legislation
  check_stop_date::Union(Date, Nothing)  # The last date for which this tax scale (or lack of it) has been verified in legislation
  description::Union(Nothing, String)
  comment::Union(Nothing, String)

  AmountScale(brackets; unit = nothing, check_start_date = nothing, check_stop_date = nothing, description = nothing,
    comment = nothing) = new(brackets, unit, check_start_date, check_stop_date, description, comment)
end


immutable AmountScaleAtDate <: TaxScaleAtDate
  amounts::Array{Float32}
  thresholds::Array{Float32}
  # unit ?
end


# Rated-based tax scales


immutable LinearAverageRateScaleAtDate <: RateScaleAtDate
  rates::Array{Float32}
  thresholds::Array{Float32}
  # unit ?
end


immutable MarginalRateScaleAtDate <: RateScaleAtDate
  rates::Array{Float32}
  thresholds::Array{Float32}
  # unit ?
end


immutable RateBracket <: Bracket
  threshold::Array{DateRangeValue{Float32}}
  rate::Array{DateRangeValue{Float32}}
  base::Union(Array{DateRangeValue{Float32}}, Nothing)

  RateBracket(; threshold = nothing, rate = nothing, base = nothing) = new(threshold, rate, base)
end


immutable LinearAverageRateScale <: RateScale
  brackets::Array{RateBracket}
  unit::Union(Nothing, String)
  check_start_date::Union(Date, Nothing)  # The first date for which this tax scale (or lack of it) has been verified in legislation
  check_stop_date::Union(Date, Nothing)  # The last date for which this tax scale (or lack of it) has been verified in legislation
  description::Union(Nothing, String)
  comment::Union(Nothing, String)

  LinearAverageRateScale(brackets; unit = nothing, check_start_date = nothing, check_stop_date = nothing,
    description = nothing, comment = nothing) = new(brackets, unit, check_start_date, check_stop_date, description,
    comment)
end


immutable MarginalRateScale <: RateScale
  brackets::Array{RateBracket}
  unit::Union(Nothing, String)
  check_start_date::Union(Date, Nothing)  # The first date for which this tax scale (or lack of it) has been verified in legislation
  check_stop_date::Union(Date, Nothing)  # The last date for which this tax scale (or lack of it) has been verified in legislation
  description::Union(Nothing, String)
  comment::Union(Nothing, String)

  MarginalRateScale(brackets; unit = nothing, check_start_date = nothing, check_stop_date = nothing,
    description = nothing, comment = nothing) = new(brackets, unit, check_start_date, check_stop_date, description,
    comment)
end


# Functions


apply_tax_scale(tax_scale::TaxScaleAtDate, array_handle::ArrayHandle) = apply_tax_scale(tax_scale, get_array(
  array_handle))

function apply_tax_scale(tax_scale::AmountScaleAtDate, array::Array{Number})
  base = repeat(array, outer = [1, length(tax_scale.thresholds)])
  thresholds = repeat(hcat(tax_scale.thresholds', Inf), outer = [length(array), 1])
  a = min(base, thresholds[:, 2:end]) - thresholds[:, 1:end - 1]
  return (a .> 0) * tax_scale.amounts
end

function apply_tax_scale(tax_scale::LinearAverageRateScaleAtDate, array::Array{Number})
  if length(tax_scale.rates) == 1
    return array * tax_scale.rates[1]
  end

  tiled_base = repeat(array, outer = [1, length(tax_scale.thresholds) - 1])
  tiled_thresholds = repeat(tax_scale.thresholds', (length(array), 1))
  bracket_dummy = (tiled_base .>= tiled_thresholds[:, 1:end - 1]) * (tiled_base .< tiled_thresholds[:, 2:end])
  rate_slope = (tax_scale.rates[2:end] - tax_scale.rates[1:end - 1])
    ./ (tax_scale.thresholds[2:end] - tax_scale.thresholds[1:end - 1])
  average_rate_slope = bracket_dummy * rate_slope

  bracket_average_start_rate = bracket_dummy * tax_scale.rates[1:end - 1]
  bracket_threshold = bracket_dummy * tax_scale.thresholds[1:end - 1]
  return array .* (bracket_average_start_rate + (array - bracket_threshold) * average_rate_slope)
end

function apply_tax_scale(tax_scale::MarginalRateScaleAtDate, array::Array; factor = 1, round_base_decimals = nothing)
  base = repeat(array, outer = [1, length(tax_scale.thresholds)])
  thresholds = factor .* repeat(hcat(tax_scale.thresholds', Inf), outer = [length(array), 1])
  if round_base_decimals !== nothing
    thresholds = round(thresholds, round_base_decimals)
  end
  a = max(min(base, thresholds[:, 2:end]) - thresholds[:, 1:end - 1], 0)
  if round_base_decimals === nothing
    @assert(ndims(a) == 2)
    @assert(ndims(tax_scale.rates) == 1)
    result = a * tax_scale.rates
    @assert(size(result, 2) == 1)
    result = result[:,1]
    return result
  end
  @assert(ndims(a) == 2)
  @assert(ndims(tax_scale.rates) == 1)
  result = sum(round(a, round_base_decimals) * repeat(tax_scale.rates, outer = [1, length(array)]), 2)
  @assert(size(result, 2) == 1)
  result = result[:,1]
  return result
end

apply_tax_scale(tax_scale::MarginalRateScaleAtDate, array_handle::ArrayHandle; factor = 1,
  round_base_decimals = nothing) = apply_tax_scale(tax_scale, get_array(array_handle); factor = factor,
  round_base_decimals = round_base_decimals)


function legislation_at(tax_scale::AmountScale, date::Date)
  thresholds = DateRangeValue{Float32}[]
  amounts = DateRangeValue{Float32}[]
  for bracket in tax_scale.brackets
    if bracket.threshold === nothing
      continue
    end
    threshold = legislation_at(bracket.threshold, date, check_start_date = tax_scale.check_start_date,
      check_stop_date = tax_scale.check_stop_date)
    if threshold === nothing
      continue
    end

    if bracket.amount === nothing
      continue
    end
    amount = legislation_at(bracket.amount, date, check_start_date = tax_scale.check_start_date,
      check_stop_date = tax_scale.check_stop_date)
    if amount === nothing
      continue
    end

    push!(thresholds, threshold)
    push!(amounts, amount)
  end
  return AmountScaleAtDate(amounts, thresholds)  # TODO: option?
end


function legislation_at(tax_scale::RateScale, date::Date)
  thresholds = Float32[]
  rates = Float32[]
  for bracket in tax_scale.brackets
    if bracket.threshold === nothing
      continue
    end
    threshold = legislation_at(bracket.threshold, date, check_start_date = tax_scale.check_start_date,
      check_stop_date = tax_scale.check_stop_date)
    if threshold === nothing
      continue
    end

    if bracket.rate === nothing
      continue
    end
    rate = legislation_at(bracket.rate, date, check_start_date = tax_scale.check_start_date,
      check_stop_date = tax_scale.check_stop_date)
    if rate === nothing
      continue
    end

    if bracket.base !== nothing
      base = legislation_at(bracket.base, date, check_start_date = tax_scale.check_start_date,
        check_stop_date = tax_scale.check_stop_date)
      if base !== nothing
        rate *= base
      end
    end

    push!(thresholds, threshold)
    push!(rates, rate)
  end
  if isa(tax_scale, LinearAverageRateScale)
    return LinearAverageRateScaleAtDate(rates, thresholds)  # TODO: option?, unit?
  end
  tax_scale::MarginalRateScale
  return MarginalRateScaleAtDate(rates, thresholds)  # TODO: option?
end
