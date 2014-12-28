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


abstract Bracket
abstract DatedTaxScale
abstract DatedRateScale <: DatedTaxScale
abstract TaxScale
abstract RateScale <: TaxScale


# Amount-based tax scales


type AmountBracket <: Bracket
  threshold::Array{DateRangeValue{Float32}}
  amount::Array{DateRangeValue{Float32}}
  base::Union(Array{DateRangeValue{Float32}}, Nothing)

  AmountBracket(; threshold = nothing, amount = nothing, base = nothing) = new(threshold, amount, base)
end


type AmountScale <: TaxScale
  brackets::Array{AmountBracket}
  unit::Union(Nothing, String)
  check_start_date::Union(Date, Nothing)  # The first date for which this tax scale (or lack of it) has been verified in legislation
  check_stop_date::Union(Date, Nothing)  # The last date for which this tax scale (or lack of it) has been verified in legislation
  description::Union(Nothing, String)
  comment::Union(Nothing, String)

  AmountScale(brackets; unit = nothing, check_start_date = nothing, check_stop_date = nothing, description = nothing,
    comment = nothing) = new(brackets, unit, check_start_date, check_stop_date, description, comment)
end


type DatedAmountScale <: DatedTaxScale
  amounts::Array{Float32}
  thresholds::Array{Float32}
  # unit ?
end


# Rated-based tax scales


type DatedLinearAverageRateScale <: DatedRateScale
  rates::Array{Float32}
  thresholds::Array{Float32}
  # unit ?
end


type DatedMarginalRateScale <: DatedRateScale
  rates::Array{Float32}
  thresholds::Array{Float32}
  # unit ?
end


type RateBracket <: Bracket
  threshold::Array{DateRangeValue{Float32}}
  rate::Array{DateRangeValue{Float32}}
  base::Union(Array{DateRangeValue{Float32}}, Nothing)

  RateBracket(; threshold = nothing, rate = nothing, base = nothing) = new(threshold, rate, base)
end


type LinearAverageRateScale <: RateScale
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


type MarginalRateScale <: RateScale
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


function at(tax_scale::AmountScale, date::Date)
  thresholds = DateRangeValue{Float32}[]
  amounts = DateRangeValue{Float32}[]
  for bracket in tax_scale.brackets
    threshold = at(bracket.threshold, date, check_start_date = tax_scale.check_start_date,
      check_stop_date = tax_scale.check_stop_date)
    if threshold === nothing
      continue
    end

    amount = at(bracket.amount, date, check_start_date = tax_scale.check_start_date,
      check_stop_date = tax_scale.check_stop_date)
    if amount === nothing
      continue
    end

    push!(thresholds, threshold)
    push!(amounts, amount)
  end
  return DatedAmountScale(thresholds, amounts)  # TODO: option?
end


function at(tax_scale::RateScale, date::Date)
  thresholds = DateRangeValue{Float32}[]
  rates = DateRangeValue{Float32}[]
  for bracket in tax_scale.brackets
    threshold = at(bracket.threshold, date, check_start_date = tax_scale.check_start_date,
      check_stop_date = tax_scale.check_stop_date)
    if threshold === nothing
      continue
    end

    rate = at(bracket.rate, date, check_start_date = tax_scale.check_start_date,
      check_stop_date = tax_scale.check_stop_date)
    if rate === nothing
      continue
    end

    base = at(bracket.base, date, check_start_date = tax_scale.check_start_date,
      check_stop_date = tax_scale.check_stop_date)
    if base !== nothing
      rate *= base
    end

    push!(thresholds, threshold)
    push!(rates, rate)
  end
  if isa(tax_scale, LinearAverageRateScale)
    return DatedLinearAverageRateScale(thresholds, rates)  # TODO: option?, unit?
  end
  tax_scale::MarginalRateScale
  return DatedMarginalRateScale(thresholds, rates)  # TODO: option?
end
