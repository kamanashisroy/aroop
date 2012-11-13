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
 *      Author: Kamanashis Roy
 */

#ifndef XULTB_STRING_H_
#define XULTB_STRING_H_

#include "core/config.h"

C_CAPSULE_START

// TODO build an immutable txt ..
struct aroop_txt {
	struct aroop_txt*proto;
	int hash;
	int size;
	int len;
	char*str;
};

typedef struct aroop_txt aroop_txt;
typedef int xultb_bool_t;

#define aroop_txt_embeded(x,y) ({(x)->str = y,(x)->hash = 0,(x)->len = strlen(y);(x)->size=(x)->len+1;})
#define aroop_txt_embeded_static(x,y) ({(x)->str = y,(x)->hash = 0,(x)->len = sizeof(y) - 1;(x)->size=(x)->len+1;})

#if false
aroop_txt*xultb_subtxt(aroop_txt*src, int off, int width, aroop_txt*dest);
#endif
#define xultb_subtxt(src,off,width,dest) ({(dest)->str = (src)->str+off;(dest)->len = width;(dest)->hash=0;dest;})

#define aroop_txtcmp(x,y) ({int min = x->len>y->len?y->len:x->len;memcmp(x->str, y->str, min);})
#define aroop_txt_equals(x,y) ({(x && y && x->len == y->len && !memcmp(x->str, y->str, x->len));})
#define aroop_txt_iequals(x,y) ({(x && y && x->len == y->len && !strncasecmp(x->str, y->str, x->len));})

#define aroop_txt_equals_static(x,static_y) ({char static_text[] = static_y;(x && x->len == (sizeof(static_text)-1) && !memcmp(x->str, static_text,x->len));})


aroop_txt*aroop_txt_new(char*content, int len, aroop_txt*proto, int scalability_index);
#define aroop_txt_new_static(x) ({aroop_txt_new(x,sizeof(x)-1, NULL, 0);})
aroop_txt*aroop_txt_clone(const char*content, int len, int scalability_index);
aroop_txt*aroop_txtrim(aroop_txt*text);

aroop_txt*aroop_txt_cat(aroop_txt*text, aroop_txt*suffix);
aroop_txt*aroop_txt_cat_char(aroop_txt*text, char c);
aroop_txt*aroop_txt_cat_static(aroop_txt*text, char*suffix);
aroop_txt*aroop_txt_set_len(aroop_txt*text, int len);
#define aroop_txt_indexof_char(haystack, niddle) ({const char*haystack##pos = strchr(haystack->str, niddle);int haystack##i = -1;if(haystack##pos && haystack##pos < (haystack->str+haystack->len))haystack##i = haystack##pos-haystack->str;haystack##i;})
#define aroop_txt_length(x) ({(x)->len;})
#define aroop_txt_get_hash(x) ({((x)->hash != 0)?hash:(hash = opp_get_hash_bin((x)->str, (x)->len));})
#define aroop_txt_to_vala(x) ({((x)&&(x)->str)?(x)->str:"(null)"})
#define aroop_txt_to_vala_magical(x) ({((x)&&(x)->str&&(x)->len!=0)?(x)->str:"(null)"})
#define aroop_txt_is_empty(x) ({(!((x)->str) || ((x)->len == 0))})
#define aroop_txt_is_empty_magical(x) ({(!(x) || !((x)->str) || ((x)->len == 0))})
#define aroop_txt_string_or(x,y) ({(x->str&&x->len!=0)?x:y;})
#define aroop_txt_string_or_magical(x,y) ({((x)&&(x)->str&&(x)->len!=0)?x:y;})
#define aroop_txt_destroy(x) ({if((x)->proto)OPPUNREF((x)->proto);})

void aroop_txt_system_init();
void aroop_txt_system_deinit();

C_CAPSULE_END

#endif /* XULTB_STRING_H_ */
