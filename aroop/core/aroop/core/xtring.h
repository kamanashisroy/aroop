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
#include "aroop/core/config.h"
#include "aroop/aroop_core.h"
#include "aroop/opp/opp_hash.h"
#include "aroop/opp/opp_hash_table.h"
#endif

C_CAPSULE_START

enum {
	XTRING_IS_IMMUTABLE = 1,
	XTRING_IS_ARRAY = 1<<2,
};

struct aroop_txt {
	SYNC_UWORD16_T internal_flag;
	SYNC_UWORD16_T size;
	SYNC_UWORD16_T len;
	opp_hash_t hash;
	union {
		struct aroop_txt_pointer {
			aroop_none*proto;
			char*str;
		} pointer;
		char str[1];
	} content;
} typedef aroop_txt_t;

struct aroop_searchable_txt {
	struct opp_object_ext aroop_internal_ext;
	struct aroop_txt tdata;
} typedef aroop_searchable_txt_t;

typedef int xultb_bool_t;

#define aroop_searchable_string_rehash(y) ({opp_set_hash(y, aroop_txt_get_hash(&(y)->tdata));})
#define aroop_txt_to_embeded_pointer(x) (x)

#define aroop_txt_embeded_set_content(x,y,z,p) ({ \
	(x)->internal_flag = 0, \
	(x)->content.pointer.proto = p, \
	(x)->content.pointer.str = y, \
	(x)->hash = 0, \
	(x)->len = z; \
	(x)->size=(x)->len; \
})
#define aroop_txt_embeded_rebuild_and_set_content(x,y,z,p) ({aroop_txt_destroy(x);aroop_txt_embeded_set_content(x,y,z,p);})
#define aroop_txt_embeded(x,y,p) ({(x)->internal_flag = 0,(x)->content.pointer.proto = p,(x)->content.pointer.str = (y),(x)->hash = 0,(x)->len = strlen(y);(x)->size=(x)->len;})
#define aroop_txt_embeded_copy_on_demand_helper(x,y) ({ \
	(x)->internal_flag = ((y)->internal_flag & XTRING_IS_IMMUTABLE); \
	(x)->hash = (y)->hash; \
	(x)->len = (y)->len; \
	(x)->size=(y)->size; \
	if((y)->internal_flag & XTRING_IS_ARRAY) { \
		(x)->content.pointer.proto = (y); \
		(x)->content.pointer.str = (y)->content.str; \
	} else if((y)->content.pointer.proto) { \
		(x)->content.pointer.proto = OPPREF((y)->content.pointer.proto); \
		(x)->content.pointer.str = (y)->content.pointer.str; \
	} else { \
		opp_str2_reuse2(&(x)->content.pointer.str, (y)->content.pointer.str, (y)->len); \
		(x)->content.pointer.proto = (x)->content.pointer.str; \
		(x)->len = (y)->len+1; \
	} \
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
	aroop_txt_embeded_txt_copy_shallow(x,y); \
})

#define aroop_txt_embeded_txt_copy_shallow(x,y) ({ \
	aroop_memclean_raw2(x); \
	aroop_txt_embeded_txt_copy_shallow_helper(x,y); \
})
#define aroop_txt_embeded_txt_copy_shallow_helper(x,y) ({ \
	(x)->internal_flag = ((y)->internal_flag & XTRING_IS_IMMUTABLE); \
	(x)->hash = (y)->hash; \
	(x)->len = (y)->len; \
	(x)->size=(y)->size; \
	if((y)->internal_flag & XTRING_IS_ARRAY) { \
		(x)->content.pointer.proto = (y); \
		(x)->content.pointer.str = (y)->content.str; \
	} else if((y)->content.pointer.proto) { \
		(x)->content.pointer.proto = OPPREF((y)->content.pointer.proto); \
		(x)->content.pointer.str = (y)->content.pointer.str; \
	} else { \
		(x)->content.pointer.proto = NULL; \
		(x)->content.pointer.str = (y)->content.pointer.str; \
		(x)->len = (y)->len; \
	} \
})

