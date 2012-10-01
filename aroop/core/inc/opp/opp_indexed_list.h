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

#include "opp/opp_factory.h"

C_CAPSULE_START

void*opp_indexed_list_get(struct opp_factory*olist, int index);
int opp_indexed_list_set(struct opp_factory*olist, int index, void*obj_data);
int opp_indexed_list_create2(struct opp_factory*olist, int pool_size);
C_CAPSULE_END

#endif
