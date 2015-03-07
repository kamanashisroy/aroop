/**
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

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/config.h"
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_any_obj.h"
#include "aroop/opp/opp_io.h"
#include "aroop/aroop_core_type_conversion.h"
#include "aroop/aroop_core_type_info.h"
#include "aroop/aroop_error.h"
#include "aroop/aroop_assignment.h"
#include "aroop/aroop_array.h"
#include "aroop/aroop_int_type.h"
#endif


typedef void aroop_none;
typedef int aroop_bool;

#define true 1
#define false 0

typedef char string;


C_CAPSULE_START

int aroop_init(int argc, char ** argv); // deprecated, use aroop_main0 instead
int aroop_main0(int argc, char ** argv, int (*cb)());
int aroop_main1(int argc, char ** argv, int (*cb)(char*args));
int aroop_deinit();

#define aroop_object_alloc(x,y) opp_any_obj_alloc(x,y,NULL)
#define aroop_none_unpin(x) ({void*y=x;OPPUNREF(y);/*x=y;*/}) // TODO fix this workarround.
#define aroop_none_pray(x,y,z) opp_callback(x,y,z)
#define aroop_none_describe(x) opp_callback(x, OPPN_ACTION_DESCRIBE, NULL)
#define aroop_none_get_source_module(x,y) opp_callback(x, OPPN_ACTION_GET_SOURCE_MODULE, y)
#define aroop_none_get_class_name(x,y) opp_callback(x, OPPN_ACTION_GET_CLASS_NAME, y)
#define aroop_none_is_same(x,y) ({(x && y && x == y);})
#define aroop_none_shrink(x,y) ({opp_shrink(x,sizeof(*x)+y);})
#define aroop_factory_iterator_get(x,y,a,b,c) ({opp_iterator_create(y,x,a,b,c);})
#define aroop_factory_iterator_get_wrapper(x) ({struct opp_iterator _it;opp_iterator_create(&_it,x,OPPN_ALL,0,0);_it;})
#define aroop_list_item_get(x,y) ({*(y) = ((x)->obj_data);})
#define aroop_list_item_set(x,y) ({OPPUNREF((x)->obj_data);(x)->obj_data = OPPREF(y);})
#define aroop_get_token(x) ({(x)->token;})
#define aroop_donothing(x) ({0;})
#define aroop_donothing3(x,y,z) ({0;})
#define aroop_donothing4(x,y,a,b) ({0;})
#define aroop_memclean_raw2(x) ({memset(x,0,sizeof(*(x)));})
#define aroop_memclean_raw_2args(x,y) ({memset(x,0,sizeof(*(x)));})
#define aroop_memclean(x,y) ({memset(((x)->opp_internal_ext+1), 0, y - sizeof((x)->opp_internal_ext));})
#define aroop_memclean_raw(x,y) ({memset(x, 0, y);})
// TODO remove all the SYNC_ prefix things ..
#define aroop_assert(x)	SYNC_ASSERT(x)
#define aroop_assert_no_error() ({if(errno){aroop_printf("%s", strerror(errno));SYNC_ASSERT(0);};})
#define aroop_memcpy_struct(x,nouse,y,nouse2) ({ \
	if(x) { \
		if(y) { \
			memcpy(x,y,sizeof(*(x))); \
		} else { \
			memset(x,0,sizeof(*(x))); \
		} \
	} \
})
#define aroop_memcpy_strt2(x,nouse,y,nouse2) ({if(x){if(y){memcpy(x,y,sizeof(*(x)));}else{memset(x,0,sizeof(*(x)));}}})
#define aroop_mem_copy(x,y,z) ({memcpy(x,y,z);})
#define aroop_mem_shift(x,y) ({((char*)x+y);})
#define aroop_easy_swap2(unused1,unused2,a,b) ({aroop_none*__x = b;b=a,a=__x;})

#define aroop_struct_cpy_or_destroy(x,y,destroy_func) ({\
	if(x && y){ \
		memcpy(x,y,sizeof(*x)); \
	} else { \
		destroy_func(x); \
	};0;})

#define aroop_object_ref(x) ({OPPREF(x);x;})
#define aroop_generic_object_ref(x) ({OPPREF(x);x;})
#define aroop_object_unref(targ,gt_unused,x) ({OPPUNREF(x);(targ)x;})
#define aroop_generic_object_unref(targ,gt,obj) ({gt(&obj, OPPN_ACTION_UNREF, NULL,0,0);obj;})
#define aroop_no_unref(targ, ...)
#define aroop_build_generics(x,y,obj) ({x(obj,OPPN_ACTION_SET_GENERIC_TYPES,y,0,0);})

#define aroop_cleanup_in_countructor_function(x) ({x=NULL;})
#define aroop_cleanup_in_countructor_function_for_struct(x) memset(&x,0,sizeof(x))
#define aroop_cleanup_in_countructor_function_for_array_costly(x) memset(&x,0,sizeof(x))

#define aroop_assign_closure_of_delegate(x,y) ({x##_closure_data=y##_closure_data;})
#define aroop_assign_closure_as_it_is_of_delegate(x,y) ({x##_closure_data=y;})
#define NULL_closure_data NULL

#define aroop_get_source_file() __FILE__
#define aroop_get_source_lineno() __LINE__
#define aroop_get_source_module() AROOP_MODULE_NAME
#define aroop_array(x,y) (x)

// value
#define aroop_value_set(nouse,x,y) ({x=y;})
void aroop_core_gc_unsafe();

int aroop_get_argc();
char**aroop_get_argv();

C_CAPSULE_END

#endif // AROOP_CORE_H_
