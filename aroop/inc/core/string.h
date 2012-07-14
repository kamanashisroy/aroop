/*
 * xultb_string.h
 *
 *  Created on: Dec 21, 2011
 *      Author: ayaskanti
 */

#ifndef XULTB_STRING_H_
#define XULTB_STRING_H_

#include "core/config.h"

C_CAPSULE_START

// TODO build an immutable string ..
struct xultb_str {
	struct xultb_str*proto;
	int hash;
	int size;
	int len;
	char*str;
};

typedef struct xultb_str xultb_str_t;
typedef int xultb_bool_t;

#define xultb_str_create(x) ({xultb_str_t y;y.str = x,y.hash = 0,y.len = strlen(x);y.size=y.len+1;y;})

#if 0
xultb_str_t*xultb_substring(xultb_str_t*src, int off, int width, xultb_str_t*dest);
#endif
#define xultb_substring(src,off,width,dest) ({(dest)->str = (src)->str+off;(dest)->len = width;(dest)->hash=0;dest;})

#define xultb_strcmp(x,y) ({int min = x->len>y->len?y->len:x->len;memcmp(x->str, y->str, min);})

#define xultb_str_equals_static(x,static_y) ({char static_text[] = static_y;(x && x->len == (sizeof(static_text)-1) && !memcmp(x->str, static_text,x->len));})


xultb_str_t*xultb_str_alloc(char*content, int len, xultb_str_t*proto, int scalability_index);
#define xultb_str_alloc_static(x) ({xultb_str_alloc(x,sizeof(x)-1, NULL, 0);})
xultb_str_t*xultb_str_clone(const char*content, int len, int scalability_index);
xultb_str_t*xultb_str_trim(xultb_str_t*text);

xultb_str_t*xultb_str_cat(xultb_str_t*text, xultb_str_t*suffix);
xultb_str_t*xultb_str_cat_char(xultb_str_t*text, char c);
xultb_str_t*xultb_str_cat_static(xultb_str_t*text, char*suffix);
xultb_str_t*xultb_str_set_len(xultb_str_t*text, int len);
#define xultb_str_indexof_char(haystack, niddle) ({const char*haystack##pos = strchr(haystack->str, niddle);int haystack##i = -1;if(haystack##pos && haystack##pos < (haystack->str+haystack->len))haystack##i = haystack##pos-haystack->str;haystack##i;})

void xultb_str_system_init();

C_CAPSULE_END

#endif /* XULTB_STRING_H_ */
