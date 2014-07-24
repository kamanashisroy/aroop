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

#ifndef AROOP_CONCATENATED_FILE
#include "core/config.h"
#include "aroop_core.h"
#include "opp/opp_hash.h"
#include "opp/opp_hash_table.h"
#endif

// TODO remove dead code

C_CAPSULE_START

// TODO build an immutable txt ..
struct aroop_txt {
	aroop_none*proto;
	opp_hash_t hash;
	int size;
	int len;
	char*str;
} typedef aroop_txt_t;

struct aroop_searchable_txt {
	struct opp_object_ext aroop_internal_ext;
	struct aroop_txt tdata;
} typedef aroop_searchable_txt_t;

typedef int xultb_bool_t;

#define aroop_searchable_string_rehash(y) ({opp_set_hash(y, aroop_txt_get_hash(&(y)->tdata));})
#define aroop_txt_to_embeded_pointer(x) (x)

#define aroop_txt_embeded_set_content(x,y,z,p) ({ \
	(x)->proto = NULL, \
	(x)->str = y, \
	(x)->hash = 0, \
	(x)->len = z; \
	(x)->size=(x)->len+1; \
})
#define aroop_txt_embeded_rebuild_and_set_content(x,y,z,p) ({aroop_txt_destroy(x);aroop_txt_embeded_set_content(x,y,z,p);})
#define aroop_txt_embeded(x,y,p) ({(x)->proto = NULL,(x)->str = (y),(x)->hash = 0,(x)->len = strlen(y);(x)->size=(x)->len+1;})
#define aroop_txt_embeded_copy_on_demand_helper(x,y) ({ \
	if((y)->proto) { \
		(x)->proto = OPPREF((y)->proto); \
		(x)->str = (y)->str; \
	} else { \
		opp_str2_reuse2(&(x)->str, (y)->str); \
		(x)->proto = (x)->str; \
	} \
	(x)->hash = (y)->hash; \
	(x)->len = (y)->len; \
	(x)->size=(x)->len+1; \
})

#define aroop_txt_embeded_copy_on_demand(x,y) ({ \
	aroop_memclean_raw2(x); \
	aroop_txt_embeded_copy_on_demand_helper(x,y); \
})
#define aroop_txt_embeded_rebuild_copy_on_demand(x,y) ({ \
	aroop_txt_destroy(x); \
	aroop_txt_embeded_copy_on_demand_helper(x,y); \
})

#define aroop_txt_embeded_rebuild_copy_shallow(x,y) ({ \
	aroop_txt_destroy(x); \
	aroop_txt_embeded_copy_shallow(x,y); \
})

#define aroop_txt_embeded_txt_copy_shallow(x,y) ({ \
	aroop_memclean_raw2(x); \
	aroop_txt_embeded_txt_copy_shallow_helper(x,y); \
})
#define aroop_txt_embeded_txt_copy_shallow_helper(x,y) ({ \
	if((y)->proto) { \
		(x)->proto = OPPREF((y)->proto); \
		(x)->str = (y)->str; \
	} else { \
		(x)->str = (y)->str; \
		(x)->proto = OPPREF(y); \
	} \
	(x)->hash = (y)->hash; \
	(x)->len = (y)->len; \
	(x)->size=(x)->len+1; \
})

#if 1
#define aroop_txt_embeded_copy_shallow(x,y) ({ \
	*(x) = *(y); \
	if((x)->proto) { \
		OPPREF((x)->proto); \
	} \
})
#else
#define aroop_txt_embeded_copy_shallow(x,y) ({ \
	aroop_memclean_raw2(x); \
	if((y)->proto) { \
		(x)->proto = OPPREF((y)->proto); \
		(x)->str = (y)->str; \
	} else { \
		(x)->str = (y)->str; \
		(x)->proto = NULL; \
	} \
	(x)->hash = (y)->hash; \
	(x)->len = (y)->len; \
	(x)->size=(x)->len+1; \
})
#endif