#define aroop_txt_embeded_copy_deep(x,y) ({\
	aroop_memclean_raw2(x); \
	opp_str2_dup2(&(x)->content.pointer.str, aroop_txt_to_string(y), (y)->len); \
	(x)->content.pointer.proto = (x)->content.pointer.str; \
	(x)->hash = (y)->hash; \
	(x)->len = (y)->len; \
	(x)->size=(x)->len+1; \
})
#define aroop_txt_embeded_copy_static_string(x,y) aroop_txt_embeded_copy_string_helper(x,y,sizeof(y)-1)
#define aroop_txt_embeded_copy_string(x,y) aroop_txt_embeded_copy_string_helper(x,y,strlen(y))
#define aroop_txt_embeded_copy_string_helper(x,y,ylen) ({\
	aroop_memclean_raw2(x); \
	(x)->len = ylen; \
	opp_str2_dup2(&(x)->content.pointer.str, y, (x)->len); \
	(x)->content.pointer.proto = (x)->content.pointer.str; \
	(x)->hash = 0; \
	(x)->size=(x)->len+1; \
})


#define aroop_txt_embeded_buffer(x,y) ({aroop_txt_destroy(x);if(((x)->content.pointer.proto = opp_str2_alloc(y))) {(x)->size = y;}(x)->content.pointer.str = (x)->content.pointer.proto;})
#define aroop_txt_embeded_stackbuffer(x,y) ({ \
	(x)->internal_flag = 0; \
	(x)->content.pointer.str = alloca(y+1); \
	(x)->size = y+1; \
	(x)->len = 0; \
	(x)->content.pointer.proto = NULL; \
	(x)->hash = 0; \
})

#define aroop_txt_to_string(x) ({((x)->internal_flag & XTRING_IS_ARRAY)?(x)->content.str:(x)->content.pointer.str;})

#define aroop_txt_embeded_stackbuffer_from_txt(x,y) ({ \
	(x)->internal_flag = 0; \
	char*aroop_internal_buf = (char*)alloca((y)->len+1); \
	memcpy(aroop_internal_buf,aroop_txt_to_string(y),(y)->len); \
	(x)->content.pointer.str = aroop_internal_buf; \
	(x)->content.pointer.proto = NULL; \
	(x)->size = (y)->len+1; \
	(x)->len = (y)->len; \
	(x)->content.pointer.str[(x)->len] = '\0'; \
	(x)->hash = (y)->hash; \
})

#define aroop_txt_embeded_set_static_string(x,y) ({ \
	(x)->internal_flag = XTRING_IS_IMMUTABLE; \
	(x)->content.pointer.str = y; \
	(x)->content.pointer.proto = NULL; \
	(x)->hash = 0;(x)->size = sizeof(y);(x)->len=(x)->size-1; \
})
#define aroop_txt_embeded_rebuild_and_set_static_string(x,y) ({aroop_txt_destroy(x);aroop_txt_embeded_set_static_string(x,y);})

#define aroop_txtcmp(x,y) ({int min = (x)->len>(y)->len?(y)->len:(x)->len;memcmp(aroop_txt_to_string(x), aroop_txt_to_string(y), min);})
#define aroop_txt_equals(x,y) ({((x) && (y) && (x)->len == (y)->len && !memcmp(aroop_txt_to_string(x), aroop_txt_to_string(y), (x)->len));})
#define aroop_txt_iequals(x,y) ({((x) && (y) && (x)->len == (y)->len && !strncasecmp(aroop_txt_to_string(x), aroop_txt_to_string(y), (x)->len));})

#define aroop_txt_equals_chararray_helper(x,y,calclen) ({((x) && (y) && (x)->len == (calclen) && !memcmp(aroop_txt_to_string(x), y,(x)->len));})
#define aroop_txt_equals_static(x,static_y) aroop_txt_equals_chararray_helper(x,static_y,sizeof(static_y)-1)
#define aroop_txt_equals_chararray(x,y) aroop_txt_equals_chararray_helper(x,y,strlen(y))
#define aroop_txt_zero_terminate(x) ({ \
	int internal_return = 0; \
	if(!((x)->internal_flag & XTRING_IS_IMMUTABLE) && (x)->len < (x)->size) { \
		char*internal_str = aroop_txt_to_string(x); \
		if(internal_str && internal_str[(x)->len] != '\0') internal_str[(x)->len] = '\0'; \
		internal_return = 1; \
	} \
	internal_return; \
})
#define aroop_txt_is_zero_terminated(x) ({ \
	char*internal_str = aroop_txt_to_string(x); \
	(internal_str && (x)->len < (x)->size && internal_str[(x)->len] == '\0'); \
})

#define aroop_txt_printf(x, ...) ({(x)->len = snprintf(aroop_txt_to_string(x), (x)->size - 1, __VA_ARGS__);})

