/*
 * opp_hash_table.h
 *
 *  Created on: Jan 16, 2012
 *      Author: kamanashisroy
 */

#ifndef OPP_HASH_TABLE_H_
#define OPP_HASH_TABLE_H_


#include "opp/opp_factory.h"

C_CAPSULE_START

void*opp_hash_table_get(struct opp_factory*ht, aroop_txt*key);
int opp_hash_table_set(struct opp_factory*ht, aroop_txt*key, void*obj_data);
int opp_hash_table_create(struct opp_factory*ht, int pool_size, unsigned int flag);
C_CAPSULE_END



#endif /* OPP_HASH_TABLE_H_ */
