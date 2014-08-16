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
#include "aroop/core/config.h"
#include "aroop/opp/opp_any_obj.h"
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_factory_profiler.h"
#include "aroop/opp/opp_type.h"
#include "aroop/opp/opp_io.h"
#ifdef AROOP_OPP_DEBUG
#include "aroop/core/xtring.h"
#endif
#endif

C_CAPSULE_START

//opp_vtable_declare(any_obj,);
//opp_class_declare(any_obj,);
struct any_obj {
	opp_callback_t cb;
#ifdef AROOP_OPP_DEBUG
	SYNC_UWORD8_T signature;
#endif
};

static struct opp_factory deca_objs,hecto_objs,kilo_objs;
#define SELECT_ANY_OBJ(x) ((x) > 1024 ? &kilo_objs : ((x) > 128 ? &hecto_objs : &deca_objs))
void*opp_any_obj_alloc(int size, opp_callback_t cb, void*arg, ...) {
	void*obj = opp_alloc4(SELECT_ANY_OBJ(size), size+sizeof(struct any_obj), 0, 0, (void*)cb);
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
#ifdef AROOP_OPP_DEBUG
		cb->signature = 123;
		aroop_txt_t obj_module_name;
		aroop_memclean_raw2(&obj_module_name);
		opp_callback(data, OPPN_ACTION_GET_SOURCE_MODULE, &obj_module_name);
		printf("Any object:%s\n", obj_module_name.str);
		aroop_txt_destroy(&obj_module_name);
#endif
//		obj->vtable->oppcb = cb_data;
		break;
	}
	default:
	{
		struct any_obj*cb = (struct any_obj*)pointer_arith_add_byte(data,size);
		cb--;
#ifdef AROOP_OPP_DEBUG
		assert(cb->signature == 123);
#endif
		return cb->cb(obj, callback, cb_data, ap, size - sizeof(struct any_obj));
	}
	}
	return 0;
}
#ifdef AROOP_OPP_DEBUG
#include "core/xtring.h"
static int opp_any_obj_assert_no_module_helper(void*func_data, void*content) {
	char*module_name = (char*)func_data;
	aroop_txt_t obj_module_name;
	aroop_memclean_raw2(&obj_module_name);
	
	//OPP_CB_FUNC(any_obj)(content, OPPN_ACTION_GET_SOURCE_MODULE, &obj_module_name, va, 0);
	opp_callback(content, OPPN_ACTION_GET_SOURCE_MODULE, &obj_module_name);
	printf("%s,%s\n", module_name, obj_module_name.str);
	assert(!(!aroop_txt_is_empty_magical(&obj_module_name) && module_name != NULL && aroop_txt_equals_chararray(&obj_module_name, module_name)));
	aroop_txt_destroy(&obj_module_name);
	return 0;
}
void opp_any_obj_assert_no_module(char*module_name) {
	opp_factory_do_full(&deca_objs, opp_any_obj_assert_no_module_helper, module_name, OPPN_ALL, 0, 0);
	opp_factory_do_full(&hecto_objs, opp_any_obj_assert_no_module_helper, module_name, OPPN_ALL, 0, 0);
	opp_factory_do_full(&kilo_objs, opp_any_obj_assert_no_module_helper, module_name, OPPN_ALL, 0, 0);
}
#endif

void opp_any_obj_gc_unsafe() {
	opp_factory_gc_donot_use(&deca_objs);
	opp_factory_gc_donot_use(&hecto_objs);
	opp_factory_gc_donot_use(&kilo_objs);
}

void opp_any_obj_system_init() {
	SYNC_ASSERT(!OPP_PFACTORY_CREATE(
		&deca_objs
		, 64,32
		, OPP_CB_FUNC(any_obj))
	);
	SYNC_ASSERT(!OPP_PFACTORY_CREATE(
		&hecto_objs
		, 32,128
		, OPP_CB_FUNC(any_obj))
	);
	SYNC_ASSERT(!OPP_PFACTORY_CREATE(
		&kilo_objs
		, 8,1024
		, OPP_CB_FUNC(any_obj))
	);
}

void opp_any_obj_system_deinit() {
	opp_factory_destroy(&deca_objs);
	opp_factory_destroy(&hecto_objs);
	opp_factory_destroy(&kilo_objs);
}


C_CAPSULE_END

