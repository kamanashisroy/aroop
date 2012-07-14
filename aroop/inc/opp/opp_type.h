/*
 * opp_type.h
 *
 *  Created on: Dec 13, 2011
 *      Author: ayaskanti
 */

#ifndef OPP_TYPE_H_
#define OPP_TYPE_H_

#include "core/config.h"

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