aroop_txt_t*aroop_txt_new_set_content(char*content, int len, aroop_txt_t*proto, struct opp_factory*gpool);
aroop_txt_t*aroop_txt_new_alloc(int len, struct opp_factory*gpool);
#define aroop_txt_new_copy_on_demand(x,fac) ({ \
	if((x)->internal_flag & XTRING_IS_ARRAY) { \
		aroop_txt_new_set_content((x)->content.str, (x)->len, (x), fac); \
	} else if((x)->content.pointer.proto) { \
		aroop_txt_new_set_content((x)->content.pointer.str, (x)->len, (x)->content.pointer.proto, fac); \
	} else { \
		aroop_txt_new_copy_content_deep((x)->content.pointer.str,(x)->len,fac); \
	} \
	0; \
})
#define aroop_txt_new_copy_deep(x,y) aroop_txt_new_copy_content_deep(aroop_txt_to_string(x), (x)->len, y)
#define aroop_txt_new_copy_shallow(x,sc) ({ \
	if((x)->internal_flag & XTRING_IS_ARRAY) { \
		aroop_txt_new_set_content((x)->content.str, (x)->len, (x), fac); \
	} else { \
		aroop_txt_new_set_content((x)->content.pointer.str, (x)->len, (x)->content.pointer.proto, fac); \
	} \
})
#define aroop_txt_copy_string(x,y) aroop_txt_new_copy_content_deep(x, strlen(x), y)
#define aroop_txt_memcopy_from_etxt_factory_build(x,y) ({ \
	(x)->internal_flag = XTRING_IS_ARRAY; \
	memcpy((x)->content.str,aroop_txt_to_string(y),(y)->len); \
	(x)->size=(y)->len; \
	(x)->len=(y)->len; \
	(x)->hash = (y)->hash; \
})
#define aroop_txt_copy_static_string(x,y) ({aroop_txt_new_copy_content_deep(x,sizeof(x)-1, y);})
#define aroop_txt_set_static_string(x,y) ({aroop_txt_new_set_content(x,sizeof(x)-1,NULL, y);})
aroop_txt_t*aroop_txt_new_copy_content_deep(const char*content, int len,  struct opp_factory*gpool);
#if false
aroop_txt_t*aroop_txtrim(aroop_txt_t*text);
aroop_txt_t*aroop_txt_cat(aroop_txt_t*text, aroop_txt_t*suffix);
aroop_txt_t*aroop_txt_cat_char(aroop_txt_t*text, char c);
aroop_txt_t*aroop_txt_cat_static(aroop_txt_t*text, char*suffix);
aroop_txt_t*aroop_txt_set_len(aroop_txt_t*text, int len);
#define aroop_txt_indexof_char(haystack, niddle) ({const char*haystack##pos = strchr((haystack)->str, niddle);int haystack##i = -1;if(haystack##pos && haystack##pos < ((haystack)->str+(haystack)->len))haystack##i = haystack##pos-(haystack)->str;haystack##i;})
#endif
#define aroop_txt_size(x) ({(x)->size;})
#define aroop_txt_length(x) ({(x)->len;})
#define aroop_txt_trim_to_length(x,y) ({if(y < (x)->len)(x)->len = y;})
#define aroop_txt_get_hash(x) ({((x)->hash != 0)?(x)->hash:((x)->hash = opp_get_hash_bin(aroop_txt_to_string(x), (x)->len));})
#define aroop_txt_to_string_cb(x,cb,defaultval) ({((!(x) || (x)->len ==0)?defaultval:(((x)->internal_flag & XTRING_IS_ARRAY)?(cb((x)->content.str)):(cb((x)->content.pointer.str))));})
#define aroop_txt_to_string_suffix(x,suffix,defaultval) ({((!(x) || (x)->len ==0)?defaultval:(((x)->internal_flag & XTRING_IS_ARRAY)?((x)->content.str suffix):((x)->content.pointer.str suffix)));})
#define aroop_txt_to_vala(x) aroop_txt_to_string_cb(x, (char*), "(null)")
#define aroop_txt_to_int(x) aroop_txt_to_string_cb(x,atoi,0)
#define aroop_txt_to_vala_magical(x) aroop_txt_to_vala(x)
#define aroop_txt_is_empty(x) ({((x)->len == 0);})
#define aroop_txt_is_empty_magical(x) ({(!(x) || ((x)->len == 0));})
#define aroop_txt_or(x,y) {aroop_txt_is_empty_magical(x)?y:x;})
#define aroop_txt_or_string_magical(x,y) aroop_txt_to_string_cb(x,(char*),y)
#define aroop_txt_destroy(x) ({if(!((x)->internal_flag & XTRING_IS_ARRAY)) {if((x)->content.pointer.proto){OPPUNREF((x)->content.pointer.proto);}(x)->content.pointer.str = NULL;(x)->size = 0;}else{(x)->content.str[0] = '\0';}(x)->len = 0;(x)->hash = 0;})

