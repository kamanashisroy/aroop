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
 *  Created on: Dec 27, 2010
 *      Author: kamanashisroy@gmail.com
 */

#ifndef OPP_HASH_H_
#define OPP_HASH_H_

#ifndef AROOP_CONCATENATED_FILE
#include "opp/opp_factory.h"
#endif

C_CAPSULE_START

opp_hash_t opp_get_hash(const char *z);
opp_hash_t opp_get_hash_bin(const void*data, int size);

#if 0
int hash_test();
#endif

C_CAPSULE_END

#endif /* OPP_HASH_H_ */
