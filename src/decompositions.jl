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


abstract AbstractDecompositionNode


immutable Color
  red::Uint8
  green::Uint8
  blue::Uint8
end


immutable DecompositionNode <: AbstractDecompositionNode
  name::String
  label::String
  short_label::String
  color::Color
  children::Union(Array{DecompositionNode}, Nothing)
  variable_definition::Union(VariableDefinition, Nothing)
end


visit_decomposition(
  tax_benefit_system::TaxBenefitSystem, variable_name::String, label::String, short_label::String, color::Color
) = DecompositionNode(
  variable_name, label, short_label, color, nothing, tax_benefit_system.variable_definition_by_name[variable_name]
)

visit_decomposition(
  tax_benefit_system::TaxBenefitSystem, variable_name::Symbol, label::String, short_label::String, color::Expr
) = visit_decomposition(
  tax_benefit_system, string(variable_name), label, short_label, Color(color.args...)
)

visit_decomposition(tax_benefit_system::TaxBenefitSystem, name::String, label::String, short_label::String,
  color::Color, children::Array{DecompositionNode}) = DecompositionNode(name, label, short_label, color, children, nothing)

function visit_decomposition(tax_benefit_system::TaxBenefitSystem, name::Symbol, label::String, short_label::String,
    color::Expr, children::Expr)
  @assert children.head in [:hcat, :row, :vcat]
  children_nodes::Array{DecompositionNode} = map(
    arg -> visit_decomposition(tax_benefit_system, arg.args...),
    children.args,
  )
  visit_decomposition(tax_benefit_system, string(name), label, short_label, Color(color.args...), children_nodes)
end
