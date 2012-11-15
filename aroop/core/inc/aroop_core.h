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
#include "aroop_core_type_conversion.h"

typedef void aroop_god;
typedef int bool;

#define true 1
#define false 0

typedef char string;


C_CAPSULE_START

int aroop_init(int argc, char ** argv);
int aroop_deinit();

#define aroop_object_alloc(x,y) opp_any_obj_alloc(x,y,NULL)
#define aroop_god_unpin(x) ({void*y=x;OPPUNREF(y);/*x=y;*/}) // TODO fix this workarround.
#define aroop_god_pray(x,y,z) opp_callback(x,y,z)
#define aroop_god_describe(x) opp_callback(x, OPPN_ACTION_DESCRIBE, NULL)
#define aroop_god_is_same(x,y) ({(x && y && x == y);})
#define aroop_god_shrink(x,y) ({opp_shrink(x,sizeof(*x)+y);})
#define aroop_iterator_next(x) ({opp_iterator_next(x) != NULL})
#define aroop_iterator_get(x) ({x->data})
#define aroop_factory_iterator_get(x,y,a,b,c) ({opp_iterator_create(y,x,a,b,c);})
#define aroop_list_item_get(x) ({(x)->obj_data;})
#define aroop_get_token(x) ({(x)->token;})
#define aroop_donothing(x)
#define aroop_donothing4(x,y,a,b)
#define aroop_memclean(x,y) ({memset((x->_ext+1), 0, y - sizeof(x->_ext));})
#define aroop_memclean_raw(x,y) ({memset(x, 0, y);})
// TODO remove all the SYNC_ prefix things ..
#define aroop_assert(x)	SYNC_ASSERT(x)
#define aroop_memcpy_struct(x,nouse,y,nouse2) ({if(x && y){memcpy(x,y,sizeof(*x));}})
#define aroop_mem_copy(x,y,z) ({memcpy(x,y,z);})
#define aroop_mem_shift(x,y) ({((char*)x+y);})
#define aroop_queue_init(x,y,z) ({opp_queue_init2(x,z);})

//#define aroop_unref(x) ({OPPUNREF(x);NULL;})
#define any_is_a(x,y) 1

#define aroop_struct_cpy_or_destroy(x,y,destroy_func) ({\
	if(x && y){ \
		memcpy(x,y,sizeof(*x)); \
	} else { \
		destroy_func(x); \
	};0;})


C_CAPSULE_END

#endif // AROOP_CORE_H_
