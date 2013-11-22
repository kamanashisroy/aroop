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

#ifndef AROOP_CONCATENATED_FILE
#include "core/config.h"
#include "opp/opp_factory.h"
#include "opp/opp_any_obj.h"
#include "opp/opp_io.h"
#include "opp/opp_indexed_list.h"
#include "opp/opp_list.h"
#endif

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
#define aroop_alloc_full(x0,x1,x2,x3,x4) ({*(x4)=(typeof((*x4)))opp_alloc4(x0,x1,x2,x3);})
#define aroop_assert_factory_creation_full(x0, x1, x2, x3, x4, x5) ({\
	aroop_assert(opp_factory_create_full(x0, x1, x2, x3 ,x4, x5) == 0);})
#define aroop_assert_factory_creation_for_type(x0, x1, x2, x3, x4) ({\
	aroop_assert_factory_creation_full(x0, x2, x1(NULL, OPPN_ACTION_GET_SIZE, NULL, NULL, 0), x3 ,x4, x1);})
#define aroop_assert_factory_creation_for_type_full(x0, x1, x2, x3, x4, x5) ({\
	aroop_assert_factory_creation_full(x0, x2, x3 ,x4, x5, x1);})
#define aroop_factory_get_by_token(x,y,z) ({*z = opp_get(x,y);})
//typedef int (*aroop_iterator_cb)(void*func_data, void*data);
#define aroop_factory_do_full(x,a,ax,b,c,d) ({opp_factory_do_full(x,(obj_do_t)a,ax,b,c,d);})
#define aroop_factory_list_do_full(x,a,ax,b,c,d,e,f,g) ({opp_factory_list_do_full(x,(obj_do_t)a,ax,b,c,d,e,f,g);})


// searchable
#define aroop_srcblefac_constr(x0, x1, x2, x3, x4, x5) ({\
	aroop_assert(opp_factory_create_full(x0, x1, x2, x3 ,x4 | AROOP_FLAG_SEARCHABLE | AROOP_FLAG_EXTENDED, x5) == 0);})
#define aroop_srcblefac_constr_4_type(x0, x1, x2, x3, x4) ({\
	aroop_srcblefac_constr(x0, x2, x1(NULL, OPPN_ACTION_GET_SIZE, NULL, NULL, 0), x3, x4, x1);})
#define aroop_srcblefac_constr_4_type_full(x0, x1, x2, x3, x4, x5) ({\
	aroop_srcblefac_constr(x0, x2, x3 ,x4, x5, x1);})
#define aroop_cl_aroop_aroop_searchable_type_system_init()
// TODO set the hash while constructing searchable
#define aroop_cl_aroop_aroop_searchable_construct(x)
#define aroop_search(a,h,cb,cbp,ret) ({(typeof((*ret)))opp_search(a, h, (obj_comp_t)cb, cbp, (void**)ret);})
#define aroop_search_no_ret_arg(a,h,cb,cbp) ({opp_search(a, h, (obj_comp_t)cb, cbp, NULL);})


// ArrayList
#define aroop_array_list_create(x,y,z) ({aroop_assert(opp_indexed_list_create2(x,z) == 0);})
#define aroop_indexed_list_get(x,y,z) ({*z = opp_indexed_list_get(x, y);})
#define aroop_indexed_list_set(x,y,z) ({opp_indexed_list_set(x, y, z);})

// Set
#define aroop_list_create(x0, x1, x2, x3) ({opp_list_create2(x0, x2, x3);})
#define aroop_list_add(x,y) ({opp_alloc4(x,0,0,y) != NULL;})
#define aroop_list_add_container(x,y,hash,flag) ({void*__mem = NULL;if((__mem = opp_alloc4(x,0,0,y)) != NULL){if(flag)opp_set_flag(__mem, flag);if(hash)opp_set_hash(__mem,hash);};__mem;})
#define aroop_searchable_list_prune(ls,h,x) ({opp_list_search_and_prune(ls, h, x);})
#define aroop_searchable_list_create(x0, x1, x2, x3) ({opp_list_create2(x0, x2, x3 | AROOP_FLAG_SEARCHABLE | AROOP_FLAG_EXTENDED);})

#define aroop_factory_cpy_or_destroy(x,nouse,y,nouse2) ({\
	if((x) && (y)){ \
		memcpy(x,y,sizeof(*(x))); \
	} else { \
		opp_factory_destroy(x); \
	};0;})

// queue
#define aroop_dequeue(x,y) ({*y = opp_dequeue(x);})

// object 
#define aroop_mark_searchable_ext(x,y) ({(x)->flag |= y;})
#define aroop_unmark_searchable_ext(x,y) ({(x)->flag &= y;})
#define aroop_test_searchable_ext(x,y) ({(x)->flag & y;})

C_CAPSULE_END

#endif // AROOP_FACTORY_H