// string play
// TODO optimize this shift code
#define aroop_txt_shift_token(x,s,y) ({ \
	if((x)->internal_flag & XTRING_IS_ARRAY) SYNC_ASSERT(!"We cannot handle continuous string in shift token\n"); \
})

#if false
	aroop_txt_destroy(y); \
	(y)->internal_flag = ((x)->internal_flag & XTRING_IS_IMMUTABLE); \
	(y)->content.pointer.proto = NULL; \
	char*internal_old_str = aroop_txt_to_string_cb((x),char*,NULL); \
	char*internal_str = internal_old_str;
	if(((y)->content.pointer.str = strsep(internal_str,s))) { \
		(y)->len = internal_str - internal_old_str; \
		(x)->content.pointer.str = internal_str; \
		(y)->content.pointer.proto = ((x)->internal_flag & XTRING_IS_ARRAY)?(x):(x)->content.pointer.proto; \
		if((y)->content.pointer.proto) OPPREF((y)->content.pointer.proto); \
	} \
	(x)->len -= (y)->len; \
	(x)->size -= (y)->len; \
})
#endif

#if false
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
#endif

// char operation
#define aroop_txt_char_at(x,i) aroop_txt_to_string_suffix(x, [i], '\0')
#define aroop_txt_contains_char(x,c) ({((!(x) || (x)->len ==0)?NULL:((x)->internal_flag & XTRING_IS_ARRAY)?memchr((x)->content.str, c, (x)->len):memchr((x)->content.pointer.str, c, (x)->len));})
#define aroop_txt_shift(x,inc) ({ \
	if((x)->len) { \
		if(inc < 0) { \
			if((x)->len >= (-inc)) { \
				(x)->len+=inc; \
				(x)->hash = 0; \
				1; \
			} else { \
				0; \
			} \
		} else if((x)->len >= inc){ \
			if((x)->internal_flag & XTRING_IS_ARRAY) { \
				if((x)->len-inc)memmove((x)->content.str, (x)->content.str+inc, (x)->len-inc); \
			} else { \
				(x)->content.pointer.str+=inc; \
				(x)->size-=inc; \
			} \
			(x)->len-=inc; \
			(x)->hash = 0; \
			1; \
		} else { \
			0; \
		} \
	}else{0;} \
})

#define aroop_txt_concat(x,y) { \
	int aroop_internal_ret = !((x)->internal_flag & XTRING_IS_IMMUTABLE) && !aroop_txt_is_empty_magical(y) && ((x)->len+(y)->len <= (x)->size); \
	if(aroop_internal_ret) { \
		memmove(aroop_txt_to_string(x)+(x)->len, aroop_txt_to_string(y), (y)->len); \
		(x)->hash = 0; \
		(x)->len += (y)->len; \
	} \
	aroop_internal_ret; \
}
#define aroop_txt_concat_string(x,y) { \
	int aroop_internal_len = strlen(y); \
	int aroop_internal_ret = !((x)->internal_flag & XTRING_IS_IMMUTABLE) && (y) && ((x)->len+aroop_internal_len <= (x)->size); \
	if(aroop_internal_ret) { \
		memmove(aroop_txt_to_string(x)+(x)->len, (y), aroop_internal_len); \
		(x)->hash = 0; \
		(x)->len += aroop_internal_len; \
	} \
	aroop_internal_ret; \
}
#define aroop_txt_concat_char(x,y) { \
	int aroop_internal_ret = !((x)->internal_flag & XTRING_IS_IMMUTABLE) && (((x)->len+1) < (x)->size); \
	if(aroop_internal_ret) { \
		if((x)->internal_flag & XTRING_IS_ARRAY)(x)->content.str[(x)->len] = y; else (x)->content.pointer.str[(x)->len] = y; \
		(x)->hash = 0; \
		(x)->len++; \
	} \
	aroop_internal_ret; \
}

#if false
#define aroop_txt_factory_build_and_copy_deep(f,x) ({aroop_txt_t*aroop_internal_x = opp_alloc4(f,sizeof(aroop_txt_t)+x->len+1,0,0,NULL);aroop_txt_memcopy_from_etxt_factory_build(aroop_internal_x,x);aroop_internal_x;})
#endif
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
