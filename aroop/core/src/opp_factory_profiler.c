/*
 * This file is part of aroop.
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
 *  Created on: Feb 9, 2011
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */
#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/config.h"
#include "aroop/core/memory.h"
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_iterator.h"
#include "aroop/opp/opp_factory_profiler.h"
#endif

C_CAPSULE_START
#ifdef AROOP_OPP_PROFILE

enum {
	PROFILER_SIGNATURE = 1213,
};

#define RETURN_IF_PROFILER_OFF(x) if(prof.signature != PROFILER_SIGNATURE)return x;
static struct {
	int signature;
	int check;
	OPP_VOLATILE_VAR int total_allocated;
	struct opp_factory list;
} prof;

#if 0
struct opp_memory_size {
	int bt;
	int kb;
	int mb;
	int gb;
}
#endif

#ifndef sync_do_compare_and_swap
#define sync_do_compare_and_swap(x,a,b) ({SYNC_ASSERT(*(x) == a);*(x)=b;})
#endif

static int check_stop(int from, int to) {
	int i = 0;
	for(i = 20;i;i--) {
		if(sync_do_compare_and_swap(&(prof.check), from, to)) {
			i = -2;
			break;
		}
	}
	if(i != -2) {
		return -1;
	}
	return 0;
}

void opp_factory_profiler_visit(obj_do_t obj_do, void*func_data) {
	RETURN_IF_PROFILER_OFF();
	opp_factory_do_full(&prof.list, obj_do, func_data, OPPN_ALL, 0, 0);
}

OPP_CB(opp_factory_profiler) {
	struct opp_factory_profiler_info*x = data;
	switch(callback) {
	case OPPN_ACTION_INITIALIZE:
		memset(x,0,sizeof(*x));
		break;
	case OPPN_ACTION_FINALIZE:
		break;
	}
	return 0;
}

int opp_factory_profiler_init() {
	if(prof.signature == PROFILER_SIGNATURE) {
		return -2;
	}
	if(opp_factory_create_full(&prof.list, 4, sizeof(struct opp_factory_profiler_info), 1,  OPPF_HAS_LOCK, OPP_CB_FUNC(opp_factory_profiler))) {
		return -1;
	}
	struct opp_factory_profiler_info*x = OPP_ALLOC1(&prof.list);
	x->source_file = "profiler_itself";
	x->source_line = 0;
	x->module_name = "opp_profiler";
	time_t now = time(NULL);
	gmtime_r(&now, &x->birth);
	x->obuff = &prof.list;
	prof.check = 1;
	prof.total_allocated = prof.list.memory_chunk_size;
	prof.signature = PROFILER_SIGNATURE;
	return 0;
}

int opp_factory_profiler_deinit() {
	prof.signature = 0;
	opp_factory_destroy(&prof.list);
	return 0;
}

int opp_factory_create_full_and_profile(struct opp_factory*obuff
		, SYNC_UWORD16_T inc
		, SYNC_UWORD16_T obj_size
		, int token_offset
		, unsigned char property
		, opp_callback_t callback
		, char*source_file, int source_line, char*module_name
	) {
	//property |= OPPF_HAS_LOCK | OPPF_SWEEP_ON_UNREF;
	if(opp_factory_create_full(obuff,inc,obj_size,token_offset,property,callback) != 0) {
		return -1;
	}
	RETURN_IF_PROFILER_OFF(0);
	struct opp_factory_profiler_info*x = OPP_ALLOC1(&prof.list);
	x->source_file = source_file;
	x->source_line = source_line;
	x->module_name = module_name;
	time_t now = time(NULL);
	gmtime_r(&now, &x->birth);
	x->obuff = obuff;
	return 0;
}

static int opp_factory_profiler_visit_to_prune(void*func_data, void*data) {
	struct opp_factory_profiler_info*x = data;
	if(x->obuff == func_data) {
		OPPUNREF(x);
		return 1;
	}
	return 0;
}

int opp_factory_destroy_and_remove_profile(struct opp_factory*src) {
	RETURN_IF_PROFILER_OFF(0);
	if(check_stop(1,0)) return 0;
	opp_factory_profiler_visit(opp_factory_profiler_visit_to_prune, src);
	if(check_stop(0,1)) return 0;
	return 0;
}


void*profiler_replace_malloc(size_t size) {
	void*ret = sync_malloc(size);
	if(!ret) {
		return NULL;
	}
	RETURN_IF_PROFILER_OFF(ret);
	do {
		volatile int oldval,newval;
		oldval = prof.total_allocated;
		newval = oldval+size;
		if(sync_do_compare_and_swap(&(prof.total_allocated), oldval, newval)) {
			break;
		}
	} while(1);
	return ret;
}

void profiler_replace_free(void*ptr, size_t size) {
	sync_free(ptr);
	RETURN_IF_PROFILER_OFF();
	do {
		volatile int oldval,newval;
		oldval = prof.total_allocated;
		newval = oldval-size;
		if(sync_do_compare_and_swap(&(prof.total_allocated), oldval, newval)) {
			break;
		}
	} while(1);
}

static int opp_factory_profiler_visit_to_get_total_memory(void*func_data, void*data) {
	struct opp_factory_profiler_info*x = data;
	*((int*)func_data) += (x->obuff->memory_chunk_size*x->obuff->pool_count);
	return 0;
}


void opp_factory_profiler_get_total_memory(int*grasped,int*really_allocated) {
	*grasped = 0;
	*really_allocated = 0;
	RETURN_IF_PROFILER_OFF();
	int linked_memory = 0;
	if(check_stop(1,0)) return;
	opp_factory_profiler_visit(opp_factory_profiler_visit_to_get_total_memory, &linked_memory);
	if(check_stop(0,1)) return;
	*grasped = linked_memory;
	*really_allocated = prof.total_allocated;
}


void opp_factory_profiler_checkleak_debug() {
	RETURN_IF_PROFILER_OFF();
	int linked = 0,allocated = 0;
	opp_factory_profiler_get_total_memory(&linked,&allocated);
	SYNC_ASSERT(linked == allocated);
}
#endif

C_CAPSULE_END
