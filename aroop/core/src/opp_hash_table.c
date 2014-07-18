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
#include "core/txt.h"
#include "opp/opp_factory.h"
#include "opp/opp_factory_profiler.h"
#include "opp/opp_iterator.h"
#include "opp/opp_hash_table.h"
#include "opp/opp_hash.h"
#include "core/logger.h"
#endif

C_CAPSULE_START

struct opp_hash_table_item {
	struct opp_object_ext _ext;
	aroop_txt_t*key;
	void*obj_data;
};

OPP_CB(hash_table_item) {
	struct opp_hash_table_item*item = (struct opp_hash_table_item*)data;

	switch(callback) {
	case OPPN_ACTION_INITIALIZE:
		item->key = (aroop_txt_t*)cb_data;
		OPPREF(item->key);
		item->obj_data = va_arg(ap, void*);
		OPPREF(item->obj_data);
		break;
	case OPPN_ACTION_FINALIZE:
		OPPUNREF(item->key);
		OPPUNREF(item->obj_data);
		break;
	}


	return 0;
}

static int match_hash(const void*func_data, const void*data) {
	const struct opp_hash_table_item*item = (const struct opp_hash_table_item*)data;
	const aroop_txt_t*key = (const aroop_txt_t*)func_data;
	if(key->len == item->key->len && !memcmp(key->str, item->key->str, key->len)) {
		return 0;
	}
	return -1;
}

static int match_hash_and_delete(const void*func_data, const void*data) {
	const struct opp_hash_table_item*item = (const struct opp_hash_table_item*)data;
	const aroop_txt_t*key = (const aroop_txt_t*)func_data;
	if(key->len == item->key->len && !memcmp(key->str, item->key->str, key->len)) {
		OPPUNREF(item);
	}
	return -1;
}

void*opp_hash_table_get(struct opp_factory*ht, aroop_txt_t*key) {
	unsigned long hash = aroop_txt_get_hash(key);
	struct opp_hash_table_item*item = (struct opp_hash_table_item*)opp_search(ht, hash, match_hash, key, NULL);
	if(!item) {
		return NULL;
	}
	void*ret = item->obj_data;
	OPPUNREF(item);
	return ret;
}

int opp_hash_table_set(struct opp_factory*ht, aroop_txt_t*key, void*obj_data) {
	if(!obj_data) {
		opp_search(ht, aroop_txt_get_hash(key), match_hash_and_delete, key, NULL);return 0;
	}
	struct opp_hash_table_item*item = (struct opp_hash_table_item*)opp_search(ht, aroop_txt_get_hash(key), match_hash, key, NULL);
	if(item) {
		if(item->obj_data) {
			OPPUNREF(item->obj_data);
		}
		item->obj_data = OPPREF(obj_data);
		OPPUNREF(item);
	} else {
		item = (struct opp_hash_table_item*)opp_alloc4(ht, 0, 0, 0, key, obj_data);
		opp_set_hash(item, aroop_txt_get_hash(key));
	}

	//SYNC_LOG(SYNC_VERB, "set hash table value: %s\n", item->obj_data);
	return 0;
}

int opp_hash_table_create_and_profile(struct opp_factory*ht, int pool_size, unsigned int flag
		, char*source_file, int source_line, char*module_name) {
	return opp_factory_create_full_and_profile(ht, pool_size
			, sizeof(struct opp_hash_table_item)
			, 1, flag | OPPF_SWEEP_ON_UNREF | OPPF_EXTENDED | OPPF_SEARCHABLE
			, OPP_CB_FUNC(hash_table_item)
			, source_file, source_line, module_name);
}

C_CAPSULE_END