#define aroop_txt_embeded_copy_deep(x,y) ({\
	aroop_memclean_raw2(x); \
	opp_str2_dup2(&(x)->str, (y)->str); \
	(x)->proto = (x)->str; \
	(x)->hash = (y)->hash; \
	(x)->len = (y)->len; \
	(x)->size=(x)->len+1; \
})
#define aroop_txt_embeded_copy_static_string(x,y) ({\
	aroop_memclean_raw2(x); \
	opp_str2_dup2(&(x)->str, y); \
	(x)->proto = (x)->str; \
	(x)->hash = 0; \
	(x)->len = sizeof(y)-1; \
	(x)->size=(x)->len+1; \
})


#define aroop_txt_embeded_copy_string(x,y) ({\
	aroop_memclean_raw2(x); \
	opp_str2_dup2(&(x)->str, y); \
	(x)->proto = (x)->str; \
	(x)->hash = 0; \
	(x)->len = strlen(y); \
	(x)->size=(x)->len+1; \
})


#define aroop_txt_embeded_buffer(x,y) ({aroop_txt_destroy(x);if(((x)->proto = opp_str2_alloc(y))) {(x)->size = y;}(x)->str = (x)->proto;})
#define aroop_txt_embeded_stackbuffer(x,y) ({ \
	char*aroop_internal_buf = alloca(y+1)/*char buf##y[y]*/; \
	(x)->str = aroop_internal_buf; \
	(x)->size = y; \
	(x)->len = 0; \
	(x)->proto = NULL; \
	(x)->hash = 0; \
})

#define aroop_txt_embeded_stackbuffer_from_txt(x,y) ({ \
	char*aroop_internal_buf = (char*)alloca((y)->len+1)/*char buf##y[(y)->len+1]*/; \
	memcpy(aroop_internal_buf,(y)->str,(y)->len); \
	(x)->str = aroop_internal_buf; \
	(x)->size = (y)->len; \
	(x)->len = (y)->len; \
	(x)->str[(x)->len] = '\0'; \
	(x)->proto = NULL; \
	(x)->hash = (y)->hash; \
})

#define aroop_txt_embeded_static(x,y) ({(x)->proto = NULL;(x)->str = y;(x)->hash = 0;(x)->size = sizeof(y);(x)->len=(x)->size-1;})
#define aroop_txt_embeded_rebuild_and_set_static_string(x,y) ({aroop_txt_destroy(x);aroop_txt_embeded_static(x,y);})

#if false
aroop_txt_t*xultb_subtxt(aroop_txt_t*src, int off, int width, aroop_txt_t*dest);
#endif
#define xultb_subtxt(src,off,width,dest) ({(dest)->str = (src)->str+off;(dest)->len = width;(dest)->hash=0;dest;})

#define aroop_txtcmp(x,y) ({int min = (x)->len>(y)->len?(y)->len:(x)->len;memcmp((x)->str, (y)->str, min);})
#define aroop_txt_equals(x,y) ({((x) && (y) && (x)->len == (y)->len && !memcmp((x)->str, (y)->str, (x)->len));})
#define aroop_txt_iequals(x,y) ({((x) && (y) && (x)->len == (y)->len && !strncasecmp((x)->str, (y)->str, (x)->len));})

#define aroop_txt_equals_static(x,static_y) ({((x) && (x)->len == (sizeof(static_y)-1) && !memcmp((x)->str, static_y,(x)->len));})
#define aroop_txt_equals_chararray(x,y) ({((!(x) && !(y)) || ((x) && !(x)->str && !(y) )) || ((x) && !strcmp((x)->str, y));})
#define aroop_txt_zero_terminate(x) ({if((x)->len < (x)->size && (x)->str != NULL && (x)->str[(x)->len] != '\0') (x)->str[(x)->len] = '\0';})
#define aroop_txt_is_zero_terminated(x) ({((x)->len < (x)->size && (x)->str != NULL && (x)->str[(x)->len] == '\0');})

#define aroop_txt_printf(x, ...) ({(x)->len = snprintf((x)->str, (x)->size - 1, __VA_ARGS__);})

