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
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */

#ifndef AROOP_CONCATENATED_FILE
#include "opp/opp_factory.h"
#include "opp/opp_salt.h"
#endif


#if 0
static int opp_search_helper(const void*data, const void*compare_data) {
	va_list ap = *(va_list*)compare_data;
	va_list ap2;
	__va_copy(ap2, ap);
	struct opp_object*obj = (data - sizeof(struct opp_object));
	struct opp_factory*obuff = obj->obuff;
	void*result[] = va_arg(ap2, void*[]);
	int resultlen = va_arg(ap2, int);
	int index = *(int*)result[0];
	if(index >= resultlen) {
		return -1;
	}
	if(obuff->callback(data, OPPN_ACTION_SEARCH1, NULL, ap2) == 0) {
		resultlen[index] = OPPREF(data);
		*(int*)result[0] = index+1;
	}
	va_end(ap2);
	return -1;
}

int opp_search_multi(struct opp_factory*obuff
		, opp_hash_t hash
		, void*result[], int resultlen
		, ...) {
	va_list ap;
	va_start(ap, obuff);
	opp_search(obuff
				, hash, opp_search_helper, &ap);
	va_end(ap);
}
#endif

