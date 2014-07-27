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
#include "aroop/core/xtring.h"
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_factory_profiler.h"
#include "aroop/opp/opp_iterator.h"
#include "aroop/opp/opp_list.h"
#include "aroop/opp/opp_hash_table.h"
#include "aroop/opp/opp_hash.h"
#include "aroop/core/logger.h"
#endif

C_CAPSULE_START

OPP_CB(hash_table_item) {
	opp_map_pointer_ext_t*item = (opp_map_pointer_ext_t*)data;

	switch(callback) {
	case OPPN_ACTION_INITIALIZE:
		item->key = cb_data;
		OPPREF(item->key);
		item->ptr.obj_data = va_arg(ap, void*);
		OPPREF(item->ptr.obj_data);
		break;
	case OPPN_ACTION_FINALIZE:
		OPPUNREF(item->key);
		OPPUNREF(item->ptr.obj_data);
		break;
	}


	return 0;
}

struct match_data {
	opp_hash_table_t*ht;
	void*key;
};

#define OPP_KEY_EQUALS(x,y) ({mdata->ht->efunc.aroop_cb(mdata->ht->efunc.aroop_closure_data,y,mdata->key);})
static int match_hash(const void*func_data, const void*data) {
	const opp_map_pointer_ext_t*item = (const opp_map_pointer_ext_t*)data;
	struct match_data*mdata = (struct match_data*)func_data;
	if(OPP_KEY_EQUALS(mdata,item->key)) {
		return 0;
	}
	return -1;
}

static int match_hash_and_delete(const void*func_data, const void*data) {
	const opp_map_pointer_ext_t*item = (const opp_map_pointer_ext_t*)data;
	struct match_data*mdata = (struct match_data*)func_data;
	if(OPP_KEY_EQUALS(mdata,item->key)) {
		OPPUNREF(item);
	}
	return -1;
}

#define OPP_KEY_HASH(h,x) ({h->hfunc.aroop_cb(h->hfunc.aroop_closure_data,x);})
void*opp_hash_table_get(opp_hash_table_t*ht, void*key) {
	//unsigned long hash = aroop_txt_get_hash(key);
	unsigned long hash = OPP_KEY_HASH(ht,key);
	struct match_data mdata = {ht,key};
	opp_map_pointer_ext_t*item = (opp_map_pointer_ext_t*)opp_search(&ht->fac, hash, match_hash, &mdata, NULL);
	if(!item) {
		return NULL;
	}
	void*ret = item->ptr.obj_data; // Note: we did not ref it.
	OPPUNREF(item);
	return ret;
}

int opp_hash_table_set(opp_hash_table_t*ht, void*key, void*obj_data) {
	if(!obj_data) {
		opp_search(&ht->fac, OPP_KEY_HASH(ht,key), match_hash_and_delete, key, NULL);return 0;
	}
	opp_map_pointer_ext_t*item = (opp_map_pointer_ext_t*)opp_search(&ht->fac, OPP_KEY_HASH(ht,key), match_hash, key, NULL);
	if(item) {
		if(item->ptr.obj_data) {
			OPPUNREF(item->ptr.obj_data);
		}
		item->ptr.obj_data = OPPREF(obj_data);
		OPPUNREF(item);
	} else {
		item = (opp_map_pointer_ext_t*)opp_alloc4(&ht->fac, 0, 0, 0, key, obj_data);
		opp_set_hash(item, OPP_KEY_HASH(ht,key));
	}

	//SYNC_LOG(SYNC_VERB, "set hash table value: %s\n", item->obj_data);
	return 0;
}

int opp_hash_table_create_and_profile(opp_hash_table_t*ht, int pool_size, unsigned int flag, opp_hash_function_t hfunc, opp_equals_t efunc
		, char*source_file, int source_line, char*module_name) {
	ht->hfunc = hfunc;
	ht->efunc = efunc;
	return opp_factory_create_full_and_profile(&ht->fac, pool_size
			, sizeof(opp_map_pointer_ext_t)
			, 1, flag | OPPF_SWEEP_ON_UNREF | OPPF_EXTENDED | OPPF_SEARCHABLE
			, OPP_CB_FUNC(hash_table_item)
			, source_file, source_line, module_name);
}

C_CAPSULE_END