aroop_txt_t*aroop_txt_new(char*content, int len, aroop_txt_t*proto, int scalability_index);
#define aroop_txt_new_alloc(x,y) aroop_txt_new(NULL, x, NULL, y)
#define aroop_txt_new_copy_on_demand(x,sc) ({((x)->proto)?aroop_txt_new((x)->str,(x)->len,(x)->proto,sc):aroop_txt_clone((x)->str,(x)->len,sc);})
#define aroop_txt_new_copy_deep(x,y) aroop_txt_clone((x)->str, (x)->len, y)
#define aroop_txt_new_copy_shallow(x,sc) aroop_txt_new((x)->str, (x)->len, (x)->proto, sc)
#define aroop_txt_copy_string(x) aroop_txt_clone(x, strlen(x), 0)
#define aroop_txt_memcopy_from_etxt_factory_build(x,y) ({ \
	(x)->str = (((aroop_txt_t*)x)+1); \
	(x)->size=(y)->len; \
	(x)->len=(y)->len; \
	(x)->hash = (y)->hash; \
	(x)->proto = NULL; \
	memcpy((x)->str,(y)->str,(x)->len); \
})
#define aroop_txt_copy_static_string(x) ({aroop_txt_clone(x,sizeof(x)-1, 0);})
#define aroop_txt_set_static_string(x) ({aroop_txt_new(x,sizeof(x)-1,NULL, 0);})
aroop_txt_t*aroop_txt_clone(const char*content, int len, int scalability_index);
aroop_txt_t*aroop_txtrim(aroop_txt_t*text);

aroop_txt_t*aroop_txt_cat(aroop_txt_t*text, aroop_txt_t*suffix);
aroop_txt_t*aroop_txt_cat_char(aroop_txt_t*text, char c);
aroop_txt_t*aroop_txt_cat_static(aroop_txt_t*text, char*suffix);
aroop_txt_t*aroop_txt_set_len(aroop_txt_t*text, int len);
#define aroop_txt_indexof_char(haystack, niddle) ({const char*haystack##pos = strchr((haystack)->str, niddle);int haystack##i = -1;if(haystack##pos && haystack##pos < ((haystack)->str+(haystack)->len))haystack##i = haystack##pos-(haystack)->str;haystack##i;})
#define aroop_txt_size(x) ({(x)->size;})
#define aroop_txt_length(x) ({(x)->len;})
#define aroop_txt_trim_to_length(x,y) ({if(y < (x)->len)(x)->len = y;})
#define aroop_txt_get_hash(x) ({((x)->hash != 0)?(x)->hash:((x)->hash = opp_get_hash_bin((x)->str, (x)->len));})
#define aroop_txt_to_vala(x) ({(char*)(((x)&&(x)->str)?(x)->str:"(null)");})
#define aroop_txt_to_int(x) ({((x) && (x)->str)?atoi((x)->str):0;})
#define aroop_txt_to_vala_magical(x) ({(((x)&&(x)->str&&(x)->len!=0)?(x)->str:"(null)");})
#define aroop_txt_is_empty(x) ({(!((x)->str) || ((x)->len == 0));})
#define aroop_txt_is_empty_magical(x) ({(!(x) || !((x)->str) || ((x)->len == 0));})
#define aroop_txt_string_or(x,y) ({((x)->str&&(x)->len!=0)?x:y;})
#define aroop_txt_string_or_magical(x,y) ({((x)&&(x)->str&&(x)->len!=0)?x:y;})
#define aroop_txt_destroy(x) ({if((x)->proto){OPPUNREF((x)->proto);}(x)->str = NULL;(x)->len = 0;(x)->hash = 0;(x)->size = 0;})

// string play
// TODO optimize this shift code
#define aroop_txt_shift_token(x,s,y) ({ \
	aroop_txt_destroy(y); \
	char*aroop_internal_p = (x)->str; \
	(y)->str = strsep(&((x)->str),s); \
	if((y)->str){ \
		(y)->len = strlen(((y)->str)); \
		if((x)->proto){(y)->proto = OPPREF(((x)->proto));} \
	} \
	(x)->len = (x)->str?strlen(((x)->str)):0; \
	(x)->size = (x)->str?((x)->size - ((x)->str - aroop_internal_p)):(x)->len; \
})

