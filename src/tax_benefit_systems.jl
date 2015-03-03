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


type TaxBenefitSystem
  entity_definition_by_name::Dict{String, EntityDefinition}
  legislation_by_date_cache::WeakKeyDict{Date, Legislation}
  legislation::Legislation
  person_name::String  # Name of person entity
  reference  # Reference tax-benefit system. Used only by reforms. Note: Reforms can be chained.
  to_test_case  # Optional function that validates a JSON test case (inside a scenario).
  variable_definition_by_name::Dict{String, VariableDefinition}

  TaxBenefitSystem(entity_definition_by_name::Dict{String, EntityDefinition}, legislation::Legislation,
    variable_definition_by_name::Dict{String, VariableDefinition}; reference = nothing, to_test_case = nothing
  ) = new(
    entity_definition_by_name,
    WeakKeyDict{Date, Legislation}(),
    legislation,
    get_person_name(entity_definition_by_name),
    reference,
    to_test_case,
    variable_definition_by_name,
  )
end

TaxBenefitSystem(entities_definition::Array{EntityDefinition}, legislation::Legislation,
  variables_definition::Array{VariableDefinition}; reference = nothing
) = TaxBenefitSystem(
  [
    entity_definition.name => entity_definition
    for entity_definition in entities_definition
  ],
  legislation,
  [
    variable_definition.name => variable_definition
    for variable_definition in variables_definition
  ],
)


function get_person_name(entity_definition_by_name::Dict{String, EntityDefinition})
  for (entity_name, entity_definition) in entity_definition_by_name
    if entity_definition.is_person
      return entity_name
    end
  end
  error("List of entities ", entity_definition_by_name, " contains no person entity")
end


function legislation_at(tax_benefit_system::TaxBenefitSystem, date::Date; reference = false)
  if reference
    reference_tax_benefit_system = tax_benefit_system.reference
    if reference_tax_benefit_system !== nothing
      return legislation_at(reference_tax_benefit_system, date, reference = reference)
    end
    # Tax-benefit system is a reference tax-benefit system.
  end
  return get!(tax_benefit_system.legislation_by_date_cache, date) do
    return legislation_at(tax_benefit_system.legislation, date)
  end
end


Base.show(io::IO, tax_benefit_system::TaxBenefitSystem) = print(io, "$(typeof(tax_benefit_system))(...)")
