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
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_factory_profiler.h"
#include "aroop/opp/opp_str2.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

enum {
#ifdef AROOP_LOW_MEMORY
	OPP_STR2_BUFFER_INC = 32
#else
	OPP_STR2_BUFFER_INC = 1024
#endif
};


static struct opp_factory str2_factory;
char*opp_str2_alloc(int size) {
	return (char*)opp_alloc4(&str2_factory, size, 0, 0, NULL);
}

void opp_str2_alloc2(char**dest, int size) {
	OPPUNREF(*dest);
	*dest = NULL;
	*dest = opp_alloc4(&str2_factory, size, 0, 0, NULL);
}
char*opp_str2_reuse(char*string, int len) {
	char *ret = NULL;

	if(!string || !string[0]) {
		return NULL;
	}

	// try to find the string
	if(opp_exists(&str2_factory, string)) {
		OPPREF(string);
		return string;
	}

	ret = (char*)opp_alloc4(&str2_factory, len+1, 0, 0, NULL);

	if(!ret) {
		return NULL;
	}

	memcpy(ret, string, len);
	ret[len] = '\0';
	return ret;
}

void opp_str2_reuse2(char**dest, char*string, int len) {

	OPPUNREF(*dest);
	*dest = NULL;

	if(!string || !string[0]) {
		return;
	}
	// try to find the string
	if(opp_exists(&str2_factory, string)) {
		OPPREF(string);
		*dest = string;
		return;
	}
	*dest = (char*)opp_alloc4(&str2_factory, len+1, 0, 0, NULL);

	memcpy(*dest, string, len);
	*(*dest + len) = '\0';
}


char*opp_str2_dup(const char*string, int len) {
	char *ret = NULL;

	if(!string || !string[0]) {
		return NULL;
	}
	ret = (char*)opp_alloc4(&str2_factory, len+1, 0, 0, NULL);

	if(!ret) {
		return NULL;
	}

	memcpy(ret, string, len);
	ret[len] = '\0';
	return ret;
}

void opp_str2_dup2(char**dest, const char*string, int len) {

	OPPUNREF(*dest);
	*dest = NULL;

	if(!string || !string[0]) {
		return;
	}
	*dest = (char*)opp_alloc4(&str2_factory, len+1, 0, 0, NULL);

	memcpy(*dest, string, len);
	*(*dest + len) = '\0';
}

void opp_str2system_traverse(void*cb, void*cb_data) {
	opp_factory_do_full(&str2_factory, cb, cb_data, OPPN_ALL, 0, 0);
}
#ifdef OPP_ALLOW_UNSAFE_MULTIPLE_INIT
static int initialized = 0; // TODO make it volatile
#endif
void opp_str2system_init() {
#ifdef OPP_ALLOW_UNSAFE_MULTIPLE_INIT
	// XXX this is not thread safe
	if(!initialized) {
#endif
		OPP_PFACTORY_CREATE(&str2_factory, OPP_STR2_BUFFER_INC, 32, NULL);
#ifdef OPP_ALLOW_UNSAFE_MULTIPLE_INIT
		initialized = 1; // TODO make it atomic
	}
#endif
}

void opp_str2system_deinit() {
	OPP_PFACTORY_DESTROY(&str2_factory);
#ifdef OPP_ALLOW_UNSAFE_MULTIPLE_INIT
	initialized = 0; // TODO make it atomic
#endif
}

#ifdef __cplusplus
}
#endif