#define aroop_txt_move_to_what_the_hell(x,y) ({ \
	if((x)->str && (y)->str && (x)->len <= (y)->size){ \
		memmove((y)->str, (x)->str, (x)->len); \
		(y)->len = (x)->len; \
		(x)->size = (y)->size; \
		(x)->str = (y)->str; \
		if((x)->proto) { \
			OPPUNREF((x)->proto); \
		} \
		if((y)->proto) { \
			(x)->proto = OPPREF((y)->proto); \
		} \
	} \
})

// char operation
#define aroop_txt_char_at(x,i) ({((x)->str && (x)->len > i)?(x)->str[i]:'\0';})
#define aroop_txt_contains_char(x,c) ({((x)->str)?memchr((x)->str,c,(x)->len):0;})
#define aroop_txt_shift(x,inc) ({ \
	if((x)->str) { \
		if(inc < 0) { \
			if((x)->len >= (-inc)) { \
				(x)->len+=inc; \
				(x)->hash = 0; \
				1; \
			} else { \
				0; \
			} \
		} else if((x)->len >= inc){ \
			(x)->str+=inc; \
			(x)->len-=inc; \
			(x)->size-=inc; \
			(x)->hash = 0; \
			1; \
		} else { \
			0; \
		} \
	}else{0;} \
})

#define aroop_txt_concat(x,y) { \
	int aroop_internal_ret = (y) && (y)->str && ((x)->len+(y)->len <= (x)->size); \
	if(aroop_internal_ret) { \
		memmove((x)->str+(x)->len, (y)->str, (y)->len); \
		(x)->hash = 0; \
		(x)->len += (y)->len; \
	} \
	aroop_internal_ret; \
}
#define aroop_txt_concat_string(x,y) { \
	int aroop_internal_len = strlen(y); \
	int aroop_internal_ret = (y) && ((x)->len+aroop_internal_len <= (x)->size); \
	if(aroop_internal_ret) { \
		memmove((x)->str+(x)->len, (y), aroop_internal_len); \
		(x)->hash = 0; \
		(x)->len += aroop_internal_len; \
	} \
	aroop_internal_ret; \
}
#define aroop_txt_concat_char(x,y) { \
	int aroop_internal_ret = (((x)->len+1) < (x)->size); \
	if(aroop_internal_ret) { \
		(x)->str[(x)->len] = (y); \
		(x)->hash = 0; \
		(x)->len++; \
	} \
	aroop_internal_ret; \
}

#define aroop_txt_factory_build_and_copy_deep(f,x) ({aroop_txt_t*aroop_internal_x = opp_alloc4(f,sizeof(aroop_txt_t)+x->len+1,0,0,NULL);aroop_txt_memcopy_from_etxt_factory_build(aroop_internal_x,x);aroop_internal_x;})
#define aroop_txt_searchable_factory_build_and_copy_deep(f,x) ({aroop_searchable_txt_t*aroop_internal_x = opp_alloc4(f,sizeof(aroop_searchable_txt_t)+x->len+1,0,0,NULL);aroop_txt_memcopy_from_etxt_factory_build(&aroop_internal_x->tdata,x);aroop_internal_x;})

// system 
void aroop_txt_system_init();
void aroop_txt_system_deinit();

int aroop_txt_printf_extra(aroop_txt_t*output, char* format, ...);

OPP_CB_NOSTATIC(aroop_txt);
OPP_CB_NOSTATIC(aroop_searchable_txt);
#define aroop_txt_t_pray OPP_CB_FUNC(aroop_txt)
#define aroop_searchable_txt_t_pray OPP_CB_FUNC(aroop_searchable_txt)

extern aroop_txt_t*BLANK_STRING;
extern opp_equals_t aroop_txt_equals_cb;
extern opp_hash_function_t aroop_txt_get_hash_cb;

C_CAPSULE_END

#endif /* XULTB_STRING_H_ */
