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
#include "opp/opp_factory.h"
#include "opp/opp_io.h"
#include "core/txt.h"
#endif

aroop_txt_t*DOT;
aroop_txt_t*BLANK_STRING;
aroop_txt_t*ASTERISKS_STRING;
static struct opp_factory txt_pool;
aroop_txt_t*aroop_txt_new(char*content, int len, aroop_txt_t*proto, int scalability_index) {
	if(content) {
		aroop_txt_t*str = (aroop_txt_t*)opp_alloc4(&txt_pool, 0, 0, NULL);
		XULTB_ASSERT_RETURN(str, NULL);
		str->size = str->len = len;
		str->str = content;
		str->hash = 0;
		str->proto = proto?OPPREF(proto):NULL;
		return str;
	} else {
		aroop_txt_t*str = (aroop_txt_t*)opp_alloc4(&txt_pool, sizeof(aroop_txt_t)+len+1, 0, NULL);
		XULTB_ASSERT_RETURN(str, NULL);
		str->str = (char*)(str+1);
		*str->str = '\0';
		str->len = 0;
		str->size = len+1;
		str->hash = 0;
		str->proto = NULL;
		return str;
	}
}

aroop_txt_t*aroop_txt_clone(const char*content, int len, int scalability_index) {
	XULTB_ASSERT_RETURN(content && len, NULL);
	aroop_txt_t*str = (aroop_txt_t*)opp_alloc4(&txt_pool, sizeof(aroop_txt_t)+len+1, 0, NULL);
	str->hash = 0;
	XULTB_ASSERT_RETURN(str, NULL);
	str->size = len+1;
	str->len = len;
	str->str = (char*)(str+1);
	if(len) {
		memcpy(str->str, content, len);
	}
	*(str->str+len) = '\0';
	str->hash = 0;
	str->proto = NULL;
	return str;
}

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

#include <printf.h>
static int print_etxt (FILE *stream,
                   const struct printf_info *info,
                   const void *const *args) {
	int len = 0;
	const aroop_txt_t *x = *((const aroop_txt_t **) (args[0]));
	/* Pad to the minimum field width and print to the stream. */
	len = fprintf (stream, "%s", x->str);
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
	done = vsnprintf (output->str, output->size, format, arg);
	va_end (arg);

	return done;
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
		return 0;
	case OPPN_ACTION_FINALIZE:
		OPPUNREF(txt->proto);
		break;
	case OPPN_ACTION_DESCRIBE:
		if(txt->str && txt->len != 0) {
			printf("%s\n", txt->str);
		}
		break;
	}
	return 0;
}

void aroop_txt_system_init() {
	SYNC_ASSERT(!OPP_FACTORY_CREATE(&txt_pool, 128, sizeof(aroop_txt_t)+32, OPP_CB_FUNC(aroop_txt)));
	BLANK_STRING = aroop_txt_new("", 0, NULL, 0);
	ASTERISKS_STRING = aroop_txt_new("***********************************************", 30, NULL, 0);
	DOT = aroop_txt_new(".", 1, NULL, 0);
#ifndef AROOP_BASIC
	register_printf_function ('T', print_etxt, print_etxt_arginfo);
#endif
}

void aroop_txt_system_deinit() {
	opp_factory_destroy(&txt_pool);
}
