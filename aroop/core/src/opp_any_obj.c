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
 *  Created on: Jun 17, 2011
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */


#ifndef AROOP_CONCATENATED_FILE
#include "core/config.h"
#include "opp/opp_any_obj.h"
#include "opp/opp_factory.h"
#include "opp/opp_type.h"
#include "opp/opp_io.h"
#endif

C_CAPSULE_START

//opp_vtable_declare(any_obj,);
//opp_class_declare(any_obj,);
struct any_obj {
	opp_callback_t cb;
};

static struct opp_factory tiny_objs,gig_objs;
void*opp_any_obj_alloc(int size, opp_callback_t cb, void*arg, ...) {
	void*obj = opp_alloc4((size < 128)?&tiny_objs:&gig_objs, size+sizeof(struct any_obj), 0, (void*)cb);
	va_list ap;
	va_start(ap, arg);
	cb(obj, OPPN_ACTION_INITIALIZE, arg, ap, size);
	va_end(ap);
	return obj;
}

OPP_CB(any_obj) {
	void*obj = data;
	switch(callback) {
	case OPPN_ACTION_INITIALIZE:
	{
		struct any_obj*cb = (struct any_obj*)pointer_arith_add_byte(data,size);
		cb--;
		cb->cb = (opp_callback_t)cb_data;
//		obj->vtable->oppcb = cb_data;
		break;
	}
	case OPPN_ACTION_FINALIZE:
	{
		struct any_obj*cb = (struct any_obj*)pointer_arith_add_byte(data,size);
		cb--;
		return cb->cb(obj, OPPN_ACTION_FINALIZE, NULL, ap, size - sizeof(struct any_obj));
	}
	case OPPN_ACTION_DESCRIBE:
	{
		struct any_obj*cb = (struct any_obj*)pointer_arith_add_byte(data,size);
		cb--;
		return cb->cb(obj, OPPN_ACTION_DESCRIBE, NULL, ap, size - sizeof(struct any_obj));
	}
	}
	return 0;
}

void opp_any_obj_system_init() {
	SYNC_ASSERT(!OPP_FACTORY_CREATE(
		&tiny_objs
		, 32,16
		, OPP_CB_FUNC(any_obj))
	);
	SYNC_ASSERT(!OPP_FACTORY_CREATE(
		&gig_objs
		, 64,8
		, OPP_CB_FUNC(any_obj))
	);
}

void opp_any_obj_system_deinit() {
	opp_factory_destroy(&tiny_objs);
	opp_factory_destroy(&gig_objs);
}


C_CAPSULE_END
