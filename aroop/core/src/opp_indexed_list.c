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
#include "opp/opp_factory.h"
#include "opp/opp_factory_profiler.h"
#include "opp/opp_indexed_list.h"
#include "opp/opp_iterator.h"
#include "opp/opp_list.h"
#endif

C_CAPSULE_START

#define OPPREF_CONTENT(x,y) ({if(!((x)->property & OPPL_POINTER_NOREF))OPPREF(y);})
#define OPPUNREF_CONTENT(x,y) ({if(!((x)->property & OPPL_POINTER_NOREF))OPPUNREF(y);})

OPP_CB(indexed_list_item) {
	opp_pointer_ext_t*item = (opp_pointer_ext_t*)data;
	switch(callback) {
	case OPPN_ACTION_FINALIZE:
		OPPUNREF(item->obj_data);
		break;
	case OPPN_ACTION_INITIALIZE:
		item->obj_data = (void*)cb_data;
		OPPREF(item->obj_data);
		break;
	}
	return 0;
}


OPP_CB(indexed_list_item_noref) {
	opp_pointer_ext_t*item = (opp_pointer_ext_t*)data;
	switch(callback) {
	case OPPN_ACTION_FINALIZE:
		break;
	case OPPN_ACTION_INITIALIZE:
		item->obj_data = (void*)cb_data;
		break;
	}
	return 0;
}


void*opp_indexed_list_get(struct opp_factory*olist, int index) {
	opp_pointer_ext_t*holder = (opp_pointer_ext_t*)opp_search(olist, index, NULL, NULL, NULL);
	void*ret = NULL;
	if(holder) {
		ret = holder->obj_data;
		if(ret) {
			OPPREF_CONTENT(olist,ret);
		}
		OPPUNREF(holder);
	}
	return ret;
}

int opp_indexed_list_set(struct opp_factory*olist, int index, void*obj_data) {
	int ret = 0;
	opp_factory_lock_donot_use(olist);
	opp_pointer_ext_t*holder = (opp_pointer_ext_t*)opp_search(olist, index, NULL, NULL, NULL);
	if(holder) {
		opp_set_flag(holder, OPPN_ZOMBIE);
		void*tmp = holder;
		OPPUNREF(holder);
		OPPUNREF(tmp);
	}
	if(obj_data) {
		opp_pointer_ext_t*item = (opp_pointer_ext_t*)OPP_ALLOC2(olist, obj_data);
		if(!item) {
			ret = -1;
		} else {
			opp_set_hash(item, index);
		}
	}
	opp_factory_unlock_donot_use(olist);
	return ret;
}

int opp_indexed_list_create2_and_profile(struct opp_factory*olist, int pool_size
		, unsigned char property, char*source_file, int source_line, char*module_name) {
	return opp_factory_create_full_and_profile(olist, pool_size
			, sizeof(opp_pointer_ext_t)
			, 1, property | OPPF_SEARCHABLE | OPPF_EXTENDED | OPPF_SWEEP_ON_UNREF
			, (property & OPPL_POINTER_NOREF) ? OPP_CB_FUNC(indexed_list_item_noref) : OPP_CB_FUNC(indexed_list_item)
			, source_file, source_line, module_name);
}

C_CAPSULE_END
