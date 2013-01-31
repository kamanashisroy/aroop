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

#include "core/txt.h"
#include "opp/opp_factory.h"
#include "opp/opp_iterator.h"
#include "opp/opp_hash_table.h"
#include "opp/opp_hash.h"
#include "core/logger.h"

C_CAPSULE_START

struct opp_hash_table_item {
	struct opp_object_ext _ext;
	aroop_txt*key;
	void*obj_data;
};

OPP_CB(hash_table_item) {
	struct opp_hash_table_item*item = (struct opp_hash_table_item*)data;

	switch(callback) {
	case OPPN_ACTION_INITIALIZE:
		item->key = (void*)cb_data;
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
	const struct opp_hash_table_item*item = data;
	const aroop_txt*key = func_data;
	if(key->len == item->key->len && !memcmp(key->str, item->key->str, key->len)) {
		return 0;
	}
	return -1;
}

void*opp_hash_table_get(struct opp_factory*ht, aroop_txt*key) {
	unsigned long hash = opp_get_hash_bin(key->str, key->len);
	struct opp_hash_table_item*item = opp_search(ht, hash, match_hash, key);
	if(!item) {
		return NULL;
	}
	void*ret = item->obj_data;
	OPPUNREF(item);
	return ret;
}

int opp_hash_table_set(struct opp_factory*ht, aroop_txt*key, void*obj_data) {
	struct opp_hash_table_item*item = opp_search(ht, opp_get_hash_bin(key->str, key->len), match_hash, key);
	if(item) {
		if(item->obj_data) {
			OPPUNREF(item->obj_data);
		}
		item->obj_data = OPPREF(obj_data);
		OPPUNREF(item);
	} else {
		item = opp_alloc4(ht, 0, 0, key, obj_data);
		opp_set_hash(item, opp_get_hash_bin(item->key->str, item->key->len));
	}

	//SYNC_LOG(SYNC_VERB, "set hash table value: %s\n", item->obj_data);
	return 0;
}

int opp_hash_table_create(struct opp_factory*ht, int pool_size, unsigned int flag) {
	return opp_factory_create_full(ht, pool_size
			, sizeof(struct opp_hash_table_item)
			, 1, flag | OPPF_SWEEP_ON_UNREF | OPPF_EXTENDED | OPPF_SEARCHABLE
			, OPP_CB_FUNC(hash_table_item));
}

C_CAPSULE_END
