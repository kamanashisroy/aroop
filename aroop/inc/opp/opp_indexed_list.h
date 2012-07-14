/*
 * opp_indexed_list.h
 *
 *  Created on: Aug 21, 2011
 *      Author: Kamanashis Roy
 */

#ifndef OPP_INDEXED_LIST_H
#define OPP_INDEXED_LIST_H

#include "opp/opp_factory.h"

C_CAPSULE_START

void*opp_indexed_list_get(struct opp_factory*olist, int index);
int opp_indexed_list_set(struct opp_factory*olist, int index, void*obj_data);
int opp_indexed_list_create2(struct opp_factory*olist, int pool_size);
C_CAPSULE_END

#endif
