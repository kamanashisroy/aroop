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
 *  Created on: Dec 21, 2011
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_factory_profiler.h"
#include "aroop/opp/opp_io.h"
#include "aroop/core/xtring.h"
#endif

aroop_txt_t*DOT;
aroop_txt_t*BLANK_STRING;
aroop_txt_t*ASTERISKS_STRING;
opp_equals_t aroop_txt_equals_cb;
opp_hash_function_t aroop_txt_get_hash_cb;
static struct opp_factory txt_pool;
aroop_txt_t*aroop_txt_new_alloc(int len, struct opp_factory*gpool) {
	aroop_txt_t*str = (aroop_txt_t*)opp_alloc4(gpool?gpool:&txt_pool, sizeof(aroop_txt_t)+len+1, 0, 0, NULL);
	XULTB_ASSERT_RETURN(str, NULL);
	str->internal_flag = XTRING_IS_ARRAY;
	str->content.str[0] = '\0';
	str->len = 0;
	//str->size = len+1;
	str->hash = 0;
	return str;
}
aroop_txt_t*aroop_txt_new_set_content(char*content, int len, aroop_txt_t*proto, struct opp_factory*gpool) {
	if(content == NULL) return NULL;
	aroop_txt_t*str = (aroop_txt_t*)opp_alloc4(gpool?gpool:&txt_pool, 0, 0, 0, NULL);
	XULTB_ASSERT_RETURN(str, NULL);
	str->internal_flag = 0;
	str->len = len;
	str->size = len;
	str->content.pointer.str = content;
	str->hash = 0;
	str->content.pointer.proto = proto?OPPREF(proto):NULL;
	return str;
}

aroop_txt_t*aroop_txt_new_copy_content_deep(const char*content, int len,  struct opp_factory*gpool) {
	XULTB_ASSERT_RETURN(content && len, NULL);
	aroop_txt_t*str = (aroop_txt_t*)opp_alloc4(gpool?gpool:&txt_pool, sizeof(aroop_txt_t)+len+1-sizeof(struct aroop_txt_pointer), 0, 0, NULL);
	XULTB_ASSERT_RETURN(str, NULL);
	str->internal_flag = XTRING_IS_ARRAY;
	//str->size = len+1;
	str->len = len;
	if(len) {
		memcpy(str->content.str, content, len);
	}
	str->content.str[len] = '\0';
	str->hash = 0;
	return str;
}

#if false
aroop_txt_t*aroop_txtrim(aroop_txt_t*text) {
	// TODO trim
	text->hash = 0;
	return text;
}

aroop_txt_t*aroop_txt_cat(aroop_txt_t*text, aroop_txt_t*suffix) {
	// TODO check if we have enough space
	SYNC_ASSERT(text->size > (text->len + suffix->len));
	text->hash = 0;
	memcpy(text->str+text->len, suffix->str, suffix->len);
	text->len += suffix->len;
	*(text->str+text->len) = '\0';
	return text;
}

aroop_txt_t*aroop_txt_cat_char(aroop_txt_t*text, char c) {
	SYNC_ASSERT(text->size > (text->len + 1));
	text->hash = 0;
	*(text->str+text->len) = c;
	text->len++;
	*(text->str+text->len) = '\0';
	return text;
}

aroop_txt_t*aroop_txt_cat_static(aroop_txt_t*text, char*suffix) {
	int len = strlen(suffix);
	SYNC_ASSERT(text->size > (text->len + len));
	text->hash = 0;
	memcpy(text->str+text->len, suffix, len);
	text->len += len;
	*(text->str+text->len) = '\0';
	return text;
}

aroop_txt_t*aroop_txt_set_len(aroop_txt_t*text, int len) {
	SYNC_ASSERT(text->size > len);
	text->hash = 0;
	text->len = len;
	*(text->str+len) = '\0';
	return text;
}
#endif

#ifndef AROOP_BASIC
#include <printf.h>
static int print_etxt (FILE *stream,
                   const struct printf_info *info,
                   const void *const *args) {
	int len = 0;
	const aroop_txt_t *x = *((const aroop_txt_t **) (args[0]));
	/* Pad to the minimum field width and print to the stream. */
	len = fprintf (stream, "%s", aroop_txt_to_vala_string(x));
	return len;
}

int print_etxt_arginfo (const struct printf_info *info, size_t n,
                           int *argtypes)
{
	/* We always take exactly one argument and this is a pointer to the
	  structure.. */
	if (n > 0)
	 argtypes[0] = PA_POINTER;
	return 1;
}
int aroop_txt_printf_extra(aroop_txt_t*output, char* format, ...) {
	va_list arg;
	int done;

	va_start (arg, format);
	done = vsnprintf (aroop_txt_to_string(output), output->size, format, arg);
	va_end (arg);

	return done;
}
#endif

static int aroop_txt_equals_cb_impl(void*cb_data, const void*xarg, const void*otherarg) {
	const aroop_txt_t*x = xarg;
	const aroop_txt_t*other = otherarg;
	return aroop_txt_equals(x,other);
}

static opp_hash_t aroop_txt_get_hash_cb_impl(void*cb_data, const void*xarg) {
	aroop_txt_t*x = (aroop_txt_t*)xarg;
	return aroop_txt_get_hash(x);
}


OPP_CB_NOSTATIC(aroop_searchable_txt) {
	aroop_searchable_txt_t*stxt = (aroop_searchable_txt_t*)data;
	switch(callback) {
	//case OPPN_ACTION_INITIALIZE:
		//memset(stxt, 0, sizeof(struct opp_object_ext));
		//return 0;
	case OPPN_ACTION_FINALIZE:
		aroop_txt_destroy((&stxt->tdata));
		break;
	}
	return 0;
}

OPP_CB_NOSTATIC(aroop_txt) {
	aroop_txt_t*txt = (aroop_txt_t*)data;
	switch(callback) {
	case OPPN_ACTION_INITIALIZE:
		txt->content.str[0] = '\0';
		txt->size = size - sizeof(aroop_txt_t);
		txt->len = 0;
		return 0;
	case OPPN_ACTION_FINALIZE:
		aroop_txt_destroy(txt);
		break;
	case OPPN_ACTION_DESCRIBE:
		aroop_printf("%s\n", aroop_txt_to_vala_string(txt));
		break;
	}
	return 0;
}

void aroop_txt_system_init() {
	SYNC_ASSERT(!OPP_PFACTORY_CREATE(&txt_pool, 128, sizeof(aroop_txt_t)+32, OPP_CB_FUNC(aroop_txt)));
	BLANK_STRING = aroop_txt_new_set_content("", 0, NULL, 0);
	ASTERISKS_STRING = aroop_txt_new_set_content("***********************************************", 30, NULL, 0);
	DOT = aroop_txt_new_set_content(".", 1, NULL, 0);
	aroop_txt_equals_cb.aroop_closure_data = NULL;
	aroop_txt_equals_cb.aroop_cb = aroop_txt_equals_cb_impl;
	aroop_txt_get_hash_cb.aroop_closure_data = NULL;
	aroop_txt_get_hash_cb.aroop_cb = aroop_txt_get_hash_cb_impl;
#ifndef AROOP_BASIC
	register_printf_function ('T', print_etxt, print_etxt_arginfo);
#endif
}

void aroop_txt_system_deinit() {
	opp_factory_destroy(&txt_pool);
}
