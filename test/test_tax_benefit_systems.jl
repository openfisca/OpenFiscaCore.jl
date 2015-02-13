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


famille = EntityDefinition("famille", "familles", index_variable_name = "id_famille",
  role_variable_name ="role_dans_famille")
individu = EntityDefinition("individu", "individus", is_person = true)

PARENT1 = Role(1)
PARENT2 = Role(2)


# Input variables


age_en_mois = VariableDefinition(missing_value, "age_en_mois", individu, Month,
  input_variable = true,
  label = "Âge (en nombre de mois)",
)

birth = VariableDefinition(permanent_default_value, "birth", individu, Date,
  cell_default = Date(1970, 1, 1),
  input_variable = true,
  label = "Date de naissance",
  permanent = true,
)

depcom = VariableDefinition(requested_period_last_value, "depcom", famille, String,
  input_variable = true,
  label = """Code INSEE "depcom" de la commune de résidence de la famille""",
)

id_famille = VariableDefinition(permanent_default_value, "id_famille", individu, Unsigned,
  input_variable = true,
  label = "Identifiant de la famille",
  permanent = true,
)

role_dans_famille = VariableDefinition(permanent_default_value, "role_dans_famille", individu, Role,
  input_variable = true,
  label = "Rôle dans la famille",
  permanent = true,
)

salaire_brut = VariableDefinition(last_duration_last_value, "salaire_brut", individu, Float32,
  input_variable = true,
  label = "Salaire brut",
)


# Formulas


age = VariableDefinition("age", individu, Year, label = "Âge (en nombre d'années)") do simulation, variable, period
  @variable_at(age_en_mois, period, nothing)
  return period, (age_en_mois === nothing
    ? Year[Year(period.start) - Year(birth_cell) for birth_cell in @calculate(birth, period)]
    : Year[Year(int(div(cell, 12))) for cell in age_en_mois])
end


dom_tom = VariableDefinition("dom_tom", famille, Bool, label = "La famille habite-t-elle les DOM-TOM ?"
) do simulation, variable, period
  period = YearPeriod(firstdayofyear(period.start))
  @calculate(depcom, period)
  return period, beginswith(depcom, "97") .+ beginswith(depcom, "98")
end


dom_tom_individu = VariableDefinition("dom_tom_individu", individu, Bool,
  label = "La personne habite-t-elle les DOM-TOM ?") do simulation, variable, period
  return period, entity_to_person(@calculate(dom_tom, period))
end


revenu_disponible = VariableDefinition("revenu_disponible", individu, Float32, label = "Revenu disponible de la famille"
) do simulation, variable, period
  period = YearPeriod(firstdayofyear(period.start))
  @sum_calculate(rsa, period)
  @calculate(salaire_imposable, period)
  return period, rsa + salaire_imposable * 0.7
end


rsa = VariableDefinition("rsa", individu, Float32, label = "RSA") do simulation, variable, period
  period = MonthPeriod(firstdayofmonth(period.start))
  date = period.start
  if date < Date(2010, 1, 1)
    array = zeros(variable)
  else
    @divide_calculate(salaire_imposable, period)
    if date < Date(2011, 1, 1)
      array = (salaire_imposable .< 500) * 100
    elseif date < Date(2013, 1, 1)
      array = (salaire_imposable .< 500) * 200
    else
      array = (salaire_imposable .< 500) * 300
    end
  end
  return period, array
end


salaire_imposable = VariableDefinition("salaire_imposable", individu, Float32, label = "Salaire imposable"
) do simulation, variable, period
  period = YearPeriod(firstdayofyear(period.start))
  return period, @calculate(salaire_net, period) * 0.9 - 100 * @calculate(dom_tom_individu, period)
end


salaire_net = VariableDefinition("salaire_net", individu, Float32, label = "Salaire net") do simulation, variable, period
  period = YearPeriod(firstdayofyear(period.start))
  return period, @calculate(salaire_brut, period) * 0.8
end


# Tests


tax_benefit_system = TaxBenefitSystem(
  [famille, individu],
  Legislation(),
  [
    age,
    age_en_mois,
    birth,
    depcom,
    dom_tom,
    dom_tom_individu,
    id_famille,
    revenu_disponible,
    rsa,
    role_dans_famille,
    salaire_brut,
    salaire_imposable,
    salaire_net,
  ],
)

@test famille.name == "famille"
@test tax_benefit_system.entity_definition_by_name["famille"] === famille

