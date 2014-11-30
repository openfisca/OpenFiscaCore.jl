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


famille = EntityDefinition("famille")
individu = EntityDefinition("individu")

age_en_mois = BareVariableDefinition("age_en_mois", individu, Month, label = "Âge (en nombre de mois)")
birth = BareVariableDefinition("birth", individu, Date, label = "Date de naissance", permanent = true)
depcom = BareVariableDefinition("depcom", famille, String,
  label = """Code INSEE "depcom" de la commune de résidence de la famille""")
id_famille = BareVariableDefinition("id_famille", individu, Unsigned, label = "Identifiant de la famille")
role_famille = BareVariableDefinition("role_dans_famille", individu, Unsigned, label = "Rôle dans la famille")
salaire_brut = BareVariableDefinition("salaire_brut", individu, Float32, label = "Salaire brut")


age = FormulaDefinition("age", individu, Year, label = "Âge (en nombre d'années)") do variable, period
  @get_period_array(age_en_mois, period, nothing)
  return PeriodArray(period,
    age_en_mois === nothing
      ? Year[Year(period.start) - Year(birth_cell) for birth_cell in @calculate(birth, period)]
      : Year[Year(int(div(cell, 12))) for cell in age_en_mois])
end


dom_tom = FormulaDefinition("dom_tom", famille, Bool, label = "La famille habite-t-elle les DOM-TOM ?"
) do variable, period
  period = YearPeriod(firstdayofyear(period.start))
  @calculate(depcom, period)
  return PeriodArray(period, beginswith(depcom, "97") || beginswith(depcom, "98"))
end


revenu_disponible = FormulaDefinition("revenu_disponible", individu, Float32, label = "Revenu disponible de la famille"
) do variable, period
  period = YearPeriod(firstdayofyear(period.start))
  @calculate(rsa, period)
  @calculate(salaire_imposable, period)
  return PeriodArray(period, rsa + salaire_imposable * 0.7)
end


rsa = FormulaDefinition("rsa", individu, Float32, label = "RSA") do variable, period
  period = YearPeriod(firstdayofyear(period.start))
  date = period.start
  if date < Date(2010, 1, 1)
    variable_definition = variable.definition
    return PeriodArray(period, zeros(variable_definition.cell_type, variable_definition.count))
  end
  if date < Date(2012, 1, 1)
    return PeriodArray(period, (@calculate(salaire_imposable, period) .< 500) * 100)
  end
  if date < Date(2013, 1, 1)
    return PeriodArray(period, (@calculate(salaire_imposable, period) .< 500) * 200)
  end
  return PeriodArray(period, (@calculate(salaire_imposable, period) .< 500) * 300)
end


salaire_imposable = FormulaDefinition("salaire_imposable", individu, Float32, label = "Salaire imposable"
) do variable, period
  period = YearPeriod(firstdayofyear(period.start))
  return PeriodArray(period, @calculate(salaire_net, period) * 0.9)  # - 100 * dom_tom_individu
end


salaire_net = FormulaDefinition("salaire_net", individu, Float32, label = "Salaire net") do variable, period
  period = YearPeriod(firstdayofyear(period.start))
  return PeriodArray(period, @calculate(salaire_brut, period) * 0.8)
end


tax_benefit_system = TaxBenefitSystem(
  [famille, individu],
  [
    age,
    age_en_mois,
    birth,
    depcom,
    dom_tom,
    id_famille,
    revenu_disponible,
    rsa,
    role_famille,
    salaire_brut,
    salaire_imposable,
    salaire_net,
  ],
)

@test famille.name == "famille"
@test tax_benefit_system.entity_definition_by_name["famille"] === famille

simulation = Simulation(tax_benefit_system, YearPeriod(2013))
@test simulation.entity_by_name["famille"].definition === famille
set_array(simulation, "birth", [Date(1973, 1, 1), Date(1974, 1, 1)])
@test_approx_eq(calculate(simulation, "age").array, [Year(40), Year(39)])

simulation = Simulation(tax_benefit_system, YearPeriod(2013))
set_period_array(simulation, "age_en_mois", [Month(40 * 12 + 11), Month(39 * 12)])
@test_approx_eq(calculate(simulation, "age").array, [Year(40), Year(39)])

simulation = Simulation(tax_benefit_system, YearPeriod(2013))
set_period_array(simulation, "salaire_brut", [0.0, 50000.0, 100000.0])
@test_approx_eq(calculate(simulation, "revenu_disponible").array, [300.0, 25200.0, 50400.0])
