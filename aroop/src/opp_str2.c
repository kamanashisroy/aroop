/*
 * obj_str2.c
 *
 *  Created on: Feb 9, 2011
 *      Author: Kamanashis Roy
 */

#include "opp/opp_factory.h"
#include "opp/opp_str2.h"

#ifdef __cplusplus
extern "C" {
#endif

enum {
#ifdef SYNC_LOW_MEMORY
	OPP_STR2_BUFFER_INC = 32
#else
	OPP_STR2_BUFFER_INC = 1024
#endif
};


static struct opp_factory str2_factory;
char*opp_str2_alloc(int size) {
	return (char*)opp_alloc4(&str2_factory, size, 0, NULL);
}

char*opp_str2_reuse(char*string) {
	char *ret = NULL;
	int len;

	if(!string || !string[0]) {
		return NULL;
	}

	// try to find the string
	if(opp_exists(&str2_factory, string)) {
		OPPREF(string);
		return string;
	}

	len = strlen(string);
	ret = (char*)opp_alloc4(&str2_factory, len+1, 0, NULL);

	if(!ret) {
		return NULL;
	}

	memcpy(ret, string, len);
	ret[len] = '\0';
	return ret;
}

void opp_str2_reuse2(char**dest, char*string) {
	int len;

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
	len = strlen(string);
	*dest = (char*)opp_alloc4(&str2_factory, len+1, 0, NULL);

	memcpy(*dest, string, len);
	*(*dest + len) = '\0';
}


char*opp_str2_dup(const char*string) {
	char *ret = NULL;
	int len;

	if(!string || !string[0]) {
		return NULL;
	}
	len = strlen(string);
	ret = (char*)opp_alloc4(&str2_factory, len+1, 0, NULL);

	if(!ret) {
		return NULL;
	}

	memcpy(ret, string, len);
	ret[len] = '\0';
	return ret;
}

void opp_str2_dup2(char**dest, const char*string) {
	int len;

	OPPUNREF(*dest);
	*dest = NULL;

	if(!string || !string[0]) {
		return;
	}
	len = strlen(string);
	*dest = (char*)opp_alloc4(&str2_factory, len+1, 0, NULL);

	memcpy(*dest, string, len);
	*(*dest + len) = '\0';
}

static int opp_str2_verb_helper(const void*data, const void*func_data) {
	// do nothing
	return 0;
}
void opp_str2system_verb(void (*log)(void *log_data, const char*fmt, ...), void*log_data) {
	opp_factory_verb(&str2_factory, opp_str2_verb_helper, NULL, log, log_data);
}

#ifdef OPP_ALLOW_UNSAFE_MULTIPLE_INIT
static int initialized = 0;
#endif
void opp_str2system_init() {
#ifdef OPP_ALLOW_UNSAFE_MULTIPLE_INIT
	// XXX this is not thread safe
	if(!initialized) {
#endif
		OPP_FACTORY_CREATE(&str2_factory, OPP_STR2_BUFFER_INC, 32, NULL);
#ifdef OPP_ALLOW_UNSAFE_MULTIPLE_INIT
		initialized = 1;
	}
#endif
}

void opp_str2system_deinit() {
	opp_factory_destroy(&str2_factory);
#ifdef OPP_ALLOW_UNSAFE_MULTIPLE_INIT
	initialized = 0;
#endif
}

#ifdef __cplusplus
}
#endif
