/*
 * utils.c
 *
 *  Created on: Dec 29, 2010
 *      Author: kgm212
 */

#ifndef SYNC_MEMORY_H
#define SYNC_MEMORY_H

#include "core/config.h"

#ifdef __EPOC32___CLIENT
#if 0
#define USE_SYMBIAN_ALLOC
void*symb_malloc(size_t size);
void symb_free(void*memory);
#define sync_malloc symb_malloc
#define sync_free symb_free
#else
#define sync_malloc malloc
#define sync_free free
#endif
#else
#define sync_malloc malloc
#define sync_free free
#endif


#define SYNC_EMPTY_STRING(x) ({(!x||*x == '\0');})

#define SYNC_ARRAY_LEN(a) (sizeof(a) / sizeof(0[a]))

#define STR_OR(x,y) (x?x:y)

#endif // SYNC_MEMORY_H
