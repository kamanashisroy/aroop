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
