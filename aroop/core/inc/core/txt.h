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
#endif

C_CAPSULE_START

// TODO build an immutable txt ..
struct aroop_txt {
	aroop_none*proto;
	int hash;
	int size;
	int len;
	char*str;
} typedef arptxt;

struct aroop_hashable_txt {
	OPP_OBJECT_EXT_TINY();
	struct aroop_txt tdata;
};

typedef struct aroop_txt aroop_txt;
typedef int xultb_bool_t;

#define aroop_txt_embeded_new_with_length(x,y,z,p) ({ \
	(x)->proto = NULL, \
	(x)->str = y, \
	(x)->hash = 0, \
	(x)->len = z; \
	(x)->size=(x)->len+1; \
})
#define aroop_txt_embeded_with_length(x,y,z,p) ({aroop_txt_destroy(x);aroop_txt_embeded_new_with_length(x,y,z,p);})
#define aroop_txt_embeded(x,y,p) ({(x)->proto = NULL,(x)->str = y,(x)->hash = 0,(x)->len = strlen(y);(x)->size=(x)->len+1;})
#define aroop_txt_embeded_reuse_embeded(x,y) ({ \
	aroop_memclean_raw2(x); \
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


#define aroop_txt_embeded_share_txt(x,y) ({ \
	aroop_memclean_raw2(x); \
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

#define aroop_txt_embeded_share_embeded(x,y) ({ \
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

#define aroop_txt_embeded_dup_embeded(x,y) ({\
	aroop_memclean_raw2(x); \
	opp_str2_dup2(&(x)->str, (y)->str); \
	(x)->proto = (x)->str; \
	(x)->hash = (y)->hash; \
	(x)->len = (y)->len; \
	(x)->size=(x)->len+1; \
})

#define aroop_txt_embeded_dup_string(x,y) ({\
	aroop_memclean_raw2(x); \
	opp_str2_dup2(&(x)->str, y); \
	(x)->proto = (x)->str; \
	(x)->hash = 0; \
	(x)->len = strlen(y); \
	(x)->size=(x)->len+1; \
})

#define aroop_txt_embeded_same_same(x,y) ({ \
	*(x) = *(y); \
	if((x)->proto) { \
		OPPREF((x)->proto); \
	} \
})

#define aroop_txt_embeded_buffer(x,y) ({aroop_txt_destroy(x);if(((x)->str = opp_str2_alloc(y))) {(x)->size = y;}(x)->str;(x)->proto = (x)->str;})
#define aroop_txt_embeded_stackbuffer(x,y) ({ \
	char*__buf = alloca(y+1)/*char buf##y[y]*/; \
	(x)->str = __buf; \
	(x)->size = y; \
	(x)->len = 0; \
	(x)->proto = NULL; \
	(x)->hash = 0; \
})

#define aroop_txt_embeded_stackbuffer_from_txt(x,y) ({ \
	char*__buf = (char*)alloca((y)->len+1)/*char buf##y[(y)->len+1]*/; \
	memcpy(__buf,(y)->str,(y)->len); \
	(x)->str = __buf; \
	(x)->size = (y)->len; \
	(x)->len = (y)->len; \
	(x)->str[(x)->len] = '\0'; \
	(x)->proto = NULL; \
	(x)->hash = (y)->hash; \
})

#define aroop_txt_embeded_static(x,y) ({(x)->proto = NULL,(x)->str = y,(x)->hash = 0,(x)->len = sizeof(y) - 1;(x)->size=(x)->len+1;})

#if false
aroop_txt*xultb_subtxt(aroop_txt*src, int off, int width, aroop_txt*dest);
#endif
#define xultb_subtxt(src,off,width,dest) ({(dest)->str = (src)->str+off;(dest)->len = width;(dest)->hash=0;dest;})

#define aroop_txtcmp(x,y) ({int min = (x)->len>(y)->len?(y)->len:(x)->len;memcmp((x)->str, (y)->str, min);})
#define aroop_txt_equals(x,y) ({((x) && (y) && (x)->len == (y)->len && !memcmp((x)->str, (y)->str, (x)->len));})
#define aroop_txt_iequals(x,y) ({((x) && (y) && (x)->len == (y)->len && !strncasecmp((x)->str, (y)->str, (x)->len));})

