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

#include "opp/opp_factory.h"
#include "opp/opp_indexed_list.h"
#include "opp/opp_iterator.h"
#include "opp/opp_list.h"

C_CAPSULE_START

OPP_CB(list_item) {
	struct opp_list_item*item = (struct opp_list_item*)data;
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

void*opp_indexed_list_get(struct opp_factory*olist, int index) {
	struct opp_list_item*holder = (struct opp_list_item*)opp_search(olist, index, NULL, NULL, NULL);
	void*ret = NULL;
	if(holder) {
		ret = holder->obj_data;
		if(ret) {
			OPPREF(ret);
		}
		OPPUNREF(holder);
	}
	return ret;
}

int opp_indexed_list_set(struct opp_factory*olist, int index, void*obj_data) {
	int ret = 0;
	opp_factory_lock_donot_use(olist);
	struct opp_list_item*holder = (struct opp_list_item*)opp_search(olist, index, NULL, NULL, NULL);
	if(holder) {
		opp_set_flag(holder, OPPN_ZOMBIE);
		void*tmp = holder;
		OPPUNREF(holder);
		OPPUNREF(tmp);
	}
	if(obj_data) {
		struct opp_list_item*item = (struct opp_list_item*)OPP_ALLOC2(olist, obj_data);
		if(!item) {
			ret = -1;
		} else {
			opp_set_hash(item, index);
		}
	}
	opp_factory_unlock_donot_use(olist);
	return ret;
}

int opp_indexed_list_create2(struct opp_factory*olist, int pool_size) {
	return opp_factory_create_full(olist, pool_size
			, sizeof(struct opp_list_item)
			, 1, OPPF_SEARCHABLE | OPPF_EXTENDED | OPPF_SWEEP_ON_UNREF
			, OPP_CB_FUNC(list_item));
}

C_CAPSULE_END