simulation = Simulation(tax_benefit_system, YearPeriod(2013))
famille = get_entity(simulation, "famille")
famille.count = 1
famille.roles_count = 2
individu = get_entity(simulation, "individu")
individu.count = 2
set_array(simulation, "birth", [Date(1973, 1, 1), Date(1974, 1, 1)])
set_array(simulation, "id_famille", [1, 1])
set_array(simulation, "role_dans_famille", [PARENT1, PARENT2])
assert_near(calculate(simulation, "age"), [Year(40), Year(39)], error_margin = 0)

# Redo the previous simulation using the add_member helper function.
simulation = Simulation(tax_benefit_system, YearPeriod(2013))
famille = get_entity(simulation, "famille")
individu = get_entity(simulation, "individu")
add_member(famille)
add_member(individu, birth = Date(1973, 1, 1), role_dans_famille = PARENT1)
add_member(individu, birth = Date(1974, 1, 1), role_dans_famille = PARENT2)
assert_near(calculate(simulation, "age"), [Year(40), Year(39)], error_margin = 0)

simulation = Simulation(tax_benefit_system, YearPeriod(2013))
famille = get_entity(simulation, "famille")
famille.count = 1
famille.roles_count = 2
individu = get_entity(simulation, "individu")
individu.count = 2
set_array(simulation, "age_en_mois", [Month(40 * 12 + 11), Month(39 * 12)])
set_array(simulation, "id_famille", [1, 1])
set_array(simulation, "role_dans_famille", [PARENT1, PARENT2])
assert_near(calculate(simulation, "age"), [Year(40), Year(39)], error_margin = 0)

# Redo the previous simulation using the add_member helper function.
simulation = Simulation(tax_benefit_system, YearPeriod(2013))
famille = get_entity(simulation, "famille")
individu = get_entity(simulation, "individu")
add_member(famille)
add_member(individu, age_en_mois = Month(40 * 12 + 11), role_dans_famille = PARENT1)
add_member(individu, age_en_mois = Month(39 * 12), role_dans_famille = PARENT2)
assert_near(calculate(simulation, "age"), [Year(40), Year(39)], error_margin = 0)


function check_revenu_disponible(year, depcom, expected_revenu_disponible)
  simulation = Simulation(tax_benefit_system, YearPeriod(year))
  famille = get_entity(simulation, "famille")
  famille.count = 3
  famille.roles_count = 2
  individu = get_entity(simulation, "individu")
  individu.count = 6
  set_array(simulation, "depcom", [depcom, depcom, depcom])
  set_array(simulation, "id_famille", [1, 1, 2, 2, 3, 3])
  set_array(simulation, "role_dans_famille", [PARENT1, PARENT2, PARENT1, PARENT2, PARENT1, PARENT2])
  set_array(simulation, "salaire_brut", [0.0, 0.0, 50000.0, 0.0, 100000.0, 0.0])
  assert_near(calculate(simulation, "revenu_disponible"), expected_revenu_disponible)

  # Redo the previous simulation using the add_member helper function.
  simulation = Simulation(tax_benefit_system, YearPeriod(year))
  famille = get_entity(simulation, "famille")
  individu = get_entity(simulation, "individu")
  salaire_brut = [0.0, 0.0, 50000.0, 0.0, 100000.0, 0.0]
  for famille_index in 1:3
    add_member(famille, depcom = depcom)
    add_member(individu, role_dans_famille = PARENT1, salaire_brut = salaire_brut[(famille_index - 1) * 2 + 1])
    add_member(individu, role_dans_famille = PARENT2, salaire_brut = salaire_brut[(famille_index - 1) * 2 + 2])
  end
  assert_near(calculate(simulation, "revenu_disponible"), expected_revenu_disponible)
end


check_revenu_disponible(2009, "75101", [0, 0, 25200, 0, 50400, 0])
check_revenu_disponible(2010, "75101", [1200, 1200, 25200, 1200, 50400, 1200])
check_revenu_disponible(2011, "75101", [2400, 2400, 25200, 2400, 50400, 2400])
check_revenu_disponible(2012, "75101", [2400, 2400, 25200, 2400, 50400, 2400])
check_revenu_disponible(2013, "75101", [3600, 3600, 25200, 3600, 50400, 3600])

check_revenu_disponible(2009, "97123", [-70.0, -70.0, 25130.0, -70.0, 50330.0, -70.0])
check_revenu_disponible(2010, "97123", [1130.0, 1130.0, 25130.0, 1130.0, 50330.0, 1130.0])
check_revenu_disponible(2011, "98456", [2330.0, 2330.0, 25130.0, 2330.0, 50330.0, 2330.0])
check_revenu_disponible(2012, "98456", [2330.0, 2330.0, 25130.0, 2330.0, 50330.0, 2330.0])
check_revenu_disponible(2013, "98456", [3530.0, 3530.0, 25130.0, 3530.0, 50330.0, 3530.0])
