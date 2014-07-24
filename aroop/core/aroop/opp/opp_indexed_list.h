/*
 * This file part of aroop.
 *
 * Copyright (C) 2012  Kamanashis Roy
 *
 * Aroop is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MiniIM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Aroop.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Created on: Aug 21, 2011
 *      Author: Kamanashis Roy
 */

#ifndef OPP_INDEXED_LIST_H
#define OPP_INDEXED_LIST_H

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/opp/opp_factory.h"
#endif

C_CAPSULE_START

void*opp_indexed_list_get(struct opp_factory*olist, int index);
int opp_indexed_list_set(struct opp_factory*olist, int index, void*obj_data);
#define OPP_INDEXED_LIST_CREATE2(olist, pool_size, property) ({opp_indexed_list_create2_and_profile(olist, pool_size, property, __FILE__, __LINE__, "aroop");})
int opp_indexed_list_create2_and_profile(struct opp_factory*olist, int pool_size, unsigned char property, char*source_file, int source_line, char*module_name);
C_CAPSULE_END

#endif
