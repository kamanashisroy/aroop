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
#include "aroop/core/config.h"
#include "aroop/core/xtring.h"
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_factory_profiler.h"
#include "aroop/opp/opp_hash_table.h"
#include "aroop/opp/opp_any_obj.h"
#include "aroop/opp/opp_io.h"
#include "aroop/opp/opp_indexed_list.h"
#include "aroop/opp/opp_list.h"
#endif

typedef struct opp_factory opp_factory_t;
typedef struct opp_pool opp_pool_t;

C_CAPSULE_START

typedef struct {
	void*aroop_closure_data;
	obj_do_t aroop_cb;
} aroop_do_t;

enum {
	AROOP_FLAG_HAS_LOCK = OPPF_HAS_LOCK,
	AROOP_FLAG_SWEEP_ON_UNREF = OPPF_SWEEP_ON_UNREF,
	AROOP_FLAG_EXTENDED = OPPF_EXTENDED,
	AROOP_FLAG_SEARCHABLE = OPPF_SEARCHABLE,
	AROOP_FLAG_INITIALIZE = OPPF_FAST_INITIALIZE,
	AROOP_FLAG_MEMORY_CLEAN = OPPF_MEMORY_CLEAN,
#if 0
	AROOP_FLAG_HAS_LOCK = OPPF_COPY_OBJ_HASH_TO_LIST_ITEM = 1<<5,
#endif
};
// Factory
#define aroop_alloc_full(x0,x1,x2,x3,x4,x5) ({*(x5)=(typeof((*x5)))opp_alloc4(x0,x1,x2,x3,x4);})
#define aroop_alloc_added_size(x0,x1,x2) ({*(x2)=(typeof((*x2)))opp_alloc4(x0,(x0)->obj_size+x1,0,0,0);})
#define aroop_assert_factory_creation_full(x0, x1, x2, x3, x4, x5) ({\
	aroop_assert(OPP_PFACTORY_CREATE_FULL(x0, x1, x2, x3 ,x4, x5) == 0);})
#define aroop_assert_factory_creation_for_type(x0, x1, x2, x3, x4) ({\
	aroop_assert_factory_creation_full(x0, x2, x1(NULL, OPPN_ACTION_GET_SIZE, NULL, NULL, 0), x3 ,x4, x1);})
#define aroop_assert_factory_creation_for_type_full(x0, x1, x2, x3, x4, x5) ({\
	aroop_assert_factory_creation_full(x0, x2, x3 ,x4, x5, x1);})
#define aroop_factory_get_by_token(x,y,z) ({*z = opp_get(x,y);})
//typedef int (*aroop_iterator_cb)(void*func_data, void*data);
#define aroop_factory_do_full(x,a,b,c,d) ({opp_factory_do_full(x,(obj_do_t)(a).aroop_cb,(a).aroop_closure_data,b,c,d);})
#define aroop_factory_list_do_full(x,a,b,c,d,e,f,g) ({opp_factory_list_do_full(x,(obj_do_t)(a).aroop_cb,(a).aroop_closure_data,b,c,d,e,f,g);})

// searchable
#define aroop_srcblefac_constr(x0, x1, x2, x3, x4, x5) ({\
	aroop_assert(OPP_PFACTORY_CREATE_FULL(x0, x1, x2, x3 ,x4 | AROOP_FLAG_SEARCHABLE | AROOP_FLAG_EXTENDED, x5) == 0);})
#define aroop_srcblefac_constr_4_type(x0, x1, x2, x3, x4) ({\
	aroop_srcblefac_constr(x0, x2, x1(NULL, OPPN_ACTION_GET_SIZE, NULL, NULL, 0), x3, x4, x1);})
#define aroop_srcblefac_constr_4_type_full(x0, x1, x2, x3, x4, x5) ({\
	aroop_srcblefac_constr(x0, x2, x3 ,x4, x5, x1);})
#define aroop_cl_aroop_aroop_searchable_type_system_init()
// TODO set the hash while constructing searchable
#define aroop_cl_aroop_aroop_searchable_construct(x)
#define aroop_cl_aroop_aroop_hashable_construct(x)
#define aroop_cl_aroop_aroop_hashable_type_system_init()
#define aroop_search(a,h,cb,ret) ({(typeof((*ret)))opp_search(a, h, (obj_do_t)(cb).aroop_cb,(cb).aroop_closure_data, (void**)ret);})
#define aroop_search_no_ret_arg(a,h,cb) ({opp_search(a, h, (obj_do_t)(cb).aroop_cb,(cb).aroop_closure_data, NULL);})


