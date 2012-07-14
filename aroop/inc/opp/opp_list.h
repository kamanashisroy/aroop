/*
 * opp_list.h
 *
 *  Created on: Feb 9, 2011
 *      Author: Kamanashis Roy
 */

#ifndef OPP_LIST_H
#define OPP_LIST_H
#include "core/config.h"
#include "opp/opp_factory.h"

C_CAPSULE_START

struct opp_list_item {
	struct opp_object_ext _ext; // To access this try flag OBJ_FACTORY_EXTENDED
	void*obj_data;
};

struct opp_list_item*opp_list_add_noref(struct opp_factory*olist, void*obj_data);
#define OPP_LIST_CREATE(olist, x) ({opp_list_create2(olist, x, OPPF_HAS_LOCK | OPPF_SWEEP_ON_UNREF);})
#define OPP_LIST_CREATE_NOLOCK(olist, x) ({opp_list_create2(olist, x, OPPF_SWEEP_ON_UNREF);})
#define OPP_LIST_CREATE_NOLOCK_EXT(olist, x) ({opp_list_create2(olist, x, OPPF_SWEEP_ON_UNREF | OPPF_EXTENDED);})
int opp_list_prune(struct opp_factory*olist, void*target, int if_flag, int if_not_flag, int hash);
int opp_list_create2(struct opp_factory*olist, int pool_size, unsigned int flag);
int opp_list_find_from_factory(struct opp_factory*obuff, struct opp_factory*olist, int (*compare_func)(const void*data, const void*compare_data), const void*compare_data);

C_CAPSULE_END

#endif /* OPP_LIST_H */
