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
 *  Created on: Feb 9, 2011
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_factory_profiler.h"
#include "aroop/opp/opp_list.h"
#include "aroop/opp/opp_iterator.h"
#endif

C_CAPSULE_START

#define OPPREF_CONTENT(x,y) ({if(!((x)->property & OPPL_POINTER_NOREF))OPPREF(y);})
#define OPPUNREF_CONTENT(x,y) ({if(!((x)->property & OPPL_POINTER_NOREF))OPPUNREF(y);})

OPP_CB(list_item) {
	opp_pointer_ext_t*item = (opp_pointer_ext_t*)data;

	switch(callback) {
	case OPPN_ACTION_INITIALIZE:
		item->obj_data = (void*)cb_data;
		OPPREF(item->obj_data);
		break;
	case OPPN_ACTION_FINALIZE:
		OPPUNREF(item->obj_data);
		break;
	}
	return 0;
}

OPP_CB(list_item_noref) {
	opp_pointer_ext_t*item = (opp_pointer_ext_t*)data;

	switch(callback) {
	case OPPN_ACTION_INITIALIZE:
		item->obj_data = (void*)cb_data;
		break;
	}
	return 0;
}


opp_pointer_ext_t*opp_list_add_noref(struct opp_factory*olist, void*obj_data) {
	opp_pointer_ext_t*item = (opp_pointer_ext_t*)OPP_ALLOC2(olist, obj_data);
	// link
	if(!item) {
		return NULL;
	}

	OPPUNREF_CONTENT(olist, obj_data);
	return item;
}

int opp_list_create2_and_profile(struct opp_factory*olist, int pool_size, opp_property_t flag
		, char*source_file, int source_line, char*module_name) {
	return opp_factory_create_full_and_profile(olist, pool_size
			, sizeof(opp_pointer_ext_t)
			, 1, flag | OPPF_SWEEP_ON_UNREF
			, (flag & OPPL_POINTER_NOREF) ? OPP_CB_FUNC(list_item_noref) : OPP_CB_FUNC(list_item)
			, source_file, source_line, module_name);
}

struct opp_find_list_helper {
	obj_comp_t compare_func;
	const void*compare_data;
	struct opp_factory*olist;
	int count;
};

static int opp_factory_list_compare(void*func_data, void*data) {
	struct opp_find_list_helper*helper = (struct opp_find_list_helper*)func_data;

	if(helper->compare_func(helper->compare_data, data)) {
		return 0;
	}

	OPP_ALLOC2(helper->olist, data);
	return 0;
}

static int opp_list_prune_helper(void*data, void*target) {
	if(((opp_pointer_ext_t*)data)->obj_data == target) {
		OPPUNREF(data);
	}
	return 0;
}

int opp_list_prune(struct opp_factory*olist, void*target, int if_flag, int if_not_flag, int hash) {
	opp_factory_do_full(olist, opp_list_prune_helper, target, if_flag, if_not_flag, hash);
	return 0;
}

static int opp_list_search_and_prune_comparator(const void*data, const void*target) {
	if(((opp_pointer_ext_t*)data)->obj_data == target) {
		OPPUNREF(data);
	}
	return -1;
}

int opp_list_search_and_prune(struct opp_factory*obuff
	, opp_hash_t hash, const void*target) {
	void*rval = NULL;
	opp_search(obuff, hash, opp_list_search_and_prune_comparator, target, &rval);
	SYNC_ASSERT(rval == NULL);
	return 0;
}

int opp_list_find_from_factory(struct opp_factory*obuff, struct opp_factory*olist
		, obj_comp_t compare_func, const void*compare_data) {
	struct opp_find_list_helper helper = {
#ifdef __cplusplus
			compare_func, compare_data, olist, 0
#else
			.compare_func = compare_func,
			.compare_data = compare_data,
			.olist = olist,
			.count = 0,
#endif
	};

	OPP_FACTORY_DO(obuff, opp_factory_list_compare, &helper);
	return helper.count;
}

C_CAPSULE_END