#define aroop_txt_equals_static(x,static_y) ({char static_text[] = static_y;((x) && (x)->len == (sizeof(static_y)-1) && !memcmp((x)->str, static_text,(x)->len));})
#define aroop_txt_equals_chararray(x,y) ({((!(x) && !(y)) || ((x) && !(x)->str && !(y) )) || ((x) && !strcmp((x)->str, y));})
#define aroop_txt_zero_terminate(x) ({if((x)->len < (x)->size && (x)->str != NULL) (x)->str[(x)->len] = '\0';})
#define aroop_txt_is_zero_terminated(x) ({((x)->len < (x)->size && (x)->str != NULL && (x)->str[(x)->len] == '\0');})

#define aroop_txt_printf(x, ...) ({(x)->len = snprintf((x)->str, (x)->size - 1, __VA_ARGS__);})

aroop_txt*aroop_txt_new(char*content, int len, aroop_txt*proto, int scalability_index);
#define aroop_txt_memcopy_from_etxt_factory_build(x,y) ({ \
	(x)->str = (((aroop_txt*)x)+1); \
	(x)->size=(y)->len; \
	(x)->len=(y)->len; \
	(x)->hash = (y)->hash; \
	(x)->proto = NULL; \
	memcpy((x)->str,(y)->str,(x)->len); \
})
#define aroop_txt_new_static(x) ({aroop_txt_new(x,sizeof(x)-1, NULL, 0);})
aroop_txt*aroop_txt_clone(const char*content, int len, int scalability_index);
#define aroop_txt_clone_etxt(x) aroop_txt_clone((x)->str, (x)->len, 0)
aroop_txt*aroop_txtrim(aroop_txt*text);

aroop_txt*aroop_txt_cat(aroop_txt*text, aroop_txt*suffix);
aroop_txt*aroop_txt_cat_char(aroop_txt*text, char c);
aroop_txt*aroop_txt_cat_static(aroop_txt*text, char*suffix);
aroop_txt*aroop_txt_set_len(aroop_txt*text, int len);
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
#define aroop_txt_destroy(x) ({if((x)->proto)OPPUNREF((x)->proto);(x)->str = NULL;(x)->len = 0;(x)->hash = 0;(x)->size = 0;})

// string play
// TODO optimize this shift code
#define aroop_txt_shift_token(x,s,y) ({ \
	aroop_txt_destroy(y); \
	char*_p = (x)->str; \
	(y)->str = strsep(&((x)->str),s); \
	if((y)->str){ \
		(y)->len = strlen(((y)->str)); \
		if((x)->proto){(y)->proto = OPPREF(((x)->proto));} \
	} \
	(x)->len = (x)->str?strlen(((x)->str)):0; \
	(x)->size = (x)->str?((x)->size - ((x)->str - _p)):(x)->len; \
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
	int __ret = (y) && (y)->str && ((x)->len+(y)->len <= (x)->size); \
	if(__ret) { \
		memmove((x)->str+(x)->len, (y)->str, (y)->len); \
		(x)->hash = 0; \
		(x)->len += (y)->len; \
	} \
	__ret; \
}
#define aroop_txt_concat_char(x,y) { \
	int __ret = (((x)->len+1) < (x)->size); \
	if(__ret) { \
		(x)->str[(x)->len] = (y); \
		(x)->hash = 0; \
		(x)->len++; \
	} \
	__ret; \
}

// system 
void aroop_txt_system_init();
void aroop_txt_system_deinit();

int aroop_txt_printf_extra(aroop_txt*output, char* format, ...);

OPP_CB_NOSTATIC(aroop_txt);
#define arptxt_pray OPP_CB_FUNC(aroop_txt)

extern aroop_txt*BLANK_STRING;

C_CAPSULE_END

#endif /* XULTB_STRING_H_ */
