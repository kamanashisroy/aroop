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
 * Author:
 * 	Kamanashis Roy (kamanashisroy@gmail.com)
 */


#ifndef AROOP_CORE_H_
#define AROOP_CORE_H_

#include "core/config.h"
#include "opp/opp_factory.h"
#include "opp/opp_any_obj.h"
#include "opp/opp_io.h"

typedef void aroop_god;
typedef int bool;

#define true 1
#define false 0

typedef struct opp_factory opp_factory_t;
typedef struct opp_pool opp_pool_t;
typedef char string;



C_CAPSULE_START

int aroop_init(int argc, char ** argv);

#define aroop_object_alloc(x,y) opp_any_obj_alloc(x,y,NULL)
#define aroop_god_pray(x,y,z) opp_callback(x,y,z)
#define aroop_god_is_same(x,y) ({(x && y && x == y);})
#define aroop_indexed_list_get(x,y,z) ({*z = opp_indexed_list_get(x, y);})
#define aroop_set_add(x,y) ({opp_alloc4(x,0,0,y) != NULL})
#define aroop_iterator_next(x) ({opp_iterator_next(x) != NULL})
#define aroop_iterator_get(x) ({x->data})
#define aroop_factory_iterator_get(x,y,a,b,c) ({opp_iterator_create(y,x,a,b,c);})
#define aroop_list_item_get(x) ({x->obj_data;})

C_CAPSULE_END

#endif // AROOP_CORE_H_
