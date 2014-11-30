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


export Simulation


type Simulation
  tax_benefit_system::TaxBenefitSystem
  period::DatePeriod
  entity_by_name::Dict{String, Entity}
  variable_by_name::Dict{String, Variable}

  Simulation(tax_benefit_system, period, variable_by_name) = new(
    tax_benefit_system,
    period,
    [
      name => Entity(entity_definition, 0)
      for (name, entity_definition) in tax_benefit_system.entity_definition_by_name
    ],
    variable_by_name,
  )
end

Simulation(tax_benefit_system, period) = Simulation(tax_benefit_system, period, Dict{String, Variable}())
