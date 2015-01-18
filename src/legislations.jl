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


typealias Legislation Dict{String, Any}


function add_to_legislation(legislation::Legislation, path, parameter)
  @assert(path !== nothing && !isempty(path))
  split_path = split(path, '.', 2, false)
  @assert(!isempty(split_path))
  child = get!(legislation, split_path[1]) do
    return length(split_path) == 1 ? parameter : Legislation()
  end
  if length(split_path) == 2
    add_to_legislation(child, split_path[2], parameter)
  end
  return legislation
end


legislation_at(legislation::Legislation, date::Date) = Legislation([
  name => legislation_at(child, date)
  for (name, child) in legislation
])
