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


#ifndef AROOP_FACTORY_H
#define AROOP_FACTORY_H

#include "core/config.h"
#include "opp/opp_factory.h"
#include "opp/opp_any_obj.h"
#include "opp/opp_io.h"
#include "opp/opp_indexed_list.h"
#include "opp/opp_list.h"

typedef struct opp_factory opp_factory_t;
typedef struct opp_pool opp_pool_t;

C_CAPSULE_START

enum {
	AROOP_FLAG_HAS_LOCK = OPPF_HAS_LOCK,
	AROOP_FLAG_SWEEP_ON_UNREF = OPPF_SWEEP_ON_UNREF,
	AROOP_FLAG_EXTENDED = OPPF_EXTENDED,
	AROOP_FLAG_SEARCHABLE = OPPF_SEARCHABLE,
	AROOP_FLAG_INITIALIZE = OPPF_FAST_INITIALIZE,
#if 0
	AROOP_FLAG_HAS_LOCK = OPPF_COPY_OBJ_HASH_TO_LIST_ITEM = 1<<5,
#endif
};

// Factory
#define aroop_alloc_full(x0,x1,x2,x3,x4) ({*(x4)=opp_alloc4(x0,x1,x2,x3);})
#define aroop_assert_factory_creation_full(x0, x1, x2, x3, x4, x5) ({\
	aroop_assert(opp_factory_create_full(x0, x1, x2, x3 ,x4, x5) == 0);})
#define aroop_assert_factory_creation_for_type(x0, x1, x2, x3, x4) ({\
	aroop_assert_factory_creation_full(x0, x2, sizeof(x1), x3 ,x4, x1##_pray);})
#define aroop_assert_factory_creation_for_type_full(x0, x1, x2, x3, x4, x5) ({\
	aroop_assert_factory_creation_full(x0, x2, x3 ,x4, x5, x1##_pray);})
#define aroop_factory_get_by_token(x,y,z) ({*z = opp_get(x,y);})
typedef int (*aroop_iterator_cb)(void*func_data, void*data);

// searchable
#define aroop_srcblefac_constr(x0, x1, x2, x3, x4, x5) ({\
	aroop_assert(opp_factory_create_full(x0, x1, x2, x3 ,x4 | AROOP_FLAG_SEARCHABLE | AROOP_FLAG_EXTENDED, x5) == 0);})
#define aroop_srcblefac_constr_4_type(x0, x1, x2, x3, x4) ({\
	aroop_srcblefac_constr(x0, x2, sizeof(x1), x3, x4, x1##_pray);})
#define aroop_srcblefac_constr_4_type_full(x0, x1, x2, x3, x4, x5) ({\
	aroop_srcblefac_constr(x0, x2, x3 ,x4, x5, x1##_pray);})
#define aroop_searchable_type_system_init()
// TODO set the hash while constructing searchable
#define aroop_searchable_construct(x)



// ArrayList
#define aroop_array_list_create(x,y,z) ({aroop_assert(opp_indexed_list_create2(x,z) == 0);})
#define aroop_indexed_list_get(x,y,z) ({*z = opp_indexed_list_get(x, y);})
#define aroop_indexed_list_set(x,y,z) ({opp_indexed_list_set(x, y, z);})

// Set
#define aroop_list_create(x0, x1, x2, x3) ({opp_list_create2(x0, x2, x3);})
#define aroop_list_add(x,y) ({opp_alloc4(x,0,0,y) != NULL;})

#define aroop_factory_cpy_or_destroy(x,nouse,y,nouse2) ({\
	if((x) && (y)){ \
		memcpy(x,y,sizeof(*(x))); \
	} else { \
		opp_factory_destroy(x); \
	};0;})

// queue
#define aroop_dequeue(x,y) ({*y = opp_dequeue(x);})

C_CAPSULE_END

#endif // AROOP_FACTORY_H
