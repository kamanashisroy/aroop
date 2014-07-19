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
 *      Author: Kamanashis Roy
 */

#ifndef OPP_LIST_H
#define OPP_LIST_H
#ifndef AROOP_CONCATENATED_FILE
#include "core/config.h"
#include "opp/opp_factory.h"
#endif

C_CAPSULE_START

typedef struct {
	struct opp_object_ext _ext; // To access this try flag OBJ_FACTORY_EXTENDED
	void*obj_data;
} opp_pointer_ext_t;

opp_pointer_ext_t*opp_list_add_noref(struct opp_factory*olist, void*obj_data);
#define OPP_LIST_CREATE(olist, x) ({opp_list_create2_and_profile(olist, x, OPPF_HAS_LOCK | OPPF_SWEEP_ON_UNREF, __FILE__, __LINE__, "aroop");})
#define OPP_LIST_CREATE_NOLOCK(olist, x) ({opp_list_create2_and_profile(olist, x, OPPF_SWEEP_ON_UNREF, __FILE__, __LINE__, "aroop");})
#define OPP_LIST_CREATE_NOLOCK_EXT(olist, x) ({opp_list_create2_and_profile(olist, x, OPPF_SWEEP_ON_UNREF | OPPF_EXTENDED, __FILE__, __LINE__, "aroop");})
int opp_list_prune(struct opp_factory*olist, void*target, int if_flag, int if_not_flag, int hash);
#define OPP_PLIST_CREATE_FULL(olist, _psize, _prop) ({opp_list_create2_and_profile(olist, _psize, _prop, __FILE__, __LINE__, "aroop");})
int opp_list_create2_and_profile(struct opp_factory*olist, int pool_size, opp_property_t property, char*source_file, int source_line, char*module_name);
int opp_list_find_from_factory(struct opp_factory*obuff, struct opp_factory*olist, int (*compare_func)(const void*data, const void*compare_data), const void*compare_data);
int opp_list_search_and_prune(struct opp_factory*obuff, opp_hash_t hash, const void*target);
int aroop_factory_prune_marked_pointer(struct opp_factory*olist, int flag);

C_CAPSULE_END

#endif /* OPP_LIST_H */
