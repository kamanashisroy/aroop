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
 *  Created on: Dec 13, 2011
 *      Author: kamanashis Roy
 */

#ifndef OPP_TYPE_H_
#define OPP_TYPE_H_

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/config.h"
#endif

C_CAPSULE_START


#if 0
#define opp_convert(x,ytype,zvalue) ({opp_callback2(x, OPPN_ACTION_CONVERT, ytype, &zvalue);})
#define opp_typeof(x,ytype) ({opp_callback(x, OPPN_ACTION_TYPEOF, ytype);})
#endif

#define opp_class_declare(name,table) struct name {table struct opp_vtable_##name*vtable;}

#define opp_class_declare_novtable(name,table) struct name {table}

#define opp_vtable_declare(name,table) struct name;struct opp_vtable_##name {int (*oppcb)(void*data, int callback, void*cb_data, va_list ap, int size); table}

#define opp_vtable_define(name,defaultvalue) struct opp_vtable_##name vtable_##name = {defaultvalue};

#define opp_vtable_extern(name) extern struct opp_vtable_##name vtable_##name;

#define opp_vtable_set(var,name) (var)->vtable = &vtable_##name

#define opp_class_define(name,x) struct opp_class_##name c_##name = {.callback = x};

#define opp_class_extend(x) x super_data;
#define opp_extvt(x) (x)->super_data.vtable

#define opp_super_cb(supertype) vtable_##supertype.oppcb

#define ANDMORE(x) ,x

C_CAPSULE_END

#endif /* OPP_TYPE_H_ */
