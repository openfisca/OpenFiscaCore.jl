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


immutable Role
  value::Uint8
end


ALL_ROLES = [Role(0)]


convert{T<:Number}(::Type{T}, role::Role) = convert(T, role.value)


.==(left::Role, right::Union(Array, Number)) = left.value .== right

.==(left::Union(Array, Number), right::Role) = left .== right.value


isless(left::Number, right::Role) = isless(left, right.value)

isless(left::Role, right::Number) = isless(left.value, right)

isless(left::Role, right::Role) = isless(left.value, right.value)
