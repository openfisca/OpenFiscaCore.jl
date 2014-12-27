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


# abstract AbstractBracket
# abstract AbstractDatedTaxScale
# abstract AbstractTaxScale
#
#
# type AmountBracket <: AbstractBracket
#   amount::DateRangeValue{Float32}[]
#   base::DateRangeValue{Float32}[]
#   threshold::DateRangeValue{Float32}[]
#   comment
# end
#
#
# type AmountTaxScale <: AbstractTaxScale
#   brackets::AmountBracket[]
#   unit
#   check_start_date  # The first date for which this tax scale (or lack of it) has been verified in legislation
#   check_stop_date  # The last date for which this tax scale (or lack of it) has been verified in legislation
#   comment
# end
#
#
# DatedAmountTaxScale <: AbstractDatedTaxScale
#   amounts::Float32[]
#   thresholds::Float32[]
#   # unit ?
# end
#
#
# DatedRateTaxtScale <: AbstractDatedTaxScale
#   rates::Float32[]
#   thresholds::Float32[]
#   # unit ?
# end


# type RateBracket <: AbstractBracket
#   base::DateRangeValue{Float32}[]
#   threshold::DateRangeValue{Float32}[]
#   rate::DateRangeValue{Float32}[]
#   comment
# end
#
#
# type RateTaxScale <: AbstractTaxScale
#   brackets::RateBracket[]
#   unit
#   check_start_date  # The first date for which this tax scale (or lack of it) has been verified in legislation
#   check_stop_date  # The last date for which this tax scale (or lack of it) has been verified in legislation
#   comment
# end
