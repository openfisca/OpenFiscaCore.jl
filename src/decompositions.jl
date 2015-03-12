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


typealias DecompositionNodeChild Union(AbstractDecompositionNode, VariableDefinition)


immutable DecompositionNode <: AbstractDecompositionNode
    name::String
    children::Array{DecompositionNodeChild}
end


decomposition(tax_benefit_system::TaxBenefitSystem, variable_name::String) =
    tax_benefit_system.variable_definition_by_name[variable_name]

decomposition(tax_benefit_system::TaxBenefitSystem, name::Symbol) = decomposition(tax_benefit_system, string(name))

decomposition(tax_benefit_system::TaxBenefitSystem, name::String, children::Array{DecompositionNodeChild}) =
    DecompositionNode(name, children)

decomposition(tax_benefit_system::TaxBenefitSystem, name::Symbol, children::Array{DecompositionNodeChild}) =
    decomposition(tax_benefit_system, string(name), children)

function decomposition(tax_benefit_system::TaxBenefitSystem, name::Symbol, children::Expr; depth = 1)
    @assert children.head in [:hcat, :row, :vcat]
    normalized_args = mapreduce(vcat, [], children.args) do arg
        isa(arg, Expr) && arg.head === :row ? arg.args : arg
    end
    children_nodes::Array{DecompositionNodeChild} = filter(
        x -> x !== nothing,
        map(partition(normalized_args, 2, 1)) do pair
            left, right = pair
            if isa(left, Symbol) && isa(right, Symbol)
                decomposition(tax_benefit_system, string(left))
            elseif isa(left, Symbol) && isa(right, Expr)
                decomposition(tax_benefit_system, left, right; depth = depth + 1)
            elseif isa(left, Expr) && isa(right, Expr)
                error("Unexpected two consecutive Expr for $left and $right")
            end
        end
    )
    last_arg = last(children.args)
    if isa(last_arg, Symbol)
        push!(children_nodes, decomposition(tax_benefit_system, string(last_arg)))
    end
    decomposition(tax_benefit_system, name, children_nodes)
end


flatten(decomposition_node::DecompositionNode) = [
    decomposition_node,
    map(flatten, decomposition_node.children)...,
]

flatten(variable_definition::VariableDefinition) = variable_definition


to_json(decomposition_node::DecompositionNode) = [
    "children" => map(to_json, decomposition_node.children),
    "name" => decomposition_node.name,
]

to_json(variable_definition::VariableDefinition) = [
    "entity_definition.name" => variable_definition.entity_definition.name,
    "name" => variable_definition.name,
]