// ArrayList
#define aroop_array_list_create(x,y,z) ({SYNC_ASSERT(OPP_INDEXED_LIST_CREATE2(x,z,0) == 0);})
#define aroop_indexed_list_get(x,y,z) ({*z = opp_indexed_list_get(x, y);})
#define aroop_indexed_list_set(x,y,z) ({opp_indexed_list_set(x, y, z);})

// Set
#define aroop_list_create(x0, x1, x2, x3) ({OPP_PLIST_CREATE_FULL(x0, x2, x3);})
#define aroop_list_add(x,y) ({opp_alloc4(x,0,0,0,y) != NULL;})
#define aroop_list_add_container(x,y,hash,flag) ({void*__mem = NULL;if((__mem = opp_alloc4(x,0,0,0,y)) != NULL){if(flag)opp_set_flag(__mem, flag);if(hash)opp_set_hash(__mem,hash);aroop_object_ref(__mem);};__mem;})
#define aroop_searchable_list_prune(ls,h,x) ({opp_list_search_and_prune(ls, h, x);})
#define aroop_searchable_list_create(x0, x1, x2, x3) ({OPP_PLIST_CREATE_FULL(x0, x2, x3 | AROOP_FLAG_SEARCHABLE | AROOP_FLAG_EXTENDED);})

#define aroop_factory_cpy_or_destroy(x,nouse,y,nouse2) ({\
	if((x) && (y)){ \
		memcpy(x,y,sizeof(*(x))); \
	} else { \
		opp_factory_destroy(x); \
	};0;})

// queue
#define aroop_dequeue(x,y) ({*y = opp_dequeue(x);})
#define aroop_queue_init(x,y,z) ({opp_queue_init2(x,z);})
#define aroop_queue_copy_or_destroy(x,xindex,y,yindex) ({ \
	if((x) && (y)){ \
		memcpy((x)+xindex,(y)+yindex,sizeof(*(x))); \
	} else { \
		opp_factory_destroy(((x)+xindex)); \
	};0;})

// object 
#define aroop_mark_searchable_ext(x,y) ({(x)->flag |= y;})
#define aroop_unmark_searchable_ext(x,y) ({(x)->flag &= y;})
#define aroop_test_searchable_ext(x,y) ({(x)->flag & y;})

// iterator
#define aroop_iterator_create(x,targ,y,a,b,c) ({opp_iterator_create(x,y,a,b,c);})
#define aroop_iterator_next(x) ({opp_iterator_next(x) != NULL;})
#define aroop_iterator_get_unowned(x,y) ({*(y)=(x)->data;})
#define aroop_iterator_get(x,y) ({*(y)=(x)->data;(x)->data=NULL;})
#define aroop_iterator_unlink(x) ({if((x)->data)OPPUNREF((x)->data);})
#define aroop_iterator_cpy_or_destroy(x,nouse,y,nouse2) ({\
	if((x) && (y)){ \
		memcpy(x,y,sizeof(*(x))); \
	} else { \
		opp_iterator_destroy(x); \
	};0;})

// hashtable
#define aroop_hash_table_create(x0, xx1, xx2, a, b, x2, x3) ({opp_hash_table_create(x0, x2, x3, a, b);})
#define aroop_hash_table_get(x,y,z) ({*z = opp_hash_table_get(x, y);})
#define aroop_hash_table_use_count(x) (OPP_FACTORY_USE_COUNT(&(x)->fac));
#define aroop_hash_table_pointer_get_key(x,y) ({*(y) = (x)->key;})

// cleanup
#define opp_object_ext_tiny_t_prepare_internal(x)
#define opp_object_ext_t_prepare_internal(x)

#define aroop_factory_mark_all(x,y) ({aroop_factory_action_all_internal(x,1,y);})
#define aroop_factory_unmark_all(x,y) ({aroop_factory_action_all_internal(x,0,y);})
#define aroop_factory_prune_marked(x,y) ({aroop_factory_action_all_internal(x,-1,y);})
int aroop_factory_action_all_internal(struct opp_factory*opp, int action, unsigned int flag);
int aroop_cl_aroop_aroop_hashable_pray(void*data, int callback, void*cb_data, va_list ap, int size);
int aroop_cl_aroop_aroop_searchable_pray(void*data, int callback, void*cb_data, va_list ap, int size);

//#define aroop_factory_free_function(unused1,unused2,x) opp_factory_destroy(x)
#define aroop_factory_free_function(x, unused1, x2, unused2) opp_factory_destroy(x)

C_CAPSULE_END

#endif // AROOP_FACTORY_H
